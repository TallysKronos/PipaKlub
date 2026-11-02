extends SceneTree
## Visual review only: no slot is created or written; not a gameplay test.
const FrontEnd = preload("res://scripts/campaign/front_end.gd")
const State = preload("res://scripts/campaign/state.gd")
const ParkCheckpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Audit = preload("res://tools/ui_margin_audit.gd")
const Paper = preload("res://scripts/ui_mural/paper_layout.gd")
var shot_override:=""

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var shots:PackedStringArray=[]
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):shots=argument.trim_prefix("--shots=").split(",")
	if shots.is_empty():shots.append("")
	for shot in shots:
		shot_override=shot
		await _capture_once()
	quit()

func _capture_once()->void:
	Paper.auditing=true;Paper.audit.clear()
	# Static captures must not inherit a mouse hover/tooltip from the desktop cursor.
	root.gui_disable_input = true
	var shot := "menu"
	var viewport_size := Vector2i(1280, 720)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			shot = argument.trim_prefix("--shot=")
		if argument.begins_with("--width="): viewport_size.x = clampi(argument.trim_prefix("--width=").to_int(), 800, 2560)
		if argument.begins_with("--height="): viewport_size.y = clampi(argument.trim_prefix("--height=").to_int(), 600, 1440)
	var audit := "--audit" in OS.get_cmdline_user_args()
	if not shot_override.is_empty():shot=shot_override
	if shot not in ["settings", "slots", "map", "care", "menu", "controls", "bedroom", "street", "professor", "practice", "workshop", "park", "trail", "clearing", "boss", "live", "impact", "paused", "victory", "victory-unfocused", "defeat", "team", "bag", "pause", "morro", "morro-2", "morro-3", "morro-4", "morro-5", "morro-battle", "morro-dialog", "dex", "evolution", "emblems", "identity", "missions", "kronasta"]:
		quit(1)
		return
	root.size = viewport_size
	var view := FrontEnd.new()
	var sandbox_path:=ProjectSettings.globalize_path("res://../tmp/pip139-capture-"+shot)
	view.session._store=preload("res://scripts/campaign/save_store.gd").new(sandbox_path)
	view.preferences.storage_path=sandbox_path+".cfg"
	view.preferences.audio_levels.master=0
	root.add_child(view)
	view.preferences.crt=false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--text-scale="):view.preferences.text_scale=clampf(argument.trim_prefix("--text-scale=").to_float(),1,1.5)
	view._apply_preferences()
	if "--reduced-motion" in OS.get_cmdline_user_args():view.preferences.reduced_motion=true
	# Review window size must not inherit the user's fullscreen preference.
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	view.preferences.fullscreen = false
	root.size = viewport_size
	await process_frame
	if shot == "controls": view._show_controls()
	if shot == "settings": view._show_settings()
	if shot == "slots": view._show_slots(true)
	if shot not in ["menu", "controls", "settings", "slots"]:
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
			var park_scene := "park-trail" if shot == "trail" else "park-clearing"
			saved.checkpoint = ParkCheckpoint.make(park_scene, ParkCheckpoint.spawn(park_scene), ParkCheckpoint.SPACE)
		elif shot in ["park", "team", "bag", "pause", "map", "care", "dex", "evolution", "emblems", "identity", "missions", "kronasta"]:
			saved.player.journey = {"lesson": 5, "phase": "complete"}
			saved.player.flags.ninaAccepted = true
			saved.player.inventory = {"quest-nina-tail": 1, "rabiola-basica": 2, "rabiola-lacertubo": 1}
			saved.checkpoint = ParkCheckpoint.make("park-veredas", ParkCheckpoint.spawn("park-veredas"), ParkCheckpoint.SPACE)
		elif shot in ["boss", "live", "impact", "paused", "victory", "victory-unfocused", "defeat"]:
			var model = load("res://scripts/campaign/encounter_model.gd").new(saved.player.partners[0])
			if shot in ["live", "impact", "paused"]: model.intro = 0
			if shot in ["victory", "victory-unfocused"]:
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
		if int(saved.player.get("journey",{}).get("lesson",0))>=5:
			preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(saved.player)
			saved.player.flags.pipeiroDocumentsSeen=true
		view.session._snapshot = saved
		if saved.checkpoint.kind=="world" and ParkCheckpoint.MAPS.has(saved.checkpoint.get("scene","")):view._show_park()
		else:view._show_saved()
		# The park opens behind an animated loading cover; wait before switching pages.
		for frame in 600:
			if not view.flow_busy and not is_instance_valid(view.scene_loading): break
			await process_frame
		if shot == "morro-dialog":
			var story: Dictionary = load("res://scripts/campaign/morro_rules.gd").content().stories["morro-3"]
			var text: String = "\n\n".join(story.before.map(func(line): return "%s: %s" % [line[0], line[1]])) + "\n\n" + story.tactic
			view._confirm_park("Juninho e Lia", text, "Vamos voar!", func(): pass)
		if shot == "paused": view.battle.paused = true
		# Alt-tab or a screenshot tool pauses the view on the result screen.
		if shot == "victory-unfocused": view.battle.suspend_actions()
		if shot == "impact":
			# Synthetic confirmed hit in a read-only visual fixture, frozen for inspection.
			view.battle.paused = true
			view.battle.model._apply_hit({"target": view.battle.model.q, "body": false, "damage": 12.0})
		if shot == "pause": view._pause_game()
		if shot in ["team", "bag", "map", "care", "dex", "evolution", "emblems", "identity", "missions", "kronasta"]:
			# Capture uses an in-memory fixture: never attempt to persist its position.
			view._clear()
			if shot == "team": view._show_collection()
			elif shot in ["dex","evolution"]:
				view._show_collection()
				for child in view.get_children():
					if child.get_script()==preload("res://scripts/ui_mural/partner_album.gd"):child.set_mode(shot)
			elif shot=="emblems":view._open_emblem_case()
			elif shot=="identity":view._show_identity()
			elif shot=="missions":view._show_missions()
			elif shot=="kronasta":view._show_kronasta()
			elif shot == "map": view._show_map()
			elif shot == "care": view._show_partner_care("visual-review")
			else: view._show_bag()
	for i in 4:
		await process_frame
	# Let the 450ms reveal and the once-only reward counter settle before review.
	await create_timer(1.3 if shot in ["victory", "victory-unfocused", "defeat"] else .5).timeout
	await RenderingServer.frame_post_draw
	if audit: Audit.report(root, shot + ("" if viewport_size == Vector2i(1280, 720) else "-%dx%d" % [viewport_size.x, viewport_size.y]))
	if audit:
		var glyphs:=0;var faults:=0
		for id in Paper.audit:
			var owner=instance_from_id(id)
			if not is_instance_valid(owner) or not owner.is_inside_tree():continue
			for entry in Paper.audit[id]:
				glyphs+=1
				if not entry.safe.grow(.1).encloses(entry.glyphs):faults+=1;print("PAPER_AUDIT ",JSON.stringify({"shot":shot,"text":entry.text,"glyphs":str(entry.glyphs),"safe":str(entry.safe)}))
		print("PAPER_DONE ",JSON.stringify({"shot":shot,"glyphs":glyphs,"failures":faults,"physical":str(root.size),"logical":str(root.get_visible_rect().size)}))
	var folder := ProjectSettings.globalize_path("res://").get_base_dir().path_join("../tmp/campaign-review").simplify_path()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):folder=argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(folder)
	var suffix := "" if viewport_size == Vector2i(1280, 720) else "-%dx%d" % [viewport_size.x, viewport_size.y]
	var path := folder.path_join(shot + suffix + ".png")
	root.get_texture().get_image().save_png(path)
	print(path)
	view.free()
	await process_frame

