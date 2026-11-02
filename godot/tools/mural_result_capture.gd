extends SceneTree
const Fixtures=preload("res://tools/mural_result_fixtures.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var checks:=0
var failures:Array=[]
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	var requested:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--resolution="):requested=argument.trim_prefix("--resolution=")
	if requested not in ["1280x720","1920x1080","1024x768","1280x800"]:push_error("Pass -- --resolution=1280x720");quit(1);return
	var parts:=requested.split("x");root.size=Vector2i(int(parts[0]),int(parts[1]));root.content_scale_size=Vector2i.ZERO;Paper.auditing=true
	preload("res://scripts/campaign/controls.gd").install()
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-136/capturas");DirAccess.make_dir_recursive_absolute(output)
	for scale in [1.0,1.5]:
		for mode in ["won","lost","fled","morro","boss","blocked","item","emblem","level"]:
			var view:Control
			var background:TextureRect
			if mode in ["item","emblem","level"]:
				background=TextureRect.new();background.texture=load("res://assets/campaign/veredas-arena-wide-v2.png");background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;root.add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				view=preload("res://scripts/campaign/hud_key_item_banner.gd").new();view.moment=mode;view.text_scale=scale;view.item_name="Insígnia do Morro do Sol" if mode=="emblem" else "Carteira de Pipeiro";view.item_texture=load("res://assets/ui/key-items/insignia-morro-do-sol.png" if mode=="emblem" else "res://assets/ui/key-items/carteira-pipeiro.png");root.add_child(view);view.set_process(false);view.elapsed=.8;view.queue_redraw()
				if mode=="level":
					view.item_name="Rabbito · Nv. 1 → 3";view.item_texture=preload("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+Fixtures.content.combat.rabbito.image),"rabbito")
			else:
				view=Fixtures.create(mode,scale);root.add_child(view);view.set_physics_process(false);view.blocked=mode=="blocked";view._physics_process(0)
			for frame in 12:await process_frame
			if mode not in ["item","emblem","level"]:view._layout_actions()
			for frame in 8:await process_frame
			await RenderingServer.frame_post_draw
			for entries in Paper.audit.values():
				for entry in entries:
					checks+=1
					if not entry.safe.grow(.1).encloses(entry.glyphs):failures.append(mode+str(scale)+entry.text)
			Paper.audit.clear()
			var error:=root.get_texture().get_image().save_png(output.path_join(requested+"-"+mode+("-150" if scale>1 else "")+".png"));print("CAPTURE ",requested," ",mode," ",scale," ",error);view.free()
			if background!=null:background.free()
	var file:=FileAccess.open(output.get_base_dir().path_join("padding-"+requested+".json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));file.close()
	print("RESULT PADDING ",checks," ",failures.size());quit(0 if failures.is_empty() else 1)
