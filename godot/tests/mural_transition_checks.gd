extends SceneTree
const Loading=preload("res://scripts/campaign/hud_scene_loading.gd")
const Surface=preload("res://scripts/ui_mural/travel_surface.gd")
const Director=preload("res://scripts/campaign/sound_director.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var checks:=0
var failures:Array=[]
class InputSink extends Node:
	var received:=0
	func _unhandled_input(_event:InputEvent)->void:received+=1
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func run()->void:
	var audio:=Director.new();root.add_child(audio)
	audio.configure({"master":0,"ui":0,"sfx":0,"music":.3},false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("UI")),"UI zero is silent")
	var music_gain:=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	audio.game_paused=true;audio.transition()
	check(audio.voices.size()==1,"travel allowed during loading pause")
	check(audio.voices[0].bus=="UI","travel uses UI preference")
	audio.clear_context()
	check(not audio.voices[0].is_queued_for_deletion(),"travel survives scene disposal")
	check(is_equal_approx(music_gain,AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),"travel preserves music preference")
	audio.play_event("progress.coins");audio.play_event("progress.xp");audio.play_event("progress.level_up")
	await process_frame;await process_frame
	check(audio.connected_events.has("progress.level_up"),"level is heard")
	check(not audio.connected_events.has("progress.coins") and not audio.connected_events.has("progress.xp"),"same-frame reward jingles coalesce")
	audio.last_play.clear();audio.play_event("progress.item");audio.play_event("progress.save_error")
	await process_frame;await process_frame
	check(not audio.connected_events.has("progress.item"),"save error cancels queued celebration")
	audio.focused=false;audio.last_play.clear();var count:=audio.voices.size();audio.transition()
	check(audio.voices.size()==count,"unfocused window stays silent")
	audio.free()
	var sink:=InputSink.new();root.add_child(sink)
	var previous:=Button.new();root.add_child(previous);previous.grab_focus()
	for reduce in [false,true]:
		var gate:=Loading.new();gate.reduced_motion=reduce;root.add_child(gate)
		await gate.cover()
		var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_W
		var mouse:=InputEventMouseButton.new();mouse.pressed=true;mouse.button_index=MOUSE_BUTTON_LEFT
		var pad:=InputEventJoypadButton.new();pad.pressed=true;pad.button_index=JOY_BUTTON_A
		for event in [key,mouse,pad]:root.push_input(event,true)
		check(sink.received==0,"keyboard mouse and simulated pad blocked under loading")
		check(gate.phase=="loading" and is_equal_approx(gate.opacity,1),"cover completes before load")
		await create_timer(.03).timeout
		check(gate.phase=="loading","no timer reveals an unready scene")
		await gate.reveal()
		check(gate.phase=="complete","explicit readiness releases gate")
		check(is_zero_approx(gate.slide) if reduce else is_equal_approx(gate.slide,1),"reduced motion uses fade")
		gate.free()
		await process_frame;await process_frame
		check(root.gui_get_focus_owner()==previous,"surviving focus restored on return")
	previous.free();sink.free()
	for reduce in [false,true]:
		var layer:=CanvasLayer.new();root.add_child(layer)
		var wipe=preload("res://scripts/campaign/hud_ink_transition.gd").new();wipe.reduced_motion=reduce;layer.add_child(wipe)
		await create_timer(.4).timeout
		check(not is_instance_valid(layer),"short reveal releases its own layer")
	var surface:=Surface.new();root.add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for extent in [Vector2(1280,720),Vector2(1920,1080),Vector2(1024,768),Vector2(1280,800)]:
		for scale in [1.0,1.5]:
			surface.size=extent;surface.text_scale=scale
			var rect:=surface.label_rect();var safe:=Paper.content(rect,.3)
			check(Rect2(Vector2.ZERO,extent).grow(-24).encloses(rect),"24px safe margin "+str(extent)+str(scale))
			check(safe.size.x-66>=Paper.T.label().get_string_size("Carregando…",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(26*scale)).x,"loading text fits "+str(extent)+str(scale))
			check(safe.size.y>=Paper.T.label().get_height(roundi(26*scale)),"loading font height fits "+str(extent)+str(scale))
	surface.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-137"))
	var output:=FileAccess.open("res://../documentation/hud-v2/pip-137/testes.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));output.close()
	print("PIP137 ",checks," checks, ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
