extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
var app:Control
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL ",message)
func settle() -> void:
	for i in 10:await process_frame
func current() -> Control:
	for child in app.get_children():
		if child.has_meta("emblem_case"):return child
	return null
func capture(view:Control,name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var directory:=ProjectSettings.globalize_path("res://../documentation/qa/emblem-case-v1")
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name+".png"))
func run() -> void:
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://emblem-case-"+State.new_id()
	app.session._store=Store.new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	check(app.session.start("slot-1").status=="ok","isolated slot")
	var saved:Dictionary=app.session.snapshot()
	saved.player.journey={"lesson":5,"phase":"complete"}
	saved.player.partners=[{"id":"case-partner","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	saved.player.equippedPartnerId="case-partner"
	Identity.issue_into(saved.player);saved.player.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint({"kind":"world","scene":"professor-home","position":[1152,864]},saved.player).status=="ok","issued case fixture")
	app._show_saved();await settle();app._pause_game();await settle()
	check(app.pause_overlay.buttons.has("emblems") and not app.pause_overlay.buttons.emblems.disabled,"direct pause entry available")
	app.pause_overlay.buttons.emblems.grab_focus()
	app.pause_overlay.buttons.emblems.pressed.emit();await settle()
	var view:=current()
	check(is_instance_valid(view),"case overlay opens over existing world")
	if not is_instance_valid(view):quit(1);return
	check(not app.pause_overlay.visible and not app.room.can_walk,"pause hidden and movement still stopped")
	check(app.pause_overlay.buttons.resume.focus_mode==Control.FOCUS_NONE,"underlying buttons excluded from modal focus")
	check(view.slots.size()==12 and view.slots.all(func(slot):return slot.visible),"twelve fixed positions")
	check(view.count.text.ends_with("0 / 12"),"real save remains empty")
	view.slots[11].pressed.emit()
	check("12" in view.title.text and "Ainda" in view.location.text,"locked selection detail")
	view.set_filter(1)
	check(view.slots.all(func(slot):return not slot.visible) and "Nenhum" in view.empty.text,"empty earned filter")
	view.set_filter(2)
	check(view.slots.all(func(slot):return slot.visible),"pending filter")
	view.set_filter(0);view.select_slot(0)
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		await settle()
		for slot in view.slots:check(root.get_visible_rect().encloses(slot.get_global_rect()),"slot fits "+str(viewport))
		check(root.get_visible_rect().encloses(view.back.get_global_rect()),"close fits")
		check(root.get_visible_rect().encloses(view.count.get_global_rect()),"counter fits")
		await capture(view,"estojo-vazio-%dx%d"%[viewport.x,viewport.y])
	var map_key:=InputEventKey.new();map_key.physical_keycode=KEY_M;map_key.keycode=KEY_M;map_key.pressed=true
	root.push_input(map_key,true);await settle()
	check(is_instance_valid(current()) and app.last_scene_key=="world:professor-home","map shortcut cannot leak through modal")
	var tab:=InputEventKey.new();tab.physical_keycode=KEY_TAB;tab.keycode=KEY_TAB;tab.pressed=true
	root.push_input(tab,true);await settle()
	check(view.filter_index==1,"Tab changes filter")
	var shoulder:=InputEventJoypadButton.new();shoulder.button_index=JOY_BUTTON_RIGHT_SHOULDER;shoulder.pressed=true
	root.push_input(shoulder,true);await settle()
	check(view.filter_index==2,"controller shoulder changes filter")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=true
	root.push_input(escape,true);await settle()
	check(not is_instance_valid(current()) and app.pause_overlay.visible,"Escape restores pause instead of resuming world")
	check(root.gui_get_focus_owner()==app.pause_overlay.buttons.emblems,"pause focus restored")
	check(app.pause_overlay.buttons.resume.focus_mode==Control.FOCUS_ALL,"underlying focus modes restored")
	check(not app.session.snapshot().player.has("districtEmblems"),"view never grants emblems")
	# Three purely visual examples. Never write these into the campaign slot.
	var examples:Dictionary=app.session.snapshot().player
	for i in 3:
		check(Identity.award_district(examples,i,"preview-chief-%d"%i,["Selo da Rajada","Selo dos Elos","Selo da Pipa"][i],{"districtName":"Bairro de exemplo","bossName":"Chefe de exemplo","description":"Uma conquista de bairro, guardada junto aos fios da sua jornada."}),"example metadata supported")
	check(Identity.valid_emblems(examples.districtEmblems),"metadata valid")
	view=load("res://scripts/campaign/hud_emblem_case.gd").new();view.player=examples
	app.add_child(view);app.pause_overlay.hide();await settle()
	check(view.count.text.ends_with("3 / 12") and view.art.earned,"earned state and enlarged emblem")
	check(view.title.text=="Selo da Rajada" and "Chefe de exemplo" in view.chief.text,"selected earned details")
	view.set_filter(1)
	check(view.slots.filter(func(slot):return slot.visible).size()==3,"earned filter has three")
	view.set_filter(2)
	check(view.slots.filter(func(slot):return slot.visible).size()==9,"pending filter has nine")
	view.set_filter(0);view.select_slot(0)
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		await settle();await capture(view,"exemplo-visual-%dx%d"%[viewport.x,viewport.y])
	check(not app.session._store.load_slot("slot-1").data.player.has("districtEmblems"),"visual examples never touch disk")
	view.player.districtEmblems["bairro-01"].name="Uma conquista de bairro com um nome bem comprido para conferir"
	view.player.districtEmblems["bairro-01"].description="Uma história de ventos, fios e encontros. ".repeat(7)
	view.select_slot(0);await settle()
	check(root.get_visible_rect().encloses(view.count.get_global_rect()) and root.get_visible_rect().encloses(view.back.get_global_rect()),"long details keep counter and close visible")
	var malformed:Dictionary=examples.districtEmblems.duplicate(true);malformed["bairro-01"].bossName=7
	check(not Identity.valid_emblems(malformed),"invalid metadata rejected")
	view.queue_free();await settle();app.pause_overlay.show()
	app.pause_overlay.buttons.identity.pressed.emit();await settle()
	check(app.last_scene_key=="page:CARTEIRA DE PIPEIRO","identity remains accessible")
	app._open_emblem_case(7);await settle()
	check(current().selected==7,"case can open from identity on requested position")
	current().back.pressed.emit();await settle()
	check(app.last_scene_key=="page:CARTEIRA DE PIPEIRO" and not is_instance_valid(current()),"close returns to identity")
	app.queue_free();await settle()
	print("EMBLEM CASE: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
