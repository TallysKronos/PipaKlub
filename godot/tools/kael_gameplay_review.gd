extends SceneTree
## Actual campaign controllers, injected workspace-only save store and fictitious snapshots.
const Front = preload("res://scripts/campaign/front_end.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Avatar = preload("res://scripts/avatar.gd")
var front: Control
var failures: Array[String]=[]
var checks := 0
var samples: Array[Dictionary]=[]
var output := "res://../documentation/pixelgen/kael-in-game-v1"
var DIRECTIONS := [Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized(),Vector2.UP,Vector2(1,-1).normalized()]
const NAMES := ["e","se","s","sw","w","nw","n","ne"]
func _initialize() -> void:call_deferred("review")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func capture(id: String) -> void:
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func input(direction: Vector2) -> void:
	for pair in [["right",maxf(0,direction.x)],["left",maxf(0,-direction.x)],["down",maxf(0,direction.y)],["up",maxf(0,-direction.y)]]:
		var id: String="campaign_"+pair[0]
		if pair[1]>.001:Input.action_press(id,pair[1])
		else:Input.action_release(id)
func position_of(view: Node2D, room: bool) -> Vector2:
	return view.actor if room else view.player
func place(view: Node2D, point: Vector2, room: bool) -> void:
	if room:
		view.actor=point;view.companion_point=point;view.trail.clear();view._update_order()
	elif view.has_method("resolve_step"):
		view.cell=point;view.surface=view.world.cell_id(floori(point.x),floori(point.y))
		view.elevation=view.world.surface_height(view.world.find_surface(view.surface),point,true)
		view.follower=point;view.follower_surface=view.surface;view.follower_height=view.elevation
		view.distance_walked=0;view.trail.assign([{"p":point,"h":view.elevation,"surface":view.surface,"distance":0.0}])
		view._refresh_visuals()
	else:
		view.player=point
		view.follower=point;view.trail.clear()
		view.grass_distance=0
		if view.has_method("_near_jump"):view.last_point=point;view.autosave_distance=0
		else:view.distance=0
		if view.has_method("_refresh_positions"):view._refresh_positions()
		else:view._refresh()
func open_point(view: Node2D, room: bool) -> Vector2:
	if view.has_method("resolve_step"):
		for v in range(1,26):
			for u in range(3,28):
				var p := Vector2(u+.5,v+.5)
				var s: String=view.world.cell_id(u,v)
				if view.world.find_surface(s).is_empty() or view._obstructed(p,s):continue
				var clear := true
				for d in DIRECTIONS:
					if view._obstructed(p+d*.7,s):clear=false;break
				if clear:return p
		return view.player
	if room:
		for r in view.data.walkable:
			for y in range(r[1]+50,r[1]+r[3]-50,48):
				for x in range(r[0]+50,r[0]+r[2]-50,48):
					var p := Vector2(x,y)
					if DIRECTIONS.all(func(d: Vector2):return view._safe(p+d*65)):return p
		return view.actor
	for y in range(300,850,24):
		for x in range(180,1350,24):
			var p := Vector2(x,y)
			if view.has_method("walkable"):
				if view.walkable(p) and DIRECTIONS.all(func(d: Vector2):return view.ground.clear_segment(p,p+d*36)):return p
			elif view.safe(p) and DIRECTIONS.all(func(d: Vector2):return view.safe(p+d*55)):return p
	return view.player
func tick(view: Node2D, room: bool, delta: float) -> void:
	if room:view._process(delta)
	else:view._physics_process(delta)
func review() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for i in DIRECTIONS.size():check(Avatar.facing_for(DIRECTIONS[i])==NAMES[i],"direction "+NAMES[i])
	check(Avatar.facing_for(Vector2.ZERO,"nw")=="nw","idle keeps last orientation")
	front=Front.new()
	front.session._store=load("res://scripts/campaign/save_store.gd").new("res://../tmp/kael-gameplay-fixture")
	front.preferences.storage_path="res://../tmp/kael-gameplay-fixture/settings.cfg"
	root.add_child(front);front.preferences.reduced_motion=true
	for scene in ["opening-3","professor","street","trail","clearing","park","morro-area-2"]:
		input(Vector2.ZERO)
		Fixtures.show(front,scene)
		for i in 4:await process_frame
		var settling := 0
		while (front.flow_busy or is_instance_valid(front.scene_loading)) and settling<900:
			await create_timer(.02).timeout
			settling+=1
		check(not front.flow_busy and not is_instance_valid(front.scene_loading),scene+": loading/staging releases player")
		var room: bool=is_instance_valid(front.room)
		var view: Node2D=front.room if room else front.park
		check(is_instance_valid(view),scene+": active campaign scene")
		view.set_process(false);view.set_physics_process(false)
		if room:view.can_walk=true
		check(view.avatar.has_method("item_pose") and view.avatar.has_method("face_motion"),scene+": shared pixel avatar")
		check(view.avatar.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,scene+": nearest sampling")
		var center := open_point(view,room)
		var walked := 0
		for direction in DIRECTIONS:
			place(view,center,room)
			input(direction)
			for i in 5:tick(view,room,.02)
			var point := position_of(view,room)
			check(point.distance_to(center)>.001,scene+": walk "+str(direction))
			if point.distance_to(center)>.001:walked+=1
			check(view.avatar.moving,scene+": moving matches actual displacement")
			if room:check(view._safe(point),scene+": sole remains inside room")
			elif view.has_method("resolve_step"):check(not view._obstructed(point,view.surface),scene+": solid footprint clearance")
			elif view.has_method("walkable"):check(view.walkable(point),scene+": terrain support")
			else:check(view.safe(point),scene+": route support")
		input(Vector2.ZERO);tick(view,room,.02)
		check(not view.avatar.moving,scene+": release stops walk cycle")
		var before := position_of(view,room)
		front._pause_game();input(Vector2.RIGHT);tick(view,room,.2)
		check(position_of(view,room)==before,scene+": pause blocks movement")
		input(Vector2.ZERO);front._resume_game()
		view.avatar.set_motion_action("descer");view.avatar._process(.1)
		check(view.avatar.motion_action=="descer",scene+": cinematic stairs action remains compatible")
		view.avatar.set_motion_action("")
		place(view,center,room)
		view.avatar.facing="se";view.avatar.moving=false
		if view.has_method("resolve_step"):view.camera.position=view.player_root.position-Vector2(0,35)
		elif not room and is_instance_valid(view.camera):view.camera.position=view.avatar.position
		await capture(scene)
		samples.append({"scene":scene,"walkDirections":walked,"pixelScale":[view.avatar.scale.x,view.avatar.scale.y],"facing":view.avatar.facing})
		if scene=="street":
			# Follow the measured shortcut staircase in both directions with the real resolver.
			place(view,Vector2(9.5,12.5),false)
			for i in 180:
				var old: Vector2=view.cell
				view.walk(Vector2(0,-.035))
				view.avatar.moving=old.distance_to(view.cell)>.0001
				if view.avatar.moving:view.avatar.face_motion(view.world.iso(view.cell)-view.world.iso(old))
				view._refresh_visuals();view.camera.position=view.player_root.position-Vector2(0,35)
				if i%6==0:await capture("stair-up-%02d"%(i/6))
			check(view.cell.y<7,"city shortcut staircase reaches upper landing")
			check(view.elevation>=55,"city upper landing height")
			for i in 180:
				var old: Vector2=view.cell
				view.walk(Vector2(0,.035))
				view.avatar.moving=old.distance_to(view.cell)>.0001
				if view.avatar.moving:view.avatar.face_motion(view.world.iso(view.cell)-view.world.iso(old))
				view._refresh_visuals();view.camera.position=view.player_root.position-Vector2(0,35)
				if i%6==0:await capture("stair-down-%02d"%(i/6))
			check(view.cell.y>12,"city shortcut staircase reaches lower landing")
			check(view.elevation<=8.01,"city lower landing height")
		if scene=="opening-3":
			# Push into the room perimeter: it must stop, not slide through solid space.
			input(Vector2.LEFT)
			for i in 240:tick(view,true,.02)
			check(view._safe(view.actor),"room wall prevents leaving the floor")
			input(Vector2.ZERO);tick(view,true,.02)
	input(Vector2.ZERO)
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples,"usesProductionSave":false,"fixtureDirectory":"tmp/kael-gameplay-fixture"},"  "))
	print("Kael in-game audit: checks=",checks," failures=",failures.size())
	front.session.close_session();front.free()
	quit(0 if failures.is_empty() else 1)
