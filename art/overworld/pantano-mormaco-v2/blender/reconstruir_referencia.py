"""Rebuild the approved reference in its measured orthographic composition."""
from pathlib import Path
import json
import math
import random
import bpy
import bmesh
from mathutils import Vector
from mathutils.geometry import tessellate_polygon

OUT = Path(__file__).resolve().parent
SOURCE = OUT / "construir_lago.py"
# Reuse primitive builders and palette definitions without running the older scene.
exec(compile(SOURCE.read_text(encoding="utf-8").split("\nbuild_terrain()\n")[0], str(SOURCE), "exec"))
RNG = random.Random(812)
W, H, UNIT = 1672, 941, 52.0
CAM = camera("CAM_Referencia_Hero", (0, 0, 0), 100, W / UNIT)
scene.camera = CAM
ROT = CAM.rotation_euler.to_matrix()
RIGHT = ROT @ Vector((1, 0, 0))
UP = ROT @ Vector((0, 1, 0))
AWAY = Vector((-math.sqrt(.5), math.sqrt(.5), 0))
SUN = Vector((-.55, -.20, .80)).normalized()


def at(x, y, z=0):
    return RIGHT * ((x-W/2)/UNIT) + AWAY * (((H/2-y)/UNIT-z*math.cos(math.pi/6))/.5) + Vector((0, 0, z))


def pixel(point):
    point = Vector(point)
    return (W/2+point.dot(RIGHT)*UNIT, H/2-point.dot(UP)*UNIT)


def painted(name, color):
    return material(name, color)


rock_palette = [painted("Rochedo "+c,c) for c in ("414d65","4e586e","5c6276","697081","777b88","929098","696973","5e6264")]
top_palette = [painted("Grama de topo "+c,c) for c in ("7e9842","8eaa49","9bb34e","a6bb53","b3c267")]
path_palette = [painted("Areia compactada "+c,c) for c in ("bd9f73","d0ad7c","dcba86","e0c494")]
bush_palette = [painted("Folha pintada "+c,c) for c in ("21494b","315a4a","426f49","5c8448","7b9f4b","9ab34f","b3c567")]
stone_palette = [painted("Pedra solta "+c,c) for c in ("515c72","6c7382","888993","a4a096")]
wood_dark = painted("Madeira · sombra","66513f")
wood_light = painted("Madeira · topo","ae9062")
water_color = painted("Água profunda · lago","17677c")
water_shallow = painted("Água rasa","287e8d")
water_ripple = painted("Luz de água","4a9aab")
bright_foam = painted("Espuma clara","a4d6df")
flower_white = painted("Flor branca","e3e2bb")
flower_blue = painted("Flor azul","84b6d9")
foliage_mat = painted("Vinha verde","78973d")
banner_mat = painted("Estandarte azul","3d7098")

for item in rock_palette+top_palette+path_palette+stone_palette:
    shade_pattern(item,3.0,.10)


def signed(poly):
    return sum(a[0]*b[1]-a[1]*b[0] for a,b in zip(poly,poly[1:]+poly[:1]))


def polygon_parts(poly):
    vectors=[Vector((x,y,0)) for x,y in poly]
    return [[poly[i] for i in tri] for tri in tessellate_polygon([vectors])]


def flat(name, poly, z, mats, col):
    # Subdivide in a stable small grid and give restrained color variation.
    result=Surface()
    tri=polygon_parts(poly)
    for shape in tri:
        points=[at(x,y,z) for x,y in shape]
        normal=(points[1]-points[0]).cross(points[2]-points[0])
        if normal.z<0:
            points.reverse()
        result.face(points,min(2,len(mats)-1))
    return result.build(name,mats,col)


POOL = [(635,401),(658,368),(710,338),(788,316),(851,306),(919,309),(1019,332),(1126,364),(1193,403),(1247,446),(1251,469),(1223,498),(1169,527),(1092,548),(991,563),(892,565),(809,547),(747,519),(696,477),(659,434)]
POOL=[(x+max(0,x-1019)*.37,y) for x,y in POOL]
pool_controls=[Vector(p) for p in POOL]
POOL=[]
for i in range(len(pool_controls)):
    a,b,c,d=[pool_controls[(i+k)%len(pool_controls)] for k in (-1,0,1,2)]
    for j in range(3):
        t=j/3
        p=(2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)*.5
        POOL.append(tuple(p))
BASE = [(43,425),(126,374),(266,307),(389,247),(541,188),(715,157),(898,181),(1076,225),(1270,280),(1452,335),(1625,402),(1607,429),(1503,500),(1371,586),(1214,682),(1050,787),(901,870),(745,788),(572,699),(396,608),(218,516),(70,447)]
WEST = [(275,277),(385,228),(481,193),(596,199),(666,220),(738,241),(680,278),(624,310),(573,332),(525,336),(500,318),(481,299),(434,286),(405,322),(376,357),(342,366),(295,345),(261,321)]
MID = [(481,145),(550,110),(629,94),(713,95),(786,123),(838,142),(855,159),(815,181),(737,193),(665,195),(594,188),(526,171),(485,164)]
PEAK = [(597,56),(631,36),(683,15),(743,34),(791,57),(831,82),(820,104),(771,120),(716,112),(653,104),(600,88)]
REAR = [(796,201),(835,171),(878,162),(928,160),(978,172),(1041,195),(1111,221),(1195,254),(1279,290),(1369,327),(1455,363),(1510,393),(1492,406),(1419,375),(1350,338),(1276,309),(1190,279),(1104,248),(1029,221),(962,203),(931,198),(919,205),(897,205),(884,225),(861,238),(837,250),(813,254),(796,245)]


def clipped_floor(name, outline, z, exclusions, mats, col):
    # Clip in world XY to preserve a true hole after elevation.
    result=Surface()
    outline_xy=[Vector(at(x,y,z)[:2]) for x,y in outline]
    cuts=[]
    for excluded,ez in exclusions:
        for tri in polygon_parts(excluded):
            cut=[Vector(at(x,y,ez)[:2]) for x,y in tri]
            if (cut[1]-cut[0]).cross(cut[2]-cut[0])<0:
                cut.reverse()
            cuts.append(cut)
    poly_vectors=[Vector((*p,0)) for p in outline_xy]
    for indices in tessellate_polygon([poly_vectors]):
        fragment=[outline_xy[i] for i in indices]
        if signed(fragment)<0:
            fragment.reverse()
        fragments=[fragment]
        for cut in cuts:
            fragments=[part for piece in fragments for part in subtract_triangle(piece,cut)]
        for part in fragments:
            result.face([(p.x,p.y,z) for p in part],min(2,len(mats)-1))
    return result.build(name,mats,col)


CLIFF_CHECKS=[]


def cliff(name, outline, top_z, lower_z, col, grass_lip=True, closed=False):
    """One cyclic perimeter owns every joint, including the polygon corners."""
    crest=[]
    for a,b in zip(outline,outline[1:]+outline[:1]):
        p,q=at(*a,top_z),at(*b,top_z)
        count=max(1,math.ceil((q-p).length/.83))
        crest.extend(p.lerp(q,i/count) for i in range(count))
    n=len(crest)
    height=top_z-lower_z
    lip=[]
    middle=[]
    bottom=[]
    for i,p in enumerate(crest):
        tangent=(crest[(i+1)%n]-crest[(i-1)%n]).normalized()
        normal=Vector((tangent.y,-tangent.x,0))
        # Shared corners have one averaged normal and one displacement.
        offset=min(.13,height*.09)*math.sin(i*.67)
        dz=min(.18,height*.10)*math.sin(i*1.13)
        middle.append(Vector((p.x,p.y,top_z-height*.48+dz))+normal*offset)
        lip.append(p-Vector((0,0,min(.105,height*.18))))
        bottom.append(Vector((p.x,p.y,lower_z)))
    rings=[crest,lip,middle,bottom] if grass_lip else [crest,middle,bottom]
    wall=Surface()
    for row,(upper,lower) in enumerate(zip(rings,rings[1:])):
        for i in range(n):
            j=(i+1)%n
            ink=2+(1 if math.sin(i*.31+row*.23)>.45 else 0)
            if grass_lip and row==0: ink=len(rock_palette)
            # Triangulate non-planar panels consistently, without changing the seam.
            wall.face([upper[i],upper[j],lower[j]],ink)
            wall.face([upper[i],lower[j],lower[i]],ink)
    if closed:
        wall.face(crest,len(rock_palette)+1)
        wall.face(list(reversed(bottom)),2)
    obj=wall.build(name,rock_palette+[top_palette[1],top_palette[2]],col)
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    boundary=sum(e.is_boundary for e in bm.edges)
    bad=sum(not e.is_manifold for e in bm.edges)
    CLIFF_CHECKS.append({"name":name,"closed_solid":closed,"boundary_edges":boundary,"non_manifold_edges":bad,"expected_boundary_edges":0 if closed else 2*n})
    if closed and bad:
        raise RuntimeError(f"Escarpa aberta: {name}: {bad} arestas não manifold")
    if not closed and boundary!=2*n:
        raise RuntimeError(f"Fresta na parede {name}: {boundary} bordas; esperado {2*n}")
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    obj["Junções"]="Anéis cíclicos compartilhados; nenhuma borda lateral aberta"
    return obj


def plateau(name, poly, z, base):
    cliff(name+" · maciço fechado",poly,z,base,terrain,closed=True)


clipped_floor("Base · solo do diorama",BASE,0,[(POOL,-.38)],top_palette,terrain)
cliff("Base · rocha externa",BASE,0,-1.62,terrain)
plateau("Terraço oeste",WEST,1.42,0)
plateau("Patamar intermediário",MID,2.90,1.42)
plateau("Cume de trás",PEAK,4.19,2.90)
plateau("Margem alta da cachoeira",REAR,1.94,-.38)
flat("Lago · superfície",POOL,-.38,[water_color],lake)
cliff("Margem baixa · ligação contínua",[(x,y-.38*UNIT*math.cos(math.pi/6)) for x,y in POOL],0,-.39,terrain)


def ribbon_surface(name, points, width, z, mats, col, under=None):
    result=Surface()
    controls=[at(*p,z) for p in points]
    samples=[]
    for i in range(len(controls)-1):
        a,b,c,d=controls[max(0,i-1)],controls[i],controls[i+1],controls[min(len(controls)-1,i+2)]
        for j in range(10):
            t=j/10
            samples.append((2*b+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)*.5)
    samples.append(controls[-1])
    lefts,rights=[],[]
    for i,p in enumerate(samples):
        tangent=(samples[min(i+1,len(samples)-1)]-samples[max(0,i-1)]).normalized()
        side=Vector((-tangent.y,tangent.x,0))
        breadth=width*(.49+.065*math.sin(i*.79)+.035*math.sin(i*2.13))
        lefts.append(p-side*breadth)
        rights.append(p+side*breadth)
    for i in range(len(samples)-1):
        result.face([lefts[i],lefts[i+1],rights[i+1],rights[i]],min(2,len(mats)-1))
    return result.build(name,mats,col)


# Sand is a shaped continuous ribbon; broad paving opens at the front.
ribbon_surface("Trilha circular · frente",[(401,381),(476,441),(590,506),(677,554),(805,599),(933,648),(1016,677)],1.36,.021,path_palette,terrain)
ribbon_surface("Trilha circular · direita",[(1016,677),(1123,623),(1228,552),(1300,496),(1328,454)],1.04,.024,path_palette,terrain)
ribbon_surface("Trilha sobre a escada",[(465,282),(519,260),(589,243),(653,226)],1.01,1.442,path_palette,terrain)
flat("Praça da margem esquerda",[(344,377),(387,362),(454,382),(521,424),(516,461),(463,465),(400,430)],.025,path_palette,terrain)


def stair():
    upper_left,upper_right=at(428,283,1.42),at(489,302,1.42)
    lower_left,lower_right=at(375,362,0),at(436,385,0)
    sides=Surface()
    side_mat=stone_palette
    count=9
    for i in range(count):
        a,b=i/count,(i+1)/count
        z=1.42*(1-a)
        back_l=lower_left.lerp(upper_left,1-a)
        back_r=lower_right.lerp(upper_right,1-a)
        front_l=lower_left.lerp(upper_left,1-b)
        front_r=lower_right.lerp(upper_right,1-b)
        for point in (back_l,back_r,front_l,front_r):
            point.z=z
        sides.face([back_l,back_r,front_r,front_l],3 if i%3 else 2)
        sides.face([front_l,front_r,Vector((front_r.x,front_r.y,z-1.42/count)),Vector((front_l.x,front_l.y,z-1.42/count))],0)
        sides.face([back_l,front_l,Vector((front_l.x,front_l.y,-.015)),Vector((back_l.x,back_l.y,-.015))],1)
        sides.face([front_r,back_r,Vector((back_r.x,back_r.y,-.015)),Vector((front_r.x,front_r.y,-.015))],1)
    sides.build("Escada oeste · nove degraus",side_mat,terrain)
    for start,end in [(lower_left,upper_left),(lower_right,upper_right)]:
        for i in (0,.34,.67,1):
            p=start.lerp(end,i)
            beam("Montante da escada",p,p+Vector((0,0,.35)),.035,.03,wood_dark,terrain,5)
        beam("Corrimão da escada",start+Vector((0,0,.35)),end+Vector((0,0,.35)),.037,.032,wood_light,terrain,5)


stair()


def random_stone(name,xy,z,radius=.34,height=.48):
    p=at(*xy,z)
    phi=RNG.random()*math.tau
    rings=[]
    for layer,(scale,dz) in enumerate([(1,-.045),(.98,height*.36),(.57,height)]):
        ring=[]
        for k in range(6):
            angle=phi+k*math.tau/6
            ring.append(p+Vector((math.cos(angle)*radius*scale,math.sin(angle)*radius*scale*.77,dz+(min(.08,height*.16) if layer else 0)*math.sin(k*2))))
        rings.append(ring)
    s=Surface()
    for layer in range(2):
        for k in range(6):
            next=(k+1)%6
            s.face([rings[layer][k],rings[layer][next],rings[layer+1][next],rings[layer+1][k]],(k+layer)%3)
    s.face(rings[2],3)
    obj=s.build(name,stone_palette,lake)
    obj["game_foot"]=list(p)
    obj["game_radius"]=radius*.65
    return obj


# Large cliff breakups have measured bases, with taller stones near the waterfall.
for x,y,r,h in [(624,395,.45,.94),(672,355,.45,1.12),(742,305,.47,1.64),(793,265,.38,1.42),(848,244,.29,1.15),(971,283,.39,1.3),(1007,303,.35,.91),(1058,318,.34,.72),(1110,339,.29,.78),(1391,414,.54,.68),(1467,432,.51,.67),(1519,454,.60,.82)]:
    random_stone("Pé da escarpa", (x,y),-.35,r,h)
for xy,z,r,h in [((279,378),0,.5,.72),((211,420),0,.55,.55),((327,417),0,.34,.43),((481,391),0,.29,.42),((577,480),0,.36,.48),((500,623),0,.69,1.26),((641,726),0,.29,.51),((773,779),0,.47,.65),((1084,223),1.94,.46,1.16),((1266,302),1.94,.29,.42),((1370,512),0,.35,.66),((1238,637),0,.37,.74)]:
    random_stone("Pedra de composição",xy,z,r,h)


def ellipse_patch(name,position,sx,sy,z,mats,col,points=10):
    x,y=position
    poly=[]
    phase=RNG.uniform(0,math.tau)
    for k in range(points):
        theta=k*math.tau/points
        size=1+.10*math.sin(k*2.3+phase)
        poly.append((x+math.cos(theta)*sx*size,y+math.sin(theta)*sy*size))
    return flat(name,poly,z,mats,col)


for i in range(34):
    theta=i*math.tau/34
    x=936+292*math.cos(theta)
    y=439+122*math.sin(theta)
    if 640<x<1245 and y>338:
        ellipse_patch("Baixio no lago",(x,y),RNG.uniform(9,22),RNG.uniform(3,8),-.366,[water_shallow],lake)
for i in range(26):
    theta=.09+math.tau*i/26
    x=926+306*math.cos(theta)
    y=435+129*math.sin(theta)
    if y<346 or x<656 or x>1231:
        continue
    random_stone("Pedra de margem", (x,y),-.14,RNG.uniform(.18,.39),RNG.uniform(.16,.35))


def canopy(center,radius,seed):
    """Broad, layered leaf masses with dark undersides and lit scalloped crowns."""
    local=random.Random(seed)
    s=Surface()
    n=13
    variation=[local.uniform(.83,1.15) for _ in range(n)]
    rings=[]
    for layer,(rad,dz) in enumerate(((.67,-.20),(1.0,0),(.79,.20),(.31,.36))):
        ring=[]
        for k in range(n):
            angle=k*math.tau/n
            r=radius*rad*variation[k]
            ring.append(Vector(center)+Vector((math.cos(angle)*r,math.sin(angle)*r*.90,dz*radius+.04*radius*math.sin(k*2.4))))
        rings.append(ring)
    for row in range(3):
        for k in range(n):
            j=(k+1)%n
            angle=k*math.tau/n
            light=math.cos(angle-2.0)
            ink=0 if row==0 else max(1,min(6,2+row+(1 if light>.4 else 0)))
            s.face([rings[row][k],rings[row][j],rings[row+1][j],rings[row+1][k]],ink)
    s.face(rings[-1],5)
    for i in range(26):
        angle=local.random()*math.tau
        r=radius*local.uniform(.56,.95)
        c=Vector(center)+Vector((math.cos(angle)*r,math.sin(angle)*r*.9,radius*(.42-.31*(r/radius)**2)))
        # Flat lobed leaf clusters keep the crown broad with a painted silhouette.
        rr=radius*local.uniform(.17,.29)
        ring=[c+Vector((math.cos(j*math.tau/7)*rr,math.sin(j*math.tau/7)*rr*.75,rr*.15*math.sin(j*2.1))) for j in range(7)]
        near=Vector((math.cos(angle),math.sin(angle),0)).dot(AWAY)<-.25
        ink=(i%2) if near and r>radius*.60 else 3+i%4
        s.face(ring,ink)
    return s.build("Copa · folhas em camadas",bush_palette,forest)


def supported(xy,z):
    outlines={0:BASE,1.42:WEST,2.90:MID,4.19:PEAK,1.94:REAR}
    poly=outlines.get(z)
    if poly is None or not inside(xy,[Vector(p) for p in poly]): return False
    if z==0 and inside(xy,[Vector((x,y-.38*UNIT*math.cos(math.pi/6))) for x,y in POOL]): return False
    return True


def model_tree(xy,z,height=1.30,width=1.14,seed=0):
    if not supported(xy,z): return
    previous_objects=set(bpy.data.objects)
    base=at(*xy,z)
    r=random.Random(seed)
    bend=base+Vector((r.uniform(-.13,.13),r.uniform(-.13,.13),height*.55))
    stem=base+Vector((r.uniform(-.20,.20),r.uniform(-.16,.16),height))
    beam("Tronco · base",base,bend,.145,.10,bark[1],forest,7)
    beam("Tronco · bifurcação",bend,stem,.10,.06,bark[0],forest,7)
    for k in range(4):
        angle=k*math.tau/4+.45
        toe=base+Vector((math.cos(angle)*.25,math.sin(angle)*.25,.012))
        beam("Raiz",base+Vector((0,0,.19)),toe,.073,.02,bark[k%3],forest,5)
    for k in range(5):
        angle=k*2.4
        direction=Vector((math.cos(angle),math.sin(angle),0))
        top=stem+direction*width*.44+Vector((0,0,.15+r.uniform(0,.34)))
        beam("Galho",base.lerp(stem,.59),top,.06,.018,bark[0],forest,5)
        canopy(top,width*(.52 if k<4 else .58),seed*17+k)
    canopy(stem+Vector((0,0,.62)),width*.64,seed+400)
    parts=set(bpy.data.objects)-previous_objects
    group=bpy.data.objects.new("Árvore · grupo de exportação",None)
    forest.objects.link(group)
    group["game_foot"]=list(base)
    group["game_radius"]=.24
    for part in parts:part.parent=group


TREE_SITES=[
    ((265,331),0,1.52,1.35),((150,365),0,1.14,.94),((102,427),0,1.10,.79),
    ((323,390),0,1.01,.83),((278,511),0,1.10,.94),((348,558),0,1.12,.96),
    ((733,747),0,1.28,1.10),((826,810),0,1.12,.94),((1217,610),0,1.08,.89),
    ((1314,589),0,1.42,1.12),((1401,555),0,1.36,1.15),((1477,490),0,1.31,1.10),
    ((1357,405),1.94,1.35,1.04),((1262,334),1.94,1.16,.89),((1169,286),1.94,1.08,.85),
    ((1019,202),1.94,1.43,1.16),((966,184),1.94,1.08,.87),
    ((839,157),2.90,1.55,1.24),((779,147),2.90,1.24,.97),((714,181),2.90,1.08,.87),
    ((228,396),0,1.18,.97),((379,533),0,1.12,.91),((191,463),0,1.04,.91),
    ((656,716),0,1.11,.99),((1101,703),0,1.06,.94),((1180,680),0,1.09,.95),
    ((1436,528),0,1.05,.91),((1287,633),0,1.10,.93),
]
for k,(xy,z,h,r) in enumerate(TREE_SITES):
    model_tree(xy,z,h*1.24,r*1.22,k+20)


def shrub(xy,z,size=.29):
    if not supported(xy,z): return
    center=at(*xy,z+.03)
    for i in range(3):
        d=Vector((RNG.uniform(-size,size),RNG.uniform(-size,size),RNG.uniform(.06,.15)))
        canopy(center+d,size,RNG.randrange(10000))


for x,y,z,size in [(300,444,0,.36),(272,610,0,.36),(359,600,0,.40),(461,617,0,.30),(683,675,0,.24),(648,743,0,.34),(879,817,0,.26),(1090,710,0,.34),(1168,690,0,.35),(1263,637,0,.38),(1375,611,0,.31),(1459,457,0,.30),(1500,420,0,.27),(413,279,1.42,.27),(558,270,1.42,.24),(634,288,1.42,.28),(622,140,2.90,.25),(782,228,2.90,.28),(908,144,1.94,.26),(1116,228,1.94,.30)]:
    if (x,y)==(782,228): y=177
    if (x,y)==(908,144): y=183
    shrub((x,y),z,size)


def strip(name, positions,width,mat,col):
    for i,(a,b) in enumerate(zip(positions,positions[1:])):
        beam(name,a,b,width,width*.88,mat,col,4)


def fence(a,b,z,name="Cerca"):
    a,b=at(*a,z),at(*b,z)
    count=max(2,math.ceil((b-a).length/.52))
    for k in range(count+1):
        p=a.lerp(b,k/count)
        beam(name+" · poste",p,p+Vector((0,0,.39)),.04,.035,wood_dark,station,4)
    for h in (.13,.28):
        beam(name+" · ripa",a+Vector((0,0,h)),b+Vector((0,0,h)),.035,.030,wood_light,station,4)


fence((293,387),(383,359),0)
fence((423,539),(492,575),0)
fence((889,722),(981,685),0)
fence((1101,216),(1321,310),1.94)


def pennant(xy,z):
    p=at(*xy,z)
    beam("Haste do estandarte",p,p+Vector((0,0,1.38)),.027,.022,steel,station,6)
    cloth=Surface()
    top=p+Vector((0,0,1.25))
    for k in range(4):
        a,b=k*.12,(k+1)*.12
        wa=math.sin(k*1.2)*.045
        wb=math.sin((k+1)*1.2)*.045
        cloth.face([top+RIGHT*a+AWAY*wa,top+RIGHT*b+AWAY*wb,top+RIGHT*b+AWAY*wb-Vector((0,0,.70)),top+RIGHT*a+AWAY*wa-Vector((0,0,.70))],0)
    cloth.build("Bandeira azul",[banner_mat],station)
    center=top+RIGHT*.23-Vector((0,0,.30))-AWAY*.03
    points=[center+UP*.11,center+RIGHT*.078,center-UP*.11,center-RIGHT*.078,center+UP*.11]
    strip("Emblema do estandarte",points,.008,bright_foam,station)
    beam("Travessa superior",top-RIGHT*.05,top+RIGHT*.53,.025,.024,wood_light,station,5)


pennant((521,562),0)
pennant((978,681),0)
pennant((1231,332),1.94)


def dock():
    # The measured corners define one real horizontal deck.
    corners=[at(1148,348,.50),at(1191,327,.50),at(1355,410,.50),at(1320,435,.50)]
    shape=Surface()
    shape.face(corners,0)
    shape.build("Passarela · piso marfim",[slab],station)
    for a,b in zip(corners,corners[1:]+corners[:1]):
        beam("Viga da plataforma",a-Vector((0,0,.08)),b-Vector((0,0,.08)),.065,.065,steel,station,4)
    for i in range(1,24):
        a=corners[0].lerp(corners[3],i/24)
        b=corners[1].lerp(corners[2],i/24)
        beam("Junta de régua",a+Vector((0,0,.005)),b+Vector((0,0,.005)),.008,.008,wood_dark,station,4)
    for a,b in [(corners[0],corners[1]),(corners[1],corners[2]),(corners[0],corners[3]),(corners[2],corners[3])]:
        for k in range(6):
            p=a.lerp(b,k/5)
            beam("Montante do mirante",p,p+Vector((0,0,.32)),.025,.025,steel,station,5)
        for dz in (.17,.32):
            beam("Guarda-corpo",a+Vector((0,0,dz)),b+Vector((0,0,dz)),.018,.018,wood_light,station,5)
    for t in (.14,.53,.90):
        for a,b in [(corners[0],corners[3]),(corners[1],corners[2])]:
            p=a.lerp(b,t)
            beam("Pilar do mirante",(p.x,p.y,-.42),p-Vector((0,0,.08)),.038,.038,wood_dark,station,6)
    p=at(1228,354,.50)
    box("Gabinete do mirante",p+Vector((0,0,.29)),(.44,.32,.58),ivory,station)
    box("Monitor azul",p+RIGHT*.13+Vector((0,0,.49)),(.21,.33,.20),screen,station)


dock()


def waterfall():
    r=Surface()
    # Vertically corresponding lips, centre and impact are measured in the reference.
    start=at(906,204,1.94)-AWAY*.45
    foot=Vector((start.x,start.y,-.36))
    for k in range(8):
        a,b=(k/8-.5)*.62,((k+1)/8-.5)*.62
        offset=RIGHT
        upper_a=start+offset*a
        upper_b=start+offset*b
        lower_a=foot+offset*a*.89+AWAY*.08
        lower_b=foot+offset*b*.89+AWAY*.08
        r.face([upper_a,upper_b,lower_b,lower_a],1 if k in (1,5) else 0)
    r.build("Cachoeira central",[stream_blue,stream_light],lake)
    for k in range(19):
        c=foot+RIGHT*RNG.uniform(-.49,.49)+AWAY*RNG.uniform(-.22,.22)+Vector((0,0,.055))
        sphere("Espuma da cachoeira",c,(.15,.12,.055),bright_foam,lake,1)
    for j in range(4):
        radius=.43+j*.23
        points=[foot+RIGHT*math.cos(i*.17)*radius+AWAY*math.sin(i*.17)*radius*.49+Vector((0,0,.018)) for i in range(24)]
        strip("Arco de espuma",points,.010,bright_foam,lake)


waterfall()


def surface_details():
    s=Surface()
    for k in range(310):
        x,y=RNG.uniform(103,1563),RNG.uniform(228,819)
        if not inside((x,y),[Vector(p) for p in BASE]) or inside((x,y),[Vector(p) for p in POOL]):
            continue
        if 460<x<1100 and y<329:
            continue
        center=at(x,y,.027)
        r=RNG.uniform(.035,.105)
        for j in range(3):
            angle=j*2.4
            base=center+Vector((math.cos(angle)*r,math.sin(angle)*r,0))
            s.face([base,base+RIGHT*.028,base+Vector((RNG.uniform(-.07,.07),0,RNG.uniform(.08,.17)))],k%4)
    s.build("Herbáceas de borda",bush_palette[2:6],forest)
    for k in range(56):
        x,y=RNG.uniform(465,1037),RNG.uniform(480,682)
        if inside((x,y),[Vector(p) for p in POOL]):
            continue
        if RNG.random()<.58:
            random_stone("Pavimento solto",(x,y),.02,RNG.uniform(.065,.19),.035)
    for x,y,z in [(291,410,0),(402,580,0),(553,623,0),(641,670,0),(847,787,0),(1100,695,0),(1322,571,0),(1480,424,0),(648,128,2.90),(775,187,2.90),(1115,205,1.94)]:
        for i in range(5):
            p=at(x+RNG.uniform(-12,12),y+RNG.uniform(-4,7),z+.04)
            stem=p+Vector((0,0,RNG.uniform(.08,.18)))
            beam("Talo de flor",p,stem,.006,.004,moss,forest,3)
            for a in range(5):
                theta=a*math.tau/5
                c=stem+RIGHT*math.cos(theta)*.027+AWAY*math.sin(theta)*.027
                sphere("Pétala",c,(.028,.022,.012),flower_blue if i%2 else flower_white,forest,1)


surface_details()

# Colour islands and overlapping low growth break the planar lawn into an authored biome.
def segment_distance(point,a,b):
    p,a,b=Vector(point),Vector(a),Vector(b)
    direction=b-a
    t=max(0,min(1,(p-a).dot(direction)/max(.001,direction.length_squared)))
    return (p-a-direction*t).length

path_pixels=[(401,381),(476,441),(590,506),(677,554),(805,599),(933,648),(1016,677),(1123,623),(1228,552),(1300,496),(1328,454)]
ground_ink=[painted("Cobertura de chão "+c,c) for c in ("829b45","94a94b","a1af56","a6b55d","758f40")]
patches=Surface()
for k in range(1900):
    x,y=RNG.uniform(75,1607),RNG.uniform(190,843)
    if not inside((x,y),[Vector(p) for p in BASE]) or inside((x,y),[Vector(p) for p in POOL]): continue
    if min(segment_distance((x,y),a,b) for a,b in zip(path_pixels,path_pixels[1:]))<24: continue
    rx,ry=RNG.uniform(3,15),RNG.uniform(1.5,5)
    pts=[at(x+math.cos(j*math.tau/7)*rx*(.8+RNG.random()*.4),y+math.sin(j*math.tau/7)*ry,.033) for j in range(7)]
    patches.face(pts,k%len(ground_ink))
patches.build("Chão · manchas de vegetação pintada",ground_ink,forest)

for poly,z,count in [(BASE,0,27),(WEST,1.42,10),(MID,2.90,8),(PEAK,4.19,5),(REAR,1.94,12)]:
    xmin,xmax=min(p[0] for p in poly),max(p[0] for p in poly)
    ymin,ymax=min(p[1] for p in poly),max(p[1] for p in poly)
    placed=0
    for attempt in range(count*30):
        if placed>=count: break
        x,y=RNG.uniform(xmin+8,xmax-8),RNG.uniform(ymin+5,ymax-5)
        if not inside((x,y),[Vector(p) for p in poly]): continue
        if z==0 and (inside((x,y),[Vector(p) for p in POOL]) or min(segment_distance((x,y),a,b) for a,b in zip(path_pixels,path_pixels[1:]))<33): continue
        if z==0 and 400<x<1100 and y<380: continue
        shrub((x,y),z,RNG.uniform(.14,.28))
        placed+=1

# Individual hanging stems follow the physical cliff height rather than a pasted wall strip.
for poly,z,bottom in [(WEST,1.42,0),(MID,2.90,1.42),(PEAK,4.19,2.90),(REAR,1.94,-.38)]:
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if b[0]>a[0]: continue
        for j in range(max(1,int((Vector(a)-Vector(b)).length/27))):
            t=RNG.uniform(.08,.92)
            xy=Vector(a).lerp(Vector(b),t)
            root=at(*xy,z)-AWAY*.055
            length=RNG.uniform(.18,min(.90,z-bottom))
            tip=root+Vector((RNG.uniform(-.07,.07),RNG.uniform(-.07,.07),-length))
            beam("Vinha pendente",root,tip,.008,.004,foliage_mat,forest,4)
            for k in range(4):
                p=root.lerp(tip,(k+1)/5)
                leaves=Surface()
                for sign in (-1,1):
                    leaves.face([p,p+RIGHT*sign*.07+Vector((0,0,.025)),p+RIGHT*sign*.115-Vector((0,0,.045)),p-Vector((0,0,.065))],0)
                leaves.build("Folhas de vinha",[bush_palette[3+k%3]],forest)


def sprite_screen(name,file,cell_xy,extent,pivot,anchor,z,visual_scale):
    billboard(name,file,cell_xy,extent,pivot,(0,0),CAM,0,visual_scale*(32*math.sqrt(2))/UNIT)
    obj=bpy.data.objects[name]
    obj.location=at(*anchor,z)


sprite_screen("Mormaço · referência","godot/assets/campaign/mormaco-v1/submerged.png",(0,320),(320,320),(160,302),(880,469),-.38,.65)
sprite_screen("Capanga no mirante","godot/assets/overworld/kits/camara-do-elo-v1/capanga-feminina-idle-eight.png",(64,0),(64,96),(32,90),(1219,375),.50,.31)
for k in range(14):
    p=at(880,468,-.36)+RIGHT*math.cos(k*.39)*1.90+AWAY*math.sin(k*.39)*.86
    q=at(880,468,-.36)+RIGHT*math.cos(k*.39+.12)*1.90+AWAY*math.sin(k*.39+.12)*.86
    beam("Ondulação do Mormaço",p,q,.014,.012,bright_foam,lake,4)
for x,y in [(784,357),(799,371),(815,383),(1134,441),(1148,453),(1161,464),(905,496),(890,507)]:
    ellipse_patch("Folha sobre água",(x,y),RNG.uniform(5,9),RNG.uniform(2,4),-.36,[moss],lake)

exec(compile((OUT/"refinar_ambientacao.py").read_text(encoding="utf-8"),str(OUT/"refinar_ambientacao.py"),"exec"))

lighting()
scene.world.node_tree.nodes.get("Background").inputs[0].default_value=(.43,.60,.78,1)
scene.world.node_tree.nodes.get("Background").inputs[1].default_value=.65
sun=bpy.data.lights.get("Sol filtrado")
sun.energy=2.25
sun.color=(1.0,.95,.84)
backdrop(CAM,(0,0,0))
scene.render.engine="BLENDER_EEVEE"
scene.render.resolution_x=W
scene.render.resolution_y=H
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.view_settings.view_transform="Standard"
scene.view_settings.look="Medium High Contrast"
scene.render.film_transparent=False
scene["Referência"]="codex-clipboard-25c4813d-468c-4251-be51-eb04fb269d14.png"
scene["Método"]="Marcos projetados da referência na câmera ortográfica. Elementos modelados em 3D."
def ground_projection(x,y,z):
    p=at(x,y,z)
    p.z=0
    return list(pixel(p))
scene["runtime_navigation"]=json.dumps({"ground":BASE,"water":[ground_projection(x,y,-.38) for x,y in POOL],"raised":[[ground_projection(x,y,z) for x,y in poly] for poly,z in [(WEST,1.42),(MID,2.90),(PEAK,4.19),(REAR,1.94)]],"water_surface":POOL,"spawn":[560,463],"targets":[[534,435],[807,601],[1220,559]],"scope":"lower lakeside pilot"})
for screen_item in bpy.data.screens:
    for area in screen_item.areas:
        if area.type=="VIEW_3D":
            area.spaces.active.region_3d.view_perspective="CAMERA"
            area.spaces.active.shading.color_type="MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"mormaco-referencia.blend"))
scene.render.filepath=str(OUT/"referencia-reconstruida.png")
bpy.ops.render.render(write_still=True)
report={"camera":"orthographic","resolution":[W,H],"objects":len(scene.objects),"landmarks":{"stair_top":[470,285],"waterfall":[906,204],"boss":[880,469],"pier":[1219,375]},"reference":scene["Referência"],"cliff_topology":CLIFF_CHECKS}
report["refinement"]={"closed_rock_objects":sum(o.type=="MESH" for o in refinement.objects if o.name.startswith(("Escarpa ·","Contraforte"))),"pier_landing_supported":all(supported(p,0) for p in [(1370,482),(1405,457)]),"art_match_status":"partial; not an identical reproduction"}
assert report["refinement"]["pier_landing_supported"],"Escada do mirante sem apoio no solo"
(OUT/"validacao-referencia.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
