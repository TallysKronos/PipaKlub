extends Control
## Shared PIP-68 action. Drawn in a 112×128 local box, shown at 150×171 at 1080p (approved
## HUD board: large illustrated disc, ring in the action colour, key sticker, cost pill).
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const SIZE := Vector2(150,171)
var action_texture: Texture2D
signal held_changed(held: bool)
var title := "Cortar"
var lock_reason := ""
var selected := false
var active := false
var charge := 0.0
var reduced_motion := false
var icon_id := "attack"
var key_text := ""
var action_id := "cut"
var cooldown := 0.0
var cooldown_peak := 0.0
var was_cooling := false
var ready_flash := 0.0
var cost := 0
var enough_energy := true
func _ready() -> void:
	action_texture = load(Ink.ROOT+"actions-painted-v1/"+icon_id+".png")
	custom_minimum_size = SIZE * get_viewport_rect().size.y / 1080.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
func _process(dt: float) -> void:
	if cooldown > 0: cooldown_peak = maxf(cooldown_peak,cooldown)
	elif was_cooling: ready_flash = .12; cooldown_peak = 0
	was_cooling = cooldown > 0
	ready_flash = maxf(0,ready_flash-dt)
	if ready_flash > 0 or cooldown > 0: queue_redraw()
func regions() -> Dictionary:
	var f := size.y / 128.0
	return {"caption":Rect2(0,108,112,20),"state":Rect2(70,60,32,26),"button":Rect2(4,2,104,100),"factor":f}
const CENTER := Vector2(56,52)
func button_polygon() -> PackedVector2Array:
	# Approved board: illustrated disc with a ring in the action colour; the special is a diamond.
	if action_id == "signature": return PackedVector2Array([CENTER+Vector2(0,-50),CENTER+Vector2(50,0),CENTER+Vector2(0,50),CENTER+Vector2(-50,0)])
	var points := PackedVector2Array()
	for i in 40: points.append(CENTER+Vector2.from_angle(TAU*i/40.0)*48)
	return points

func fill_polygons(progress: float) -> Array[PackedVector2Array]:
	var inset := PackedVector2Array()
	for point in button_polygon(): inset.append(CENTER+(point-CENTER)*.90)
	var y := lerpf(CENTER.y+50,CENTER.y-50,clampf(progress,0,1))
	var band := PackedVector2Array([Vector2(-1,y),Vector2(113,y),Vector2(113,113),Vector2(-1,113)])
	return Geometry2D.intersect_polygons(inset,band)

func _draw() -> void:
	var factor := size.y / 128.0
	var readable:=ceili(14/maxf(.01,factor))
	draw_set_transform(Vector2((size.x-112*factor)/2,0),0,Vector2.ONE*factor)
	var color: Color = Ink.COLORS.get(icon_id,Tokens.CEU)
	var special := action_id=="signature"
	var points := button_polygon()
	var shadow := PackedVector2Array()
	for point in points: shadow.append(point+Vector2(3,4))
	draw_colored_polygon(shadow,Tokens.NANQUIM)
	draw_colored_polygon(points,Tokens.TINTA)
	# Fill stays clipped inside the actual silhouette, including the diamond.
	var progress := charge if charge>0 else 1-cooldown/maxf(.01,cooldown_peak) if cooldown>0 else 0.0
	for polygon in fill_polygons(progress):
		draw_colored_polygon(polygon,Tokens.alpha(Tokens.CEU if charge>0 else color,.32))
	var usable := enough_energy and lock_reason.is_empty()
	var tint := Tokens.UNTINTED if usable and cooldown<=0 else Tokens.alpha(Tokens.UNTINTED,.45)
	# Painted flat manga action art fills the disc; it keeps its own paper, bamboo and colours.
	if action_texture != null: draw_texture_rect(action_texture,Rect2(CENTER-Vector2(40,40),Vector2(80,80)) if not special else Rect2(CENTER-Vector2(36,38),Vector2(72,72)),false,tint)
	points.append(points[0])
	draw_polyline(points,Tokens.NANQUIM,9,true)
	draw_polyline(points,Tokens.CEU if active else Tokens.PAPEL if has_focus() or ready_flash>0 else color if usable else Tokens.TINTA_3,5 if selected or has_focus() or active else 4,true)
	# Separate countdown badge: never mask the centre of the picture or the caption.
	if cooldown>0:
		var badge: Rect2 = regions().state
		draw_rect(badge,Tokens.NANQUIM)
		draw_rect(badge,Tokens.PAPEL,false,2)
		var number := str(ceili(cooldown))
		var nw := Tokens.label().get_string_size(number,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_string(Tokens.label(),Vector2(badge.get_center().x-nw/2,badge.end.y-5),number,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Tokens.PAPEL)
	# Cost pill on the lower rim; coral when the energy is short (not only dimmer).
	var pill := Rect2(CENTER+Vector2(-21,36 if not special else 30),Vector2(42,19))
	draw_rect(pill,Tokens.NANQUIM)
	draw_rect(pill,Tokens.SOL if enough_energy else Tokens.RABIOLA,false,2)
	var bolt := PackedVector2Array([Vector2(8,1),Vector2(2,9),Vector2(7,9),Vector2(4,17),Vector2(13,6),Vector2(8,6)])
	for i in bolt.size(): bolt[i]+=pill.position+Vector2(3,1)
	draw_colored_polygon(bolt,Tokens.SOL if enough_energy else Tokens.RABIOLA)
	draw_string(Tokens.label(),pill.position+Vector2(18,16),str(cost),HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(16,readable),Tokens.PAPEL if enough_energy else Tokens.RABIOLA)
	# Key sticker on the upper-left rim, with the binding the player actually has.
	var glyph := Controls.glyph(action_id)
	# Long keys (Espaço, Shift) get a wider sticker so the glyph stays legible.
	var sticker := Rect2(0,0,32 if glyph==null or glyph.get_width()<=glyph.get_height()*1.3 else 50,28)
	draw_rect(Rect2(sticker.position+Vector2(2,2),sticker.size),Tokens.NANQUIM)
	draw_rect(sticker,Tokens.PAPEL)
	draw_rect(sticker,Tokens.NANQUIM,false,2)
	if glyph != null: draw_texture_rect(glyph,Hud.fit_texture(glyph,sticker.grow(-3)),false)
	else: draw_string(Tokens.label(),Vector2(6,21),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(16,readable),Tokens.NANQUIM)
	var caption := "ESPECIAL" if special else title.to_upper()
	var font_size := maxi(15,readable)
	var w := Tokens.label().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string_outline(Tokens.label(),Vector2((112-w)/2,125),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,5,Tokens.NANQUIM)
	draw_string(Tokens.label(),Vector2((112-w)/2,125),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Tokens.PAPEL)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held_changed.emit(event.pressed)
		accept_event()
	elif event.is_action_pressed("ui_accept") and (event is InputEventJoypadButton or (event is InputEventKey and event.physical_keycode == KEY_ENTER)):
		held_changed.emit(true)
		accept_event()
	elif event.is_action_released("ui_accept") and (event is InputEventJoypadButton or (event is InputEventKey and event.physical_keycode == KEY_ENTER)):
		held_changed.emit(false)
		accept_event()
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_MOUSE_EXIT:
		held_changed.emit(false)
