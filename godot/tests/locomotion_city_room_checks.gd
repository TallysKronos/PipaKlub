extends SceneTree
## Check the other real movement controllers; no campaign saves are opened.
const Controls=preload("res://scripts/campaign/controls.gd")
const Motion=preload("res://scripts/campaign/locomotion.gd")
const State=preload("res://scripts/campaign/state.gd")
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func run() -> void:
	Controls.install(Controls.DEFAULTS);Controls.use_keyboard();Motion.toggled=false
	var city:Node2D=load("res://scripts/campaign/neighborhood_view.gd").new()
	city.saved_player=State.fresh("slot-1").player
	city.saved_player.journey={"phase":"complete","lesson":5}
	city.checkpoint_position=Vector2(10.5,20.5)
	root.add_child(city);await process_frame
	city.set_process(false);city.set_physics_process(false);city.avatar.set_process(false)
	var start:Vector2=city.cell
	var surface:String=city.surface
	var elevation:float=city.elevation
	var distances:Array[float]=[]
	for sprint in [false,true]:
		Motion.toggled=sprint;city.cell=start;city.surface=surface;city.elevation=elevation
		Input.action_press("campaign_right");city._physics_process(1.0/60);Input.action_release("campaign_right")
		distances.append(city.cell.distance_to(start))
		check(city.avatar.moving and city.avatar.running==sprint,"city keyboard selects gait")
	check(distances[0]>.001 and absf(distances[1]/maxf(.00001,distances[0])-1.8)<.001,"city sprint is 1.8x walk")
	city.paused=true;var before:Vector2=city.cell
	Input.action_press("campaign_right");city._physics_process(.1);Input.action_release("campaign_right")
	check(city.cell==before and not city.avatar.running,"city pause blocks sprint")
	city.paused=false;city.conversation.assign(["Conversa de teste"])
	city.avatar.running=true;city._physics_process(.1)
	check(not city.avatar.running and not city.avatar.moving,"city conversation blocks sprint")
	city.queue_free();await process_frame
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var room:Node2D=load("res://scripts/campaign/room_view.gd").new()
	room.configure(content.rooms.bedroom,[900,800],true,"*",false,false)
	root.add_child(room);await process_frame;room.set_process(false);room.avatar.set_process(false)
	var origin:=Vector2.INF
	for y in range(350,1000,32):
		for x in range(420,1280,32):
			var point:=Vector2(x,y)
			if room._safe(point) and room._safe(point+Vector2(30,-30)):origin=point;break
		if origin.is_finite():break
	check(origin.is_finite(),"interior has supported lane")
	if origin.is_finite():
		var lengths:Array[float]=[]
		for sprint in [false,true]:
			Motion.toggled=sprint;room.actor=origin
			Input.action_press("campaign_right");room._process(1.0/60);Input.action_release("campaign_right")
			lengths.append(origin.distance_to(room.actor))
			check(room.avatar.moving and room.avatar.running==sprint,"room keyboard selects gait")
		check(absf(lengths[1]/maxf(.00001,lengths[0])-1.8)<.001,"room sprint is 1.8x walk")
	room.can_walk=false;room.cinematic_actor_moving=true;room._process(.1)
	check(room.avatar.moving and not room.avatar.running,"cinematic movement keeps walk gait")
	room.set_story_paused(true)
	check(not room.avatar.moving and not room.avatar.running,"story pause clears sprint")
	Motion.toggled=false;room.queue_free();await process_frame
	print("KAEL CITY/ROOM ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
