extends SceneTree
## Scripted player journey: no granted inventory, partner or synthetic victory.
## UI callbacks and actual view controllers are driven with bounded input traces.
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var view: Control
var directory := "user://playthrough-" + State.new_id()
var checks := 0
var failures := 0
var walked := 0.0

func check(value: bool, message: String) -> bool:
	checks += 1
	print(("PASS " if value else "FAIL ") + message)
	if not value: failures += 1
	return value

func freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): freeze(child)

func frame() -> void:
	await process_frame
	if "--pointer-ui" in OS.get_cmdline_user_args():
		if DisplayServer.get_name() != "headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		root.size = Vector2i(1270, 710)
		for index in 3: await process_frame
	freeze(view)
	if "--capture-journey" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var destination := ProjectSettings.globalize_path("res://").path_join("../tmp/player-audit-2026-10-26/journey").simplify_path()
		DirAccess.make_dir_recursive_absolute(destination)
		var checkpoint: Dictionary = view.session.snapshot().get("checkpoint", {})
		var key := str(checkpoint.get("kind", "menu")) + "-" + str(checkpoint.get("scene", checkpoint.get("step", checkpoint.get("lesson", ""))))
		root.get_texture().get_image().save_png(destination.path_join("%03d-%s.png" % [checks, key.validate_filename()]))

func button(node: Node, text: String) -> Button:
	for child in node.get_children():
		# Slots display a short action; the tooltip retains the unique journey label.
		if child is Button and (child.text == text or child.tooltip_text == text): return child
		var found := button(child, text)
		if found != null: return found
	return null

func click(text: String) -> bool:
	var target := button(view, text)
	if not check(target != null and not target.disabled, "button: " + text): return false
	if "--pointer-ui" in OS.get_cmdline_user_args(): return pointer_click(target)
	target.pressed.emit()
	return true

func pointer_click(target: Button) -> bool:
	var rect := target.get_global_rect()
	var visible := rect.intersection(target.get_viewport().get_visible_rect())
	var ancestor := target.get_parent()
	while ancestor != null and ancestor != target.get_viewport():
		if ancestor is Control and ancestor.clip_contents: visible = visible.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	if not check(visible.size.x * visible.size.y >= rect.size.x * rect.size.y * .985, "whole clickable target visible: " + target.text): return false
	var receipt := {"pressed": false}
	target.pressed.connect(func(): receipt.pressed = true, CONNECT_ONE_SHOT)
	var viewport := target.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = rect.get_center()
	if viewport != root:
		motion.position = target.get_screen_transform() * (target.size / 2)
		Input.parse_input_event(motion)
	else: viewport.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = rect.get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		if viewport != root:
			event.position = target.get_screen_transform() * (target.size / 2)
			Input.parse_input_event(event)
		else: viewport.push_input(event, true)
	Input.flush_buffered_events()
	return check(receipt.pressed, "GUI received real pointer click: " + target.text)

func confirm_popup(dialog: Control) -> void:
	while dialog.page_index<dialog.pages.size()-1:dialog.next_page()
	if "--pointer-ui" in OS.get_cmdline_user_args(): pointer_click(dialog.get_ok_button())
	else: dialog.confirmed.emit()

func direction(value: Vector2) -> void:
	for pair in [["left", -value.x], ["right", value.x], ["up", -value.y], ["down", value.y]]:
		if pair[1] > 0: Input.action_press("campaign_" + pair[0], pair[1])
		else: Input.action_release("campaign_" + pair[0])

func segment(room: Node2D, a: Vector2, b: Vector2) -> bool:
	for index in range(ceili(a.distance_to(b) / 6) + 1):
		var amount := minf(1, index * 6 / maxf(1, a.distance_to(b)))
		if not room._safe(a.lerp(b, amount)): return false
	return true

func walk_room(target: Vector2) -> bool:
	var room: Node2D = view.room
	var graph := AStar2D.new()
	var cells := {}
	for rect in room.data.walkable:
		for y in range(int(rect[1]), int(rect[1] + rect[3]) + 1, 32):
			for x in range(int(rect[0]), int(rect[0] + rect[2]) + 1, 32):
				var point := Vector2(roundf(x / 32.0) * 32, roundf(y / 32.0) * 32)
				if cells.has(point) or not room._safe(point): continue
				cells[point] = graph.get_available_point_id()
				graph.add_point(cells[point], point)
	for point: Vector2 in cells:
		for offset in [Vector2(32, 0), Vector2(0, 32), Vector2(32, 32), Vector2(-32, 32)]:
			if cells.has(point + offset) and segment(room, point, point + offset): graph.connect_points(cells[point], cells[point + offset])
	if graph.get_point_count() == 0: return check(false, "room has navigable grid")
	var start := graph.get_closest_point(room.actor)
	var finish := graph.get_closest_point(target)
	var path := graph.get_point_path(start, finish)
	if not segment(room, room.actor, graph.get_point_position(start)): return check(false, "spawn joins navigation")
	if path.is_empty(): return check(false, "route to " + str(target))
	for point in path:
		for tick in 200:
			if room.actor.distance_to(point) < 5: break
			var before: Vector2 = room.actor
			direction((room.project(point) - room.project(room.actor)).normalized())
			room._process(1.0 / 60)
			walked += before.distance_to(room.actor)
			if tick == 199:
				direction(Vector2.ZERO)
				return check(false, "movement stall at " + str(room.actor))
	direction(Vector2.ZERO)
	room._process(0)
	return check(room.actor.distance_to(target) < 110, "walked to " + str(target))

func interact_room(id: String) -> bool:
	for spot in view.room.data.hotspots:
		if spot.id != id: continue
		if not walk_room(Vector2(spot.x, spot.y)): return false
		if not check(view.room.near == id, "proximity: " + id): return false
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		event.pressed = true
		view.room._unhandled_input(event)
		return true
	return check(false, "missing hotspot " + id)

func _initialize() -> void:
	call_deferred("run_journey")

func fixture_path(name: String) -> String:
	var bundled := "res://tests/fixtures/" + name + ".json"
	# Release packs exclude test data. An external runner reads its sibling fixtures.
	return bundled if FileAccess.file_exists(bundled) else get_script().resource_path.get_base_dir().path_join("fixtures").path_join(name + ".json")

func run_journey() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--resume-directory="):
			var folder := argument.trim_prefix("--resume-directory=")
			var pattern := RegEx.create_from_string("^playthrough-[0-9a-f-]{36}$")
			if not check(pattern.search(folder) != null, "isolated resume directory"): return finish()
			directory = "user://" + folder
			await resume_completed_journey()
			return
	print("ISOLATED PLAYTHROUGH: ", ProjectSettings.globalize_path(directory))
	view = Front.new()
	view.session._store = Store.new(directory)
	view.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(view)
	await frame()
	view._show_slots(true)
	await frame()
	if not click("Jornada 1 · Novo jogo"): return finish()
	await frame()
	for step in range(15):
		if not check(view.session.snapshot().checkpoint.step == step, "opening step %d" % step): return finish()
		if step in [3, 11, 13]:
			if not interact_room("desk" if step == 3 else "stairs" if step == 11 else "exit"): return finish()
		elif step == 10:
			view.name_input.text = "Brisa"
			if not click("Confirmar nome"): return finish()
		elif not click("Sair para a rua" if step == 14 else "Avançar"): return finish()
		await frame()
	if not interact_room("professor-home"): return finish()
	await frame()
	if not interact_room("professor"): return finish()
	await frame()
	var tutorial: Array = JSON.parse_string(FileAccess.get_file_as_string(fixture_path("tutorial")))
	for fixture in tutorial:
		var flight: Control
		for child in view.get_children():
			if child.get_script() == view.FlightView: flight = child
		if not check(flight != null, "lesson view %d" % fixture.lesson): return finish()
		var previous_nonce := 0
		for event in fixture.events:
			var input: Dictionary = event.input
			direction(Vector2(input.x, input.y))
			for action in ["cut", "skill", "dodge", "guard"]:
				if input.get(action, false): Input.action_press("campaign_" + action)
				else: Input.action_release("campaign_" + action)
			var nonce: int = input.get("lineNonce", 0)
			if nonce > previous_nonce: Input.action_press("campaign_line")
			else: Input.action_release("campaign_line")
			previous_nonce = nonce
			flight._process(event.dt)
		for action in Controls.DEFAULTS: Input.action_release("campaign_" + action)
		if not check(flight.model.complete, "lesson completed through input %d" % fixture.lesson): return finish()
		if not click(flight.next_button.text): return finish()
		await frame()
	if not click("Carcará"): return finish()
	await frame()
	for child in view.get_children():
		if child.is_in_group("manga_dialogue") and not child.cancel_button_text.is_empty(): confirm_popup(child)
	await frame()
	if not check(view.session.snapshot().checkpoint.kind == "workshop", "workshop started without granted items"): return finish()
	await run_workshop()
	if failures: return finish()
	if not check(view.session.snapshot().player.partners.size() == 2, "starter born from actual workshop"): return finish()
	if not interact_room("exit"): return finish()
	await frame()
	if "--with-morro" in OS.get_cmdline_user_args():
		if not await run_morro(): return finish()
	if not interact_room("park"): return finish()
	await frame()
	check(view.session.snapshot().checkpoint.scene == "park-trail", "reached park after complete opening/training/workshop")
	if "--pointer-ui" in OS.get_cmdline_user_args():
		if not await run_interface_checks(): return finish()
	var before: Dictionary = view.session.snapshot()
	view._return_to_menu()
	await frame()
	view.queue_free()
	await process_frame
	view = Front.new()
	view.session._store = Store.new(directory)
	view.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(view)
	await frame()
	view._show_slots(false)
	await frame()
	if not click("Jornada 1 · Continuar — Kael"): return finish()
	await frame()
	var after: Dictionary = view.session.snapshot()
	check(after.checkpoint.scene == "park-trail", "fresh frontend resumes park")
	check(after.player.partners.size() == 2 and after.player.partners[0].id == before.player.partners[0].id, "restart retains unique partners")
	for scene in ["park-trail", "park-clearing"]:
		if not await walk_park_exit(scene): return finish()
	if not check(view.session.snapshot().checkpoint.scene == "park-veredas", "walked through both initial park maps"): return finish()
	if not await walk_veredas(Vector2(816, 480)): return finish()
	view.park._interact()
	await frame()
	for child in view.get_children():
		if child.is_in_group("manga_dialogue") and not child.cancel_button_text.is_empty(): confirm_popup(child)
	await frame()
	if not check(view.session.snapshot().player.flags.get("ninaAccepted", false), "accepted Nina mission through nearby dialogue"): return finish()
	if not await walk_veredas(Vector2(1300, 154)): return finish()
	view.park._interact()
	await frame()
	for child in view.get_children():
		if child.is_in_group("manga_dialogue") and not child.cancel_button_text.is_empty(): confirm_popup(child)
	await frame()
	if not check(is_instance_valid(view.battle), "boss reached and encounter opened through exploration"): return finish()
	await fight_boss()
	if failures: return finish()
	if not check(view.session.snapshot().player.flags.get("guardianDefeated", false), "actual boss victory persisted"): return finish()
	check(not view.park.guardian.visible, "guardian disappears after actual victory")
	if not await walk_veredas(Vector2(1260, 195)): return finish()
	view.park._interact()
	await frame()
	dismiss_notice()
	await frame()
	if not check(view.session.snapshot().player.flags.get("ninaTail", false), "collected Nina tail from actual boss aftermath"): return finish()
	if not await walk_veredas(Vector2(816, 480)): return finish()
	view.park._interact()
	await frame()
	dismiss_notice()
	await frame()
	check(view.session.snapshot().player.flags.get("ninaReturned", false), "returned Nina tail through nearby dialogue")
	check(view.session.snapshot().player.inventory.get("rabiola-lacertubo", 0) == 1, "guardian own tail remains separate")
	check(not view.session.snapshot().player.inventory.has("quest-nina-tail"), "returned quest item removed")
	view._return_to_menu()
	await frame()
	view._show_slots(false)
	await frame()
	if not click("Jornada 1 · Continuar — Kael"): return finish()
	await frame()
	check(not view.park.guardian.visible and view.session.snapshot().player.flags.get("ninaReturned", false), "completed quest survives save/reload")
	if not await walk_veredas(Vector2(224, 810)): return finish()
	view.park._interact()
	await frame()
	for scene in ["park-clearing", "park-trail"]:
		if not await walk_park_exit(scene, true): return finish()
	if not check(view.session.snapshot().checkpoint.scene == "quintal", "returned from park to street"): return finish()
	if not interact_room("professor-home"): return finish()
	await frame()
	if not interact_room("professor"): return finish()
	await frame()
	dismiss_notice()
	await frame()
	for partner in view.session.snapshot().player.partners:
		check(partner.condition.line == 100 and partner.condition.structure == 100, "professor repaired actual battle wear")
	view._return_to_menu()
	await frame()
	finish()

func resume_completed_journey() -> void:
	view = Front.new()
	view.session._store = Store.new(directory)
	view.preferences.storage_path = directory.path_join("settings.cfg")
	root.add_child(view)
	await frame()
	view._show_slots(false)
	await frame()
	if not click("Jornada 1 · Continuar — Kael"): return finish()
	await frame()
	var saved: Dictionary = view.session.snapshot()
	if not check(saved.checkpoint.kind == "world" and saved.checkpoint.scene in ["park-veredas", "professor-home"], "new process loads actual completed journey"): return finish()
	check(saved.player.partners.size() == 2 and saved.player.partners[0].personalName == "Brisa", "new process retains named partners")
	check(saved.player.flags.get("ninaReturned", false), "new process retains completed mission")
	check(saved.player.flags.get("guardianDefeated", false) and saved.player.flags.get("ninaTail", false), "new process retains boss defeat and collected item")
	check(saved.player.inventory.get("rabiola-lacertubo", 0) == 1 and not saved.player.inventory.has("quest-nina-tail"), "new process retains correct separate rewards")
	if "--with-morro" in OS.get_cmdline_user_args():
		check(saved.player.get("morro", {}).get("stars", {}).size() == 5, "new process retains five Morro victories")
		check(saved.player.inventory.get("rabiola-raio", 0) == 1, "new process retains Mikka unique tail")
	finish()

func dismiss_notice() -> void:
	for child in view.get_children():
		if child.is_in_group("manga_dialogue") and child.cancel_button_text.is_empty(): confirm_popup(child)

func press_key(code: int) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)

func focus_button(text: String) -> bool:
	for step in 30:
		var focused := root.gui_get_focus_owner()
		if focused is Button and focused.text == text: return check(true, "keyboard navigation reaches: " + text)
		press_key(KEY_TAB)
		await frame()
	return check(false, "keyboard navigation reaches: " + text)

func run_interface_checks() -> bool:
	var previous: Vector2 = view.park.player
	if not click("Menu"): return false
	await frame()
	if not check(is_instance_valid(view.pause_overlay) and view.park.paused, "overworld menu pauses actual movement"): return false
	if not click("Mochila"): return false
	await frame()
	press_key(KEY_ESCAPE)
	await frame()
	if not check(is_instance_valid(view.park) and view.park.player == previous, "Escape from bag restores actual parked position"): return false
	if not click("Menu"): return false
	await frame()
	if not click("Configurações"): return false
	await frame()
	var old_crt: bool = view.preferences.crt
	if not click("Filtro de TV (CRT)"): return false
	await frame()
	if not check(view.preferences.crt != old_crt and view.crt_layer.visible == view.preferences.crt, "CRT toggle affects actual renderer"): return false
	if not click("Reduzir animações da interface"): return false
	await frame()
	if not click("Controles"): return false
	await frame()
	var binding_text := "%s · %s" % [Controls.LABELS.cut, OS.get_keycode_string(int(view.preferences.bindings.cut))]
	if not await focus_button(binding_text): return false
	if not click(binding_text): return false
	await frame()
	press_key(KEY_T)
	await frame()
	if not check(view.preferences.bindings.cut == KEY_T and button(view, Controls.LABELS.cut + " · T") != null, "rebind saves and updates displayed key"): return false
	if not click("Restaurar padrão"): return false
	await frame()
	if not check(view.preferences.bindings.cut == KEY_SPACE, "restore input defaults works"): return false
	press_key(KEY_ESCAPE)
	await frame()
	if not check(view.last_scene_key == "page:Configurações", "Escape from key bindings returns to settings"): return false
	press_key(KEY_ESCAPE)
	await frame()
	return check(is_instance_valid(view.park) and view.park.player == previous, "Escape from settings restores actual exploration")

func walk_park_exit(scene: String, backwards: bool = false) -> bool:
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string(fixture_path("park")))
	var path: Array = []
	for fixture in fixtures:
		if fixture.id != scene: continue
		for entry in fixture.paths:
			if entry.path.back() == [1296.0, 400.0]: path = entry.path
	if not check(not path.is_empty(), "canonical path to exit " + scene): return false
	if backwards: path.reverse()
	for point_data in path:
		var point := Vector2(point_data[0], point_data[1])
		for tick in 300:
			if view.session.snapshot().checkpoint.kind == "encounter":
				await frame()
				if not check(is_instance_valid(view.battle), "wild encounter opened during actual walking"): return false
				view.battle.paused = true
				view.battle._physics_process(0)
				await frame()
				if not click("Fugir sem recompensa"): return false
				await frame()
				check(view.session.snapshot().checkpoint.scene == scene, "flee returns to correct route")
			if not is_instance_valid(view.park): return check(false, "unexpected battle on route")
			if view.park.player.distance_to(point) < 4: break
			direction((view.park.project(point) - view.park.project(view.park.player)).normalized())
			view.park._physics_process(1.0 / 60)
			if tick == 299: return check(false, "park route stalled: " + str(view.park.player) + " target=" + str(point) + " safe=" + str(view.park.safe(point)))
	direction(Vector2.ZERO)
	view.park._physics_process(0)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	view.park._unhandled_input(event)
	await frame()
	return check(view.session.snapshot().checkpoint.scene != scene, "used exit after walking " + scene)

func walk_veredas(target: Vector2) -> bool:
	var path: PackedVector2Array = view.park._path(view.park.player, target)
	if not check(not path.is_empty(), "Veredas route to " + str(target)): return false
	for point in path:
		for tick in 500:
			if view.park.player.distance_to(point) < 3: break
			direction(view.park.player.direction_to(point))
			view.park._physics_process(1.0 / 60)
			if tick == 499: return check(false, "Veredas route stalled")
	direction(Vector2.ZERO)
	return check(view.park.player.distance_to(target) < 10, "walked Veredas to " + str(target))

func fight_boss() -> void:
	var battle: Control = view.battle
	battle.paused = false
	for tick in 8000:
		if not battle.model.outcome.is_empty(): break
		var p: Dictionary = battle.model.p
		var q: Dictionary = battle.model.q
		var crossing: Vector2 = Vector2(q.anchor, 585).lerp(Vector2(q.x, q.y), .6)
		var target := Vector2(clampf(p.anchor + (crossing.x - p.anchor) / .7, 55, 945), clampf(585 + (crossing.y - 585) / .7, 70, 480))
		var guard: bool = q.signatureWindup > 0 and q.signatureWindup < .3 and p.guardCooldown <= 0
		if q.signatureWindup > 0 and p.guardCooldown > 0:
			target = Vector2(p.x, p.y) + q.signatureAim.direction_to(Vector2(p.x, p.y) + Vector2(0, -1)) * 200
		direction((target - Vector2(p.x, p.y)).limit_length())
		var contact: Dictionary = battle.model.contact(p, q)
		var cut: bool = contact.get("valid", false) and q.recovery > .1
		for item in [["cut", cut], ["skill", cut and p.energy > 50], ["guard", guard], ["dodge", q.signatureWindup > 0 and q.signatureWindup < .15 and p.guardCooldown > 0 and p.guardTime <= 0]]:
			if item[1]: Input.action_press("campaign_" + item[0])
			else: Input.action_release("campaign_" + item[0])
		battle._physics_process(1.0 / 60)
	for action in Controls.DEFAULTS: Input.action_release("campaign_" + action)
	print("BOSS PLAYTHROUGH RESULT: ", battle.model.outcome, " playerLine=", battle.model.p.hp, " playerHull=", battle.model.p.hull, " bossLine=", battle.model.q.hp, " bossHull=", battle.model.q.hull)
	check(not battle.model.outcome.is_empty(), "boss fight resolves using actual inputs")
	await frame()
	if not click(battle.finish_button.text): return
	await frame()
	check(view.session.snapshot().checkpoint.kind == "world", "returned to exploration after actual battle")

func mouse(workshop: Control, point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = workshop._offset() + point * workshop._scale()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	if "--pointer-ui" in OS.get_cmdline_user_args(): workshop.get_viewport().push_input(event, true)
	else: workshop._gui_input(event)

func run_workshop() -> void:
	var workshop: Control = view.workshop
	workshop.paused = false
	for rod in workshop.model.geometry().rods:
		mouse(workshop, Vector2(820, 250), true)
		mouse(workshop, rod, false)
	if not check(workshop.model.run.stage == 1, "rods placed through view gestures"): return
	for index in 4:
		var point: Vector2 = workshop.model.geometry().points[index]
		mouse(workshop, point, true)
		var window: Array = workshop.model.run.step.windows[index]
		for tick in 500:
			if workshop.model.run.step.fill >= (window[0] + window[1]) / 2: break
			workshop._process(.01)
		mouse(workshop, point, false)
	if not check(workshop.model.run.stage == 2, "knots completed through hold/release"): return
	mouse(workshop, workshop.model.geometry().samples[0], true)
	for point in workshop.model.geometry().samples:
		if workshop.model.run.stage != 2: break
		if "--pointer-ui" in OS.get_cmdline_user_args():
			var motion := InputEventMouseMotion.new()
			motion.position = workshop._offset() + point * workshop._scale()
			workshop.get_viewport().push_input(motion, true)
		else: workshop.cursor = point
		workshop._process(.01)
	mouse(workshop, Vector2(480, 286), false)
	if not check(workshop.model.run.stage == 3, "paper cut through pointer trace"): return
	for tick in 2000:
		if workshop.model.run.stage != 3: break
		var step: Dictionary = workshop.model.run.step
		direction(Vector2(clampf(-step.theta * .25 - step.omega * .15, -1, 1), 0))
		workshop._process(.01)
	direction(Vector2.ZERO)
	if not check(workshop.model.run.stage == 4, "flight balanced through movement input"): return
	mouse(workshop, Vector2(480, 286), true)
	for tick in 500:
		if workshop.model.run.step.fill >= .88: break
		workshop._process(.01)
	mouse(workshop, Vector2(480, 286), false)
	check(workshop.model.run.outcome.get("type") == "born", "soul awakened through hold/release")
	await frame()

func finish() -> void:
	for action in Controls.DEFAULTS: Input.action_release("campaign_" + action)
	print("SCRIPTED JOURNEY: %d checks, %d failures, %.0f room-distance units walked" % [checks, failures, walked])
	if is_instance_valid(view): view.queue_free()
	quit(1 if failures else 0)

func walk_morro(point: Vector2) -> bool:
	var map: Node2D = view.park
	if not check(map.walk_to(point), "click route to " + str(point)): return false
	for tick in 4000:
		if map.player.distance_to(point) < 4: break
		map._physics_process(1.0 / 60)
		if tick == 3999: return check(false, "Morro movement stall " + str(map.player) + " -> " + str(point))
	map._physics_process(0)
	return check(map.player.distance_to(point) < 4, "walked Morro to " + str(point))

func morro_interact(place: Dictionary) -> bool:
	if not await walk_morro(Vector2(place.point[0], place.point[1])): return false
	if not check(view.park.near == place.id, "Morro proximity " + place.name): return false
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	view.park._unhandled_input(event)
	await frame()
	return true

func run_morro() -> bool:
	if not interact_room("morro"): return false
	await frame()
	if not check(view.session.snapshot().checkpoint.scene == "morro", "entered Morro through street hotspot"): return false
	for scene in ["morro", "morro-area-2", "morro-area-3", "morro-area-4", "morro-area-5"]:
		var data: Dictionary = view.park.data
		if not check(data.id == scene, "reached " + scene): return false
		var npc: Dictionary = data.places.filter(func(p): return p.has("stage"))[0]
		if not await morro_interact(npc): return false
		for child in view.get_children():
			if child.is_in_group("manga_dialogue") and not child.cancel_button_text.is_empty(): confirm_popup(child)
		await frame()
		if not check(is_instance_valid(view.battle), "Morro battle starts through dialogue"): return false
		view.battle.paused = false
		var resumed := false
		for tick in 40000:
			var battle: Control = view.battle
			if not battle.model.outcome.is_empty(): break
			var p: Dictionary = battle.model.p
			var rivals: Array = battle.model.actors.slice(1).filter(battle.model.alive)
			if rivals.is_empty():
				battle._physics_process(1.0 / 60)
				continue
			rivals.sort_custom(func(a: Dictionary, b: Dictionary): return a.hp < b.hp)
			var q: Dictionary = rivals[0]
			var crossing := Vector2(q.anchor, 585).lerp(Vector2(q.x, q.y), .6)
			var aim := Vector2(clampf(p.anchor + (crossing.x - p.anchor) / .7, 55, 945), clampf(585 + (crossing.y - 585) / .7, 70, 480))
			direction(((aim - Vector2(p.x, p.y)) / 65).limit_length())
			var cut: bool = battle.model.contact(p, q).get("valid", false)
			for command in [["cut", cut], ["skill", cut and p.energy > 45], ["line", cut and tick % 60 == 0]]:
				if command[1]: Input.action_press("campaign_" + command[0])
				else: Input.action_release("campaign_" + command[0])
			battle._physics_process(1.0 / 60)
			if scene == "morro-area-3" and not resumed and tick > 700:
				var before: Dictionary = battle.model.snapshot()
				view._return_to_menu()
				await frame()
				view._show_slots(false)
				await frame()
				if not click("Jornada 1 · Continuar — Kael"): return false
				await frame()
				if not check(JSON.parse_string(JSON.stringify(view.battle.model.snapshot())) == JSON.parse_string(JSON.stringify(before)), "three-fighter battle resumes exactly"): return false
				view.battle.paused = false
				resumed = true
		for action in Controls.DEFAULTS: Input.action_release("campaign_" + action)
		print("MORRO ACTUAL RESULT ", data.stage, " ", view.battle.model.outcome, " rounds=", view.battle.model.actors.map(func(a): return a.rounds))
		if not check(view.battle.model.outcome == "won", "actual input victory " + data.stage): return false
		await frame()
		if not click(view.battle.finish_button.text): return false
		await frame()
		dismiss_notice()
		await frame()
		if not check(view.session.snapshot().player.get("morro", {}).get("stars", {}).has(data.stage), "victory persists and unlocks passage"): return false
		if not check(not view.park.gate_closed, "gate removed after victory"): return false
		if scene != "morro-area-5":
			var exit_place: Dictionary = data.places.filter(func(p): return p.get("action", "") == "road_next")[0]
			if not await morro_interact(exit_place): return false
	# Test the final exit, re-entry and traversal without replaying cleared fights.
	var final_exit: Dictionary = view.park.data.places.filter(func(p): return p.get("action", "") == "road_next")[0]
	if not await morro_interact(final_exit): return false
	if not check(view.session.snapshot().checkpoint.scene == "quintal", "Mikka exit returns to city"): return false
	if not interact_room("morro"): return false
	await frame()
	for scene in ["morro", "morro-area-2", "morro-area-3", "morro-area-4"]:
		if not check(not view.park.gate_closed, "cleared passage remains open on revisit"): return false
		var next_exit: Dictionary = view.park.data.places.filter(func(p): return p.get("action", "") == "road_next")[0]
		if not await morro_interact(next_exit): return false
	# Return through every cleared area; no teleports or reward injection.
	for scene in ["morro-area-5", "morro-area-4", "morro-area-3", "morro-area-2", "morro"]:
		var data: Dictionary = view.park.data
		var back: Dictionary = data.places.filter(func(p): return p.get("action", "") in ["road_back", "quintal"])[0]
		if not await morro_interact(back): return false
	check(view.session.snapshot().checkpoint.scene == "quintal", "returned from Morro to street")
	check(view.session.snapshot().player.inventory.get("rabiola-raio", 0) == 1, "Mikka tail uses existing workshop recipe")
	return true
