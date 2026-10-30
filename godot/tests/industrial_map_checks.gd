extends SceneTree
const View=preload("res://scripts/overworld/view.gd")
var failures:Array[String]=[]
var trips:=0
var frames:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and label not in failures:failures.append(label);printerr("FAIL ",label)
func run() -> void:
	var view:=View.new();view.area_id=OS.get_environment("INDUSTRIAL_AREA");view.art_preview=true
	root.add_child(view);await process_frame;view.set_physics_process(false)
	check(view.model.walkable(Vector2i(view.player)),"valid entrance")
	var start:Vector2=view.player
	var goals:Dictionary={}
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
			if c.get("ramp")==null:continue
			var direction:Vector2i=view.model.DIRS[c.ramp]
			var point:=Vector2(u+.5,v+.5)
			goals[point]="ramp "+str(Vector2i(u,v))
			if is_zero_approx(float(c.get("rampFrom",0))):goals[point-Vector2(direction)]="foot"
			if is_equal_approx(float(c.get("rampTo",1)),1):goals[point+Vector2(direction)*2]="landing"
	for goal:Vector2 in goals:
		walk(view,goal,str(goals[goal])+" outward")
		walk(view,start,str(goals[goal])+" return")
	for event in view.model.data.events.duplicate(true):
		if event.type!="saida":continue
		var source:String=view.area_id
		view.nearby=event.duplicate(true);view.interact()
		check(view.area_id==event.props.destino,"destination of "+source)
		check(view.player==Vector2(event.props.chegada_u+.5,event.props.chegada_v+.5),"arrival of "+source)
		view.load_area(source)
	view.queue_free();await process_frame
	print("INDUSTRIAL ",goals.size()," targets; ",trips," trips; ",frames," frames; ",failures.size()," failures")
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
		check(view.model.clear_segment(behind,view.follower),label+" follower crossed blocker")
		check((view.player_root.position+view.avatar.position).distance_to(view.model.project(view.player))<.02,label+" player feet")
		check((view.follower_root.position+view.companion.position).distance_to(view.model.project(view.follower))<.02,label+" follower feet")
	check(view.player.distance_to(goal)<.02,label+" stopped before destination")
	for tick in 30:view._physics_process(1.0/30.0)
	check(view.player.distance_to(view.follower)<1.5,label+" follower left behind")
