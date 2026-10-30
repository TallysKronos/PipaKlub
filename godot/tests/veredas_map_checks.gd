extends SceneTree

var failures:Array[String]=[]
var trips:=0
var frames:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and label not in failures:failures.append(label);printerr("FAIL ",label)
func run() -> void:
	var view: Node2D=load("res://scripts/overworld/view.gd").new();view.area_id="veredas-do-encanamento";view.art_preview=true
	root.add_child(view);await process_frame;view.set_physics_process(false)
	check(view.player==Vector2(2.5,13.5),"south entrance")
	var start:Vector2=view.player
	var goals:Dictionary={Vector2(39.5,29.5):"guardian courtyard"}
	for event in view.interaction_events:
		if event.type=="entrada":continue
		var point:=Vector2(event.u+.5,event.v+.5)
		if not view.model.walkable(Vector2i(point.floor())):
			for d in view.model.DIRS.values():
				var approach:Vector2=point+Vector2(d)
				if not view.model.path_to(start,approach).is_empty():point=approach;break
		goals[point]=event.name
	for v in int(view.model.data.h):
		for u in int(view.model.data.w):
			var c:Dictionary=view.model.cell_at(Vector2i(u,v))
			if c.material=="ponte":goals[Vector2(u+.5,v+.5)]="bridge"
			if c.get("ramp")==null:continue
			var direction:Vector2i=view.model.DIRS[c.ramp]
			var point:=Vector2(u+.5,v+.5)
			goals[point]="ramp "+str(Vector2i(u,v))
			if is_zero_approx(float(c.get("rampFrom",0))):goals[point-Vector2(direction)]="foot"
			if is_equal_approx(float(c.get("rampTo",1)),1):goals[point+Vector2(direction)*2]="landing"
	for goal:Vector2 in goals:
		walk(view,goal,str(goals[goal])+" outward")
		walk(view,start,str(goals[goal])+" return")
	var door:Dictionary={}
	for event in view.interaction_events:
		if event.type=="saida" and event.props.destino=="park-clearing":door=event
	check(not door.is_empty(),"B exit exists")
	view.nearby=door;view.interact()
	check(view.area_id=="clareira-do-papel" and view.player==Vector2(44.5,8.5),"C to B arrival")
	for event in view.interaction_events:
		if event.type=="saida" and event.props.get("destino","")=="park-veredas":view.nearby=event;break
	view.interact()
	check(view.area_id=="veredas-do-encanamento" and view.player==Vector2(2.5,13.5),"B to C return")
	view.queue_free();await process_frame
	print("VEREDAS ",goals.size()," targets; ",trips," trips; ",frames," frames; ",failures.size()," failures")
	print("Real preview movement and foot support; no saves/rewards changed; visual occlusion and human controller test not asserted")
	quit(0 if failures.is_empty() else 1)
func walk(view:Node2D,goal:Vector2,label:String) -> void:
	trips+=1
	if view.player.distance_to(goal)<.02:return
	if not view.walk_to(goal):check(false,label+" no path");return
	var ticks:=0
	while not view.path.is_empty() and ticks<10000:
		var old:Vector2=view.player;var behind:Vector2=view.follower
		view._physics_process(1.0/30.0);ticks+=1;frames+=1
		check(view.model.clear_segment(old,view.player),label+" player crossed blocker")
		if view.model.cell_at(Vector2i(view.player)).material!="ponte":check(not preload("res://scripts/overworld/forest_structures.gd").is_water(view.model,view.player),label+" feet over water cut")
		check(view.model.clear_segment(behind,view.follower),label+" follower crossed blocker")
		check((view.player_root.position+view.avatar.position).distance_to(view.model.project(view.player))<.02,label+" player feet")
		check((view.follower_root.position+view.companion.position).distance_to(view.model.project(view.follower))<.02,label+" follower feet")
	check(view.player.distance_to(goal)<.02,label+" stopped before destination")
	for tick in 120:
		if view.player.distance_to(view.follower)<1.5:break
		view._physics_process(1.0/30.0)
	if view.player.distance_to(view.follower)>=1.5:
		var route:PackedVector2Array=view.model.path_to(view.follower,view.player)
		print("FOLLOW ROUTE ",route.slice(0,4)," valid ",view.model.point_walkable(view.follower)," segments ",view.model.clear_segment(view.follower,route[0]) if route.size()>0 else false," ",view.model.clear_segment(view.follower,route[1]) if route.size()>1 else false)
	check(view.player.distance_to(view.follower)<1.5,label+" follower left behind at "+str(view.follower)+" target "+str(view.player))
