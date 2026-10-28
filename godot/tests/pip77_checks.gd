extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr(message)
func settle() -> void:
	for i in 10:await process_frame
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://pip77-"+State.new_id())
	front.preferences.storage_path="user://pip77-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=viewport
		for stage in 5:
			Fixtures.show(front,"workshop-%d"%stage);await settle()
			var view:Control=front.workshop
			view.paused=false
			check(not view.bottom_panel.visible,"normal workshop has no permanent footer")
			check(Rect2(Vector2.ZERO,front.size).encloses(view.pause_button.get_global_rect()),"pause glyph fits")
			view.pause_button.pressed.emit();await settle()
			check(is_instance_valid(front.pause_overlay),"workshop opens shared pause")
			var before:Dictionary=view.model.run.duplicate(true)
			view._process(.25)
			check(view.model.run==before,"pause freezes workshop simulation")
			front._resume_game();await settle()
			check(not view.paused,"resume releases workshop")
	front.queue_free();await settle()
	print("PIP77: %d checks; %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
