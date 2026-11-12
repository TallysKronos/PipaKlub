extends SceneTree

const Follow = preload("res://scripts/campaign/companion_follow.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const Motion = preload("res://scripts/campaign/locomotion.gd")
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", label)

func settle() -> void:
	for i in 12: await process_frame

func expect_model(sprite: Sprite2D, model_id: String) -> void:
	check(sprite.visible and sprite.texture != null and sprite.texture.resource_path.ends_with("/" + model_id + ".png"), "equipped texture " + model_id)
	check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "nearest sampling " + model_id)

func expect_scale(sprite: Sprite2D, avatar: Node2D, park_ratio: float, area: String) -> void:
	check(is_equal_approx(sprite.scale.y / avatar.scale.y, park_ratio), "same relative scale in " + area)

func run() -> void:
	root.size = Vector2i(1280, 720)
	check(Follow.ground_pivots.size() >= 178, "all overworld batches in the registry")
	for id: String in Follow.ground_pivots:
		var sheet := Follow.overworld_texture(id)
		check(sheet != null and sheet.get_size() == Vector2(160, 80), "two 80x80 cells " + id)
		var pivot: Variant = Follow.ground_pivots[id]
		var rows: Array = pivot if pivot is Array else [pivot]
		check(rows.size() in [1, 2] and rows.all(func(y): return int(y) in range(1, 80)), "pivot inside cell " + id)

	var folder := ProjectSettings.globalize_path("res://../tmp/companion-qa-" + State.new_id())
	var front := Front.new()
	front.session._store = Store.new(folder)
	front.preferences.storage_path = folder.path_join("preferences.cfg")
	root.add_child(front)
	front.preferences.reduced_motion = true
	var player: Dictionary = front.session.start("slot-1").data.player
	for model_id in ["alvacordo", "farpim", "miralis", "basica", "mata", "azulao"]:
		player.partners.append({"id":model_id, "modelId":model_id, "personalName":model_id, "xp":0, "craftBonus":0})
	player.equippedPartnerId = "alvacordo"
	var point := Checkpoint.make("park-veredas", Checkpoint.spawn("park-veredas"), Checkpoint.SPACE)
	check(front.session.checkpoint(point, player).status == "ok", "prepared isolated campaign save")
	front._show_park()
	await settle()
	expect_model(front.park.companion, "alvacordo")
	check(is_equal_approx(front.park.companion.scale.y, 1.0), "park keeps the reviewed sprite size")
	var park_ratio: float = front.park.companion.scale.y / front.park.avatar.scale.y
	for facing in ["sw", "nw", "ne", "se"]:
		front.park.avatar.facing = facing
		front.park._refresh_positions()
		var pivot_y := 63.0 if facing in ["nw", "ne"] else 65.0
		check(is_equal_approx(front.park.companion.offset.y + pivot_y, 40.0), "Alvacordo planted foot " + facing)

	front._show_collection()
	await settle()
	for button in front.page.find_children("*", "Button", true, false):
		if button.text == "Próxima":
			button.pressed.emit()
			break
	await settle()
	var equipped := false
	for button in front.page.find_children("*", "Button", true, false):
		if button.text == "Escolher parceiro":
			button.pressed.emit()
			equipped = true
			break
	check(equipped and front.session.snapshot().player.equippedPartnerId == "farpim", "team button saves equipped partner")
	front._return_to_game()
	await settle()
	var park = front.park
	expect_model(park.companion, "farpim")
	park.set_physics_process(false)
	for facing in ["sw", "nw", "ne", "se", "w", "e", "n", "s"]:
		park.avatar.facing = facing
		park._refresh_positions()
		check(park.companion.region_rect.position.x == (80 if facing in ["nw", "ne", "n"] else 0), "pose " + facing)
		if facing.length() == 2:
			check(park.companion.flip_h == facing.ends_with("e"), "mirroring " + facing)
	Controls.install(Controls.DEFAULTS)
	Controls.use_keyboard()
	Motion.toggled = true
	var start: Vector2 = park.player
	var follower_start: Vector2 = park.follower
	var target := start
	for id in park.model.graph.get_point_ids():
		var candidate: Vector2 = park.model.graph.get_point_position(id)
		if candidate.distance_to(start) > 3.0 and candidate.distance_to(start) < 9.0 and park.model.path_to(start, candidate).size() > 1:
			target = candidate
			break
	check(target != start and park.walk_to(target), "valid sprint route")
	var max_gap := 0.0
	for i in 180:
		park._physics_process(1.0/60)
		max_gap = maxf(max_gap, park.player.distance_to(park.follower))
		if park.path.is_empty(): break
	check(park.player.distance_to(start) > 2 and park.follower.distance_to(follower_start) > 1, "equipped creature follows player across map")
	check(max_gap < 1.1, "equipped creature keeps up in sprint")
	expect_model(park.companion, "farpim")

	check(front.exploration.equip("miralis").status == "ok", "second equip persisted")
	front._show_park()
	await settle()
	expect_model(front.park.companion, "miralis")
	check(front.park.follower.distance_to(front.park.player) > .6, "map spawn leaves room between the companion and Kael")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var shot := ProjectSettings.globalize_path("res://../tmp/overworld-companions-in-game.png")
		check(root.get_texture().get_image().save_png(shot) == OK, "in-game capture")
	var saved := front.session.snapshot()
	for model_id in ["farpim", "miralis", "alvacordo"]:
		saved.player.equippedPartnerId = model_id
		check(front.session.checkpoint(point, saved.player).status == "ok", "Park checkpoint")
		front._show_park()
		await settle()
		expect_model(front.park.companion, model_id)
		expect_scale(front.park.companion, front.park.avatar, park_ratio, "Park")

		check(front.session.checkpoint({"kind":"world","scene":"morro","position":[528,752]}, saved.player).status == "ok", "Morro checkpoint")
		front._show_morro()
		await settle()
		expect_model(front.park.companion, model_id)
		expect_scale(front.park.companion, front.park.avatar, park_ratio, "Morro")
		front.park.avatar.facing = "nw"
		front.park._refresh()
		check(front.park.companion.region_rect.position.x == 80, "Morro selects the rear pose")

		check(front.session.checkpoint({"kind":"world","scene":"kael-home","position":[900,800]}, saved.player).status == "ok", "home checkpoint")
		front._show_world()
		await settle()
		expect_model(front.room.companion, model_id)
		expect_scale(front.room.companion, front.room.avatar, park_ratio, "home")

		check(front.session.checkpoint({"kind":"world","scene":"quintal","space":"bairro-inicial-v2","position":[10.5,20.5]}, saved.player).status == "ok", "city checkpoint")
		front._show_world()
		for i in 120:
			await process_frame
			if not is_instance_valid(front.scene_loading): break
		expect_model(front.park.partner, model_id)
		expect_scale(front.park.partner, front.park.avatar, park_ratio, "city")

	var starter_sheets := {"basica":"carcara", "mata":"mata-verde", "azulao":"azulao"}
	for model_id in starter_sheets:
		saved.player.equippedPartnerId = model_id
		check(front.session.checkpoint(point, saved.player).status == "ok", "equipped starter " + model_id)
		front._show_park()
		await settle()
		expect_model(front.park.companion, starter_sheets[model_id])
		expect_scale(front.park.companion, front.park.avatar, park_ratio, "starter " + model_id)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var shot := ProjectSettings.globalize_path("res://../tmp/overworld-azulao-in-game.png")
		check(root.get_texture().get_image().save_png(shot) == OK, "starter in-game capture")
	saved.player.erase("equippedPartnerId")
	check(front.session.checkpoint(saved.checkpoint, saved.player).status == "ok", "unequipped fixture saved")
	front._show_park()
	await settle()
	check(not front.park.companion.visible, "no visible substitute when unequipped")

	Motion.toggled = false
	front.queue_free()
	await process_frame
	print("OVERWORLD COMPANIONS ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
