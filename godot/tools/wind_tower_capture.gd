extends SceneTree
const View=preload("res://scripts/campaign/park_overworld_view.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var view=View.new()
	view.saved_checkpoint=CP.make("kronasta-montanha-c",Vector2(28.5,14.5),CP.SPACE)
	view.saved_player=preload("res://scripts/campaign/state.gd").fresh("slot-1").player
	view.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	root.add_child(view)
	view.paused=true
	view.set_physics_process(false)
	view.exploration_hud.hide()
	view.player_root.hide()
	view.follower_root.hide()
	for npc in view.npc_nodes:npc.root.hide()
	var tower: Node2D=view.actors.get_node("WindTower")
	view.camera.position_smoothing_enabled=false
	var folder:=ProjectSettings.globalize_path("res://../tmp/tower-review")
	DirAccess.make_dir_recursive_absolute(folder)
	var mode:="geometry" if OS.get_environment("KRONASTA_GEOMETRIA")=="1" else "art"
	for shot in [{"name":"area","point":Vector2(28,24),"zoom":.36},{"name":"base","point":tower.GROUND,"zoom":2.0},{"name":"game","point":Vector2(28.5,11),"zoom":1.0}]:
		view.camera.position=view.model.project(shot.point)
		if shot.name=="game":view.camera.position.y-=110
		if shot.name=="base":view.camera.position.y-=60
		view.camera.zoom=Vector2.ONE*shot.zoom
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join(mode+"-"+shot.name+".png"))
	view.queue_free()
	await process_frame
	quit()
