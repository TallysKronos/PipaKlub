"""Run from the project folder with Blender --background --python this file."""
import json
import math
import random
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector
from mathutils.geometry import tessellate_polygon


OUT = Path(__file__).resolve().parent
PROJECT = next(path for path in OUT.parents if (path / "godot/project.godot").exists())
MAP_SOURCE = OUT / "mapa-fonte.json"
if not MAP_SOURCE.exists():
    MAP_SOURCE = PROJECT / "godot/assets/overworld/maps/kronasta-pantano-c.json"
MAP = json.loads(MAP_SOURCE.read_text(encoding="utf-8"))
DATA = MAP["blockout"]
CONTOUR = [Vector(point) for point in DATA["waterContour"]]
LAND_EDGE = [Vector(p) for p in [
    (6.4,5.3),(11.2,3.5),(16.0,2.7),(21.8,1.25),(27.4,1.65),
    (32.9,2.4),(38.2,4.7),(42.7,7.1),(44.4,12.0),(45.15,17.2),
    (44.25,22.0),(45.1,27.15),(44.4,31.75),(42.4,36.25),
    (37.15,37.52),(31.5,37.0),(26,38.65),(20.45,38.05),(15.52,38.45),
    (9.24,36.25),(5.76,33.0),(4.8,28.42),(5.55,23.04),(5.15,17.5),(5.86,12.3)
]]
HEIGHT = 1.0 / (32.0 * math.sqrt(2.0) * math.cos(math.pi / 6.0))
WATER = DATA["waterElevation"] * HEIGHT
RNG = random.Random(412)
EPS = 1e-6
WATERFALL_X = 24.65
WEST_STAIR = (11.6,20.50,24.22)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


terrain = collection("01 · Terreno e rotas")
lake = collection("02 · Poço e escarpas")
forest = collection("03 · Árvores e vegetação")
station = collection("04 · Plataforma de monitoramento")
cast = collection("05 · Marcas da emboscada")
cameras = collection("06 · Câmeras e luz")


def material(name, rgb, roughness=.88, metal=0):
    def linear(value):
        c = value / 255.0
        return c / 12.92 if c < .04045 else ((c + .055) / 1.055) ** 2.4

    result = bpy.data.materials.new(name)
    result.diffuse_color = (*[linear(int(rgb[i : i + 2], 16)) for i in (0, 2, 4)], 1)
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = result.diffuse_color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metal
    return result


grass = [material("Terraço verde " + s, s) for s in ("91ad51", "8aa94e", "83a04c", "9cb552")]
trail = [material("Trilha seca " + s, s) for s in ("d7b27a", "d9b681", "cfa974", "dfbd88")]
soil = [material("Estrato de terra " + s, s) for s in ("756056", "574e4e", "86705b")]
rock = [material("Basalto " + s, s) for s in ("646c77", "505963", "494e62", "7d7f86", "616273")]
moss = material("Musgo de borda", "769240")
wet = material("Basalto molhado", "314f55")
shoal = material("Baixio mineral", "557c77")
water = material("Lago · água termal", "1e7b85", .73)
water.node_tree.nodes.get("Principled BSDF").inputs["Specular IOR Level"].default_value = .08
leaf = [material("Folhagem " + s, s) for s in ("26504d", "35634b", "4c7e49", "729e51", "9eb850")]
bark = [material("Casca " + s,s) for s in ("544245","775443","9a7250")]
steel = material("Estrutura azul", "315873", .52, .40)
slab = material("Piso da plataforma", "b0afa1")
ivory = material("Instrumentos marfim", "d2cdb3")
yellow = material("Faixa de segurança", "d2aa55")
panel = material("Células solares", "2f5377", .28, .28)
screen = material("Tela verde-azulada", "28586b", .45)
mint = material("Traço do monitor", "7edccc")
line_ink = material("Carretel Negro · linha", "a664be")
foam = material("Água rasa e espuma", "91c9b8")
stream_blue = material("Cachoeira · água azul", "3c91bb", .50)
stream_light = material("Cachoeira · filete claro", "7ac9e0", .46)
flower = material("Flores azul-lilás", "849ddf")
flag_blue = material("Tecido azul do mirante", "426d9a")
wood = material("Madeira dos guardas", "866744")


def shade_pattern(mat, scale, strength):
    """A shared world-space grain keeps adjacent terrain pieces in register."""
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    pos = nodes.new("ShaderNodeNewGeometry")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 2
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "LINEAR"
    rgb = tuple(mat.diffuse_color)[:3]
    for stop, grade in zip(ramp.color_ramp.elements, (1-strength,1+strength)):
        stop.color = (*(channel*grade for channel in rgb),1)
    links.new(pos.outputs["Position"],noise.inputs["Vector"])
    links.new(noise.outputs["Fac"],ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"],bsdf.inputs["Base Color"])


for asset_mat in grass+trail:
    shade_pattern(asset_mat,2.1,.29)
for asset_mat in soil+rock+[moss]:
    shade_pattern(asset_mat,3.4,.24)
for asset_mat in leaf:
    shade_pattern(asset_mat,4.0,.19)


def paint_water():
    nodes, links = water.node_tree.nodes, water.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    position = nodes.new("ShaderNodeNewGeometry")
    stretch = nodes.new("ShaderNodeVectorMath")
    stretch.operation="MULTIPLY"
    stretch.inputs[1].default_value=(.9,2.7,.2)
    noise=nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value=1.8
    noise.inputs["Detail"].default_value=2.7
    ramp=nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position=.21
    ramp.color_ramp.elements[0].color=(.007,.069,.109,1)
    ramp.color_ramp.elements[1].position=.81
    ramp.color_ramp.elements[1].color=(.029,.213,.239,1)
    bump=nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value=.16
    bump.inputs["Distance"].default_value=.02
    links.new(position.outputs["Position"],stretch.inputs[0])
    links.new(stretch.outputs["Vector"],noise.inputs["Vector"])
    links.new(noise.outputs["Fac"],ramp.inputs["Fac"])
    links.new(noise.outputs["Fac"],bump.inputs["Height"])
    links.new(ramp.outputs["Color"],bsdf.inputs["Base Color"])
    links.new(bump.outputs["Normal"],bsdf.inputs["Normal"])


paint_water()


def world(point, z=0):
    return (point[0], -point[1], z)


def mesh(name, vertices, faces, materials, col, ids=()):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    col.objects.link(obj)
    for mat in materials:
        data.materials.append(mat)
    for polygon, index in zip(data.polygons, ids):
        polygon.material_index = index
    return obj


class Surface:
    def __init__(self):
        self.vertices, self.faces, self.lookup, self.ids = [], [], {}, []

    def face(self, points, index):
        ids = []
        for point in points:
            key = tuple(round(component, 6) for component in point)
            if key not in self.lookup:
                self.lookup[key] = len(self.vertices)
                self.vertices.append(point)
            ids.append(self.lookup[key])
        if len(set(ids)) >= 3:
            self.faces.append(ids)
            self.ids.append(index)

    def build(self, name, mats, col):
        return mesh(name, self.vertices, self.faces, mats, col, self.ids)


def clip(poly, a, b):
    """Positive and negative portions of a polygon split by a directed edge."""
    inside, outside = [], []
    if not poly:
        return inside, outside
    normal = Vector((a.y - b.y, b.x - a.x))
    p = poly[-1]
    prev = normal.dot(p - a)
    for q in poly:
        value = normal.dot(q - a)
        if (prev >= -EPS) != (value >= -EPS):
            crossing = p.lerp(q, prev / (prev - value))
            inside.append(crossing)
            outside.append(crossing)
        (inside if value >= -EPS else outside).append(q)
        p, prev = q, value
    return inside, outside


def subtract_triangle(poly, triangle):
    result = []
    for a, b in zip(triangle, triangle[1:] + triangle[:1]):
        poly, outside = clip(poly, a, b)
        if len(outside) >= 3:
            result.append(outside)
    return result


def triangulate(polygon):
    triangles = []
    for triangle in tessellate_polygon([[Vector((*p, 0)) for p in polygon]]):
        points = [polygon[index] for index in triangle]
        a,b,c = points
        if (b-a).cross(c-a)<0:
            points.reverse()
        bounds=(min(p.x for p in points),min(p.y for p in points),max(p.x for p in points),max(p.y for p in points))
        triangles.append((points,bounds))
    return triangles


land_triangles = triangulate(LAND_EDGE)
water_triangles = triangulate(CONTOUR)


def cell(u, v):
    if 0 <= u < MAP["w"] and 0 <= v < MAP["h"]:
        return MAP["cells"][v * MAP["w"] + u]
    return None


def smooth(a,b,value):
    t=min(1.0,max(0.0,(value-a)/(b-a)))
    return t*t*(3-2*t)


def inside(p,polygon):
    x,y=p
    return sum(((a.y>y)!=(b.y>y)) and x<(b.x-a.x)*(y-a.y)/(b.y-a.y)+a.x
               for a,b in zip(polygon,polygon[1:]+polygon[:1]))%2==1


def sculpted_height(p):
    u,v=p
    # A broad west shelf, two irregular crowns behind the waterfall and a low east rim.
    west=(1-smooth(13.04,14.65,u+.43*math.sin(v*.42)))
    south=1-smooth(WEST_STAIR[1],WEST_STAIR[2],v)
    west_level=1.84*west*south
    rear_mask=smooth(11.9,18.45,u)*(1-smooth(30.6,37.6,u))
    rear=2.12*rear_mask*(1-smooth(5.25,8.22,v+.37*math.sin(u*.35)))
    upper=1.38*(1-smooth(.61,1.02,math.hypot((u-22.1)/5.85,(v-2.85)/2.79)))
    shoulder=.81*(1-smooth(.59,1.13,math.hypot((u-30.2)/4.2,(v-3.24)/2.47)))
    east=.91*smooth(38.1,44.0,u+.44*math.sin(v*.51))*(.54+.46*(1-smooth(16,29,v)))
    return max(west_level,rear)+upper+shoulder+east


ROUTES = [
    ([(24,39,0),(22.9,35.4,0),(21.9,32,0),(23.6,28.9,0),(28.6,28.65,0),(34.6,28.7,0),(38.6,25.5,.02),(39.45,19.4,.10),(39.0,13.0,.12),(37.6,7.0,.38),(33.0,5.4,1.15),(24.0,5.2,1.66),(23.8,1.55,2.56)],1.25),
    ([(23.6,28.9,0),(18.2,28.4,0),(14.8,27.4,0),(11.6,24.22,0),(11.6,20.5,1.84),(11.25,15.4,1.84),(11.7,11.5,1.74),(15.4,8.3,1.53),(19.5,6.3,1.52),(24.0,5.2,1.66)],1.22),
    ([(37.0,27.0,.02),(41.3,27.8,.21),(43.4,29.9,.38)],.85),
    ([(13.9,26.8,0),(9.55,26.8,0),(6.0,28.9,0)],.83),
]
PATH_SEGMENTS = [
    (x,y,z,bx-x,by-y,bz-z,(bx-x)**2+(by-y)**2,width)
    for route,width in ROUTES
    for (x,y,z),(bx,by,bz) in zip(route,route[1:])
]


def route_profile(p):
    u,v=p
    result,height=100.0,0.0
    for x,y,z,dx,dy,dz,length,width in PATH_SEGMENTS:
        t=max(0.0,min(1.0,((u-x)*dx+(v-y)*dy)/length))
        distance=math.hypot(u-x-dx*t,v-y-dy*t)-width
        if distance<result:
            result,height=distance,z+dz*t
    return result,height


def surface_height(p):
    base=sculpted_height(p)
    distance,track=route_profile(p)
    blend=1-smooth(-.13,.97,distance)
    return base+(track-base)*blend


def path_distance(p):
    return route_profile(p)[0]


def solid_path(p):
    return path_distance(p)<0


def build_terrain():
    floor, faces = Surface(), Surface()
    step=.50
    for iv in range(2,80):
        for iu in range(8,92):
            u,v=iu*step,iv*step
            cell_shape=[Vector((u,v)),Vector((u+step,v)),Vector((u+step,v+step)),Vector((u,v+step))]
            land=[]
            for tri,(x,y,xx,yy) in land_triangles:
                if xx<=u or yy<=v or x>=u+step or y>=v+step:
                    continue
                poly=cell_shape
                for a,b in zip(tri,tri[1:]+tri[:1]):
                    poly,_=clip(poly,a,b)
                if len(poly)>=3:
                    land.append(poly)
            if not land:
                continue
            for cut,(x,y,xx,yy) in water_triangles:
                if xx>u and yy>v and x<u+step and y<v+step:
                    land=[piece for poly in land for piece in subtract_triangle(poly,cut)]
            for fragment in land:
                center=sum(fragment,Vector((0,0)))/len(fragment)
                mark=path_distance(center)+.16*math.sin(center.x*3.41+center.y*2.10)
                mat=RNG.choices(range(4),(18,3,2,1))[0]+(len(grass) if mark<0 else 0)
                elevation_x=surface_height(center+Vector((.12,0)))-surface_height(center-Vector((.12,0)))
                elevation_y=surface_height(center+Vector((0,.12)))-surface_height(center-Vector((0,.12)))
                steepness=math.hypot(elevation_x,elevation_y)/.24
                if mark>.08 and steepness>.68+.14*math.sin(center.x*.74-center.y*1.23):
                    mat=len(grass)+len(trail)+min(2,math.floor(steepness*2.0)%3)
                floor.face([world(p,surface_height(p)) for p in reversed(fragment)],mat)
    for i,(a,b) in enumerate(zip(LAND_EDGE,LAND_EDGE[1:]+LAND_EDGE[:1])):
        cuts={0.0,1.0}
        for origin,dest in zip(a,b):
            if abs(origin-dest)>EPS:
                for grid in range(math.floor(min(origin,dest)/step)+1,math.ceil(max(origin,dest)/step)):
                    cuts.add((grid*step-origin)/(dest-origin))
        ticks=sorted(cuts)
        for j,(t,s) in enumerate(zip(ticks,ticks[1:])):
            p,q=a.lerp(b,t),a.lerp(b,s)
            z,w=surface_height(p),surface_height(q)
            foot_p=WATER-.68+.15*math.sin((p.x-p.y)*.96)
            foot_q=WATER-.68+.15*math.sin((q.x-q.y)*.96)
            mid_p=z-(z-foot_p)*.38
            mid_q=w-(w-foot_q)*.38
            faces.face([world(p,z),world(q,w),world(q,mid_q),world(p,mid_p)],(i+j//2)%3)
            faces.face([world(p,mid_p),world(q,mid_q),world(q,foot_q),world(p,foot_p)],3+(i+j)%3)
    floor.build("Relevo contínuo · lombo oeste, cume e vale baixo",grass+trail+rock[:3],terrain)
    faces.build("Corte irregular do diorama",soil+rock[:3],terrain)
    pool = Surface()
    for tri,_ in water_triangles:
        pool.face([world(p,WATER) for p in reversed(tri)],0)
    pool.build("Água · contorno e cota do jogo",[water],lake)


def polygon_corner(i):
    p = CONTOUR[i]
    e = (p - CONTOUR[i-1]).normalized()
    n = (CONTOUR[(i+1)%len(CONTOUR)]-p).normalized()
    a, b = Vector((e.y,-e.x)), Vector((n.y,-n.x))
    m = (a+b).normalized()
    return m/max(.78,m.dot(b))


def build_bank():
    profile = []
    crest = [39,57,91,3,0,0,0,0,0,4,26]
    upper = [15,25,32,0,0,0,0,0,0,0,8]
    plant = []
    for i in (9,10,0,1,2):
        j = (i+1)%len(CONTOUR)
        cuts = math.ceil((CONTOUR[j]-CONTOUR[i]).length*2)
        for k in range(cuts+1):
            if profile and k==0:
                continue
            t = k/cuts
            a = CONTOUR[i].lerp(CONTOUR[j],t)
            n = polygon_corner(i).lerp(polygon_corner(j),t)
            notch = math.exp(-((a.x-WATERFALL_X)/.83)**4) if i==1 else 0
            rise = (crest[i]*(1-t)+crest[j]*t)*HEIGHT-.33*notch
            height = (upper[i]*(1-t)+upper[j]*t)*HEIGHT*(1-.96*notch)
            base = surface_height(a+n*.08)
            h = rise + base
            amount = min(1.0,rise/(55*HEIGHT))
            bench = a + n*(.12+amount*.86)
            crown = bench + n*(.08+amount*1.02)
            shoulder = crown + n*(.08+amount*.53)
            shoulder_height=surface_height(shoulder)-.045
            joint=WATER + (h-WATER)*(.42+.08*math.sin((a.x+a.y)*.42))
            rim=a+n*.10*amount
            profile.append([(a,WATER),(a,WATER+.22),(a+n*.07*amount,joint),(rim,h-.09*amount),(rim,h),(bench,h),(bench,h+height),(crown,h+height),(shoulder,shoulder_height)])
            if i in (0,1) and k==round(cuts*.49):
                plant.append((bench.lerp(crown,.61),h+height,.83))
    bank = Surface()
    base_mats = rock+[wet,moss,grass[2],grass[0]]
    for i,(a,b) in enumerate(zip(profile,profile[1:])):
        for edge,mat in enumerate((5,1 if i%6 else 0,0 if i%7 else 3,6,7,2,8,7)):
            bank.face([world(*a[edge]),world(*b[edge]),world(*b[edge+1]),world(*a[edge+1])],mat)
        bank.face([world(*a[0]),world(*a[-1]),world(*b[-1]),world(*b[0])],2)
    for section in (profile[0],profile[-1]):
        bank.face([world(*v) for v in section],2)
    bank.build("Escarpa soldada · ombro, patamar e basalto",base_mats,lake)
    for i,(a,b) in enumerate(zip(CONTOUR,CONTOUR[1:]+CONTOUR[:1])):
        if i in (9,10,0,1,2):
            continue
        dry = Surface()
        n = polygon_corner(i)
        m = polygon_corner((i+1)%len(CONTOUR))
        a_height,b_height=surface_height(a),surface_height(b)
        dry.face([world(a,WATER),world(b,WATER),world(b,b_height),world(a,a_height)],0)
        a_outer,b_outer=a+n*.28,b+m*.28
        dry.face([world(a,a_height+.01),world(b,b_height+.01),world(b_outer,surface_height(b_outer)+.01),world(a_outer,surface_height(a_outer)+.01)],1)
        dry.build("Margem interna %02d"%i,[wet,moss],lake)
    return plant


def box(name, center, size, mat, col):
    x,y,z = center
    a,b,c = (dimension*.5 for dimension in size)
    verts = [(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
    return mesh(name,verts,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],[mat],col)


def beam(name, a, b, r1, r2, mat, col, resolution=6):
    a,b = Vector(a),Vector(b)
    direction=(b-a).normalized()
    side=direction.cross(Vector((0,0,1)))
    if side.length<EPS:
        side=Vector((1,0,0))
    side.normalize()
    tangent=direction.cross(side)
    ring=[side*math.cos(i*math.tau/resolution)+tangent*math.sin(i*math.tau/resolution) for i in range(resolution)]
    vertices=[tuple(a+r1*p) for p in ring]+[tuple(b+r2*p) for p in ring]
    faces=[tuple(reversed(range(resolution))),tuple(range(resolution,resolution*2))]
    faces += [(i,(i+1)%resolution,(i+1)%resolution+resolution,i+resolution) for i in range(resolution)]
    return mesh(name,vertices,faces,[mat],col)


icospheres = {}


def sphere(name, center, scale, mat, col, subdivisions=1):
    key=(subdivisions,mat.name)
    if key not in icospheres:
        data=bpy.data.meshes.new(mat.name+" · forma")
        geometry=bmesh.new()
        bmesh.ops.create_icosphere(geometry,subdivisions=subdivisions,radius=1)
        geometry.to_mesh(data)
        geometry.free()
        data.materials.append(mat)
        if mat in leaf:
            for polygon in data.polygons:
                polygon.use_smooth=True
        icospheres[key]=data
    obj=bpy.data.objects.new(name,icospheres[key])
    obj.location=center
    obj.scale=scale
    col.objects.link(obj)
    return obj


def tree(p,z,size):
    if not inside(p,LAND_EDGE) or inside(p,CONTOUR):
        return
    u,v=p
    ground=Vector(world(p,z))
    top=ground+Vector((.11,.07,2.10))*size
    beam("Tronco",ground,top,.24*size,.085*size,bark[1],forest,7)
    for i in range(5):
        theta=i*math.tau/5+RNG.uniform(-.25,.25)
        radial=Vector((math.cos(theta),math.sin(theta),0))
        toe=radial*(.64*size)+ground
        grid=(toe.x,-toe.y)
        contact = surface_height(grid)
        if abs(contact-z)<.21:
            toe.z=contact+.018
        else:
            toe.z=z+.012
        beam("Raiz de apoio",ground+Vector((0,0,.29*size)),toe,.105*size,.025*size,bark[i%3],forest,5)
        branch=top+radial*(.56*size)+Vector((0,0,.30*size))
        beam("Galho",ground.lerp(top,.65),branch,.081*size,.029*size,bark[0],forest)
        center=branch+radial*.21*size
        for k in range(3):
            d=Vector((RNG.uniform(-.47,.47),RNG.uniform(-.43,.43),RNG.uniform(-.13,.39)))*size
            r=RNG.uniform(.59,.88)*size
            sphere("Copa",center+d,(r,r*.88,r*.61),leaf[(i+k)%len(leaf)],forest,2)
        tip=center+radial*.50*size+Vector((0,0,.36))*size
        sphere("Ponta iluminada da copa",tip,(.36*size,.39*size,.23*size),leaf[3+i%2],forest,2)
    sphere("Copa alta",top+Vector((0,0,.67*size)),(.83*size,.76*size,.62*size),leaf[-1],forest,2)


def build_forest(crest_trees):
    for u,v in DATA.get("treeBeds",[]):
        p=(u+.5,v+.5)
        tree(p,surface_height(p),RNG.uniform(.94,1.24))
    for p,z,size in crest_trees:
        tree(p,z,size)
    for u,v in [(4,3),(8,3),(12,2),(16,2),(18,2),(28,2),(35,2),(38,3),(42,3),(44,7),(43,10),(45,15),(45,20),(44,26),(41,33),(36,36),(32,36),(11,35),(7,32),(8,23),(8,12),(8,7),(10,5)]:
        p=(u+.45,v+.5)
        if not solid_path(p):
            tree(p,surface_height(p),RNG.uniform(.76,1.10))
    for u,v in [(16.2,24.5),(18,25),(20,26),(26,26.2),(28.8,26),(31.5,24.6),(33.6,22.5),(34.6,20),(34.8,17),(14.9,21.5),(37.1,10.4)]:
        p=(u,v)
        z=surface_height(p)
        sphere("Pedra de margem",world(p,z+.16),(.42,.31,.32),rock[RNG.randrange(5)],lake,2)
        for k in range(9):
            a=Vector(world(p,z+.01))+Vector((RNG.uniform(-.53,.53),RNG.uniform(-.32,.32),0))
            b=a+Vector((RNG.uniform(-.12,.12),RNG.uniform(-.34,.34),RNG.uniform(.14,.43)))
            beam("Taboas",a,b,.027,.006,leaf[k%5],forest,4)


def rock_spur(p,z,size,tall=1):
    """Fractured shoulder rock with a coherent base inside the support surface."""
    sides=6
    angle=RNG.uniform(0,math.tau)
    body=Surface()
    layers=[]
    for k,(height,width,shift) in enumerate(((-.15,1.0,0),(.31,.96,.02),(.89,.68,-.12),(1.08,.46,-.19))):
        rim=[]
        for i in range(sides):
            theta=angle+math.tau*i/sides
            ripple=1.0+.08*math.sin(i*3+k)
            at=(p[0]+size*(math.cos(theta)*width*ripple+shift),p[1]+size*(math.sin(theta)*width*.74+.08*k))
            rim.append(world(at,z+size*tall*(height+.08*math.cos(i*2+k))))
        layers.append(rim)
    for j,(a,b) in enumerate(zip(layers,layers[1:])):
        for i in range(sides):
            right=(i+1)%sides
            body.face([a[i],a[right],b[right],b[i]], (i+j//2+RNG.randrange(2))%5)
    body.face(list(reversed(layers[-1])),3)
    return body.build("Bloco angular de basalto",rock,lake)


def wetland_details():
    # Broken ledges follow the real wet contour. The wide entry apron stays clear.
    for i in (9,10,0,1,2,3,4,6,7):
        a,b=CONTOUR[i],CONTOUR[(i+1)%len(CONTOUR)]
        for t in (.15,.45,.76):
            p=a.lerp(b,t)
            yaw=(b-a).normalized()
            inland=Vector((yaw.y,-yaw.x))
            if i in (9,10,0,1,2) and abs(p.x-24.65)<1.0:
                continue
            rock_spur(p+inland*.07,WATER-.08,RNG.uniform(.25,.74),RNG.uniform(1.0,2.55) if i in (0,1,2,10) else .64)
    for center in [(15,25),(15.8,22.7),(19,25.55),(22,26.8),(26.8,26.65),(31.4,25.35),(34.2,24),(35.9,20.7),(30.4,7.0),(21.85,7.0),(18.8,8.7),(13.5,18.4),(38.15,28),(31.2,33.1),(17.0,33.2),(12.0,29.9),(9.1,26.6),(17,4),(27.3,3.45),(36,6.45)]:
        if not inside(center,LAND_EDGE) or inside(center,CONTOUR) or solid_path(center):
            continue
        z=surface_height(center)
        rock_spur(center,z,RNG.uniform(.33,.80),RNG.uniform(.88,1.45))
        for k in range(7):
            angle=k*2.4
            p=(center[0]+math.cos(angle)*(.45+k*.13),center[1]+math.sin(angle)*(.40+k*.1))
            if not inside(p,LAND_EDGE) or inside(p,CONTOUR) or solid_path(p) or abs(surface_height(p)-z)>.1:
                continue
            for j in range(3):
                d=RNG.uniform(.22,.43)
                at=(p[0]+RNG.uniform(-.20,.20),p[1]+RNG.uniform(-.22,.22))
                sphere("Moita baixa",world(at,z+d*.41),(d*1.15,d,d*.54),leaf[(j+k)%5],forest,2)
            if k%3==0:
                sphere("Flor de margem",world(p,z+.27),(.10,.09,.065),flower,forest,1)
    tufts=Surface()
    for u in range(4,45):
        for v in range(4,37):
            if RNG.random()>.58:
                continue
            c=cell(u,v)
            if not inside((u+.5,v+.5),LAND_EDGE) or inside((u+.5,v+.5),CONTOUR) or solid_path((u+.5,v+.5)):
                continue
            if c["level"]==0 and min((Vector((u+.5,v+.5))-p).length for p in CONTOUR)<.67:
                continue
            for k in range(RNG.randrange(3,7)):
                p=(u+RNG.uniform(.12,.9),v+RNG.uniform(.12,.9))
                if not inside(p,LAND_EDGE) or inside(p,CONTOUR) or solid_path(p):
                    continue
                z=surface_height(p)+.012
                base=Vector(world(p,z))
                side=Vector((RNG.uniform(-.063,.063),RNG.uniform(-.066,.066),0))
                tip=base+Vector((side.x*1.9,side.y*1.9,RNG.uniform(.075,.30)))
                tufts.face([tuple(base-side*.4),tuple(base+side*.4),tuple(tip)],k%4)
    tufts.build("Tapete de gramíneas em manchas",leaf[1:],forest)


def paving_and_fences():
    paths=Surface()
    for u in range(5,43):
        for v in range(5,36):
            if not solid_path((u+.5,v+.5)) or not inside((u+.5,v+.5),LAND_EDGE) or RNG.random()>.36:
                continue
            p=(u+RNG.uniform(.20,.80),v+RNG.uniform(.20,.80))
            if WEST_STAIR[1]<=p[1]<=WEST_STAIR[2] and abs(p[0]-WEST_STAIR[0])<1.04:
                continue
            radius=RNG.uniform(.14,.31)
            angle=RNG.uniform(0,math.tau)
            shape=[]
            for i in range(6):
                theta=angle+i*math.tau/6
                pt=(p[0]+math.cos(theta)*radius,p[1]+math.sin(theta)*radius*.65)
                shape.append(world(pt,surface_height(pt)+.024))
            paths.face(list(reversed(shape)),int(RNG.random()>.52))
    paths.build("Pedras chatas na trilha", [soil[2],slab],terrain)
    u,upper,lower=WEST_STAIR
    step_depth=(lower-upper)/13
    for index in range(13):
        v=upper+index*step_depth
        z=surface_height((u,v))+.018
        landing=surface_height((u,v+step_depth))
        thickness=max(.14,z-landing+.15)
        box("Degrau de pedra",world((u,v+step_depth/2),z-thickness/2),(1.83,step_depth+.008,thickness),rock[3 if index%4 else 0],terrain)
    for x in (u-.93,u+.93):
        rails=[]
        for index in (0,4,8,12):
            v=upper+index*step_depth
            z=surface_height((u,v))
            beam("Poste da escada",world((x,v),z-.04),world((x,v),z+.55),.052,.047,wood,terrain,4)
            rails.append(world((x,v),z+.55))
        for a,b in zip(rails,rails[1:]):
            beam("Corrimão da escada",a,b,.039,.037,wood,terrain,4)
    for start,end in [((17.9,34),(21.6,34)),((26.9,35),(30.2,35)),((31.35,6.6),(34.2,6.6))]:
        a,b=Vector(start),Vector(end)
        for k in range(5):
            p=a.lerp(b,k/4)
            z=surface_height(p)
            beam("Estaca de cerca",world(p,z),world(p,z+.46),.069,.059,wood,terrain,4)
        for z in (.17,.34):
            beam("Travessa de madeira",world(a,surface_height(a)+z),world(b,surface_height(b)+z),.047,.041,wood,terrain,4)
    for p,z in [((21.38,33.86),0),((29.4,34.82),0),((33.77,8.24),94*HEIGHT)]:
        dx,dy,dz=world(p,z)
        beam("Mastro do estandarte",(dx,dy,dz),(dx,dy,dz+1.39),.045,.038,steel,station,5)
        xs=[-.03,-.18,-.30,-.44,-.47]
        cloth=Surface()
        for j in range(4):
            a,b=xs[j],xs[j+1]
            low=1.04-.45
            cloth.face([(dx+a,dy-.05*math.sin(j*1.25),dz+1.29),(dx+b,dy-.05*math.sin((j+1)*1.25),dz+1.29),(dx+b,dy-.05*math.sin((j+1)*1.25),dz+low+.025*j),(dx+a,dy-.05*math.sin(j*1.25),dz+low+.025*j)],0)
        cloth.build("Estandarte do posto", [flag_blue],station)


def waterfall():
    channel=Surface()
    water_head=((57+(91-57)*(WATERFALL_X-20)/7)*HEIGHT-.33) + surface_height((WATERFALL_X,7.92))
    rungs=[(7.31,water_head+.05,.47),(7.63,water_head+.02,.49),(7.93,water_head+.005,.47),(8.09,water_head-.16,.46),(8.16,1.08,.44),(8.22,.40,.42),(8.27,-.35,.40),(8.47,WATER+.022,.55)]
    center=WATERFALL_X
    for index,((a,za,wa),(b,zb,wb)) in enumerate(zip(rungs,rungs[1:])):
        for k in range(7):
            lo=-1+k*2/7
            hi=-1+(k+1)*2/7
            channel.face([world((center+wa*lo,a),za),world((center+wb*lo,b),zb),world((center+wb*hi,b),zb),world((center+wa*hi,a),za)],int(k in (1,5) or (index+k)%12==0))
    channel.build("Cachoeira · vertedouro aberto na escarpa",[stream_blue,stream_light],lake)
    for j in range(16):
        p=(center+RNG.uniform(-.56,.64),8.50+RNG.uniform(-.02,.49))
        sphere("Espuma do pé da queda",world(p,WATER+.036),(.19,.13,.06),foam,lake,1)
    for width,depth in ((.56,.38),(.81,.51),(1.16,.73)):
        wave=[]
        for k in range(12):
            theta=math.pi*(.13+k*.74/11)
            p=(center+math.cos(theta)*width,8.62+math.sin(theta)*depth)
            wave.append(world(p,WATER+.028))
        for a,b in zip(wave,wave[1:]):
            beam("Ondulação do vertedouro",a,b,.016,.014,foam,lake,4)


def roots_and_vines():
    for x,y,z in [(19.5,8.22,1.45),(22.33,8.03,1.63),(27.8,8.38,1.90),(30.1,9.31,1.49)]:
        for i in range(3):
            step=(i-1)*.18
            u,v=x+step,y+.055
            points=[world((u,v),z-.02),world((u-.06,v+.04),z-.17),world((u+.08,v+.06),z-.44),world((u+.02,v+.07),z-.63-RNG.random()*.35)]
            for a,b in zip(points,points[1:]):
                beam("Cipó aderente",a,b,.024,.015,moss,forest,5)
            for j,mark in enumerate(points[1:]):
                p=Vector(mark)+Vector((.07*(-1 if j%2 else 1),-.018,0))
                sphere("Folha de cipó",p,(.09,.046,.047),leaf[2+j%2],forest,1)


def compose_forest():
    # Clumps along the side masses keep the view through the main path clear.
    for x,y,s in [(4.1,17.2,1.30),(5.2,13.6,1.10),(8.6,15.7,1.22),(7.9,16.9,.72),(8.3,20.3,1.15),(9.9,18.8,.78),(5.1,25.1,1.19),(4.9,26.95,.72),(15.35,30.6,.92),(12.3,31.9,.85),(13.25,36.1,1.19),(10.25,37.5,.89),(32.8,38.1,1.14),(33.9,36.7,.84),(40.5,37.6,1.22),(41.6,37.28,.84),(45.8,34.8,1.14),(46.2,32.15,.72),(44.5,23.7,1.23),(43.2,24.75,.73),(44.3,15.7,.85),(36.6,3.5,.94),(34.6,2.04,1.14),(30.95,2.75,.89)]:
        p=(x,y)
        if not solid_path(p):
            tree(p,surface_height(p),s)
    for index in range(7,23):
        a,b=LAND_EDGE[index],LAND_EDGE[(index+1)%len(LAND_EDGE)]
        direction=(b-a).normalized()
        n=Vector((direction.y,-direction.x))
        for t in (.26,.72):
            edge=a.lerp(b,t)
            top=surface_height(edge)
            p=edge+n*.08
            r=RNG.uniform(.34,.68)
            rock_spur(p,top-r*2.2,r,RNG.uniform(1.8,2.25))
            at=edge-n*.41
            if RNG.random()<.72 and not solid_path(at):
                sphere("Moita na borda",world(at,surface_height(at)+.14),(r*.83,r*.80,.31),leaf[RNG.randrange(2,5)],forest,2)
    # Angular, discontinuous shoulders soften the exposed walls of the high grid plateaus.
    for u,v in [(10.9,11.4),(10.92,15.4),(10.92,22.25),(12.0,7.3),(13.2,4.8),(16.65,3.9),(20.7,3.9),(28.4,3.9),(33.5,4.05),(39.65,9.75),(39.8,14.3),(39.8,17.1),(39.8,21.1)]:
        sample=(u-.19,v)
        z=surface_height(sample)
        if z<.9 or not inside((u,v),LAND_EDGE) or solid_path((u,v)):
            continue
        r=RNG.uniform(.27,.57)
        rock_spur((u,v),z-r*2.2,r,2.0)


def build_station():
    origin=(29.62,7.96)
    z=94*HEIGHT
    for name,(u,v),(w,h) in [("Plataforma",origin,(4.98,2.92)),("Passarela",(34.6,9.18),(3.14,1.34))]:
        box(name,world((u+w/2,v+h/2),z-.11),(w,h,.22),steel,station)
        for j in range(math.ceil(w/.25)):
            dx=min(.245,w-j*.25)
            box("Régua de piso",world((u+j*.25+dx/2,v+h/2),z-.036),(dx,h,.083),slab,station)
        for f in ((u+.25,v+h-.22),(u+w-.24,v+h-.22),(u+w-.24,v+.22)):
            data=cell(math.floor(f[0]),math.floor(f[1]))
            base=WATER-.14 if data["material"]=="agua" else surface_height(f)
            box("Sapata",world(f,base+.11),(.46,.44,.30),ivory,station)
            beam("Pilar metálico",world(f,base+.25),world(f,z-.13),.077,.077,steel,station,4)
        rails=[((u,v),(u+w,v)),((u,v+h),(u+min(1.44,w),v+h)),((u+w-.86,v+h),(u+w,v+h))]
        if name=="Passarela":
            rails=[((u,v),(u+w,v)),((u,v+h),(u+w,v+h))]
        else:
            rails.append(((u,v),(u,v+h)))
        for a,b in rails:
            a,b=Vector(a),Vector(b)
            posts=math.ceil((b-a).length/.91)
            for i in range(posts+1):
                p=a.lerp(b,i/posts)
                beam("Montante",world(p,z),world(p,z+.59),.040,.040,steel,station,4)
            for h in (.27,.59):
                beam("Guarda-corpo",world(a,z+h),world(b,z+h),.033,.033,steel,station,6)
    box("Gabinete off-white",world((30.60,8.53),z+.41),(.76,.63,.82),ivory,station)
    box("Monitor",world((31.74,8.77),z+.61),(1.05,.36,.81),steel,station)
    box("Vidro do monitor",world((31.74,8.97),z+.65),(.86,.044,.58),screen,station)
    coords=[world((31.36+i*.121,9.002),z+.58+item*.029) for i,item in enumerate((0,4,1,6,3,5,2))]
    for a,b in zip(coords,coords[1:]):
        beam("Gráfico",a,b,.016,.016,mint,station,4)
    p=world((32.44,8.2),z)
    beam("Mastro solar",p,(p[0],p[1],z+1.85),.054,.054,steel,station)
    solar=box("Painel solar",world((0,0),0),(1.15,.72,.067),panel,station)
    solar.location=world((32.44,8.2),z+1.86)
    solar.rotation_euler.y=.24
    for i in range(9):
        box("Marca amarela",world((30+i*.43,10.75),z+.014),(.18,.04,.016),yellow,station)


def camera(name, target, distance, width):
    height=math.tan(math.pi/6)*math.sqrt(2)
    location=Vector(target)+Vector((1,-1,height)).normalized()*distance
    data=bpy.data.cameras.new(name)
    data.type="ORTHO"
    data.ortho_scale=width
    obj=bpy.data.objects.new(name,data)
    cameras.objects.link(obj)
    obj.location=location
    obj.rotation_euler=(Vector(target)-location).to_track_quat("-Z","Y").to_euler()
    return obj


def billboard(name, file, cell_xy, extent, pivot, point, cam, z=0, scale=1):
    img=bpy.data.images.load(str(PROJECT/file),check_existing=True)
    img.pack()
    mat=bpy.data.materials.new(name)
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    nodes.clear()
    tex=nodes.new("ShaderNodeTexImage")
    tex.image=img
    tex.interpolation="Closest"
    emission=nodes.new("ShaderNodeEmission")
    transparent=nodes.new("ShaderNodeBsdfTransparent")
    mix=nodes.new("ShaderNodeMixShader")
    output=nodes.new("ShaderNodeOutputMaterial")
    links=mat.node_tree.links
    links.new(tex.outputs["Color"],emission.inputs["Color"])
    links.new(tex.outputs["Alpha"],mix.inputs[0])
    links.new(transparent.outputs[0],mix.inputs[1])
    links.new(emission.outputs[0],mix.inputs[2])
    links.new(mix.outputs[0],output.inputs["Surface"])
    mat.surface_render_method="DITHERED"
    right=cam.rotation_euler.to_matrix()@Vector((1,0,0))
    up=cam.rotation_euler.to_matrix()@Vector((0,1,0))
    point=Vector(world(point,z))
    unit=scale/(32*math.sqrt(2))
    w,h=extent
    x,y=cell_xy
    corners=[(0,h),(w,h),(w,0),(0,0)]
    vertices=[tuple(point+right*((a-pivot[0])*unit)+up*((pivot[1]-b)*unit)) for a,b in corners]
    obj=mesh(name,vertices,[(0,1,2,3)],[mat],cast)
    layer=obj.data.uv_layers.new()
    for loop,(a,b) in zip(layer.data,corners):
        loop.uv=((x+a)/img.size[0],1-(y+b)/img.size[1])
    return point,right,up


def lighting():
    scene.world=bpy.data.worlds.new("Luz difusa de floresta")
    scene.world.use_nodes=True
    scene.world.node_tree.nodes.get("Background").inputs[0].default_value=(.45,.61,.70,1)
    scene.world.node_tree.nodes.get("Background").inputs[1].default_value=.54
    sun=bpy.data.lights.new("Sol filtrado","SUN")
    sun.energy=3.12
    sun.color=(1.0,.927,.81)
    sun.angle=.12
    obj=bpy.data.objects.new(sun.name,sun)
    cameras.objects.link(obj)
    obj.rotation_euler=Vector((.47,-.37,-.8)).to_track_quat("-Z","Y").to_euler()


def backdrop(cam, target):
    art=collection("07 · Fundo do diorama")
    camera_matrix=cam.rotation_euler.to_matrix()
    right=camera_matrix@Vector((1,0,0))
    up=camera_matrix@Vector((0,1,0))
    back=camera_matrix@Vector((0,0,-1))
    center=Vector(target)+back*62

    def place(x,y,d=0):
        return tuple(center+right*x+up*y+back*d)

    def emission(name,color, lower=None):
        mat=bpy.data.materials.new(name)
        mat.use_nodes=True
        nodes=mat.node_tree.nodes
        nodes.clear()
        light=nodes.new("ShaderNodeEmission")
        light.inputs[0].default_value=color
        out=nodes.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(light.outputs[0],out.inputs["Surface"])
        if lower:
            uv=nodes.new("ShaderNodeTexCoord")
            separate=nodes.new("ShaderNodeSeparateXYZ")
            gradient=nodes.new("ShaderNodeValToRGB")
            gradient.color_ramp.elements[0].color=lower
            gradient.color_ramp.elements[1].color=color
            mat.node_tree.links.new(uv.outputs["UV"],separate.inputs[0])
            mat.node_tree.links.new(separate.outputs["Y"],gradient.inputs[0])
            mat.node_tree.links.new(gradient.outputs[0],light.inputs[0])
        return mat

    sky=emission("Azul atmosférico",(.225,.434,.655,1),(.044,.135,.29,1))
    plate=mesh("Gradiente azul", [place(-90,-60,4),place(90,-60,4),place(90,60,4),place(-90,60,4)],[(0,1,2,3)],[sky],art)
    layer=plate.data.uv_layers.new()
    for loop,coord in zip(layer.data,[(0,0),(1,0),(1,1),(0,1)]):
        loop.uv=coord
    ridge_mats=[emission("Serra em névoa",(.103,.24,.40,1)),emission("Rochedos ao longe",(.074,.17,.30,1))]
    for row,mat in enumerate(ridge_mats):
        for i,x in enumerate(range(-60,64,8)):
            center_y=-4-row*5+math.sin(i*1.1+row)*7
            width=3.2+RNG.uniform(0,4.6)
            height=RNG.uniform(7,18)
            profile=[(-width,-47),(-width,center_y),(-.81*width,center_y+height*.53),(-.64*width,center_y+height*.89),(-.22*width,center_y+height),(.19*width,center_y+height*.96),(.34*width,center_y+height*.72),(.66*width,center_y+height*.64),(.84*width,center_y+height*.41),(width,-47)]
            verts=[place(x+dx,y,2-row) for dx,y in profile]
            mesh("Silhueta distante",verts,[tuple(range(len(verts)))],[mat],art)


build_terrain()
crest_trees=build_bank()
build_forest(crest_trees)
build_station()
wetland_details()
waterfall()
paving_and_fences()
roots_and_vines()
compose_forest()
main=camera("Arena · câmera do jogo 2:1",world((25.3,16.75),1.43),91,34.7)
target=world((24,19.6),.94)
wide=camera("Diorama · lago C",target,101,64.0)
scene.camera=wide
backdrop(wide,target)
lighting()

kael=(24.5,28.5)
billboard("Kael · escala do jogo","godot/assets/kael-video/iso-v2/idle.png",(0,6*96),(64,96),(32,94),kael,main,surface_height(kael),.95)
rabbito=(24.24,29.2)
billboard("Rabbito · escala do jogo","godot/assets/campaign/overworld-companions-v2/rabbito.png",(0,0),(112,112),(56,100),rabbito,main,surface_height(rabbito))
guardian=tuple(DATA["guardian"])
boss, right, up = billboard("Mormaço · posição do encontro","godot/assets/campaign/mormaco-v1/submerged.png",(0,320),(320,320),(160,302),guardian,main,WATER,1.04)
agent, _, _ = billboard("Capanga do Cerol · plataforma","godot/assets/overworld/kits/camara-do-elo-v1/capanga-feminina-idle-eight.png",(64,0),(64,96),(32,90),(32.58,10.53),main,94*HEIGHT)
unit=1/(32*math.sqrt(2))
hand=agent+right*(-15*unit)+up*(33*unit)
vent=boss+right*(-42*unit)+up*(106*unit)
box("Carretel · núcleo na mão",hand,(.15,.125,.13),line_ink,cast)
def ribbon(t):
    return hand.lerp(vent,t)+Vector((0,0,math.sin(math.pi*t)*.68))


for i in range(20):
    beam("Fio do Carretel",ribbon(i/20),ribbon((i+1)/20),.019,.019,line_ink,cast,5)
for i in range(25):
    theta=RNG.uniform(0,math.tau)
    r=RNG.uniform(.29,1.0)
    at=(25.25+math.cos(theta)*r*2.0,19.9+math.sin(theta)*r*.71)
    sphere("Pedra no baixio",world(at,WATER+.01),(RNG.uniform(.18,.43),RNG.uniform(.19,.32),.12),shoal,lake,1)
for cluster in ((17.6,16.4),(19.2,12.8),(30.9,19.8),(29.7,21.6)):
    for _ in range(6):
        p=(cluster[0]+RNG.uniform(-.45,.45),cluster[1]+RNG.uniform(-.40,.40))
        sphere("Folha flutuante",world(p,WATER+.014),(.16,.11,.025),moss,lake,1)

scene["Origem do lago e dos marcos"]="godot/assets/overworld/maps/kronasta-pantano-c.json"
scene["Topografia"]="Relevo autoral no Blender. Escada oeste, trilhas com perfil de elevação e cume da cachoeira."
scene["Câmera"]= "Ortográfica, azimute 45°, elevação 30°. Base isométrica 2:1."
scene.render.engine="BLENDER_EEVEE"
scene.render.resolution_x=1600
scene.render.resolution_y=900
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.view_settings.view_transform="AgX"
for screen_view in bpy.data.screens:
    for area in screen_view.areas:
        if area.type=="VIEW_3D":
            area.spaces.active.region_3d.view_perspective="CAMERA"
            area.spaces.active.shading.color_type="MATERIAL"

bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"lago-mormaco-diorama.blend"))
scene.render.filepath=str(OUT/"diorama.png")
bpy.ops.render.render(write_still=True)
scene.camera=main
scene.render.filepath=str(OUT/"arena-diorama.png")
bpy.ops.render.render(write_still=True)
