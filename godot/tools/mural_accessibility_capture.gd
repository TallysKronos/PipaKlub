extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
func _initialize()->void:call_deferred("capture")
func settle()->void:
	for frame in 12:await process_frame
func capture()->void:
	var requested:="1280x720"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--resolution="):requested=arg.trim_prefix("--resolution=")
	var parts:=requested.split("x");root.size=Vector2i(int(parts[0]),int(parts[1]));root.content_scale_size=Vector2i.ZERO
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-138/capturas");DirAccess.make_dir_recursive_absolute(output)
	var path:=ProjectSettings.globalize_path("res://../tmp/pip138-capture-"+requested)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var boss_face:Texture2D=preload("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat.lacertubo.image),"lacertubo")
	var champion_face:Texture2D=preload("res://scripts/campaign/battle_ink.gd").portrait(load("res://assets/campaign/"+content.combat["basic-azulao"].image),"basic-azulao")
	var front:=Front.new();front.session._store=Store.new(path);front.preferences.storage_path=path+".cfg";root.add_child(front)
	preload("res://scripts/ui_mural/paper_layout.gd").auditing=true
	front.preferences.crt=false;front.preferences.reduced_motion=true;front.preferences.audio_levels.master=0
	for scale in [1.0,1.5]:
		front.preferences.text_scale=scale;front._apply_preferences();front.settings_tab="Acessibilidade";front._show_settings();await settle()
		var scroll:ScrollContainer=front.page.get_parent()
		for position in ["top","bottom"]:
			scroll.scroll_vertical=0 if position=="top" else int(scroll.get_v_scroll_bar().max_value);await settle();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(requested+"-settings-"+position+("-150" if scale>1 else "")+".png"))
		front._clear("accessibility-fixture");await settle()
		var dialog=preload("res://scripts/campaign/hud_dialogue.gd").new();dialog.text_scale=scale;dialog.reduced_motion=true;dialog.title="Kael";dialog.dialog_text="Vamos seguir pela trilha? O foco precisa continuar visível mesmo sem distinguir as cores.";dialog.options=[{"id":"go","text":"Seguir pelo caminho principal"},{"id":"stay","text":"Continuar explorando"}];front.add_child(dialog);await settle();dialog.option_buttons[0].grab_focus();await settle();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(requested+"-dialogue-focus"+("-150" if scale>1 else "")+".png"));dialog.free()
		var boss=preload("res://scripts/campaign/boss_presentation.gd").new();boss.text_scale=scale;boss.reduced_motion=true;boss.face=boss_face;front.add_child(boss);await settle();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(requested+"-boss-contrast"+("-150" if scale>1 else "")+".png"));boss.free()
		var versus=preload("res://scripts/ui_mural/champion_vs.gd").new();versus.text_scale=scale;versus.face=champion_face;versus.reduced_motion=true;front.add_child(versus);await settle();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(requested+"-versus"+("-150" if scale>1 else "")+".png"));versus.free()
	var audit=preload("res://scripts/ui_mural/paper_layout.gd").audit
	var failures:Array=[];var checks:=0
	for entries in audit.values():
		for entry in entries:
			checks+=1
			if not entry.safe.grow(.1).encloses(entry.glyphs):failures.append(entry.text)
	var file:=FileAccess.open(output.get_base_dir().path_join("padding-"+requested+".json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures}));file.close()
	print("PIP138 CAPTURE ",requested," ",checks," checks; ",failures);quit(0 if failures.is_empty() else 1)
