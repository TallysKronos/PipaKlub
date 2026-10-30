extends SceneTree
const Controls=preload("res://scripts/campaign/controls.gd")
const Motion=preload("res://scripts/campaign/locomotion.gd")
const Follow=preload("res://scripts/campaign/companion_follow.gd")
const State=preload("res://scripts/campaign/state.gd")
var failures:Array[String]=[]
var checks:=0
var output:="res://../documentation/qa/companion-sprint"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok and label not in failures:failures.append(label);printerr("FAIL ",label)
func shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame;await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(name+".png")))
func run() -> void:
	Controls.install(Controls.DEFAULTS);Controls.use_keyboard();Motion.toggled=true
	var sprite:=Sprite2D.new()
	for heading in ["w","nw","sw","e","ne","se"]:
		Follow.orient(sprite,heading)
		check(sprite.flip_h==(heading in ["w","nw","sw"]),"heading "+heading)
	Follow.orient(sprite,"w");Follow.orient(sprite,"n")
	check(sprite.flip_h,"vertical heading retains last horizontal orientation")
	sprite.free()
	# A route with many short steps must consume the whole budget, not one point.
	var trail:Array[Vector2]=[]
	for i in 100:trail.append(Vector2(i*.1,0))
	var next:=Follow.advance(Vector2.ZERO,trail,.1,6.3,.8,func(_a:Vector2,_b:Vector2):return true)
	check(is_equal_approx(next.x,.63),"multiple short waypoints consumed in one tick")
	for id in ["jardim-das-pipas","kronasta-bosque-a"]:
		var view:Node2D=load("res://scripts/overworld/view.gd").new()
		view.area_id=id;view.art_preview=true
		root.add_child(view);await process_frame;view.set_physics_process(false)
		var start:Vector2=view.player
		var goal:=start;var longest:=0
		var ids:PackedInt64Array=view.model.graph.get_point_ids()
		for index in range(0,ids.size(),maxi(1,ids.size()/50)):
			var candidate:Vector2=view.model.graph.get_point_position(ids[index])
			var route:PackedVector2Array=view.model.path_to(start,candidate)
			if route.size()>longest:longest=route.size();goal=candidate
		check(longest>6,"long route "+id)
		for destination in [goal,start]:
			check(view.walk_to(destination),"route available "+id)
			var tick:=0;var max_gap:=0.0
			while not view.path.is_empty() and tick<12000:
				var before:Vector2=view.follower
				view._physics_process(1.0/30)
				max_gap=maxf(max_gap,view.player.distance_to(view.follower))
				check(view.model.clear_segment(before,view.follower),"supported companion steps "+id)
				check(view.follower_trail.size()<40,"trail stays bounded "+id)
				tick+=1
			check(tick<12000 and max_gap<1.1,"continuous sprint keeps companion close "+id)
			check(view.companion.get_meta("facing")==view.avatar.facing,"real map heading "+id)
		view._refresh_positions();view.camera.reset_smoothing()
		var old_follower:Vector2=view.follower
		view.follower=goal
		var blocker:=Node2D.new()
		blocker.position=view.model.project(goal,false)+Vector2(0,1)
		var art:=Sprite2D.new();art.name="Art"
		var texture:=PlaceholderTexture2D.new();texture.size=Vector2(20,30)
		art.texture=texture;art.centered=false
		art.position=view.model.project(goal)-blocker.position-Vector2(10,35)
		blocker.add_child(art);view.add_child(blocker);view.occluders.append(blocker)
		view._fade_occluders()
		check(is_equal_approx(art.modulate.a,.45),"occluder reveals follower without covering Kael "+id)
		view.occluders.erase(blocker);blocker.free();view.follower=old_follower;view._refresh_positions()
		await shot(id)
		view.queue_free();await process_frame
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var room:Node2D=load("res://scripts/campaign/room_view.gd").new()
	room.configure(content.rooms.bedroom,[900,800],true,"*",false,true)
	root.add_child(room);await process_frame;room.set_process(false)
	var origin:=Vector2.INF
	var direction:=Vector2(1,-1).normalized()
	for y in range(350,1000,24):
		for x in range(420,1280,24):
			var point:=Vector2(x,y)
			if room._safe(point) and room._companion_segment(point,point+direction*300):origin=point;break
		if origin.is_finite():break
	check(origin.is_finite(),"real bedroom sprint lane")
	if origin.is_finite():
		room.actor=origin;room.companion_point=origin;room.trail.clear()
		var max_gap:=0.0
		Input.action_press("campaign_right")
		for tick in 25:
			room._process(1.0/60)
			max_gap=maxf(max_gap,room.actor.distance_to(room.companion_point))
		Input.action_release("campaign_right")
		check(room.actor.distance_to(origin)>260,"actual room sprint sustained")
		check(max_gap<85,"room companion no longer limited to walking speed")
		check(not room.companion.flip_h,"room companion faces right")
		Input.action_press("campaign_left");room._process(1.0/60);Input.action_release("campaign_left")
		check(room.companion.flip_h,"room companion turns left immediately")
		for tick in 60:room._process(1.0/60)
		check(room.actor.distance_to(room.companion_point)<=70.01,"room follower settles behind player")
	room.queue_free();await process_frame
	var city:Node2D=load("res://scripts/campaign/neighborhood_view.gd").new()
	city.saved_player=State.fresh("slot-1").player;city.checkpoint_position=Vector2(10.5,20.5)
	root.add_child(city);await process_frame;city.set_physics_process(false)
	for action in ["right","left"]:
		Input.action_press("campaign_"+action)
		for tick in 60:
			city._physics_process(1.0/60)
			check(city.cell.distance_to(city.follower)<.8,"city keeps partner in reach")
		Input.action_release("campaign_"+action)
		check(city.partner.flip_h==(action=="left"),"city partner turns "+action)
		await shot("cidade-"+action)
	city.queue_free();await process_frame;Motion.toggled=false
	print("COMPANION SPRINT ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
