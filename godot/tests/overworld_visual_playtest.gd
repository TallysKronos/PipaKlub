extends SceneTree
## Deterministic visual run through the production path follower and renderer.
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Follow = preload("res://scripts/campaign/companion_follow.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const Motion = preload("res://scripts/campaign/locomotion.gd")
const MODELS := ["farpim","papisco","azulfazo","capibaluarte","trovareta","alvacordo","aurorastro-jovem","anaconda-young","auriflama","marulume","viuva-young"]
var checks := 0
var failures: Array[String] = []
var report: Array[Dictionary] = []
var front: Control
var evidence: String

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL ",label)

func settle() -> void:
	for i in 8: await process_frame

func run() -> void:
	root.size = Vector2i(1280,720)
	var hybrid_only := "--hybrid-only" in OS.get_cmdline_user_args()
	var models: Array = MODELS
	if hybrid_only:
		models = []
		for id: String in Follow.animation_manifest:
			if Follow.animation_manifest[id].get("art_version", "").begins_with("hybrid-") or Follow.animation_manifest[id].get("art_version", "").begins_with("sheet-"):
				models.append(id)
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--model="):
			models = [argument.trim_prefix("--model=")]
			hybrid_only = true
		elif argument.begins_with("--models="):
			models = Array(argument.trim_prefix("--models=").split(",",false))
			hybrid_only = true
	evidence = ProjectSettings.globalize_path("res://../tmp/overworld-animation-playtest")
	if hybrid_only: evidence = ProjectSettings.globalize_path("res://../tmp/overworld-hybrid/playtest")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence="):
			evidence = ProjectSettings.globalize_path("res://../" + argument.trim_prefix("--evidence="))
	DirAccess.make_dir_recursive_absolute(evidence)
	front = Front.new()
	var save_dir := evidence.path_join("save-" + State.new_id())
	front.session._store = Store.new(save_dir)
	front.preferences.storage_path = save_dir.path_join("preferences.cfg")
	root.add_child(front)
	front.crt_layer.hide()
	front.preferences.reduced_motion = true
	AudioServer.set_bus_mute(0,true)
	Controls.install(Controls.DEFAULTS)
	Controls.use_keyboard()
	var player: Dictionary = front.session.start("slot-1").data.player
	for id in models:
		player.partners.append({"id":id,"modelId":id,"personalName":id,"xp":0,"craftBonus":0})
	for id in models:
		player.equippedPartnerId = id
		var point := Checkpoint.make("park-veredas", Checkpoint.spawn("park-veredas")+Vector2(4,4), Checkpoint.SPACE)
		check(front.session.checkpoint(point,player).status == "ok","save fixture " + id)
		front._show_park()
		await settle()
		var park = front.park
		park.set_physics_process(false)
		park.encounter_grace = 100000
		park.camera.zoom = Vector2.ONE
		park.camera.position_smoothing_enabled = false
		park._refresh_positions()
		var target: Vector2 = park.player
		var route_length := INF
		for vertex in park.model.graph.get_point_ids():
			var candidate: Vector2 = park.model.graph.get_point_position(vertex)
			var delta: Vector2 = candidate - park.player
			if delta.length() < 5 or delta.length() > 9: continue
			var path: Array = park.model.path_to(park.player,candidate)
			if path.size() > 1 and path.size() < route_length:
				target = candidate
				route_length = path.size()
		check(target != park.player, "reachable route " + id)
		var distance := 0.0
		var max_gap := 0.0
		var minimum_alpha := 1.0
		var facings: Array[String] = []
		var frame := 0
		for run_mode in [false,true]:
			Motion.toggled = run_mode
			var destination: Vector2 = target if not run_mode else Checkpoint.resolve(point)
			check(park.walk_to(destination),"route entry " + id + str(run_mode))
			for tick in 240:
				var before: Vector2 = park.player
				park._physics_process(1.0/60)
				distance += before.distance_to(park.player)
				max_gap = maxf(max_gap,park.player.distance_to(park.follower))
				check(park.companion.visible and park.follower_root.visible,"follower remains visible " + id)
				check(park.companion.scale.is_equal_approx(Vector2.ONE * Follow.Avatar.OVERWORLD_SCALE), "native scale in park " + id)
				if not park.avatar.facing in facings: facings.append(park.avatar.facing)
				for obstacle in park.occluders:
					var art = obstacle.get_node_or_null("Art")
					if art != null: minimum_alpha = minf(minimum_alpha,art.modulate.a)
				if tick % (4 if hybrid_only else 12) == 0 and DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var image := root.get_texture().get_image().get_region(Rect2i(430,180,420,280))
					image.save_png(evidence.path_join(id + "-%03d.png" % frame))
					frame += 1
				if park.path.is_empty(): break
				await process_frame
		Motion.toggled = false
		check(distance > 5,"walk and sprint distance " + id)
		check(max_gap < 1.1,"sprint follows within gap " + id)
		for facing in ["sw","nw","ne","se"]:
			park.avatar.facing = facing
			park._refresh_positions()
			var animated: bool = not str(park.companion.get_meta("animation_state", "")).is_empty()
			var rear: bool = facing in ["nw","ne"]
			check(park.companion.region_rect.position.y == (112 if rear else 0) if animated else park.companion.region_rect.position.x == (112 if rear else 0),"direction " + id + facing)
			check(park.companion.flip_h == facing.ends_with("e"),"mirror " + id + facing)
			check(park.companion.offset == Vector2(0,-44),"same pivot " + id + facing)
		var coverage := check_upper_body_occlusion(park,id)
		if (hybrid_only or id == "azulfazo") and DisplayServer.get_name() != "headless":
			# Include a full slow breathing cycle and its return to the first pose.
			for tick in 16:
				Follow.animate(park.companion,.15,0)
				park._refresh_positions()
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().get_region(Rect2i(430,180,420,280)).save_png(evidence.path_join(id + "-idle-%02d.png" % tick))
		report.append({"id":id,"height":Follow.reviewed_sheets[id].height,"distance":distance,"max_gap":max_gap,"directions":facings,"tree_min_alpha_on_route":minimum_alpha,"frames":frame,"upper_body_occlusion":coverage})
	var result := {"checks":checks,"failures":failures,"models":report,"method":"Production walk_to and physics follower, graphical captures when available. Synthetic canopy corner checks the tall/wide footprint."}
	var output := FileAccess.open(evidence.path_join("report.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  "))
	output.close()
	print("OVERWORLD VISUAL PLAYTEST ",checks," checks; ",failures.size()," failures")
	front.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check_upper_body_occlusion(park: Node2D,id: String) -> bool:
	var sprite: Sprite2D = park.companion
	var rect := Rect2i(sprite.region_rect)
	var image := sprite.texture.get_image().get_region(rect)
	var bounds := image.get_used_rect()
	if sprite.flip_h: bounds.position.x = 112 - bounds.end.x
	var local := Rect2(Vector2(bounds.position)-Vector2(56,100),Vector2(bounds.size))
	var raised: Vector2 = park.model.project(park.follower)
	var ground: Vector2 = park.model.project(park.follower,false)
	# Cover the upper body, where the previous fixed 42px proxy missed the sprite.
	var cover := Node2D.new()
	cover.position = Vector2(ground.x,ground.y+8)
	var art := Sprite2D.new()
	art.name = "Art"
	var patch := Image.create(12,12,false,Image.FORMAT_RGBA8)
	patch.fill(Color("#406c42"))
	art.texture = ImageTexture.create_from_image(patch)
	cover.add_child(art)
	park.actors.add_child(cover)
	park.occluders.append(cover)
	var probes: Array[Vector2] = [local.position + Vector2(local.size.x*.5,4)]
	for x in [local.position.x+4,local.end.x-4]:
		if absf(x)>26: probes.append(Vector2(x,local.position.y+local.size.y*.5))
	var faded := true
	for i in probes.size():
		art.position = raised + probes[i] - cover.position
		park._fade_occluders()
		var visible := is_equal_approx(art.modulate.a,.45)
		if local.size.y>42 or i>0: check(visible,"canopy over full body " + id + " probe " + str(i))
		faded = faded and visible
	cover.position.y -= 16
	art.position.y += 16
	park._fade_occluders()
	check(is_equal_approx(art.modulate.a,1.0),"canopy restores opacity behind footprint " + id)
	park.occluders.erase(cover)
	cover.queue_free()
	return faded
