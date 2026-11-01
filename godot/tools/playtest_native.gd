extends SceneTree
var app:Control
class Recorder extends Node:
	var app:Control
	var shots:=0
	func _input(event:InputEvent) -> void:
		if not event is InputEventKey:return
		# Windows automation reports VK_PACKET as one physical key for every key.
		# Normalize only in this QA launcher; leave shipping controls untouched.
		if event.keycode>0 and event.physical_keycode!=event.keycode:
			get_viewport().set_input_as_handled()
			if not event.pressed or event.echo:return
			var normalized:InputEventKey=event.duplicate();normalized.physical_keycode=event.keycode
			Input.parse_input_event(normalized)
			await get_tree().create_timer(.28).timeout
			normalized.pressed=false;Input.parse_input_event(normalized)
			return
		if event.pressed:
			print("QA KEY ",OS.get_keycode_string(event.keycode)," at ",Time.get_ticks_msec())
			if event.keycode==KEY_F12:
				get_viewport().set_input_as_handled();shots+=1
				await RenderingServer.frame_post_draw
				var folder:=ProjectSettings.globalize_path("res://../documentation/qa/playtest-humanlike-2026-10-30")
				get_viewport().get_texture().get_image().save_png(folder.path_join("screen-%03d.png"%shots))
				print("QA SHOT ",shots," ",app.session.snapshot().get("checkpoint",{}))
func _initialize() -> void:call_deferred("run")
func run() -> void:
	app=load("res://scripts/campaign/front_end.gd").new();root.add_child(app)
	var recorder:=Recorder.new();recorder.app=app;root.add_child(recorder)
	DisplayServer.window_set_title("Soulmonsters — Playtest isolado")
