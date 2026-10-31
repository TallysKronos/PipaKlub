extends SceneTree
## Reproduces the observed city-map, NPC-dialogue and opening interaction failures.
## Runtime load waits for autoloads; all saves/settings use an isolated test store.
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var checks:=0
var failures:=0
var front:Control
var output:=ProjectSettings.globalize_path("res://../documentation/qa/playtest-humanlike-2026-10-30/fixes")
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 10:await process_frame
func capture(id:String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("This integration suite requires a rendered viewport (city loading awaits frame_post_draw).")
		quit(2)
		return
	if await exercise()!=true:failures+=1;printerr("Regression suite did not complete")
	if is_instance_valid(front):front.queue_free()
	await settle()
	print("PLAYTEST UI: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)
func exercise() -> bool:
	DirAccess.make_dir_recursive_absolute(output)
	front=load("res://scripts/campaign/front_end.gd").new()
	front.session._store=Store.new("user://playtest-ui-"+State.new_id())
	front.preferences.storage_path="user://playtest-ui-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	var fixtures=load("res://tools/player_audit_fixtures.gd")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		root.size=viewport
		front.session._store=Store.new("user://playtest-ui-"+State.new_id())
		fixtures.show(front,"street")
		var fixture_save:Dictionary=front.session._store._save(front.session.snapshot(),true)
		check(fixture_save.status=="ok","fixture is persisted in isolated store")
		if fixture_save.status!="ok":return false
		front.session._snapshot=fixture_save.data
		await create_timer(.6).timeout
		await settle()
		var city:Node2D=front.park
		city.set_physics_process(false)
		var paths:Array=city.map_polygons()
		check(paths.size()>3 and paths.size()<100,"city paths come from merged terrain spans")
		for point in [Vector2(15,15),Vector2(10,3),Vector2(22,23),Vector2(9,9)]:
			var on_path:=false
			for polygon in paths:on_path=on_path or Geometry2D.is_point_in_polygon(point,polygon)
			check(on_path,"road/sidewalk/stair represented: "+str(point))
		var grass:=Vector2(3,10)
		var falsely_paved:=false
		for polygon in paths:falsely_paved=falsely_paved or Geometry2D.is_point_in_polygon(grass,polygon)
		check(not falsely_paved,"grass is distinct from paths")
		check(city.map_landmarks().size()==3,"only three public city landmarks")
		front._show_map()
		await settle()
		var maps=front.find_children("*","Control",true,false).filter(func(n):return n.get_script()==load("res://scripts/campaign/hud_area_map.gd"))
		check(maps.size()==1,"area map uses the existing map screen")
		if maps.is_empty():return false
		check(maps[0].regions.size()>3 and maps[0].landmarks.size()==3,"map receives terrain and named landmarks")
		check(maps[0].player.is_finite(),"player marker uses projected coordinates")
		await capture("map-%dx%d"%[viewport.x,viewport.y])
		front._return_to_game()
		await create_timer(.6).timeout
		await settle()
		city=front.park
		city.set_physics_process(false)
		var position:Vector2=city.cell
		city._say("Nina",["Aqui embaixo é a Rua do Primeiro Vento. A ladeira leva ao professor. Pela faixa, você cruza sem ficar entre os carros!"])
		await settle()
		check(not city.exploration_hud.is_visible_in_tree() and not city.exploration_hud.map.is_visible_in_tree(),"dialogue hides HUD and minimap")
		check(not city.dialogue_panel.visible,"legacy dialogue is hidden")
		var dialog:Control=city.active_dialogue
		check(dialog.is_visible_in_tree(),"shared manga dialogue opens")
		for control in [dialog.body,dialog.accept,dialog.box]:
			check(root.get_visible_rect().encloses(control.get_global_rect()),"dialogue content and continue button fit viewport")
		check(dialog.accept.get_global_rect().end.x<=viewport.x-48,"continue button leaves room for decorative arrow")
		Input.action_press("campaign_right");city._physics_process(.1);Input.action_release("campaign_right")
		check(city.cell==position,"NPC dialogue blocks movement")
		await capture("nina-%dx%d"%[viewport.x,viewport.y])
		var event:=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_E
		city._unhandled_input(event)
		await settle()
		check(not is_instance_valid(city.active_dialogue) and city.conversation.is_empty(),"E closes dialogue without reopening it")
		check(city.exploration_hud.is_visible_in_tree() and city.exploration_hud.map.is_visible_in_tree(),"HUD and minimap return after dialogue")
		for step in [3,11,13]:
			fixtures.show(front,"opening-%d"%step)
			await create_timer(3).timeout
			await settle()
			var room:Node2D=front.room
			room.set_process(false)
			var hint=front.get_children().filter(func(n):return n.get_script()==load("res://scripts/campaign/hud_opening_hint.gd"))[0]
			hint._process(0)
			check(hint.visible and not hint.objective.text.is_empty(),"opening objective stays visible at step %d"%step)
			check("setas" in hint.movement.text and "WASD" in hint.movement.text,"movement hint explains all keyboard directions")
			check(root.get_visible_rect().encloses(hint.get_global_rect()),"opening hint stays inside viewport")
			check(is_instance_valid(room.target_marker) and room.target_marker.z_index>0,"interaction marker draws above floor")
			if step==3:
				room.actor=Vector2(768,496);room._process(0)
				check(room.near.is_empty(),"TV does not show unusable interaction while desk is required")
			if step==11:
				room.actor=Vector2(650,840);room._process(0)
				check(room._safe(room.actor) and room.near=="stairs","stairs accept the supported approach beside the opening")
			await capture("opening-%d-%dx%d"%[step,viewport.x,viewport.y])
	return true
