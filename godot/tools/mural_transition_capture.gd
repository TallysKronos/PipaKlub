extends SceneTree
const Surface=preload("res://scripts/ui_mural/travel_surface.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
func _initialize()->void:call_deferred("capture")
func capture()->void:
	var requested:="1280x720"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--resolution="):requested=arg.trim_prefix("--resolution=")
	var dimensions:=requested.split("x");root.size=Vector2i(int(dimensions[0]),int(dimensions[1]));root.content_scale_size=Vector2i.ZERO
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-137/capturas");DirAccess.make_dir_recursive_absolute(output)
	var background:=ColorRect.new();background.color=Color("77d0bc");root.add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface:=Surface.new();root.add_child(surface);Paper.auditing=true
	var failures:Array=[];var checks:=0
	for scale in [1.0,1.5]:
		for state in ["loading","reveal","reduced"]:
			surface.text_scale=scale;surface.slide=.42 if state=="reveal" else 0.0;surface.opacity=.65 if state=="reduced" else 1.0;surface.reduced_motion=state=="reduced";surface.age=.5;surface.queue_redraw()
			for frame in 4:await process_frame
			await RenderingServer.frame_post_draw
			for entries in Paper.audit.values():
				for entry in entries:
					checks+=1
					if not entry.safe.grow(.1).encloses(entry.glyphs):failures.append(entry.text)
			Paper.audit.clear()
			root.get_texture().get_image().save_png(output.path_join(requested+"-"+state+("-150" if scale>1 else "")+".png"))
	var file:=FileAccess.open(output.get_base_dir().path_join("padding-"+requested+".json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures}));file.close()
	print("PIP137 CAPTURE ",requested," ",checks," checks ",failures);quit(0 if failures.is_empty() else 1)
