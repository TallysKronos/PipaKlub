extends Control
## Shared presentation clock for the birth and evolution scenes.
signal completed
signal opened

const SPLIT := 1.0
const SEAL := 2.15
const OPEN := 3.0
const END := 4.35
const LIGHT := Color("#e9faff")
const SHARD_COLORS := [Color("#51c9ff"), Color("#2c79e8"), LIGHT]
const Hud = preload("res://scripts/campaign/hud.gd")

var before: Texture2D
var after: Texture2D
var after_frames: Array[AtlasTexture] = []
var reduced_motion := false
var elapsed := 0.0
var finished := false
var flash_art: Texture2D
var shell_art: Texture2D
var creature := TextureRect.new()
var silhouette := ShaderMaterial.new()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = TEXTURE_FILTER_LINEAR
	flash_art = load("res://assets/campaign/soul-reveal-v1/clarao.png")
	shell_art = load("res://assets/campaign/soul-reveal-v1/casulo.png")
	silhouette.shader = preload("res://shaders/soul_reveal.gdshader")
	silhouette.set_shader_parameter("ink", LIGHT)
	creature.material = silhouette
	creature.mouse_filter = MOUSE_FILTER_IGNORE
	creature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	creature.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(creature)
	if before == null:
		elapsed = SPLIT + .35
	if reduced_motion:
		elapsed = END
	_update_creature()

func _process(delta: float) -> void:
	var previous := elapsed
	elapsed += delta
	if previous < OPEN and elapsed >= OPEN:
		opened.emit()
	if not finished and elapsed >= END:
		finished = true
		completed.emit()
	_update_creature()

func _update_creature() -> void:
	var is_revealed := elapsed >= OPEN
	var reveal := smoothstep(OPEN + .05, OPEN + .8, elapsed)
	var dissolve := smoothstep(.68, SPLIT + .32, elapsed)
	creature.texture = after if is_revealed else before
	if is_revealed and not after_frames.is_empty():
		var index := 0 if reduced_motion else int((elapsed - OPEN) * 12.0) % after_frames.size()
		creature.texture = after_frames[index]
	var extent := minf(size.x * .76, size.y * .95)
	var scale_factor := lerpf(.78, 1.0, reveal) if is_revealed else lerpf(1.0, .62, dissolve)
	creature.size = Vector2.ONE * extent * scale_factor
	var bob := 0.0 if reduced_motion else sin(elapsed * 3.0) * 4.0 * reveal
	creature.position = (size - creature.size) * .5 + Vector2(0, bob)
	creature.modulate.a = reveal if is_revealed else 1.0 - dissolve
	silhouette.set_shader_parameter("light_amount", 1.0 - reveal if is_revealed else smoothstep(.15, SPLIT, elapsed))
	silhouette.set_shader_parameter("coverage", reveal if is_revealed else 1.0 - dissolve)
	queue_redraw()

func _draw() -> void:
	var center := size * .5
	var unit := minf(size.x, size.y)
	var flare := smoothstep(OPEN - .15, OPEN + .18, elapsed)
	if flash_art != null:
		var bounds := Rect2(Vector2.ZERO, size).grow(unit * .16)
		var glow := flare * (.81 + .19 * (1.0 - smoothstep(OPEN + .22, END, elapsed)))
		draw_texture_rect(flash_art, Hud.fit_texture(flash_art, bounds), false, Color(1, 1, 1, glow))
	if reduced_motion:
		return
	var formed := smoothstep(SEAL - .65, SEAL, elapsed)
	var burst := smoothstep(OPEN - .05, OPEN + .73, elapsed)
	if shell_art != null and formed > 0.0 and burst < 1.0:
		var shell_size := Vector2(.49, .78) * unit * (1.0 + .035 * sin(elapsed * 12.0))
		var bounds := Hud.fit_texture(shell_art, Rect2(center - shell_size * .5, shell_size))
		if elapsed < OPEN:
			draw_texture_rect(shell_art, bounds, false, Color(1, 1, 1, formed))
		else:
			_draw_shell_pieces(bounds, burst, unit)
	if elapsed < SPLIT - .3 or elapsed > END:
		return
	var gather := smoothstep(SPLIT + .3, SEAL, elapsed)
	var spread := smoothstep(SPLIT - .3, SPLIT + .36, elapsed)
	for i in 22:
		var angle := float(i) * TAU / 22.0
		var direction := Vector2.from_angle(angle + elapsed * (1.0 - gather) * 2.4)
		var orbit := lerpf(unit * .08, unit * (.28 + float(i % 5) * .045), spread)
		var oval := direction * Vector2(.20, .33) * unit
		var point := center + (direction * orbit).lerp(oval, gather) + direction * burst * unit * .70
		var alpha := spread * (1.0 - gather * .95)
		if elapsed >= OPEN:
			alpha = 1.0 - burst
		var tangent := direction.orthogonal()
		var length := float(12 + i % 5 * 7) * (1.0 + burst)
		var color: Color = SHARD_COLORS[i % SHARD_COLORS.size()]
		draw_colored_polygon(PackedVector2Array([
			point + direction * length, point + tangent * 5.0,
			point - direction * length * .43, point - tangent * 3.0
		]), Color(color, alpha * .9))
	var pulse := maxf(0.0, 1.0 - absf(elapsed - OPEN) / .17)
	if pulse > 0:
		draw_circle(center, unit * (.12 + burst * .35), Color(LIGHT, pulse * .60), true, -1.0, true)

func _draw_shell_pieces(bounds: Rect2, burst: float, unit: float) -> void:
	var hub := Vector2(.50, .46)
	var rim := [Vector2.ZERO, Vector2(.48, 0), Vector2(1, 0), Vector2(1, .53),
		Vector2.ONE, Vector2(.57, 1), Vector2(0, 1), Vector2(0, .44)]
	for index in rim.size():
		var uvs := PackedVector2Array([hub, rim[index], rim[(index + 1) % rim.size()]])
		var middle := (uvs[0] + uvs[1] + uvs[2]) / 3.0
		var direction := (middle - hub).normalized()
		var points := PackedVector2Array()
		for uv in uvs:
			var offset := ((uv - middle) * bounds.size).rotated(burst * (.8 if index % 2 == 0 else -.8))
			points.append(bounds.position + middle * bounds.size + offset + direction * burst * unit * .72)
		draw_polygon(points, PackedColorArray([Color(1, 1, 1, 1.0 - burst)]), uvs, shell_art)
