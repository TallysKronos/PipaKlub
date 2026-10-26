extends SceneTree
const Model = preload("res://scripts/overworld/map_model.gd")
const View = preload("res://scripts/overworld/view.gd")
var checks := 0
var failures: Array[String] = []
var areas: Array = []

func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		printerr("FAIL ", text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/index.json"))
	for area in index.areas:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/"+area.id+".json"))
		var model := Model.new()
		model.setup(data)
		var expected_cells: Dictionary = {}
		var expected_edges: Dictionary = {}
		for id in data.oracle.walkable: expected_cells[int(id)] = true
		for edge in data.oracle.edges: expected_edges[str(int(edge[0]))+":"+str(int(edge[1]))] = true
		for v in int(data.h):
			for u in int(data.w):
				var at := Vector2i(u,v)
				check(model.walkable(at)==expected_cells.has(model.key(at)),area.id+" walkable "+str(at))
				for delta in Model.DIRS.values():
					var next: Vector2i = at+delta
					var key := str(model.key(at))+":"+str(model.key(next))
					check(model.can_step(at,next)==expected_edges.has(key),area.id+" edge "+key)
		for probe in data.oracle.heightProbes: check(is_equal_approx(model.height_at(Vector2(probe[0],probe[1])),float(probe[2])),area.id+" continuous ramp")
		for event in data.events:
			if event.type == "entrada":continue
			var candidates := [Vector2(event.u+.5,event.v+.5)]
			for delta in Model.DIRS.values():candidates.append(Vector2(event.u+.5,event.v+.5)+Vector2(delta))
			var reached := false
			for candidate in candidates:
				if model.path_to(Vector2(data.spawn.u+.5,data.spawn.v+.5),candidate).size()>0:reached=true;break
			check(reached,area.id+" event approachable "+event.name)
		areas.append({"id":area.id,"walkable":expected_cells.size(),"directed_edges":expected_edges.size(),"ramp_probes":data.oracle.heightProbes.size()})
	# Instantiate both review modes, and inspect real Godot tile coordinate transforms.
	var view := View.new()
	view.art_preview = true
	root.add_child(view)
	await process_frame
	for area in index.areas:
		view.load_area(area.id)
		await process_frame
		check(view.model.walkable(Vector2i(view.player)),area.id+" valid initial position")
		for layer in view.terrain_layers:
			check(layer.map_to_local(Vector2i(1,0))-layer.map_to_local(Vector2i.ZERO)==Vector2(32,16),"u projects 2:1")
			check(layer.map_to_local(Vector2i(0,1))-layer.map_to_local(Vector2i.ZERO)==Vector2(-32,16),"v projects 2:1")
		view.set_physics_process(false)
		for event in view.model.data.events:
			if event.type not in ["saida","npc"]:continue
			var goal := Vector2(event.u+.5,event.v+.5)
			if not view.model.walkable(Vector2i(goal)):
				for delta in Model.DIRS.values():
					var candidate := goal+Vector2(delta)
					if view.model.path_to(view.player,candidate).size()>0:goal=candidate;break
			var accepted: bool = view.walk_to(goal)
			if view.player.distance_to(goal)<.05:accepted=true
			check(accepted,area.id+" click route accepted")
			for tick in 4000:
				if view.player.distance_to(goal)<.05:break
				view._physics_process(1.0/60.0)
				if tick==3999:check(false,area.id+" controller stalled")
			check(view.player.distance_to(goal)<.05,area.id+" actual controller reaches "+event.name)
			check(view.model.walkable(Vector2i(view.follower)),area.id+" follower stays on walkable ground")
			for tick in 120: view._physics_process(1.0/60.0)
			check(view.follower.distance_to(view.player)<1.5,area.id+" follower catches up at "+event.name)
	view.queue_free()
	await process_frame
	var report := {"checks":checks,"failures":failures,"areas":areas,"scope":"isolated geometry and preview; no campaign saves touched"}
	var path := ProjectSettings.globalize_path("res://../documentation/overworld/reports")
	DirAccess.make_dir_recursive_absolute(path)
	var file := FileAccess.open(path.path_join("geometry.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("OVERWORLD ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
