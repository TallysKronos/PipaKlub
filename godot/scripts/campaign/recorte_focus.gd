extends Control
## Decoration below container measurement. Functional target and text stay native.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
const Marker = preload("res://scripts/campaign/recorte_rabiola.gd")
var target: Control
var reduced_motion := false
var marker: Control
var frame: NinePatchRect
var brush: TextureRect
var active := false
var _tween: Tween

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	add_to_group("recorte_motion")
	if target is PanelContainer and target.theme_type_variation == "RecorteEmptyPanel": return
	if target is PanelContainer:
		frame = NinePatchRect.new()
		frame.texture = Ink.texture("frame-panel")
		frame.draw_center = false
		frame.mouse_filter = MOUSE_FILTER_IGNORE
		frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		for side in ["left","top","right","bottom"]: frame.set("patch_margin_"+side,48)
		add_child(frame)
	if (target is Slider and not target.editable) or (target is CheckBox and target.disabled): target.modulate = Tokens.alpha(Tokens.UNTINTED,.5)
	if not target is PanelContainer:
		marker = Marker.new()
		marker.modulate.a = 0
		add_child(marker)
		target.focus_entered.connect(refresh_focus)
		target.focus_exited.connect(refresh_focus)
		target.mouse_entered.connect(refresh_focus.call_deferred)
		target.mouse_exited.connect(refresh_focus.call_deferred)
		if target is Button and not target is CheckButton and not target is CheckBox:
			target.offset_transform_enabled = true
			# Keep mouse hover boundaries stable during a purely visual focus shift.
			target.offset_transform_visual_only = true
			brush = TextureRect.new()
			brush.texture = Ink.texture("selection-1")
			brush.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			brush.modulate = Tokens.alpha(Tokens.PAPEL,0)
			brush.mouse_filter = MOUSE_FILTER_IGNORE
			brush.show_behind_parent = true
			target.add_child(brush)
			target.button_down.connect(refresh_focus)
			target.button_up.connect(refresh_focus)
	target.resized.connect(layout_art)
	layout_art()
	refresh_focus()

func layout_art() -> void:
	size = target.size
	if frame != null:
		# Keep ink corners at 12 logical pixels regardless of panel height.
		# A taller container must never produce heavier strokes over its text.
		var scale_factor := .25
		frame.scale = Vector2.ONE * scale_factor
		frame.size = size / scale_factor
	if marker != null: marker.position = Vector2(size.x-10,size.y/2-17)
	if brush != null:
		brush.position = Vector2(-8,-7)
		brush.size = size + Vector2(16,14)

func refresh_focus() -> void:
	if marker == null: return
	var disabled: bool = target is BaseButton and target.disabled
	active = not disabled and (target.has_focus() or target.get_global_rect().has_point(target.get_global_mouse_position()))
	if _tween != null: _tween.kill()
	_tween = create_tween().set_parallel(true)
	var duration := .08 if reduced_motion else .12
	if target is Button and not target is CheckButton and not target is CheckBox:
		var displacement := Vector2.ZERO if reduced_motion or not active else Vector2(24,-5)
		if target.is_pressed() and not reduced_motion: displacement += Vector2(4,4)
		_tween.tween_property(target,"offset_transform_position",displacement,duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_tween.tween_property(brush,"modulate:a",1.0 if active else 0.0,duration)
	_tween.tween_property(marker,"modulate:a",1.0 if active else 0.0,duration).set_delay(0 if reduced_motion else .04)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value and target is Button: target.offset_transform_position = Vector2.ZERO
	refresh_focus()
