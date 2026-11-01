extends SceneTree
var output: String
var records: Array=[]
func _initialize() -> void: call_deferred("run")
func capture(view, name: String, focal: Vector2, zoom: float, objects: bool = true, geometry: bool = false) -> void:
	view.camera.position_smoothing_enabled=false
	view.camera.limit_left=-10000;view.camera.limit_right=10000
	view.camera.limit_top=-10000;view.camera.limit_bottom=10000
	view.camera.zoom=Vector2.ONE*zoom
	view.camera.position=view.model.project(focal)-Vector2(0,35)
	view.camera.reset_smoothing()
	view.hide_characters()
	for node in view.piece_nodes.values(): node.visible=objects
	if view.parque_surfaces!=null: view.parque_surfaces.water_material.set_shader_parameter("preview_time",0.0)
	for polygon in view.find_children("*","Polygon2D",true,false):
		if polygon.material is ShaderMaterial and (polygon.has_meta("clareira_bank") or (view.clareira_terrain!=null and polygon.material.shader==view.clareira_terrain.material.shader)):
			polygon.material.set_shader_parameter("geometry_only",geometry)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
	records.append(name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/overworld/clareira-materials-applied")
	DirAccess.make_dir_recursive_absolute(output)
	var view=load("res://scripts/overworld/view.gd").new()
	view.area_id="clareira-do-papel";view.art_preview=true;view.use_clareira_materials=false
	root.add_child(view);view.set_physics_process(false);view.interface.hide()
	var original: String=JSON.stringify(view.model.data)
	await capture(view,"01-antes-geral",Vector2(32,24),0.52)
	view.use_clareira_materials=true
	var start:=Time.get_ticks_msec()
	view.load_area("clareira-do-papel")
	var load_ms:=Time.get_ticks_msec()-start
	await capture(view,"02-aplicado-geral",Vector2(32,24),0.52)
	await capture(view,"03-praca",Vector2(29.5,38.5),1.55)
	await capture(view,"04-rampa-sul",Vector2(24.5,37.5),2.0,false)
	await capture(view,"05-rampa-norte",Vector2(25.5,14.5),2.0,false)
	await capture(view,"06-rampa-oeste",Vector2(16.5,25.5),2.0,false)
	await capture(view,"07-rampa-leste",Vector2(48.5,29.5),2.0,false)
	await capture(view,"08-pontes-sul",Vector2(29.5,34.5),1.7,false)
	await capture(view,"09-pontes-norte",Vector2(29.5,24.5),1.7,false)
	await capture(view,"10-cores-chapadas",Vector2(24.5,37.5),2.0,false,true)
	var unchanged: bool=original==JSON.stringify(view.model.data)
	view.free()
	var campaign=load("res://scripts/campaign/park_overworld_view.gd").new()
	campaign.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	campaign.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	campaign.saved_checkpoint={"scene":"park-clearing","space":"parque-overworld-v1","x":29.5,"y":41.5}
	root.add_child(campaign);campaign.set_physics_process(false)
	await capture(campaign,"11-campanha",Vector2(29.5,38.5),1.3)
	var campaign_applied: bool=campaign.clareira_terrain!=null
	var report:={"captures":records,"mapDataUnchanged":unchanged,"campaignMaterialActive":campaign_applied,"areaReloadMs":load_ms,"coverage":[64,48],"maskBakedOffline":true}
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("CLAREIRA APPLIED: ",JSON.stringify(report))
	quit(0 if unchanged and campaign_applied else 1)
