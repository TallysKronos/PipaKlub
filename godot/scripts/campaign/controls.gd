extends RefCounted
## Named actions shared by campaign scenes; UI actions remain Godot's own map.
const DEFAULTS := {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
	"interact": KEY_E, "cut": KEY_SPACE, "skill": KEY_Q, "dodge": KEY_SHIFT,
	"line": KEY_R, "guard": KEY_G, "signature": KEY_F, "map": KEY_M}
const LABELS := {"left": "Mover à esquerda", "right": "Mover à direita", "up": "Mover para cima", "down": "Mover para baixo", "interact": "Interagir", "cut": "Cortar", "skill": "Habilidade", "dodge": "Esquiva", "line": "Puxão", "guard": "Guarda", "signature": "Assinatura", "map": "Mapa"}
const PAD := {"interact": JOY_BUTTON_A, "cut": JOY_BUTTON_X, "skill": JOY_BUTTON_Y, "dodge": JOY_BUTTON_B, "line": JOY_BUTTON_RIGHT_SHOULDER, "guard": JOY_BUTTON_LEFT_SHOULDER, "signature": JOY_BUTTON_RIGHT_STICK, "map": JOY_BUTTON_BACK}
const PAD_NAMES := {"interact": "A / ×", "cut": "X / □", "skill": "Y / △", "dodge": "B / ○", "line": "RB / R1", "guard": "LB / L1", "signature": "R3", "map": "View / Select"}
const RESERVED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_TAB, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
static var bindings: Dictionary = DEFAULTS.duplicate()
static var gamepad := false

static func validate(value: Variant) -> bool:
	if not value is Dictionary or value.size() != DEFAULTS.size(): return false
	var seen := {}
	for action in DEFAULTS:
		var key: Variant = value.get(action)
		if not (key is int or key is float) or not is_finite(float(key)) or floor(float(key)) != key or key <= 0 or key > 0x1ffffff or key in RESERVED or seen.has(int(key)): return false
		seen[int(key)] = true
	return true

static func conflict(action: String, key: int) -> String:
	if not DEFAULTS.has(action) or key in RESERVED or key <= 0: return "reserved"
	for other in bindings:
		if other != action and bindings[other] == key: return other
	return ""

static func install(value: Dictionary = DEFAULTS) -> void:
	bindings = value.duplicate() if validate(value) else DEFAULTS.duplicate()
	for action in DEFAULTS:
		var name: String = "campaign_" + action
		if not InputMap.has_action(name): InputMap.add_action(name, .2)
		InputMap.action_erase_events(name)
		var key := InputEventKey.new()
		key.physical_keycode = int(bindings[action])
		InputMap.action_add_event(name, key)
		if PAD.has(action):
			var button := InputEventJoypadButton.new()
			button.button_index = PAD[action]
			InputMap.action_add_event(name, button)
	for pair in [["left", KEY_LEFT], ["right", KEY_RIGHT], ["up", KEY_UP], ["down", KEY_DOWN], ["interact", KEY_ENTER]]:
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		InputMap.action_add_event("campaign_" + pair[0], key)
	for item in [["left", JOY_AXIS_LEFT_X, -1], ["right", JOY_AXIS_LEFT_X, 1], ["up", JOY_AXIS_LEFT_Y, -1], ["down", JOY_AXIS_LEFT_Y, 1]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = item[1]
		axis.axis_value = item[2]
		InputMap.action_add_event("campaign_" + item[0], axis)

static func observe(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed: gamepad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > .3: gamepad = true
	elif event is InputEventKey and event.pressed: gamepad = false
	elif event is InputEventMouseButton and event.pressed: gamepad = false

static func direction() -> Vector2:
	return Input.get_vector("campaign_left", "campaign_right", "campaign_up", "campaign_down", .2)

static func held(action: String) -> bool:
	return Input.is_action_pressed("campaign_" + action)

static func pressed(event: InputEvent, action: String) -> bool:
	return event.is_action_pressed("campaign_" + action) and not (event is InputEventKey and event.echo)

static func prompt(action: String) -> String:
	if gamepad: return PAD_NAMES.get(action, "Analógico")
	var key := int(bindings[action])
	return "Espaço" if key == KEY_SPACE else OS.get_keycode_string(key)

static func cancel(event: InputEvent) -> bool:
	return (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
