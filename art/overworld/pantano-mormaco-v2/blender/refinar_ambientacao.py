"""Art pass evaluated by reconstruir_referencia.py, in the same fixed camera."""
detail_rng=random.Random(1609)
refinement=collection("07 · Refinamento de rochas e margens")
stone_paint=[painted("Escarpa pintada "+c,c) for c in ("454c61","53596c","62677a","747688","868593","96919a")]
for mat in stone_paint:
    shade_pattern(mat,2.8,.12)
    bsdf=mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Emission Color"].default_value=mat.diffuse_color
    bsdf.inputs["Emission Strength"].default_value=.14


def rock_mass(name,center,tangent,normal,width,depth,height,seed):
    """Closed, intersecting rock volumes; the watertight terrain remains underneath."""
    r=random.Random(seed)
    n=7
    surface=Surface()
    rings=[]
    wobble=[r.uniform(.81,1.17) for i in range(n)]
    phase=r.uniform(-.40,.40)
    for row,(size,lift,forward) in enumerate([(1.12,0,.17),(1.0,.30,.23),(.88,.72,.08),(.68,1.0,-.04)]):
        ring=[]
        for i in range(n):
            angle=i*math.tau/n+phase
            p=Vector(center)+tangent*(math.cos(angle)*width*size*wobble[i]+r.uniform(-.10,.10)*width)+normal*(math.sin(angle)*depth*size+forward)
            p.z+=height*lift+(r.uniform(-.06,.05) if row in (1,2) else 0)
            ring.append(p)
        rings.append(ring)
    for row in range(3):
        for i in range(n):
            j=(i+1)%n
            ink=max(0,min(5,2+int(math.cos(i*math.tau/n)*1.7)+(1 if row==2 else 0)))
            surface.face([rings[row][i],rings[row][j],rings[row+1][j],rings[row+1][i]],ink)
    surface.face(list(reversed(rings[0])),1)
    surface.face(rings[-1],4)
    obj=surface.build(name,stone_paint,refinement)
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),name
    bm.to_mesh(obj.data)
    bm.free()
    return obj


# Each wall receives large structural outcrops. Their bases widen into the lower level.
rock_count=0
for outline,z,bottom in [(BASE,0,-1.62),(WEST,1.42,0),(MID,2.90,1.42),(PEAK,4.19,2.90),(REAR,1.94,-.38)]:
    world_outline=[at(*p,z) for p in outline]
    orient=1 if signed(world_outline)>0 else -1
    for a,b in zip(world_outline,world_outline[1:]+world_outline[:1]):
        tangent=(b-a).normalized()
        normal=Vector((tangent.y,-tangent.x,0))*orient
        if normal.dot(-AWAY)<.12: continue
        length=(b-a).length
        count=max(1,math.ceil(length/1.43))
        for i in range(count):
            t=max(.08,min(.92,(i+detail_rng.uniform(.30,.70))/count))
            p=a.lerp(b,t)
            x,y=pixel(p)
            if z==1.42 and 370<x<495 and y>260: continue
            # Keep the waterfall throat and the dock approach unobstructed.
            if z==1.94 and 890<x<928: continue
            p.z=bottom-.025
            h=(z-bottom)*detail_rng.uniform(.67,.97)
            rock_mass("Escarpa · bloco estrutural",p,tangent,normal,length/count*detail_rng.uniform(.49,.75),detail_rng.uniform(.16,.46),h,900+rock_count)
            if i%3==1:
                upper=p+tangent*detail_rng.uniform(-.22,.22)-normal*.06
                upper.z+=h*.62
                rock_mass("Escarpa · fratura superior",upper,tangent,normal,length/count*.43,.17,(z-upper.z)-.025,1600+rock_count)
            rock_count+=1

# A sloping rocky junction visually and physically connects the isolated upper masses.
for i,(x,y,z,h) in enumerate([(754,287,0,1.25),(776,274,0,1.57),(798,265,0,1.80)]):
    rock_mass("Contraforte entre patamares",at(x,y,z),RIGHT,-AWAY,.40,.31,h,1100+i)

# Group low vegetation into islands around roots and boulders, leaving the trail open.
for x,y,z,size in [(195,418,0,.32),(232,423,0,.27),(289,449,0,.34),(320,467,0,.22),
                   (452,598,0,.28),(477,617,0,.35),(527,639,0,.27),(615,706,0,.33),
                   (684,756,0,.28),(805,792,0,.25),(1095,685,0,.31),(1134,671,0,.29),
                   (1235,612,0,.33),(1281,572,0,.29),(1411,465,0,.35),
                   (506,262,1.42,.34),(548,284,1.42,.30),(602,297,1.42,.27),
                   (595,161,2.90,.29),(662,174,2.90,.25),(760,170,2.90,.29)]:
    shrub((x,y),z,size)

# Upper-right trees belong on the ridge, with their roots verified against its footprint.
for k,(xy,h,w) in enumerate([((1164,251),1.03,.91),((1257,297),1.10,.94),((1361,333),1.05,.88)]):
    if supported(xy,1.94): model_tree(xy,1.94,h,w,310+k)

# Reeds, wet stones and shallow-water colour follow the actual polygonal shoreline.
shore=Surface()
wet_palette=[painted("Margem úmida "+c,c) for c in ("3e7669","537f62","6c8d57")]
for i,(a,b) in enumerate(zip(POOL,POOL[1:]+POOL[:1])):
    a,b=Vector(a),Vector(b)
    if (a.y+b.y)*.5<400: continue
    for j in range(1 if i%4==0 else 0):
        p=a.lerp(b,detail_rng.uniform(.15,.85))
        random_stone("Margem · rocha parcialmente submersa",tuple(p),-.31,detail_rng.uniform(.25,.49),detail_rng.uniform(.20,.40))
        if j==0:
            ellipse_patch("Margem · transparência rasa",tuple(p),detail_rng.uniform(15,26),detail_rng.uniform(4,8),-.365,[water_shallow],lake)
    delta=b-a
    side=Vector((-delta.y,delta.x)).normalized()*detail_rng.uniform(5,9)
    shore.face([at(*a,-.355),at(*b,-.355),at(*(b+side),-.355),at(*(a+side),-.355)],i%3)
shore.build("Margem · transição de cor",wet_palette,lake)

# Water keeps large quiet regions, interspersed with fine reflections and a depth gradient.
water_nodes=water_color.node_tree.nodes
water_links=water_color.node_tree.links
bsdf=water_nodes.get("Principled BSDF")
bsdf.inputs["Roughness"].default_value=.65
bsdf.inputs["Specular IOR Level"].default_value=.12
coords=water_nodes.new("ShaderNodeNewGeometry")
noise=water_nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value=1.15
noise.inputs["Detail"].default_value=2
ramp=water_nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color=(*[.014,.075,.10],1)
ramp.color_ramp.elements[1].color=(*[.020,.14,.17],1)
water_links.new(coords.outputs["Position"],noise.inputs["Vector"])
water_links.new(noise.outputs["Fac"],ramp.inputs["Fac"])
water_links.new(ramp.outputs["Color"],bsdf.inputs["Base Color"])
for i in range(100):
    x,y=detail_rng.uniform(665,1280),detail_rng.uniform(330,551)
    if not inside((x,y),[Vector(p) for p in POOL]): continue
    if 790<x<990 and 381<y<481: continue
    p=at(x,y,-.35)
    beam("Água · reflexo interrompido",p,p+RIGHT*detail_rng.uniform(.08,.32),.005,.004,water_ripple,lake,4)

# Thicker stream ribbons taper independently; a broad foam skirt grounds the impact.
fall_top=at(906,204,1.94)-AWAY*.48
fall_base=Vector((fall_top.x,fall_top.y,-.35))
for i in range(5):
    strip_points=[]
    for j in range(13):
        t=j/12
        p=fall_top.lerp(fall_base,t)+RIGHT*((i-2)*.10+.018*math.sin(j*.79+i))+(-AWAY)*(.018+math.sin(t*math.pi)*.09)
        strip_points.append(p)
    strip("Cachoeira · fluxo irregular",strip_points,.028 if i%2 else .045,stream_light if i%2 else stream_blue,lake)
for i in range(18):
    theta=i*math.tau/18
    p=fall_base+RIGHT*math.cos(theta)*.57+AWAY*math.sin(theta)*.22
    sphere("Cachoeira · coroa de espuma",p+Vector((0,0,.055)),(.12,.09,.055),bright_foam,lake,1)

# Flat, irregular paving lies within the sand, rather than scattering pebbles over the lawn.
for i in range(21):
    x,y=detail_rng.uniform(589,776),detail_rng.uniform(548,596)
    if min(segment_distance((x,y),a,b) for a,b in zip(path_pixels,path_pixels[1:]))>22: continue
    random_stone("Trilha · laje de passagem",(x,y),.026,detail_rng.uniform(.18,.33),.035)

# The open end of the pier now lands on a stair and then the right-hand path.
stair_top_l,stair_top_r=at(1320,435,.50),at(1355,410,.50)
stair_low_l,stair_low_r=at(1370,482,0),at(1405,457,0)
for i in range(5):
    t=(i+.5)/5
    l=stair_top_l.lerp(stair_low_l,t)
    r=stair_top_r.lerp(stair_low_r,t)
    center=(l+r)*.5
    run=((stair_low_l-stair_top_l)*Vector((1,1,0))).length/5
    obj=box("Mirante · degrau de acesso",center,((r-l).length,run+.025,.10),slab,station)
    obj.rotation_euler.z=math.atan2((r-l).y,(r-l).x)
for a,b in [(stair_top_l,stair_low_l),(stair_top_r,stair_low_r)]:
    beam("Mirante · corrimão da escada",a+Vector((0,0,.32)),b+Vector((0,0,.32)),.022,.022,wood_light,station,5)

# Keep a clear opening in the end railing, aligned with the new stair.
for obj in list(station.objects):
    if not obj.name.startswith(("Guarda-corpo","Montante do mirante")): continue
    center=sum((obj.matrix_world@Vector(p) for p in obj.bound_box),Vector())/8
    x,y=pixel(center)
    # Beam origins are at their midpoint, so the short end can be identified in screen space.
    if 1317<x<1362 and 396<y<436: obj.hide_render=True

ribbon_surface("Trilha · chegada ao mirante",[(1290,516),(1345,499),(1387,470)],.82,.029,path_palette,terrain)


def backdrop(cam,target):
    """Low-frequency painted atmosphere, with soft silhouettes instead of hard polygons."""
    from mathutils import Vector
    width,height=192,108
    image=bpy.data.images.new("Fundo · névoa e serras suaves",width,height)
    image.colorspace_settings.name="Non-Color"
    pixels=[]
    mountains=[(.06,1.12,.085,.26),(.21,1.24,.08,.24),(.38,.95,.09,.22),(.61,1.17,.10,.23),(.79,1.05,.10,.28),(.94,1.20,.09,.26)]
    for y in range(height):
        v=y/(height-1)
        for x in range(width):
            u=x/(width-1)
            sky=Vector((.16+.055*v,.32+.075*v,.50+.055*v))
            for row in range(2):
                ridge=0
                for k,(cx,top,w,drop) in enumerate(mountains):
                    center=cx+.035*row
                    level=top-.22*row-.14*(abs((u-center)/w)**4)
                    level+=.025*math.sin(u*38+k)
                    alpha=max(0,min(1,(level-v)/.065+.5))*.64
                    ridge=max(ridge,alpha)
                colour=Vector((.10,.24,.39)) if row==0 else Vector((.07,.20,.34))
                sky=sky.lerp(colour,ridge)
            pixels.extend((*sky,1))
    image.pixels=pixels
    image.pack()
    matrix=cam.rotation_euler.to_matrix()
    right,up,forward=matrix@Vector((1,0,0)),matrix@Vector((0,1,0)),matrix@Vector((0,0,-1))
    center=Vector(target)+forward*62
    aspect=W/H
    half=(W/UNIT)*.55
    vertices=[center-right*half-up*half/aspect,center+right*half-up*half/aspect,center+right*half+up*half/aspect,center-right*half+up*half/aspect]
    mat=bpy.data.materials.new("Atmosfera · emissão suave")
    mat.use_nodes=True
    nodes=mat.node_tree.nodes
    nodes.clear()
    tex=nodes.new("ShaderNodeTexImage")
    tex.image=image
    tex.interpolation="Linear"
    light=nodes.new("ShaderNodeEmission")
    output=nodes.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(tex.outputs["Color"],light.inputs["Color"])
    mat.node_tree.links.new(light.outputs[0],output.inputs["Surface"])
    obj=mesh("Fundo atmosférico",vertices,[(0,1,2,3)],[mat],refinement)
    uv=obj.data.uv_layers.new()
    for loop,co in zip(uv.data,[(0,0),(1,0),(1,1),(0,1)]): loop.uv=co

scene["Refinamento ambiental"]="Rochas fechadas, massas de vegetação agrupadas, margem rasa, trilha contínua e acesso ao mirante"
scene["Blocos rochosos validados"]=rock_count+3
