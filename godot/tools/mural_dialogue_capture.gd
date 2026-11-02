extends SceneTree
const Dialogue=preload("res://scripts/campaign/hud_dialogue.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	preload("res://scripts/campaign/controls.gd").install()
	root.content_scale_size=Vector2i.ZERO
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-134/capturas")
	DirAccess.make_dir_recursive_absolute(output)
	var background:=TextureRect.new();background.texture=load("res://assets/campaign/title-v1/neighborhood-starters-soulgen-v4.png")
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		if "--opening-only" in OS.get_cmdline_user_args():break
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["fala","escolhas","dupla"]:
				var view:=Dialogue.new();view.text_scale=scale;view.reduced_motion=true
				view.title="Sr. Assis";view.dialog_text="Sr. Assis: O Elo se fortalece com cuidado. Observe a linha do seu parceiro e respeite o ritmo dele. Cada novo bairro traz histórias e desafios diferentes."
				if mode=="escolhas":view.dialog_text="Sr. Assis: Por onde você prefere começar?";view.options=[{"id":"a","text":"Quero conhecer o bosque e conversar com seus moradores."},{"id":"b","text":"Prefiro preparar meu parceiro antes de seguir.","safe":true},{"id":"c","text":"Pode me explicar como cuidar da Linha e da Armação?"},{"id":"d","text":"Vou explorar o bairro primeiro."}]
				if mode=="dupla":view.dialog_text="Kael: Quero descobrir o que há depois dessas trilhas.\n\nNina: [emo=suor] Tenha cuidado perto dos canos! Primeiro vamos preparar nossas pipas."
				root.add_child(view)
				if mode=="dupla":view.page_index=view.pages.size()-1;view._show_page()
				for frame in 8:await process_frame
				await RenderingServer.frame_post_draw
				var result:=root.get_texture().get_image().save_png(output.path_join("%dx%d-%s%s.png"%[dimensions.x,dimensions.y,mode,"-150" if scale>1 else ""]))
				print("CAPTURE ",dimensions," ",mode," ",scale," ",result)
				view.free()
	background.free()
	if "--opening-only" not in OS.get_cmdline_user_args():quit();return
	var requested:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--resolution="):requested=argument.trim_prefix("--resolution=")
	if requested not in ["1280x720","1920x1080","1024x768","1280x800"]:
		push_error("Use --opening-only --resolution=1280x720 (one opening resolution per process)")
		quit(1);return
	var front:=preload("res://scripts/campaign/front_end.gd").new()
	front.session._store=preload("res://scripts/campaign/save_store.gd").new("user://mural-dialogue-capture-"+preload("res://scripts/campaign/state.gd").new_id())
	front.preferences.storage_path="user://mural-dialogue-capture-"+preload("res://scripts/campaign/state.gd").new_id()+".cfg"
	root.add_child(front)
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		if requested!="%dx%d"%[dimensions.x,dimensions.y]:continue
		root.size=dimensions
		for scale in [1.0,1.5]:
			front.preferences.text_scale=scale;front.preferences.reduced_motion=true;front._apply_preferences()
			for step in [5,10]:
				preload("res://tools/player_audit_fixtures.gd").show(front,"opening-%d"%step)
				for frame in 1200:
					if not front.opening_busy:break
					await process_frame
				for frame in 12:await process_frame
				await RenderingServer.frame_post_draw
				var result:=root.get_texture().get_image().save_png(output.path_join("%dx%d-abertura-%d%s.png"%[dimensions.x,dimensions.y,step,"-150" if scale>1 else ""]))
				print("OPENING ",dimensions," ",step," ",scale," ",result)
	front.free();quit()
