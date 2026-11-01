extends SceneTree
const Lab = preload("res://scripts/ui_mural/mural_lab.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.content_scale_size=Vector2i.ZERO
	var folder:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-130/capturas")
	DirAccess.make_dir_recursive_absolute(folder)
	var records:=[]
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=resolution
		var lab:=Lab.new();root.add_child(lab)
		for i in 5:await process_frame
		lab.scroll.follow_focus=false
		for proof in ["principal","pressionado","estados","texto-150","texto-150-dados"]:
			if proof=="principal":lab.menu_buttons[0].grab_focus();lab.scroll.scroll_vertical=0
			if proof=="pressionado":
				var click:=InputEventMouseButton.new()
				click.button_index=MOUSE_BUTTON_LEFT
				click.position=lab.menu_buttons[0].get_global_rect().get_center()
				click.global_position=click.position;click.pressed=true
				Input.parse_input_event(click)
			if proof=="estados":
				lab.state_buttons[0].grab_focus()
				lab.scroll.scroll_vertical=roundi(lab.state_buttons[0].get_global_position().y+lab.scroll.scroll_vertical-lab.scroll.get_global_position().y-90)
			if proof=="texto-150":lab.set_text_scale(1.5);lab.menu_buttons[0].grab_focus();lab.scroll.scroll_vertical=0
			if proof=="texto-150-dados":lab.scroll.ensure_control_visible(lab.info_panel)
			for i in 5:await process_frame
			if proof in ["principal","texto-150"]:lab.scroll.scroll_vertical=0
			await RenderingServer.frame_post_draw
			var image:=root.get_texture().get_image()
			var file:="%dx%d-%s.png"%[resolution.x,resolution.y,proof]
			var error:=image.save_png(folder.path_join(file))
			records.append({"requested":[resolution.x,resolution.y],"obtained":[image.get_width(),image.get_height()],"proof":proof,"file":file,"saveError":error,"textScale":lab.text_scale})
			if proof=="pressionado":
				var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT
				click.position=lab.menu_buttons[0].get_global_rect().get_center();click.global_position=click.position
				click.pressed=false;Input.parse_input_event(click)
		lab.free()
	var output:=FileAccess.open(folder.path_join("capturas.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(records,"\t"));output.close()
	print("MURAL CAPTURES: ",records.size())
	quit()
