extends SceneTree
## Trailer footage: one shot per run, recorded by Godot's Movie Maker at a fixed frame rate.
##   godot --path godot --resolution 1920x1080 --fixed-fps 30 --write-movie out.avi \
##     -s tools/trailer_capture.gd -- --shot=porto-quebra-mar --secs=8
## Isolated in-memory save (never written to a slot). Walking shots follow waypoints on
## the map's own path; duel shots inject simulated controller input, like
## tools/battle_round_capture.gd. Visual material only, not a gameplay test.
const Front = preload("res://scripts/campaign/front_end.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const QA = preload("res://scripts/campaign/qa_jump.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const MorroModel = preload("res://scripts/campaign/morro_model.gd")
const Controls = preload("res://scripts/campaign/controls.gd")

## Walking shots: QA jump for the story state, scene, start cell and waypoints (cells).
const WALKS := {
	"centro-praca": ["reuniao", "kronasta-centro-a", Vector2(24, 37), [Vector2(24, 30), Vector2(18, 27), Vector2(15, 25), Vector2(14, 21)]],
	"porto-quebra-mar": ["porto", "kronasta-porto-c", Vector2(25, 36), [Vector2(25, 30), Vector2(24, 20), Vector2(25, 15)]],
	"porto-docas": ["porto", "kronasta-porto-b", Vector2(25, 36), [Vector2(25, 30), Vector2(20, 27), Vector2(14, 22), Vector2(12, 14)]],
	"lajes-piscina": ["taina", "kronasta-lajes-b", Vector2(24, 34), [Vector2(24, 29), Vector2(12, 28), Vector2(10, 18)]],
	"bambuzal": ["serra", "kronasta-bambuzal-a", Vector2(-1, -1), []],
	"palafitas": ["serra", "kronasta-palafitas-b", Vector2(-1, -1), []],
	"mirante": ["mirante", "kronasta-mirante-c", Vector2(-1, -1), []],
	"bosque": ["serra", "kronasta-bosque-a", Vector2(-1, -1), []],
	"serra-cume": ["serra", "kronasta-montanha-c", Vector2(-1, -1), []],
}
## Duel shots: scene (sets the arena), rival model, level, boss, name, encounter kind (the
## save validation accepts it: wild species and level band of the region, or the Estádio
## bracket). "titulo" records the title screen with its logo.
const DUELS := {
	"duelo-mirante": ["kronasta-mirante-a", "raio", 42, false, "Vael", "wild"],
	"duelo-serra": ["kronasta-montanha-c", "mata", 30, true, "Navalha", "wild"],
	"duelo-estadio": ["kronasta-estadio-a", "azulao", 50, true, "Jamile", "ruinas-elo"],
	"duelo-centro": ["kronasta-centro-c", "lacertubo", 33, true, "Capanga do Bando", "wild"],
}

var front: Control
var shot := ""
var frames := 0
var limit := 240
var tick := 0
var waypoints: Array = []
var duel := false

func arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="): return a.trim_prefix("--" + name + "=")
	return fallback

func _initialize() -> void:
	shot = arg("shot", "porto-quebra-mar")
	limit = int(float(arg("secs", "8")) * 30)
	call_deferred("setup")

func setup() -> void:
	front = Front.new()
	root.add_child(front)
	front.preferences.reduced_motion = false
	front.preferences.fullscreen = false
	if shot == "titulo":
		print("READY frame=0")
		return
	# The title screen opens a few frames after start; loading before it cancels the load.
	for i in 30: await process_frame
	front.session._store = Store.new("user://trailer-" + State.new_id())
	front.session.start("slot-1")
	var jump: String = WALKS[shot][0] if WALKS.has(shot) else "final"
	var result: Dictionary = QA.install(front.session, jump)
	if result.status != "ok": printerr("salto QA recusado: ", result); quit(1); return
	var player: Dictionary = front.session.snapshot().player
	player.name = "Kael"
	if WALKS.has(shot):
		var spec: Array = WALKS[shot]
		var at: Vector2 = (spec[2] + Vector2(.5, .5)) if spec[2].x >= 0 else CP.spawn(spec[1])
		result = front.session.checkpoint(CP.make(spec[1], at, CP.SPACE), player)
		waypoints = spec[3].map(func(p): return p + Vector2(.5, .5))
	else:
		var spec: Array = DUELS[shot]
		var model := Model.new(player.partners[0], {"modelId": spec[1], "level": spec[2]})
		model.q.boss = spec[3]
		model.q.name = spec[4]
		player.encounter = {"id": State.new_id(), "kind": spec[5], "scene": spec[0], "space": CP.SPACE, "dropRoll": .9, "returnPoint": [24, 30], "rewardXp": 0, "state": model.snapshot()}
		if spec[5] == "ruinas-elo": player.encounter.stadiumRound = 3
		result = front.session.checkpoint({"kind": "encounter"}, player)
		Controls.configure_device(0, "Xbox simulated capture", 1118)
		duel = true
	if result.status != "ok": printerr("cena recusada: ", result); quit(1); return
	front._choose("slot-1", false)
	for i in 20: await process_frame
	print("READY frame=", frames)

func button(action: String, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0; event.button_index = Controls.PAD[action]; event.pressed = pressed
	Input.parse_input_event(event); Controls.observe(event)

func axis(which: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0; event.axis = which; event.axis_value = value
	Input.parse_input_event(event); Controls.observe(event)

func _process(_delta: float) -> bool:
	if front == null: return false
	frames += 1
	if frames >= limit:
		quit(0)
		return false
	tick += 1
	# The virtual screen loses focus, which pauses duels (encounter_view, focus out).
	if duel and front.get("battle") != null and is_instance_valid(front.battle):
		front.battle.paused = false
	# Clean frames for the trailer: exploration without the HUD panels.
	if front.get("park") != null and is_instance_valid(front.park) and is_instance_valid(front.park.get("exploration_hud")):
		front.park.exploration_hud.hide()
	if duel:
		var t := tick / 30.0
		axis(JOY_AXIS_LEFT_X, sin(t * .9) * .85)
		axis(JOY_AXIS_LEFT_Y, cos(t * 1.1) * .65)
		for action in ["cut", "skill", "dodge", "line", "guard", "signature"]:
			if not Controls.PAD.has(action): continue
			var period: int = {"cut": 14, "skill": 90, "dodge": 55, "line": 70, "guard": 40, "signature": 150}[action]
			button(action, tick % period < (6 if action == "guard" else 2))
	elif front.get("park") != null and is_instance_valid(front.park) and front.park.path.is_empty() and not waypoints.is_empty():
		var park = front.park
		var route: PackedVector2Array = park.model.path_to(park.player, waypoints[0])
		waypoints.pop_front()
		if not route.is_empty(): park.path = route
	return false
