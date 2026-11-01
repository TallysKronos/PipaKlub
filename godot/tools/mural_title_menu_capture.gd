extends SceneTree
const Title=preload("res://scripts/campaign/hud_title_menu.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.content_scale_size=Vector2i.ZERO
	var output:="res://../documentation/hud-v2/pip-131/capturas/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	if "--consumer" in OS.get_cmdline_user_args():
		root.size=Vector2i(1280,720)
		var app:=preload("res://scripts/campaign/front_end.gd").new()
		app.session._store=preload("res://scripts/campaign/save_store.gd").new(ProjectSettings.globalize_path("res://../tmp/pip131-capture-empty"))
		root.add_child(app)
		for mode in ["title","main"]:
			if mode=="main":app._menu()
			for frame in 10:await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output+"consumer-"+mode+".png"))
		app.free();quit();return
	var before:="--before" in OS.get_cmdline_user_args()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for mode in (["title","main"] if before else ["title","main","main-150","main-empty"]):
			var view:=Title.new();view.mode=mode;view.has_saves=true;view.reduced_motion=true
			if mode=="main-150":view.mode="main";view.text_scale=1.5
			if mode=="main-empty":view.mode="main";view.has_saves=false
			root.add_child(view)
			for frame in 5:await process_frame
			await RenderingServer.frame_post_draw
			var path:=output+("antes-" if before else "")+"%dx%d-%s.png"%[dimensions.x,dimensions.y,mode]
			var result:=root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print(path," ",result)
			view.free()
		if before:break
	quit()
