extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
var checks:=0
var failures:Array[String]=[]
var app:Control
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func find_script(node:Node,path:String) -> Node:
	if node.get_script()!=null and node.get_script().resource_path==path:return node
	for child in node.get_children():
		var found:=find_script(child,path)
		if found!=null:return found
	return null
func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/qa/partner-care"))
	var suffix:="" if root.size==Vector2i(1280,720) else "-%dx%d"%[root.size.x,root.size.y]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/partner-care/"+name+suffix+".png"))
func run() -> void:
	app=load("res://tests/fixtures/park_frontend_fixture.gd").new()
	app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/care-integration-"+State.new_id()))
	root.add_child(app);check(app.session.start("slot-1").status=="ok","isolated frontend")
	var player:Dictionary=app.session.snapshot().player
	player.partners=[{"id":"care-partner","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":18,"structure":35}}]
	player.equippedPartnerId="care-partner";player.coins=24;player.journey={"phase":"complete","lesson":5}
	check(app.session.checkpoint({"kind":"world","scene":"quintal","position":[10.5,20.5],"space":"bairro-inicial-v2"},player).status=="ok","campaign fixture")
	app._show_collection();await process_frame
	var care_buttons:Array=app.page.find_children("*","Button",true,false).filter(func(b):return b.text=="Cuidar")
	check(care_buttons.size()==1,"team exposes care per partner")
	care_buttons[0].pressed.emit();await process_frame
	var view:Node=find_script(app,"res://scripts/campaign/partner_care_view.gd")
	check(view!=null,"team opens care page")
	check(view.action.disabled,"repair unavailable without kit")
	view.supply.pressed.emit()
	check(view.kits==1 and not view.action.disabled,"welcome kit activates treatment")
	check(root.gui_get_focus_owner()==view.action,"collecting kit focuses care rather than another purchase")
	await process_frame
	for button in [view.action,view.pet,view.supply,view.back]:
		check(view.get_global_rect().encloses(button.get_global_rect()),"care button fits page "+button.text)
	check(view.stage.size.y>=140,"pet area retains readable minimum")
	await shot("01-cuidados")
	view._care();view.back_requested.emit();await process_frame
	check(app.session.snapshot().player.inventory["kit-remendo"]==1,"cancelled care keeps kit")
	app._show_bag();await process_frame
	var inventory:Node=find_script(app,"res://scripts/campaign/hud_inventory.gd")
	inventory.select_item("kit-remendo")
	check(inventory.use_button.visible and inventory.item_name.text=="Kit de Remendo","bag identifies usable repair item")
	inventory.use_button.pressed.emit();await process_frame
	view=find_script(app,"res://scripts/campaign/partner_care_view.gd")
	view._care();view._care()
	await shot("02-armacao")
	view._care()
	check(view.saved and view.kits==0,"final care step saves and consumes kit")
	check(app.session.snapshot().player.partners[0].condition.line==100,"campaign partner repaired")
	await shot("03-recuperado")
	view.back_requested.emit();await process_frame
	check(app.last_scene_key=="page:EQUIPE","back returns to team")
	var before:Dictionary=app.session.snapshot()
	app._show_partner_care();await process_frame
	view=find_script(app,"res://scripts/campaign/partner_care_view.gd")
	view._pet()
	check(view.action.disabled and app.session.snapshot().player==before.player,"healthy pet interaction does not spend items")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	app._unhandled_input(escape);await process_frame
	check(app.last_scene_key=="page:EQUIPE","Escape returns from care to team")
	app.queue_free();await process_frame
	print("PARTNER CARE INTEGRATION ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
