extends SceneTree
## Visual review only: no slot is created or written; not a gameplay test.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var shot := "menu"
	var viewport_size := Vector2i(1280, 720)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			shot = argument.trim_prefix("--shot=")
		if argument.begins_with("--width="): viewport_size.x = clampi(argument.trim_prefix("--width=").to_int(), 800, 2560)
		if argument.begins_with("--height="): viewport_size.y = clampi(argument.trim_prefix("--height=").to_int(), 600, 1440)
	if shot not in ["menu", "controls", "bedroom", "street", "professor", "practice", "workshop", "park", "trail", "clearing", "boss", "live", "impact", "paused", "victory", "defeat", "team", "bag", "pause", "morro", "morro-2", "morro-3", "morro-4", "morro-5", "morro-battle", "morro-dialog"]:
		quit(1)
		return
	root.size = viewport_size
	var view := FrontEnd.new()
	root.add_child(view)
	# Review window size must not inherit the user's fullscreen preference.
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	view.preferences.fullscreen = false
	root.size = viewport_size
	await process_frame
	if shot == "controls": view._show_controls()
	if shot not in ["menu", "controls"]:
		var saved := State.fresh("slot-1")
		saved.player.partners = [{"id": "visual-review", "modelId": "rabbito", "personalName": "Rabbito", "xp": 0, "condition": {"line": 100, "structure": 100}}]
		saved.player.equippedPartnerId = "visual-review"
		saved.player.journey = {"lesson": 0, "phase": "practice"}
		if shot.begins_with("morro"):
			saved.player.journey = {"lesson": 5, "phase": "complete"}
			var scene: String = "morro" if shot == "morro" or shot == "morro-battle" or shot == "morro-dialog" else shot.replace("morro-", "morro-area-")
			var map: Dictionary = load("res://scripts/campaign/morro.gd").maps()[scene]
			saved.checkpoint = {"kind": "world", "scene": scene, "position": map.spawn}
			if shot == "morro-battle":
				var model = load("res://scripts/campaign/morro_model.gd").new(saved.player.partners[0], "morro-3")
				model.intro = 0
				model.tick(.016, {})
				saved.player.encounter = {"kind": "morro", "state": model.snapshot()}
				saved.checkpoint = {"kind": "encounter"}
		elif shot == "bedroom":
			saved.checkpoint = {"kind": "opening", "step": 5}
		elif shot in ["street", "professor"]:
			saved.checkpoint = {"kind": "world", "scene": "quintal" if shot == "street" else "professor-home", "position": [480, 768] if shot == "street" else [1056, 1232]}
		elif shot == "practice":
			saved.checkpoint = {"kind": "practice", "lesson": 0}
		elif shot in ["trail", "clearing"]:
			saved.player.journey = {"lesson": 5, "phase": "complete"}
			saved.checkpoint = {"kind": "world", "scene": "park-trail" if shot == "trail" else "park-clearing", "position": [336, 784]}
		elif shot in ["park", "team", "bag", "pause"]:
			saved.player.journey = {"lesson": 5, "phase": "complete"}
			saved.player.flags.ninaAccepted = true
			saved.player.inventory = {"quest-nina-tail": 1, "rabiola-basica": 2, "rabiola-lacertubo": 1}
			saved.checkpoint = {"kind": "world", "scene": "park-veredas", "position": [1160, 366]}
		elif shot in ["boss", "live", "impact", "paused", "victory", "defeat"]:
			var model = load("res://scripts/campaign/encounter_model.gd").new(saved.player.partners[0])
			if shot in ["live", "impact", "paused"]: model.intro = 0
			if shot == "victory":
				model.outcome = "won"
				model.intro = 0
				model.q.hp = 0
			if shot == "defeat":
				model.outcome = "lost"
				model.intro = 0
				model.p.hp = 0
			saved.player.encounter = {"kind": "lacertubo", "state": model.snapshot()}
			saved.checkpoint = {"kind": "encounter"}
		else:
			var model = load("res://scripts/campaign/workshop_model.gd").new()
			saved.player.workshop = {"seed": 7, "state": model.run}
			saved.checkpoint = {"kind": "workshop"}
		view.session._snapshot = saved
		view._show_saved()
		if shot == "morro-dialog":
			var story: Dictionary = load("res://scripts/campaign/morro_rules.gd").content().stories["morro-3"]
			var text: String = "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]])) + "\n\n" + story.tactic
			view._confirm_park("Juninho e Lia", text, "Vamos voar!", func(): pass)
		if shot == "paused": view.battle.paused = true
		if shot == "impact":
			# Synthetic confirmed hit in a read-only visual fixture, frozen for inspection.
			view.battle.paused = true
			view.battle.model._apply_hit({"target": view.battle.model.q, "body": false, "damage": 12.0})
		if shot == "pause": view._pause_game()
		if shot in ["team", "bag"]:
			# Capture uses an in-memory fixture: never attempt to persist its position.
			view._clear()
			if shot == "team": view._show_collection()
			else: view._show_bag()
	for i in 4:
		await process_frame
	# Let the 450ms reveal and the once-only reward counter settle before review.
	await create_timer(1.3 if shot in ["victory", "defeat"] else .5).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").get_base_dir().path_join("../tmp/campaign-review").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var suffix := "" if viewport_size == Vector2i(1280, 720) else "-%dx%d" % [viewport_size.x, viewport_size.y]
	var path := folder.path_join(shot + suffix + ".png")
	root.get_texture().get_image().save_png(path)
	print(path)
	quit()

