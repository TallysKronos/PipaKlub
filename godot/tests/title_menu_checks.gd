extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Session=preload("res://scripts/campaign/session.gd")
const Decor=preload("res://tools/decor_overlap.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for frame in 8:await process_frame
func tap_key(code:int) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code;event.keycode=code;event.pressed=true
	root.push_input(event,true)
	event=event.duplicate();event.pressed=false;root.push_input(event,true)
	await settle()
func tap_pad(code:int) -> void:
	var event:=InputEventJoypadButton.new()
	event.button_index=code;event.pressed=true
	root.push_input(event,true)
	event=event.duplicate();event.pressed=false;root.push_input(event,true)
	await settle()
func buttons(node:Node) -> Array[Button]:
	var found:Array[Button]=[]
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():found.append(child)
		found.append_array(buttons(child))
	return found
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://title-menu-"+State.new_id())
	front.preferences.storage_path="user://title-menu-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip75")
	if capture:DirAccess.make_dir_recursive_absolute(output)
	for count in [0,1,3]:
		front.session._store=Store.new("user://title-%d-"%count+State.new_id())
		for index in range(1,count+1):
			var result:Dictionary=front.session.start("slot-%d"%index)
			var player:Dictionary=result.data.player
			player.name="Kael das Correntes Douradas" if index==1 else "Kael %d"%index
			player.partners=[{"id":"partner-%d"%index,"modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
			player.equippedPartnerId=player.partners[0].id
			front.session._process(125.0)
			check(front.session.checkpoint({"kind":"world","scene":"park-clearing","position":[336,784]},player).status=="ok","create real saved journey metadata")
			check(front.session.snapshot().playSeconds>=125,"play time persisted")
		front.session.close_session()
		for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
			root.size=viewport
			front._title();await settle()
			var title_buttons:=buttons(front)
			check(title_buttons.size()==1 and title_buttons[0].text=="PRESSIONE START","title has one native start action")
			var title_view:Control=title_buttons[0].get_parent().get_parent().get_parent()
			title_view.reduced_motion=true;title_view._process(.5)
			check(is_equal_approx(title_buttons[0].modulate.a,1),"start stays still with reduced motion")
			title_view.reduced_motion=false;title_view.age=0;title_view._process(.5)
			check(title_buttons[0].modulate.a<.4,"start pulses at one hertz")
			title_view.reduced_motion=true
			if capture and count==0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("titulo-%dx%d.png"%[viewport.x,viewport.y]))
			title_buttons[0].pressed.emit();await settle()
			var commands:=buttons(front)
			check(commands.size()==4,"main has four commands")
			check(commands[0].disabled==(count==0),"continue reflects actual save availability")
			check(root.gui_get_focus_owner()==commands[1 if count==0 else 0],"first usable main action focused")
			check(Decor.inspect(front).findings.is_empty(),"main art never overlaps functional text")
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("menu-%d-saves-%dx%d.png"%[count,viewport.x,viewport.y]))
			commands[1 if count==0 else 0].pressed.emit();await settle()
			var cards:Array=[]
			for child in front.page.get_children():
				if child.get_script()==load("res://scripts/campaign/hud_journey_slot.gd"):cards.append(child)
			check(cards.size()==3,"three journey strips")
			for card in cards:
				check(card.inspection.status==("ok" if card.slot_id.trim_prefix("slot-").to_int()<=count else "missing"),"actual slot state displayed")
				check(card.size.y>=120,"usable journey strip height")
				check(Rect2(Vector2.ZERO,front.size).encloses(card.get_global_rect()),"slot remains fully visible")
				check(card.detail.get_line_count()<=card.detail.get_visible_line_count(),"long saved name fits")
				if card.inspection.status=="ok":check(card.timestamp.text.contains("2min"),"saved session time shown")
				if card.erase!=null:
					var focused_art:Rect2=card.action.get_global_rect()
					focused_art.size.x+=28
					check(not focused_art.intersects(card.erase.get_global_rect()),"selection ribbon stays clear of delete button")
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("jornadas-%d-saves-%dx%d.png"%[count,viewport.x,viewport.y]))
			if count>0:
				cards[0].erase.pressed.emit();await settle()
				var dialogs:=get_nodes_in_group("manga_dialogue")
				check(dialogs.size()==1,"delete asks confirmation")
				check(root.gui_get_focus_owner()==dialogs[0].decline,"delete starts on Cancel")
				dialogs[0].canceled.emit();await settle()
				check(front.session.inspect_slot("slot-1").status=="ok","cancel preserves save")
		if count>0:
			var before:Dictionary=front.session.inspect_slot("slot-1")
			check(front.session._store.archive_slot("slot-1",int(before.data.revision)+1).status=="stale","stale deletion cannot archive a newer save")
			var receipt:Dictionary=front.session._store.archive_slot("slot-1",int(before.data.revision))
			check(receipt.status=="ok" and front.session.inspect_slot("slot-1").status=="missing","delete moves save out of active slots")
			check(not front.session._store.latest_removed().is_empty(),"undo survives reopening store")
			var restored:Dictionary=front.session._store.restore_slot(receipt)
			check(restored.status=="ok" and restored.data==before.data,"undo restores exact save and backup")
			check(front.session._store.restore_slot(receipt).status=="occupied","undo never overwrites an occupied slot")
			check(front.session._store.archive_slot("../bad",1).status=="invalid_slot","archive rejects traversal")
		front._title();await settle()
		await tap_key(KEY_ENTER)
		check(buttons(front).size()==4,"keyboard enters main menu")
		await tap_key(KEY_ENTER)
		check(front.last_scene_key=="menu:slots","keyboard enters journeys")
		await tap_key(KEY_ESCAPE)
		check(front.last_scene_key=="menu","keyboard returns from journeys")
		front._title();await settle()
		await tap_pad(JOY_BUTTON_A)
		check(buttons(front).size()==4,"gamepad enters main menu")
		await tap_pad(JOY_BUTTON_A)
		check(front.last_scene_key=="menu:slots","gamepad enters journeys")
		await tap_pad(JOY_BUTTON_B)
		check(front.last_scene_key=="menu","gamepad returns from journeys")
		for step in (1 if count==0 else 2):await tap_key(KEY_DOWN)
		await tap_key(KEY_ENTER)
		check(front.last_scene_key.begins_with("page:"),"keyboard opens settings")
		if capture:
			var previous_size:=root.size
			for settings_size in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
				root.size=settings_size
				front._show_settings()
				await settle()
				for control in buttons(front):
					check(Rect2(Vector2.ZERO,front.size).encloses(control.get_global_rect()),"settings actions visible within viewport")
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("configuracoes-%d-saves-%dx%d.png"%[count,root.size.x,root.size.y]))
			root.size=previous_size
			await settle()
		await tap_key(KEY_ESCAPE)
		check(front.last_scene_key=="menu","keyboard returns from settings")
		for step in (1 if count==0 else 2):await tap_pad(JOY_BUTTON_DPAD_DOWN)
		await tap_pad(JOY_BUTTON_A)
		check(front.last_scene_key.begins_with("page:"),"gamepad opens settings")
		await tap_pad(JOY_BUTTON_B)
		check(front.last_scene_key=="menu","gamepad returns from settings")
	var legacy_session:=Session.new()
	legacy_session._store=Store.new("user://legacy-title-"+State.new_id())
	root.add_child(legacy_session)
	var legacy:Dictionary=legacy_session.start("slot-1").data
	legacy.erase("playSeconds")
	check(legacy_session._store.save_slot(legacy).status=="ok","old saves without time remain valid")
	legacy_session.resume_slot("slot-1")
	legacy_session._process(60)
	var resumed:Dictionary=legacy_session.snapshot()
	check(legacy_session.checkpoint(resumed.checkpoint,resumed.player).status=="ok","old save can continue and save normally")
	check(legacy_session.snapshot().playTimePartial and legacy_session.snapshot().playSeconds>=60,"old playtime is explicitly partial")
	legacy_session.free()
	front.free()
	print("TITLE MENU: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
