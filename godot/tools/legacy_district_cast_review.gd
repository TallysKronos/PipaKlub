extends SceneTree

const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var player: Dictionary = State.fresh("slot-1").player
	player.journey = {"lesson":5, "phase":"complete"}
	var failures := 0
	var seen := {}
	var selected := OS.get_cmdline_user_args()
	var palafitas := Rules.definition("palafitas")
	var before: Dictionary = player.duplicate(true)
	var champion_scene: String = palafitas.stages[4].scene
	var champion: Dictionary = CP.data(champion_scene).events.filter(func(event): return event.props.get("duel", "") == "palafitas-5")[0]
	var previous: Dictionary = Rules.entry(before, "industrial")
	previous.completed = true
	Rules.store(before, "industrial", previous)
	before.flags[palafitas.startFlag] = true
	if CP.allowed(champion, before, champion_scene):
		printerr("Caio Garça is visible before qualification")
		failures += 1
	for district: Dictionary in Rules.catalog().slice(0, 7):
		var entry: Dictionary = Rules.entry(player, district.id)
		entry.qualification = district.stages.slice(0, 4).map(func(stage): return stage.id)
		Rules.store(player, district.id, entry)
		if not str(district.get("startFlag", "")).is_empty():
			player.flags[district.startFlag] = true
		if not str(district.prerequisiteFlag).is_empty():
			player.flags[district.prerequisiteFlag] = true
		for scene: String in district.stages.map(func(stage): return stage.scene).reduce(func(scenes, id): return scenes if id in scenes else scenes + [id], []):
			var stages: Array = district.stages.filter(func(duel): return duel.scene == scene and (selected.is_empty() or duel.id in selected))
			if stages.is_empty():
				continue
			var view = View.new()
			var spawn := CP.spawn(scene)
			if not selected.is_empty():
				var duel: Dictionary = stages[0]
				for event: Dictionary in CP.data(scene).events:
					if event.props.get("duel", "") == duel.id:
						spawn = CP.safe(scene, Vector2(event.u + 1.5, event.v + .5))
						break
			view.saved_checkpoint = CP.make(scene, spawn, CP.SPACE)
			view.saved_player = player.duplicate(true)
			view.content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
			view.reduced_motion = true
			root.add_child(view)
			view.set_physics_process(false)
			for stage: Dictionary in stages:
				var frames: Array[String] = []
				for actor: Dictionary in view.npc_nodes:
					var event: Dictionary = actor.root.get_meta("event", {})
					if event.get("props", {}).get("duel", "") != stage.id:
						continue
					for sprite in actor.visual.get_children():
						if sprite is Sprite2D and sprite.is_visible_in_tree() and sprite.texture != null:
							if district.id in ["bambuzal", "beira-canal", "feira", "cais", "industrial"] and sprite.region_rect.size != Vector2(64, 64):
								failures += 1
								printerr(stage.id, ": expected a 64×64 isometric frame")
							if district.id in ["bambuzal", "beira-canal", "feira", "cais", "industrial", "palafitas"] and not check_turning(view, actor, sprite, event):
								failures += 1
								printerr(stage.id, ": NPC did not turn through all eight directions")
							var asset: String = sprite.get_meta("pixel_npc", sprite.texture.resource_path)
							frames.append(asset + str(sprite.region_rect))
				var expected := 2 if stage.id == "morro-3" else 1
				if frames.size() != expected:
					failures += 1
					printerr(stage.id, ": expected ", expected, " actors, found ", frames.size())
				for frame: String in frames:
					if seen.has(frame):
						failures += 1
						printerr(stage.id, ": sprite also used by ", seen[frame])
					seen[frame] = stage.id
				print(stage.id, " | ", stage.name, " | ", frames)
			if not selected.is_empty() and DisplayServer.get_name() != "headless":
				view.exploration_hud.objective.text = ""
				view.exploration_hud.objective_panel.hide()
				for i in range(5):
					await process_frame
				await RenderingServer.frame_post_draw
				var file := "res://../documentation/campaign/overworld-sprites/capturas/" + str(stages[0].id) + ".png"
				if root.get_texture().get_image().save_png(file) != OK:
					failures += 1
			view.free()
		entry.completed = true
		entry.champion = "player"
		Rules.store(player, district.id, entry)
	print("District cast failures: ", failures)
	quit(int(failures > 0))

func check_turning(view: View, actor: Dictionary, sprite: Sprite2D, event: Dictionary) -> bool:
	if sprite.texture.get_size() != Vector2(256, 128):
		return false
	var old_player: Vector2 = view.player
	var old_region := sprite.region_rect
	var old_nearby: Dictionary = view.nearby
	var old_paused: bool = view.paused
	view.nearby = event
	view.paused = false
	var correct := true
	# Each offset projects into the corresponding screen octant in the 2:1 grid.
	var offsets := [Vector2(1,1), Vector2(0,1), Vector2(-1,1), Vector2(-1,0),
		Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(1,0)]
	for index in offsets.size():
		view.player = actor.point + offsets[index]
		view.interact()
		var expected := Vector2(index % 4, floori(index / 4.0)) * 64.0
		if sprite.region_rect.position != expected:
			correct = false
	view.player = old_player
	view.nearby = old_nearby
	view.paused = old_paused
	sprite.region_rect = old_region
	return correct