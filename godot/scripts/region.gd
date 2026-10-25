extends Node2D
## Native Godot rendering of the authored Veredas surfaces; no browser runtime.
@export_file("*.json") var layout_path: String = "res://assets/veredas.json"
var data: Dictionary
var materials: Dictionary = {}
var terrain_texture: Texture2D = preload("res://assets/terrain.png")
var navigation := AStar3D.new()
var cells: Dictionary = {}
var ground_tiles: TileMapLayer
var path_tiles: Node2D
const STEP := 32

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	for entry in [["water",0,0],["rock",1,0],["grass",0,1],["dirt",1,1]]:
		var texture := AtlasTexture.new()
		texture.atlas = terrain_texture
		texture.region = Rect2(entry[1]*627,entry[2]*627,627,627)
		materials[entry[0]] = texture
	ground_tiles=get_parent().get_node_or_null("ReferenceGround") as TileMapLayer
	if layout_path.ends_with("scale-yard.json"):
		path_tiles=preload("res://tiles/reference-paths.tscn").instantiate()
		add_child(path_tiles)
	_build_navigation()
	queue_redraw()

func elevation(p: Vector2) -> float:
	for floor in data.walk:
		if Rect2(floor.x,floor.y,floor.w,floor.h).has_point(p):
			var props: Dictionary = floor.properties
			if props.has("rise_to"):
				return (floor.y+floor.h-p.y)/floor.h*props.rise_to
			return props.get("elevation",0.0)
	return 0.0

func project(p: Vector2) -> Vector2:
	return Vector2((p.x-p.y)*0.82,(p.x+p.y)*0.41-elevation(p))

func walkable(p: Vector2) -> bool:
	var floor_found := false
	for floor in data.walk:
		if Rect2(floor.x,floor.y,floor.w,floor.h).has_point(p):
			floor_found = true
	if not floor_found:
		return false
	for solid in data.solids:
		if Rect2(solid.x-8,solid.y-8,solid.w+16,solid.h+16).has_point(p):
			return false
	return true

func _build_navigation() -> void:
	for y in range(8,int(data.height),16):
		for x in range(8,int(data.width),16):
			var p := Vector2(x,y)
			if walkable(p):
				var id: int = cells.size()
				cells[Vector2i(x/16,y/16)] = id
				navigation.add_point(id,Vector3(x,y,elevation(p)))
	for cell: Vector2i in cells:
		var id: int = cells[cell]
		for d in [Vector2i.RIGHT,Vector2i.DOWN]:
			if cells.has(cell+d):
				var other: int = cells[cell+d]
				if absf(navigation.get_point_position(id).z-navigation.get_point_position(other).z)<=20:
					navigation.connect_points(id,other)

func route(from: Vector2,to: Vector2) -> PackedVector2Array:
	var a := navigation.get_closest_point(Vector3(from.x,from.y,elevation(from)))
	var b := navigation.get_closest_point(Vector3(to.x,to.y,elevation(to)))
	var out := PackedVector2Array()
	for p in navigation.get_point_path(a,b):
		out.append(Vector2(p.x,p.y))
	return out

func pick(screen: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var distance := INF
	for id in navigation.get_point_ids():
		var node := navigation.get_point_position(id)
		var p := Vector2(node.x,node.y)
		var d := project(p).distance_squared_to(screen)
		if d<distance:
			distance=d
			best=p
	return best

func _quad(points: PackedVector2Array,material: String,uv: PackedVector2Array,color: Color=Color.WHITE) -> void:
	draw_polygon(points,PackedColorArray([color,color,color,color]),uv,materials[material])

func _floor(r: Rect2,h: float,material: String) -> void:
	# Small tiles keep texture density constant, including partial edge cells.
	var size := 128.0
	var y := r.position.y
	while y<r.end.y:
		var x := r.position.x
		while x<r.end.x:
			var w := minf(size,r.end.x-x)
			var depth := minf(size,r.end.y-y)
			var points := PackedVector2Array()
			for p in [Vector2(x,y),Vector2(x+w,y),Vector2(x+w,y+depth),Vector2(x,y+depth)]:
				points.append(Vector2((p.x-p.y)*.82,(p.x+p.y)*.41-h))
			_quad(points,material,PackedVector2Array([Vector2.ZERO,Vector2(w/size,0),Vector2(w/size,depth/size),Vector2(0,depth/size)]))
			x+=size
		y+=size

func _draw() -> void:
	if data.is_empty():
		return
	if not is_instance_valid(ground_tiles):
		_floor(Rect2(-1200,-1200,data.width+2400,data.height+2400),0,"grass")
	for r in data.water:
		_floor(Rect2(r.x,r.y,r.w,r.h),0,"water")
	# Banks share the water footprint; rocks stop at bridge abutments.
	for r in data.water:
		for x in [r.x,r.x+r.w]:
			for y in range(int(r.y)+8,int(r.y+r.h),18):
				var at:=Vector2(x,y)
				var crossing:=false
				for bridge in data.terrain.bridges:
					if y>bridge.y-8 and y<bridge.y+bridge.h+8:
						crossing=true
				if crossing: continue
				var q:=Vector2((at.x-at.y)*.82,(at.x+at.y)*.41)
				draw_colored_polygon(PackedVector2Array([q+Vector2(-6,-2),q+Vector2(-2,-6),q+Vector2(6,-2),q+Vector2(4,4),q+Vector2(-3,4)]),Color("a8a67a"))
				draw_line(q+Vector2(-5,-2),q+Vector2(-1,-5),Color("e6d5a0"),1.5)
	for edge in data.terrain.cliffs:
		var a := Vector2(edge.x,edge.y)
		var b := a+ (Vector2(edge.w,0) if edge.axis=="x" else Vector2(0,edge.w))
		var qa := Vector2((a.x-a.y)*.82,(a.x+a.y)*.41)
		var qb := Vector2((b.x-b.y)*.82,(b.x+b.y)*.41)
		var top: float = edge.elevation
		var bottom: float = top-edge.h
		var length: float = edge.w
		var start := 0.0
		while start<length:
			var end := minf(start+128,length)
			var left := qa.lerp(qb,start/length)
			var right := qa.lerp(qb,end/length)
			_quad(PackedVector2Array([left-Vector2(0,top),right-Vector2(0,top),right-Vector2(0,bottom),left-Vector2(0,bottom)]),"rock",PackedVector2Array([Vector2.ZERO,Vector2((end-start)/128,0),Vector2((end-start)/128,1),Vector2(0,1)]))
			start=end

	for floor in data.walk:
		if floor.properties.ground_frame=="grass":
			_floor(Rect2(floor.x,floor.y,floor.w,floor.h),floor.properties.get("elevation",0),"grass")
	for floor in data.terrain.paths:
		if is_instance_valid(path_tiles):
			continue
		_floor(Rect2(floor.x,floor.y,floor.w,floor.h),floor.elevation,"dirt")
	for r in data.terrain.ramps:
		var top_left:=project(Vector2(r.x,r.y))
		var low_left:=project(Vector2(r.x,r.y+r.h-.1))
		var base_left:=Vector2((r.x-r.y)*.82,(r.x+r.y)*.41)
		var top_right:=project(Vector2(r.x+r.w-.1,r.y))
		var low_right:=project(Vector2(r.x+r.w-.1,r.y+r.h-.1))
		var base_right:=Vector2((r.x+r.w-r.y)*.82,(r.x+r.w+r.y)*.41)
		draw_colored_polygon(PackedVector2Array([top_left,low_left,base_left]),Color("9b8152"))
		draw_colored_polygon(PackedVector2Array([top_right,low_right,base_right]),Color("857248"))
		var points := PackedVector2Array([project(Vector2(r.x,r.y)),project(Vector2(r.x+r.w-.1,r.y)),project(Vector2(r.x+r.w-.1,r.y+r.h-.1)),project(Vector2(r.x,r.y+r.h-.1))])
		_quad(points,"dirt",PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]))
	for r in data.terrain.bridges:
		var deck:=PackedVector2Array([project(Vector2(r.x,r.y)),project(Vector2(r.x+r.w,r.y)),project(Vector2(r.x+r.w,r.y+r.h)),project(Vector2(r.x,r.y+r.h))])
		var shadow:=PackedVector2Array()
		for q in deck: shadow.append(q+Vector2(4,9))
		draw_colored_polygon(shadow,Color(0.07,.17,.16,.4))
		for x in [r.x-8,r.x+r.w-8]:
			var foot:=PackedVector2Array([project(Vector2(x,r.y-4)),project(Vector2(x+16,r.y-4)),project(Vector2(x+16,r.y+r.h+4)),project(Vector2(x,r.y+r.h+4))])
			draw_colored_polygon(foot,Color("9e986e"))
		draw_colored_polygon(PackedVector2Array([deck[3],deck[2],deck[2]+Vector2(0,7),deck[3]+Vector2(0,7)]),Color("6e5239"))
		for x in range(int(r.x),int(r.x+r.w),16):
			var a := project(Vector2(x,r.y))
			var b := project(Vector2(x+16,r.y))
			var c := project(Vector2(x+16,r.y+r.h))
			var d := project(Vector2(x,r.y+r.h))
			draw_colored_polygon(PackedVector2Array([a,b,c,d]),Color("ba915d"))
			draw_line(a,d,Color("705236"),2)

		for y in [r.y+3,r.y+r.h-3]:
			var a:=project(Vector2(r.x,y))
			var b:=project(Vector2(r.x+r.w,y))
			draw_line(a,b,Color("795737"),5)
			draw_line(a-Vector2(0,1),b-Vector2(0,1),Color("d6b17a"),1.5)
