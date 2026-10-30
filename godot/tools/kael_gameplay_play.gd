extends SceneTree
## Interactive test profile. Saves are isolated under this workspace's tmp/ directory.
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const State = preload("res://scripts/campaign/state.gd")
var front: Control
var scenario := 0
var scenarios := ["street","trail","clearing","park","morro-area-2","opening-3","professor"]
var caption: Label
var fixture_path: String
func _initialize() -> void:call_deferred("start")
func start() -> void:
	root.size=Vector2i(1280,720)
	fixture_path=ProjectSettings.globalize_path("res://").path_join("../tmp/kael-playtest-"+State.new_id()).simplify_path()
	front=load("res://scripts/campaign/front_end.gd").new()
	front.session._store=load("res://scripts/campaign/save_store.gd").new(fixture_path)
	front.preferences.storage_path=fixture_path.path_join("settings.cfg")
	root.add_child(front)
	front.preferences.reduced_motion=true
	var created: Dictionary=front.session.start("slot-1")
	if created.status!="ok":push_error("Test profile creation failed");quit(1);return
	var layer := CanvasLayer.new();layer.layer=250;root.add_child(layer)
	caption=Label.new();caption.position=Vector2(360,674)
	caption.add_theme_font_size_override("font_size",14)
	caption.add_theme_color_override("font_color",Color("f2e3c7"))
	caption.add_theme_color_override("font_shadow_color",Color("0b1524"))
	caption.add_theme_constant_override("shadow_outline_size",4)
	layer.add_child(caption)
	var keyboard=load("res://tools/kael_gameplay_input.gd").new()
	keyboard.received.connect(_input)
	root.add_child(keyboard)
	show_scenario()
	DisplayServer.window_set_title("Soulmonsters · Kael novo · perfil de teste isolado")
	if "--verify-kael-playtest" in OS.get_cmdline_user_args():call_deferred("smoke")
func show_scenario() -> void:
	var current: Dictionary=front.session._store.load_slot("slot-1")
	Fixtures.show(front,scenarios[scenario])
	# Fixtures deliberately reset a scenario; synchronize only the isolated store's revision.
	front.session._snapshot.revision=current.data.revision
	var snapshot: Dictionary=front.session.snapshot()
	var saved: Dictionary=front.session.checkpoint(snapshot.checkpoint,snapshot.player)
	if saved.status!="ok":push_error("Test scenario save failed: "+saved.status)
	caption.text="TESTE LOCAL · "+scenarios[scenario]+" · F1: reiniciar/trocar cenário · F2: baú das Veredas"
func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if front.flow_busy or is_instance_valid(front.scene_loading):return
	if event.physical_keycode==KEY_F1:
		scenario=(scenario+1)%scenarios.size();show_scenario();root.set_input_as_handled()
	elif event.physical_keycode==KEY_F2 and scenarios[scenario]=="park":
		var view: Node2D=front.park
		if not view.item_receipt.is_empty() or view.ledge_jump.active:return
		view.player=load("res://scripts/campaign/park_data.gd").CHESTS.lookout.point+Vector2(20,0)
		view.follower=view.player;view.trail.clear();view.last_point=view.player
		view._refresh_positions();view.camera.position=view.landscape.project(view.player)
		view.camera.reset_smoothing();root.set_input_as_handled()
func smoke() -> void:
	while front.flow_busy or is_instance_valid(front.scene_loading):await process_frame
	var key := InputEventKey.new();key.physical_keycode=KEY_F1;key.keycode=KEY_F1;key.pressed=true
	root.push_input(key,true)
	await process_frame
	var shortcut_ok := scenario==1
	scenario=3;show_scenario()
	for i in 6:await process_frame
	front.park.player=load("res://scripts/campaign/park_data.gd").CHESTS.lookout.point
	front.park.follower=front.park.player;front.park.last_point=front.park.player
	front._park_action("chest:lookout")
	var after: Dictionary=front.session.snapshot()
	var okay: bool=shortcut_ok and "lookout" in after.player.openedChests and not front.park.item_receipt.is_empty()
	print("Kael interactive fixture: isolated slot, confirmed chest reward and item animation; pass=",okay," path=",fixture_path)
	front.session.close_session();front.free();quit(0 if okay else 1)
