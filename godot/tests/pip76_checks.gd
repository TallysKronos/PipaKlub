extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:=0
var output:=""
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 16:await process_frame
func capture(name:String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+"-%dx%d.png"%[root.size.x,root.size.y]))
func tap(code:int) -> void:
	var key:=InputEventKey.new();key.pressed=true;key.keycode=code;key.physical_keycode=code
	root.push_input(key,true);key=key.duplicate();key.pressed=false;root.push_input(key,true)
	await settle()
func run() -> void:
	output=ProjectSettings.globalize_path("res://../mockups/revisao/pip76")
	DirAccess.make_dir_recursive_absolute(output)
	var front:=Front.new()
	front.session._store=Store.new("user://pip76-"+State.new_id())
	front.preferences.storage_path="user://pip76-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	var result:Dictionary=front.session.start("slot-1")
	var player:Dictionary=result.data.player
	player.partners=[{"id":"p1","modelId":"rabbito","personalName":"Um parceiro de nome bastante comprido","xp":0,"craftBonus":0,"condition":{"line":72,"structure":89}}]
	player.equippedPartnerId="p1"
	for id in ["basica","azulao","mata","raio","lacertubo"]:player.inventory["rabiola-"+id]=2
	check(front.session.checkpoint({"kind":"world","scene":"park-clearing","position":[336,784]},player).status=="ok","fixture saved")
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		front._show_saved();await settle();front._pause_game();await settle()
		check(front.park.paused,"pause freezes world")
		front.pause_overlay.buttons.map.pressed.emit();await settle()
		check(front.last_scene_key=="page:MAPA DA ÁREA","map opens from pause")
		var map=front.page.get_children()[2]
		check(not map.polygons.is_empty(),"map has actual walkable paths")
		await capture("mapa")
		await tap(KEY_ESCAPE)
		check(is_instance_valid(front.pause_overlay),"back returns to pause")
		check(root.gui_get_focus_owner()==front.pause_overlay.buttons.map,"map origin focus restored")
		var before_revision:int=front.session.snapshot().revision
		front.pause_overlay.buttons.save.pressed.emit();await settle()
		check(front.session.snapshot().revision>before_revision,"standalone save persists world")
		check(front.park.paused,"save leaves game paused")
		await capture("pausa")
		front.pause_overlay.buttons.bag.pressed.emit();await settle()
		var bag=front.page.get_children()[2]
		for item in bag.list.get_children():
			if item is Button:check(bag.scroll.get_global_rect().encloses(item.get_global_rect()),"whole inventory item visible")
		await capture("mochila")
		var event:=InputEventJoypadButton.new();event.pressed=true;event.button_index=JOY_BUTTON_RIGHT_SHOULDER
		root.push_input(event,true);event=event.duplicate();event.pressed=false;root.push_input(event,true);await settle()
		check(bag.current_filter=="Rabiolas","RB changes category")
		bag.set_load_state("loading");await settle();await capture("carregando")
		bag.set_load_state("error");await settle();await capture("erro")
		check(bag.list.get_child(1).text=="Tentar de novo","error offers retry")
		bag.set_load_state("ready");bag.populate("Missão");await settle();await capture("vazio")
		check(bag.item_name.text=="Nada por aqui","empty category clears detail")
		front._return_to_game();await settle()
		check(root.gui_get_focus_owner()==front.pause_overlay.buttons.bag,"bag origin focus restored")
		front.pause_overlay.buttons.settings.pressed.emit();await settle()
		front.settings_tab="Acessibilidade";front._show_settings();await settle()
		front.preferences.text_scale=1.3;front._apply_preferences();await settle()
		front._show_settings();await settle()
		check(front.preferences.save_settings()==OK,"text size persisted")
		var reloaded:=front.Preferences.new();reloaded.load_settings(front.preferences.storage_path)
		check(reloaded.text_scale==1.3,"text size reloads")
		await capture("texto130")
		front._show_controls();await settle();front._capture_binding("cut");await settle()
		var key:=InputEventKey.new();key.pressed=true;key.physical_keycode=KEY_Q
		front._input(key);await settle()
		check(front.binding_rows.cut.feedback.visible,"conflict shown inline")
		check(get_nodes_in_group("manga_dialogue").is_empty(),"remap has no modal")
		await capture("conflito")
		await tap(KEY_ESCAPE)
		check(front.binding_target.is_empty(),"Escape cancels inline capture")
		front.preferences.text_scale=1.0;front._apply_preferences()
		front.team_load_state="error";front._show_collection();await settle()
		check(front.page.get_child(2).state=="error","team error has retry state")
		front.team_load_state="ready"
		front.menu_origin="";front._show_saved();await settle()
	front.queue_free();await settle()
	print("PIP76: %d checks; %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
