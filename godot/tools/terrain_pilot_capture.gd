extends SceneTree
## Fixed A/B captures of a small visual patch; no campaign or save access.
var view: Node2D
var output: String
var records: Array=[]
var focal:=Vector2(29.5,38.5)

func _initialize() -> void: call_deferred("run")

func capture(name: String, objects: bool, geometry: bool = false, zoom: float = 1.55) -> void:
	view.camera.zoom=Vector2.ONE*zoom
	view.camera.position=view.model.project(focal)-Vector2(0,35)
	view.camera.reset_smoothing()
	if view.parque_surfaces!=null: view.parque_surfaces.water_material.set_shader_parameter("preview_time",0.0)
	for piece in view.piece_nodes.values(): piece.visible=objects
	view.hide_characters()
	if view.pilot!=null: view.pilot.material.set_shader_parameter("geometry_only",geometry)
	if view.pilot!=null:
		for polygon in view.find_children("*","Polygon2D",true,false):
			if polygon.material is ShaderMaterial and polygon.material.shader==view.pilot.material.shader:
				polygon.material.set_shader_parameter("geometry_only",geometry)
			elif polygon.has_meta("terrain_bank_pilot"):
				polygon.material.set_shader_parameter("geometry_only",geometry)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
	records.append({"file":name+".png","objects":objects,"geometryOnly":geometry,"zoom":zoom,"focal":[focal.x,focal.y],"pilot":view.pilot_enabled})

func run() -> void:
	if DisplayServer.get_name()=="headless": printerr("Capture requires native renderer"); quit(1); return
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/overworld/terrain-pilot-v5")
	DirAccess.make_dir_recursive_absolute(output)
	view=load("res://tools/terrain_pilot_view.gd").new()
	view.area_id="clareira-do-papel"
	view.art_preview=true
	root.add_child(view)
	view.set_physics_process(false)
	view.interface.hide()
	view.camera.position_smoothing_enabled=false
	var original_data: String=JSON.stringify(view.model.data)
	await capture("01-antes",true)
	await capture("02-antes-sem-objetos",false)
	focal=Vector2(24.5,37.5)
	await capture("07-rampa-antes",false,false,2.0)
	focal=Vector2(29.5,34.5)
	await capture("09-pontes-sul-antes",false,false,1.7)
	focal=Vector2(29.5,24.5)
	await capture("11-pontes-norte-antes",false,false,1.7)
	view.pilot_enabled=true
	view.load_area("clareira-do-papel")
	view.camera.position_smoothing_enabled=false
	focal=Vector2(29.5,38.5)
	await capture("03-depois",true)
	await capture("04-depois-sem-objetos",false)
	await capture("05-cores-chapadas",false,true)
	await capture("06-juntas-ampliadas",false,false,2.5)
	focal=Vector2(24.5,37.5)
	await capture("08-rampa-depois",false,false,2.0)
	await capture("13-rampa-cores-chapadas",false,true,2.0)
	focal=Vector2(29.5,34.5)
	await capture("10-pontes-sul-depois",false,false,1.7)
	focal=Vector2(29.5,24.5)
	await capture("12-pontes-norte-depois",false,false,1.7)
	var key:=InputEventKey.new()
	key.keycode=KEY_F6; key.pressed=true
	var point:=Vector2(29.5,41.5)
	view.player=point; view.follower=point
	view._unhandled_input(key)
	var toggle_preserved: bool=not view.pilot_enabled and view.player==point
	view._unhandled_input(key)
	toggle_preserved=toggle_preserved and view.pilot_enabled and view.player==point
	var unchanged:=JSON.stringify(view.model.data)==original_data
	var bounds: Rect2i=view.pilot.AREA
	var report:={"captures":records,"mapDataUnchanged":unchanged,"togglePreservesPosition":toggle_preserved,"pilotCells":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"scope":"opt-in visual prototype; campaign unchanged; no saves"}
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("TERRAIN PILOT: ",records.size()," captures; map unchanged=",unchanged,"; toggle preserves position=",toggle_preserved)
	if "--live" in OS.get_cmdline_user_args():
		view.load_area("clareira-do-papel")
		view.interface.show()
		view.player=Vector2(29.5,41.5)
		view.follower=view.player
		view._refresh_positions()
		view.camera.zoom=Vector2.ONE*1.4
		view.set_physics_process(true)
		view.message("Teste visual Ã¢â‚¬Â¢ F6 alterna antes/depois Ã¢â‚¬Â¢ sem salvar campanha")
		return
	quit(0 if unchanged else 1)
