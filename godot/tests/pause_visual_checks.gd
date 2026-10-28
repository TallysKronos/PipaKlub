extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(message)
func settle() -> void:
	for i in 12:await process_frame
func tap(code:int) -> void:
	var event:=InputEventKey.new()
	event.pressed=true
	event.keycode=code
	event.physical_keycode=code
	root.push_input(event,true)
	event=event.duplicate()
	event.pressed=false
	root.push_input(event,true)
	await settle()
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://pause-visual-"+State.new_id())
	front.preferences.storage_path="user://pause-visual-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	var result:Dictionary=front.session.start("slot-1")
	var player:Dictionary=result.data.player
	player.name="Kael das Correntes Douradas"
	player.partners=[{"id":"partner-1","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":72,"structure":89}}]
	player.equippedPartnerId="partner-1"
	player.partners.append({"id":"partner-2","modelId":"azulao","personalName":"Azulão","xp":65,"craftBonus":0,"condition":{"line":100,"structure":100}})
	player.inventory["rabiola-basica"]=2
	player.inventory["rabiola-azulao"]=1
	check(front.session.checkpoint({"kind":"world","scene":"park-clearing","position":[336,784]},player).status=="ok","isolated save prepared")
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip75")
	DirAccess.make_dir_recursive_absolute(output)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		front._show_saved()
		await settle()
		front._pause_game()
		await settle()
		check(is_instance_valid(front.pause_overlay),"pause displayed")
		check(root.gui_get_focus_owner().text=="Retomar","resume has default focus")
		check(front.park.paused,"world suspended")
		for button in front.pause_overlay.find_children("*","Button",true,false):
			check(Rect2(Vector2.ZERO,front.size).encloses(button.get_global_rect()),"pause command visible")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("pausa-%dx%d.png"%[viewport.x,viewport.y]))
		front._resume_game()
		await settle()
		check(not is_instance_valid(front.pause_overlay),"pause removed")
		check(not front.park.paused,"world resumed")
		front._show_collection()
		await settle()
		check(front.last_scene_key=="page:EQUIPE","team route displayed")
		for button in front.page.find_children("*","Button",true,false):
			if button.text=="Escolher parceiro":button.pressed.emit();break
		await settle()
		check(front.session.snapshot().player.equippedPartnerId=="partner-2","selecting partner persists")
		check(front.exploration.equip("partner-1").status=="ok","restore fixture partner")
		front._show_collection()
		await settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("equipe-%dx%d.png"%[viewport.x,viewport.y]))
		front._show_bag()
		await settle()
		check(front.last_scene_key=="page:MOCHILA","bag route displayed")
		var inventory=front.page.get_children()[2]
		check(inventory.item_name.text=="Rabiola de Carcará","first item details shown")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("mochila-%dx%d.png"%[viewport.x,viewport.y]))
		inventory.populate("Missão")
		await settle()
		check(inventory.item_name.text=="Nada por aqui","empty filter clears stale item")
		check(inventory.item_art.texture==null or inventory.quantity.text.is_empty(),"empty filter clears quantity")
		front._show_controls()
		await settle()
		var binding_count:=0
		for button in front.page.find_children("*","Button",true,false):
			if button.has_meta("binding_action"):
				binding_count+=1
				check(Rect2(Vector2.ZERO,front.size).encloses(button.get_global_rect()),"binding visible")
		check(binding_count==12,"all bindings displayed")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("controles-%dx%d.png"%[viewport.x,viewport.y]))
		front._confirm_restore_controls()
		await settle()
		var confirmation=get_nodes_in_group("manga_dialogue")[0]
		check(root.gui_get_focus_owner()==confirmation.decline,"restore defaults focuses Cancel")
		check(Rect2(Vector2.ZERO,front.size).encloses(confirmation.accept.get_global_rect()),"confirmation action visible")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("confirmacao-%dx%d.png"%[viewport.x,viewport.y]))
		for i in 4:
			await tap(KEY_TAB)
			check(root.gui_get_focus_owner() in [confirmation.accept,confirmation.decline],"modal keeps keyboard focus")
		await tap(KEY_ESCAPE)
		check(get_nodes_in_group("manga_dialogue").is_empty(),"Escape closes confirmation")
		check(front.last_scene_key=="page:CONTROLES · TECLADO","Escape preserves underlying controls page")
		front._capture_binding("cut")
		await settle()
		var key:=InputEventKey.new()
		key.pressed=true
		key.physical_keycode=KEY_Q
		front._input(key)
		check(front.binding_target=="cut" and front.preferences.bindings.cut==KEY_SPACE,"conflicting remap rejected")
		key.physical_keycode=KEY_ESCAPE
		front._input(key)
		await settle()
		check(front.binding_target.is_empty() and front.preferences.bindings.cut==KEY_SPACE,"cancel preserves mapping")
		front._capture_binding("cut")
		await settle()
		key.physical_keycode=KEY_T
		front._input(key)
		await settle()
		check(front.preferences.bindings.cut==KEY_T,"valid remap applied")
		front.preferences.bindings=front.Controls.DEFAULTS.duplicate()
		front.Controls.install(front.preferences.bindings)
		front.preferences.save_settings()
		await tap(KEY_ESCAPE)
		check(front.last_scene_key=="page:Configurações","controls back returns to settings")
	front.queue_free()
	await settle()
	print("PAUSE VISUAL: %d checks; %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
