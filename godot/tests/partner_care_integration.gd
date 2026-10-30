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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/qa/care-room-v1"))
	var suffix:="" if root.size==Vector2i(1280,720) else "-%dx%d"%[root.size.x,root.size.y]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/care-room-v1/"+name+suffix+".png"))
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
	check(root.gui_get_focus_owner()==view.stage,"collecting kit focuses care rather than another purchase")
	await process_frame
	for button in [view.pet,view.call_button,view.roam_button,view.supply,view.back]+view.tool_buttons:
		check(view.get_global_rect().encloses(button.get_global_rect()),"care button fits page "+button.text)
		check(button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x<button.size.x-45,"button label fits without truncation "+button.text)
	check(view.stage.size.y>=140,"pet area retains readable minimum")
	check(view.stage.focus_next==view.pet.get_path(),"Tab leaves habitat for tools")
	var previous_hand:Vector2=view.hand
	Input.action_press("ui_right");view._process(.2);Input.action_release("ui_right")
	check(view.hand.x>previous_hand.x and root.gui_get_focus_owner()==view.stage,"keyboard moves floating hand while retaining habitat focus")
	view.pointer_inside=true;view._process(.01)
	if DisplayServer.get_name()!="headless":check(Input.get_mouse_mode()==Input.MOUSE_MODE_HIDDEN,"habitat replaces native cursor with hand")
	view.stage.mouse_exited.emit()
	check(Input.get_mouse_mode()==Input.MOUSE_MODE_VISIBLE and not view.holding,"leaving habitat restores native cursor")
	await shot("01-cuidados")
	view._care();view.back_requested.emit();await process_frame
	check(app.session.snapshot().player.inventory["kit-remendo"]==1,"cancelled care keeps kit")
	app._show_bag();await process_frame
	var inventory:Node=find_script(app,"res://scripts/campaign/hud_inventory.gd")
	inventory.select_item("kit-remendo")
	check(inventory.use_button.visible and inventory.item_name.text=="Kit de Remendo","bag identifies usable repair item")
	inventory.use_button.pressed.emit();await process_frame
	view=find_script(app,"res://scripts/campaign/partner_care_view.gd")
	view.set_process(false)
	var first:Vector2=view.foot
	for i in 10:view._process(.1)
	check(view.foot.distance_to(first)>.01,"partner actually roams in habitat")
	view.select_tool("call");view.interact_at(Vector2(1,0))
	check(view.target==Vector2(.77,.58),"calling clamps destination to clear floor")
	for i in 100:view._process(.1)
	check(view.floor_point(view.foot)==view.foot,"roaming stays inside supported floor")
	view.select_tool("clean")
	view.interact_at(view.foot)
	check(view.steps.is_empty(),"care waits for arrival at rug")
	for i in 60:view._process(.1)
	check(view.state=="care" and view.foot==view.rug,"partner walks to treatment mat")
	view.hand=Vector2(.1,.2);view._touch(35)
	check(view.progress==0,"cloth outside partner cannot repair")
	view.hand=view.foot-Vector2(0,view.pet_height*.45)/view.room_rect.size
	view.holding=true
	for i in 10:
		var motion:=InputEventMouseMotion.new();motion.position=view.position_for(view.hand);motion.relative=Vector2(28,0)
		view._stage_input(motion)
	check(view.steps==["clean"] and view.tool=="frame","cloth strokes advance to patching")
	for i in 3:
		var click:=InputEventMouseButton.new();click.position=view.position_for(view.hand);click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
		view._stage_input(click)
	check(view.steps==["clean","frame"],"three patch touches strengthen frame")
	check(app.session.snapshot().player.inventory["kit-remendo"]==1,"gestures preserve kit before final adjustment")
	await shot("02-armacao")
	view.holding=true
	for i in 20:view._process(.1)
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
	view.select_tool("frame")
	check(view.tool=="hand","healthy partner cannot select repair tools")
	var registry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/care-room-v1/rigs.json"))
	for id in registry:
		var animal=load("res://scripts/campaign/care_creature.gd").new();animal.configure(id);view.stage.add_child(animal)
		animal.pose="walk";animal.animate(.2)
		check(animal.native_height>0 and not animal.rig.is_empty(),"approved articulated art loads for "+id)
		animal.position=view.position_for(view.rug);animal.scale=Vector2.ONE*170/animal.native_height
		view.creature.hide();await shot("04-parceiro-"+id)
		animal.queue_free()
		await process_frame
	view.creature.show()
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	app._unhandled_input(escape);await process_frame
	check(app.last_scene_key=="page:EQUIPE","Escape returns from care to team")
	for audio in app.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	# Let the audio thread release stopped voices before the fast headless exit.
	await create_timer(.15).timeout
	app.queue_free();await process_frame
	print("PARTNER CARE INTEGRATION ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
