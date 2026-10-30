extends SceneTree
## Exercises the actual preview movement, not just its path graph. No saves/rewards.

var failures: Array[String] = []
var frames := 0
var trips := 0
var targets := 0

func _initialize() -> void:
	call_deferred("run")

func fail(label: String) -> void:
	if label not in failures:
		failures.append(label)
		printerr("FAIL ",label)

func cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x),floori(point.y))

func walk(view: Node2D, goal: Vector2, label: String) -> void:
	trips += 1
	if view.player.distance_to(goal) < .02: return
	if not view.walk_to(goal):
		fail(label+": no route")
		return
	var ticks := 0
	while not view.path.is_empty() and ticks < 10000:
		var before: Vector2 = view.player
		var behind: Vector2 = view.follower
		view._physics_process(1.0/30.0)
		ticks += 1
		frames += 1
		if not view.model.clear_segment(before,view.player): fail(label+": player crossed blocker")
		if not view.model.clear_segment(behind,view.follower): fail(label+": follower crossed blocker")
		if not view.model.walkable(cell(view.player)): fail(label+": player unsupported")
		if not view.model.walkable(cell(view.follower)): fail(label+": follower unsupported")
		if (view.player_root.position+view.avatar.position).distance_to(view.model.project(view.player)) > .02:
			fail(label+": player feet displaced from surface")
		if (view.follower_root.position+view.companion.position).distance_to(view.model.project(view.follower)) > .02:
			fail(label+": follower feet displaced from surface")
	if view.player.distance_to(goal) > .02: fail(label+": stopped before destination")
	# Allow the follower to finish its last approach; it normally rests .8 cells away.
	for tick in 30: view._physics_process(1.0/30.0)
	if view.follower.distance_to(view.player) > 1.5: fail(label+": follower left behind")

func run() -> void:
	var view: Node2D = load("res://scripts/overworld/view.gd").new()
	view.area_id = "kronasta-bosque-a"
	view.art_preview = true
	root.add_child(view)
	await process_frame
	view.set_physics_process(false)
	var parts := ["a","b","c"]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--part="):
			var selected := argument.trim_prefix("--part=")
			if selected not in parts: fail("invalid part "+selected); quit(1); return
			parts = [selected]
	for part in parts:
		view.load_area("kronasta-bosque-"+part)
		var start: Vector2 = view.player
		var goals: Dictionary = {}
		for event in view.interaction_events:
			if event.type not in ["item","npc","saida","piece"]: continue
			var point := Vector2(event.u+.5,event.v+.5)
			if not view.model.walkable(cell(point)):
				var found := false
				for direction in view.model.DIRS.values():
					var approach: Vector2 = point+Vector2(direction)
					if not view.model.path_to(start,approach).is_empty():
						point=approach
						found=true
						break
				if not found: fail(part+": no approach to "+event.name)
			goals[point] = str(event.type)+" "+str(event.name)
		for v in int(view.model.data.h):
			for u in int(view.model.data.w):
				var c: Dictionary = view.model.cell_at(Vector2i(u,v))
				if c.get("ramp") == null: continue
				var direction: Vector2i = view.model.DIRS[c.ramp]
				var p := Vector2(u+.5,v+.5)
				goals[p] = "ramp "+str(Vector2i(u,v))
				if is_zero_approx(float(c.get("rampFrom",0))): goals[p-Vector2(direction)]="ramp foot"
				if is_equal_approx(float(c.get("rampTo",1)),1.0): goals[p+Vector2(direction)*2]="ramp landing"
		var old_trips := trips
		for goal in goals:
			targets += 1
			var label: String = part+" "+str(goals[goal])+" "+str(goal)
			walk(view,goal,label+" outward")
			walk(view,start,label+" return")
		print("BOSQUE PHYSICS ",part,": ",goals.size()," targets; ",trips-old_trips," trips")
	view.queue_free()
	await process_frame
	print("BOSQUE PHYSICS total: ",targets," targets; ",trips," trips; ",frames," frames; ",failures.size()," failures")
	print("Scope: real preview movement and projected foot support; visual occlusion/controller playtest not asserted; no saves changed")
	quit(0 if failures.is_empty() else 1)
