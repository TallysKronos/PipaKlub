extends SceneTree
## Real campaign movement and HUD, without a save store or rewards.
const Controls=preload("res://scripts/campaign/controls.gd")
const Motion=preload("res://scripts/campaign/locomotion.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:Array[String]=[]
var output:="res://../art/characters/kael-locomotion-v1/review"

func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)

func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(name+".png")))

func run() -> void:
	Controls.install()
	Controls.use_keyboard()
	Motion.toggled=false
	var remap:=Controls.DEFAULTS.duplicate();remap.dodge=KEY_T
	Controls.install(remap)
	check(Controls.validate(remap) and Controls.key_for("run")==KEY_T,"existing keymap supports contextual sprint")
	check(Controls.button_for("dodge","switch")==JOY_BUTTON_A,"Switch battle dodge unchanged")
	for family in ["xbox","ps","switch"]:
		check(Controls.button_for("run",family)==JOY_BUTTON_LEFT_STICK,"left stick sprint "+family)
	Controls.install(Controls.DEFAULTS)
	var idle:=Image.load_from_file("res://assets/kael-video/kael-idle-eight.png")
	var run_sheet:=Image.load_from_file("res://assets/kael-video/kael-run-eight.png")
	var walk:=Image.load_from_file("res://assets/kael-video/kael-walk-eight.png")
	check(idle.get_size()==Vector2i(512,768) and run_sheet.get_size()==idle.get_size(),"matching 64x96 cells, eight angles and eight phases")
	var palette:={}
	for y in walk.get_height():
		for x in walk.get_width():palette[walk.get_pixel(x,y).to_rgba32()]=true
	for sheet in [idle,run_sheet]:
		var clean:=true
		for y in sheet.get_height():
			for x in sheet.get_width():
				var color:Color=sheet.get_pixel(x,y)
				if color.a!=0 and (color.a!=1 or not palette.has(color.to_rgba32())):clean=false
		check(clean,"binary alpha and approved palette")
	for row in 8:
		var soles:=idle.get_region(Rect2i(0,row*96+78,64,18)).get_data()
		var poses:={}
		for frame in 8:
			check(idle.get_region(Rect2i(frame*64,row*96+78,64,18)).get_data()==soles,"idle feet fixed %d/%d"%[row,frame])
			var cell:=run_sheet.get_region(Rect2i(frame*64,row*96,64,96))
			check(not cell.is_invisible(),"run pose present %d/%d"%[row,frame])
			poses[cell.get_data().hex_encode().sha256_text()]=true
		check(poses.size()>=6,"distinct running poses in angle "+str(row))
	var view:Node2D=load("res://scripts/campaign/park_overworld_view.gd").new()
	view.saved_checkpoint={"scene":"kronasta-bosque-a","position":[10.5,20.5]}
	view.saved_player=State.fresh("slot-1").player
	view.saved_player.journey={"phase":"complete","lesson":5}
	view.saved_player.partners=[{"id":"test-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	view.saved_player.equippedPartnerId="test-rabbito"
	view.saved_player.encounterGraceUntil=Time.get_unix_time_from_system()+3600
	view.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	view.avatar.set_process(false)
	var start:=Vector2.INF
	var direction:=Vector2.RIGHT
	for id in view.model.graph.get_point_ids():
		var at:Vector2=view.model.graph.get_point_position(id)
		if view.model.clear_segment(at,at+direction*3):start=at;break
	check(start.is_finite(),"clear lane in real forest")
	if not start.is_finite():view.queue_free();quit(1);return
	var distances:Array[float]=[]
	for sprint in [false,true]:
		Motion.toggled=sprint
		view.player=start;view.follower=start;view.follower_trail.clear();view.path.clear()
		view.path=PackedVector2Array([start+direction*3])
		for tick in 30:
			var before:Vector2=view.player
			view._physics_process(1.0/60)
			check(view.model.clear_segment(before,view.player),"accepted movement stays supported")
		distances.append(start.distance_to(view.player))
		check(view.avatar.running==sprint,"movement chooses correct gait")
	check(is_equal_approx(distances[1]/distances[0],1.8),"running is 1.8x walking")
	view.path.clear();view._physics_process(1.0/60)
	view.avatar._process(.1)
	check(not view.avatar.moving and view.avatar.locomotion_state=="idle","release movement returns to neutral idle")
	var phase:int=view.avatar.cycle_frame(view.avatar.IDLE_TIMES)
	view.avatar._process(.55)
	check(view.avatar.cycle_frame(view.avatar.IDLE_TIMES)!=phase,"idle advances while stationary")
	view.avatar.moving=true;view.avatar.running=true
	view.avatar.set_motion_action("subir");view.avatar._process(.1)
	check(view.avatar.locomotion_state=="walk","stairs override run gait")
	view.avatar.set_motion_action("")
	view.paused=true
	var before:Vector2=view.player
	Input.action_press("campaign_right");view._physics_process(.1);Input.action_release("campaign_right")
	check(view.player==before and not view.avatar.running,"pause blocks running and movement")
	Motion.toggled=false;view.toggle_run()
	check(not Motion.toggled,"paused HUD cannot toggle sprint")
	view.paused=false
	view.exploration_hud.run_button.pressed.emit()
	check(Motion.toggled,"visible HUD button enables sprint")
	view.exploration_hud.run_button.pressed.emit()
	check(not Motion.toggled,"visible HUD button returns to walk")
	Input.action_press("campaign_run")
	check(Motion.requested() and Controls.held("run"),"holding Shift requests sprint")
	Input.action_release("campaign_run")
	check(not Motion.requested(),"releasing Shift returns to walk")
	await process_frame
	Controls.gamepad=true
	Input.action_press("campaign_run")
	Motion.update();var latched:=Motion.toggled;Motion.update()
	check(latched and Motion.toggled,"L3 toggles once per frame")
	Input.action_release("campaign_run");await process_frame
	check(Motion.requested(),"L3 sprint stays active after release")
	Motion.toggled=false;Controls.use_keyboard()
	view.avatar.moving=false;view.avatar.running=false;view.avatar.facing="se";view.avatar.clock=0
	view._refresh_positions();view.camera.reset_smoothing()
	view.exploration_hud._layout()
	await shot("idle-in-game")
	view.avatar.moving=true;view.avatar.running=true;view.avatar._process(.25)
	Motion.toggled=true;view.exploration_hud._layout()
	await shot("run-in-game")
	for viewport in [Vector2(1280,720),Vector2(1920,1080),Vector2(800,600)]:
		view.exploration_hud.size=viewport;view.exploration_hud._layout()
		var rect:Rect2=view.exploration_hud.run_button.get_rect()
		check(rect.position.x>=0 and rect.end.x<=viewport.x and rect.end.y<=viewport.y,"run button fits "+str(viewport))
	Motion.toggled=false
	view.queue_free();await process_frame
	print("KAEL LOCOMOTION ",checks," checks; ",failures.size()," failures; walk ",distances[0]," run ",distances[1])
	quit(0 if failures.is_empty() else 1)
