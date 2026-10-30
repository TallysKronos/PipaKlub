extends "res://scripts/overworld/view.gd"
## Opt-in review view only. The campaign still uses the unchanged renderer.
const Pilot=preload("res://tools/terrain_contour_pilot.gd")
var pilot_enabled:=false
var pilot: RefCounted

func _init() -> void: use_clareira_materials=false

func load_area(id: String, entrance: String = "") -> void:
	super(id,entrance)
	if not pilot_enabled or area_id!="clareira-do-papel": return
	_restyle_banks()

func _bank_surface(wall: Polygon2D, a: float, b: float, da: float, db: float, shade: float, wet: bool = false) -> void:
	wall.texture=load("res://assets/overworld/terrain-pilot-v5/barranco-manga-v2.png")
	wall.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wall.color=Color.WHITE
	# Polygon2D takes UVs in texture pixels; the shader receives normalized UVs.
	var texels: Vector2=wall.texture.get_size()
	wall.uv=PackedVector2Array([Vector2(a/384.0,0)*texels,Vector2(b/384.0,0)*texels,Vector2(b/384.0,db)*texels,Vector2(a/384.0,da)*texels])
	var finish:=ShaderMaterial.new()
	finish.shader=load("res://tools/terrain_bank_pilot.gdshader")
	finish.set_shader_parameter("face_shade",shade)
	finish.set_shader_parameter("wet",wet)
	wall.material=finish
	wall.set_meta("terrain_bank_pilot",true)

func _restyle_banks() -> void:
	for node in actors.get_children():
		# Keep the measured shore's existing lip, recessed water and draw order.
		if node.z_index in [-3,-2]:
			var logical:=Vector2((node.position.x/32.0+node.position.y/16.0)*0.5,(node.position.y/16.0-node.position.x/32.0)*0.5)
			if not Pilot.AREA.has_point(Vector2i(logical.floor())): continue
			for child in node.get_children():
				if not child is Polygon2D or child.texture==null or child.polygon.size()!=4: continue
				var p: PackedVector2Array=child.polygon
				if absf(p[2].x-p[1].x)>0.01 or absf(p[3].x-p[0].x)>0.01 or p[2].y<=p[1].y: continue
				# World y encodes u+v at the bank's zero-height upper edge.
				var a: float=(p[0].y+node.position.y)*2.0
				var b: float=(p[1].y+node.position.y)*2.0
				_bank_surface(child,a,b,1.0,1.0,0.94 if p[1].x>p[0].x else 0.82,true)
			continue
		for face: Dictionary in model.data.cliffs:
			if not Pilot.AREA.has_point(Vector2i(face.u,face.v)): continue
			var a:=Vector2(face.u+1,face.v) if face.side=="u" else Vector2(face.u,face.v+1)
			var b:=Vector2(face.u+1,face.v+1)
			if face.side=="u-": a=Vector2(face.u,face.v+1); b=Vector2(face.u,face.v)
			if face.side=="v-": a=Vector2(face.u+1,face.v); b=Vector2(face.u,face.v)
			if node.position.distance_squared_to(model.project(b,false))>0.01: continue
			for child in node.get_children():
				if not child is Polygon2D or child.polygon.size()!=4: continue
				var p: PackedVector2Array=child.polygon
				if absf(p[0].x-(model.project(a,false).x-node.position.x))>0.01: continue
				var da: float=absf(p[3].y-p[0].y)/64.0
				var db: float=absf(p[2].y-p[1].y)/64.0
				_bank_surface(child,(a.x+a.y)*32.0,(b.x+b.y)*32.0,da,db,1.0 if str(face.side).begins_with("u") else 0.85)

func _draw_manga_floor(at: Vector2i, cell: Dictionary) -> void:
	if pilot_enabled and area_id=="clareira-do-papel":
		if pilot==null:
			pilot=Pilot.new()
			pilot.setup(model,kits[1])
		if pilot.supports(at,cell):
			super(at,cell)
			pilot.tile(at,self)
			return
	super(at,cell)

func _draw_ramp(at: Vector2i, cell: Dictionary) -> void:
	super(at,cell)
	if pilot_enabled and pilot!=null and pilot.supports(at,cell): pilot.tile(at,self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F6:
		var point:=player
		var follow:=follower
		var zoom:=camera.zoom
		pilot_enabled=not pilot_enabled
		pilot=null
		load_area(area_id)
		player=point; follower=follow
		_refresh_positions()
		camera.zoom=zoom
		camera.reset_smoothing()
		message(("Depois" if pilot_enabled else "Antes")+" â€¢ F6 alterna â€¢ teste sem salvar campanha")
		get_viewport().set_input_as_handled()
		return
	super(event)
