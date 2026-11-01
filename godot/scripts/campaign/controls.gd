extends RefCounted
## Named actions shared by campaign scenes; UI actions remain Godot's own map.
const DEFAULTS := {"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
	"interact": KEY_E, "cut": KEY_SPACE, "skill": KEY_Q, "dodge": KEY_SHIFT,
	"line": KEY_R, "guard": KEY_G, "signature": KEY_F, "map": KEY_M}
const LABELS := {"left": "Mover à esquerda", "right": "Mover à direita", "up": "Mover para cima", "down": "Mover para baixo", "interact": "Interagir", "cut": "Cortar", "skill": "Habilidade", "dodge": "Esquiva / corrida na exploração", "line": "Puxão", "guard": "Guarda", "signature": "Especial", "map": "Mapa"}
const PAD := {"run": JOY_BUTTON_LEFT_STICK, "interact": JOY_BUTTON_A, "cut": JOY_BUTTON_X, "skill": JOY_BUTTON_Y, "dodge": JOY_BUTTON_B, "line": JOY_BUTTON_RIGHT_SHOULDER, "guard": JOY_BUTTON_LEFT_SHOULDER, "signature": JOY_BUTTON_RIGHT_STICK, "map": JOY_BUTTON_BACK}
const RESERVED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_TAB, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
static var bindings: Dictionary = DEFAULTS.duplicate()
static var gamepad := false
static var device_id := -1
static var pad_family := "xbox"
static var ps_generation := 4
static var family_override := "auto"
static var events = preload("res://scripts/campaign/input_events.gd").new()
static var _glyphs: Dictionary = {}
static var _device_families: Dictionary = {}
const PAD_GLYPHS := {"run":"ls", "interact":"south", "cut":"west", "skill":"north", "dodge":"east", "line":"rb", "guard":"lb", "signature":"rs", "map":"back", "pause":"start", "accept":"south", "back":"east"}
const FAMILY_NAMES := {
	"xbox":{"south":"A","east":"B","west":"X","north":"Y","rb":"RB","lb":"LB","rs":"R3","back":"View","start":"Menu","ls":"Analógico"},
	"ps":{"south":"×","east":"○","west":"□","north":"△","rb":"R1","lb":"L1","rs":"R3","back":"Share","start":"Options","ls":"Analógico"},
	"switch":{"south":"B","east":"A","west":"Y","north":"X","rb":"R","lb":"L","rs":"Analógico D","back":"−","start":"+","ls":"Analógico"}}

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

static func install(value: Dictionary = {}) -> void:
	var selected := bindings if value.is_empty() else value
	bindings = selected.duplicate() if validate(selected) else DEFAULTS.duplicate()
	for action in DEFAULTS:
		var name: String = "campaign_" + action
		if not InputMap.has_action(name): InputMap.add_action(name, .2)
		InputMap.action_erase_events(name)
		var key := InputEventKey.new()
		key.physical_keycode = int(bindings[action])
		InputMap.action_add_event(name, key)
	# Share the keyboard dodge key only in exploration; preserve saved keymaps.
	if not InputMap.has_action("campaign_run"):InputMap.add_action("campaign_run")
	InputMap.action_erase_events("campaign_run")
	var run_key := InputEventKey.new()
	run_key.physical_keycode=int(bindings.dodge)
	InputMap.action_add_event("campaign_run",run_key)
	for pair in [["left", KEY_LEFT], ["right", KEY_RIGHT], ["up", KEY_UP], ["down", KEY_DOWN], ["interact", KEY_ENTER]]:
		var key := InputEventKey.new()
		key.physical_keycode = pair[1]
		InputMap.action_add_event("campaign_" + pair[0], key)
	for item in [["left", JOY_AXIS_LEFT_X, -1], ["right", JOY_AXIS_LEFT_X, 1], ["up", JOY_AXIS_LEFT_Y, -1], ["down", JOY_AXIS_LEFT_Y, 1]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = item[1]
		axis.axis_value = item[2]
		InputMap.action_add_event("campaign_" + item[0], axis)
	for device in Input.get_connected_joypads():
		_device_families[device] = classify_pad(Input.get_joy_name(device),int(Input.get_joy_info(device).get("vendor_id",0)))
	_sync_pad_bindings()
	events.changed.emit()

static func configure_device(device: int, name: String, vendor_id: int = 0) -> void:
	_device_families[device] = classify_pad(name,vendor_id)
	_sync_pad_bindings()
	events.changed.emit()

static func remove_device(device: int) -> void:
	_device_families.erase(device)
	_sync_pad_bindings()

static func button_for(action: String, controller_family: String) -> int:
	var button: int = PAD.get(action,{"accept":JOY_BUTTON_A,"back":JOY_BUTTON_B}.get(action,JOY_BUTTON_START))
	if controller_family == "switch" and action in ["interact","dodge","accept","back"]:
		button = JOY_BUTTON_B if button == JOY_BUTTON_A else JOY_BUTTON_A
	return button

static func _sync_pad_bindings() -> void:
	var actions: Dictionary = {"ui_accept":"accept","ui_cancel":"back"}
	for action in PAD: actions["campaign_"+action] = action
	var devices: Array = _device_families.keys() if not _device_families.is_empty() else [-1]
	for input_action in actions:
		if not InputMap.has_action(input_action): InputMap.add_action(input_action)
		for event in InputMap.action_get_events(input_action):
			if event is InputEventJoypadButton: InputMap.action_erase_event(input_action,event)
		for device in devices:
			var controller_family: String = _device_families.get(device,"xbox") if family_override == "auto" else family_override
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = button_for(actions[input_action],controller_family)
			InputMap.action_add_event(input_action,event)

static func classify_pad(name: String, vendor_id: int = 0) -> String:
	var label := name.to_lower()
	if vendor_id == 0x057e or "nintendo" in label or "switch" in label or "joy-con" in label or "pro controller" in label: return "switch"
	if vendor_id == 0x054c or "playstation" in label or "dualsense" in label or "dualshock" in label or "sony" in label or "ps3" in label or "ps4" in label or "ps5" in label: return "ps"
	return "xbox"

static func set_family(value: String) -> void:
	var next := value if value in ["auto","xbox","ps","switch"] else "auto"
	if next == family_override: return
	family_override = next
	_sync_pad_bindings()
	events.changed.emit()

static func use_keyboard() -> void:
	if not gamepad: return
	gamepad = false
	events.changed.emit()

static func family() -> String:
	return "kbd" if not gamepad else pad_family if family_override == "auto" else family_override

static func observe(event: InputEvent) -> void:
	if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > .3):
		var before := family()
		gamepad = true
		device_id = event.device
		if device_id in Input.get_connected_joypads():
			var name := Input.get_joy_name(device_id).to_lower()
			pad_family = classify_pad(name,int(Input.get_joy_info(device_id).get("vendor_id",0)))
			if _device_families.get(device_id,"") != pad_family: configure_device(device_id,name,int(Input.get_joy_info(device_id).get("vendor_id",0)))
			var generation := 5 if "dualsense" in name or "ps5" in name else 3 if "ps3" in name else 4
			if generation != ps_generation:
				ps_generation = generation
				events.changed.emit()
		else:
			pad_family = _device_families.get(device_id,"xbox")
		if family() != before: events.changed.emit()
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed): use_keyboard()

static func direction() -> Vector2:
	return Input.get_vector("campaign_left", "campaign_right", "campaign_up", "campaign_down", .2)

static func held(action: String) -> bool:
	return Input.is_action_pressed("campaign_" + action)

static func pressed(event: InputEvent, action: String) -> bool:
	return event.is_action_pressed("campaign_" + action) and not (event is InputEventKey and event.echo)

static func prompt(action: String) -> String:
	if action=="run" and gamepad:return "L3" if family()!="switch" else "Analógico E"
	if gamepad and family() == "ps" and pad_glyph(action) == "back": return "Create" if ps_generation == 5 else "Select" if ps_generation == 3 else "Share"
	if gamepad and family() == "ps" and action == "pause" and ps_generation == 3: return "Start"
	if gamepad: return FAMILY_NAMES[family()].get(pad_glyph(action),"Analógico")
	var key := key_for(action)
	return "Espaço" if key == KEY_SPACE else OS.get_keycode_string(key)

static func key_for(action: String) -> int:
	if action=="run":return int(bindings.dodge)
	return int(bindings.get(action,{"accept":KEY_ENTER,"back":KEY_ESCAPE,"pause":KEY_ESCAPE}.get(action,KEY_ENTER)))

static func glyph_id(action: String, keyboard: bool = false) -> String:
	if gamepad and not keyboard:
		var id: String = pad_glyph(action)
		if family() == "ps" and id in ["back","start"] and ps_generation != 4: id += "-ps"+str(ps_generation)
		return id
	var key := key_for(action)
	var special := {KEY_SPACE:"space",KEY_ESCAPE:"escape",KEY_ENTER:"enter",KEY_KP_ENTER:"enter",KEY_SHIFT:"shift",KEY_CTRL:"ctrl",KEY_ALT:"alt",KEY_TAB:"tab",KEY_LEFT:"arrow_left",KEY_RIGHT:"arrow_right",KEY_UP:"arrow_up",KEY_DOWN:"arrow_down",KEY_BACKSPACE:"backspace",KEY_DELETE:"delete",KEY_INSERT:"insert",KEY_HOME:"home",KEY_END:"end",KEY_PAGEUP:"page_up",KEY_PAGEDOWN:"page_down"}
	return special.get(key,OS.get_keycode_string(key).to_lower())

static func pad_glyph(action: String) -> String:
	if family() == "switch" and action in ["interact","accept"]: return "east"
	if family() == "switch" and action in ["dodge","back"]: return "south"
	return PAD_GLYPHS.get(action,"ls")

static func glyph(action: String, keyboard: bool = false) -> Texture2D:
	var path := "res://assets/ui/recorte-v1/glyphs/"+("kbd" if keyboard else family())+"/"+glyph_id(action,keyboard)+".svg"
	if not _glyphs.has(path): _glyphs[path] = load(path) if ResourceLoader.exists(path) else null
	return _glyphs[path]

static func cancel(event: InputEvent) -> bool:
	return (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
