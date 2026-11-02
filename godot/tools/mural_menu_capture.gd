extends SceneTree
const Album=preload("res://scripts/ui_mural/partner_album.gd")
const Case=preload("res://scripts/campaign/hud_emblem_case.gd")
const Fixtures=preload("res://tools/mural_menu_fixtures.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var padding_checks:=0
var padding_failures:Array=[]
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	preload("res://scripts/campaign/controls.gd").install();root.content_scale_size=Vector2i.ZERO
	Paper.auditing=true
	var directory:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-135/capturas");DirAccess.make_dir_recursive_absolute(directory)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var requested:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--resolution="):requested=argument.trim_prefix("--resolution=")
	if requested not in ["1280x720","1920x1080","1024x768","1280x800"]:push_error("Capture one resolution per process: -- --resolution=1280x720");quit(1);return
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		if requested!="%dx%d"%[dimensions.x,dimensions.y]:continue
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["varal","dex","evolution","emblems","lobby"]:
				var view:Control=Case.new() if mode=="emblems" else preload("res://scripts/campaign/hud_pause.gd").new() if mode=="lobby" else Album.new();view.player=Fixtures.player();view.text_scale=scale
				if mode not in ["emblems","lobby"]:view.mode=mode;view.content=content;view.can_care=true
				root.add_child(view)
				for frame in 12:await process_frame
				if mode=="dex":view.entry_buttons[5].grab_focus()
				if mode=="evolution":view.entry_buttons[0].grab_focus()
				for frame in 12:await process_frame
				await RenderingServer.frame_post_draw
				for records in Paper.audit.values():
					for record in records:
						padding_checks+=1
						if not record.safe.grow(.1).encloses(record.glyphs):padding_failures.append(str(dimensions)+mode+str(scale)+record.text)
				Paper.audit.clear()
				var error:=root.get_texture().get_image().save_png(directory.path_join("%dx%d-%s%s.png"%[dimensions.x,dimensions.y,mode,"-150" if scale>1 else ""]))
				print("CAPTURE ",dimensions," ",mode," ",scale," ",error);view.free()
	var file:=FileAccess.open(directory.get_base_dir().path_join("padding-%dx%d.json"%[root.size.x,root.size.y]),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":padding_checks,"failures":padding_failures},"\t"));file.close()
	print("PADDING ",padding_checks," ",padding_failures.size());quit(0 if padding_failures.is_empty() else 1)
