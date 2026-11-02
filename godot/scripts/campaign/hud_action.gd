extends Control
## Shared PIP-68 action. Reference volume 112×128 at 1080p; fixed art proportions.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const Ink = preload("res://scripts/campaign/battle_ink.gd")
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var action_texture: Texture2D
var mural:=false
var text_scale:=1.0
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
	custom_minimum_size = Vector2(112,128) * get_viewport_rect().size.y / 1080.0
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
	return {"caption":Rect2(0,112,112,16),"state":Rect2(30,42,52,42),"button":Rect2(0,0,112,112),"factor":f}
func button_polygon() -> PackedVector2Array:
	if action_id == "signature": return PackedVector2Array([Vector2(56,0),Vector2(112,56),Vector2(56,112),Vector2(0,56)])
	# The slanted shape, artwork and caption share the same x=56 center axis.
	return PackedVector2Array([Vector2(22,24),Vector2(108,24),Vector2(90,112),Vector2(4,112)])

func fill_polygons(progress: float) -> Array[PackedVector2Array]:
	var inset := PackedVector2Array()
	var center := Vector2(56,56 if action_id=="signature" else 68)
	for point in button_polygon(): inset.append(center+(point-center)*.90)
	var low := 112.0
	var high := 0.0 if action_id=="signature" else 24.0
	var y := lerpf(low,high,clampf(progress,0,1))
	var band := PackedVector2Array([Vector2(-1,y),Vector2(113,y),Vector2(113,113),Vector2(-1,113)])
	return Geometry2D.intersect_polygons(inset,band)

func _draw() -> void:
	if mural:
		_draw_mural();return
	var factor := size.y / 128.0
	var readable:=ceili(14/maxf(.01,factor))
	draw_set_transform(Vector2((size.x-112*factor)/2,0),0,Vector2.ONE*factor)
	var color: Color = Ink.COLORS.get(icon_id,Tokens.CEU)
	var points := button_polygon()
	draw_colored_polygon(points,Tokens.TINTA)
	# Fill stays clipped inside the actual slanted silhouette, including the diamond.
	var progress := charge if charge>0 else 1-cooldown/maxf(.01,cooldown_peak) if cooldown>0 else 0.0
	for polygon in fill_polygons(progress):
		draw_colored_polygon(polygon,Tokens.alpha(Tokens.CEU if charge>0 else color,.32))
	points.append(points[0])
	draw_polyline(points,Tokens.NANQUIM,7,true)
	draw_polyline(points,Tokens.CEU if active else Tokens.PAPEL if has_focus() or ready_flash>0 else color if selected else Tokens.TINTA_3,3,true)
	var tint := Tokens.UNTINTED if enough_energy and lock_reason.is_empty() else Tokens.alpha(Tokens.UNTINTED,.4)
	# Painted flat manga action art; preserve its own paper, bamboo and action colors.
	var special := action_id=="signature"
	if action_texture != null: draw_texture_rect(action_texture,Rect2(20,12,72,72) if special else Rect2(18,24,76,76),false,tint)
	# Separate countdown badge: never mask the central picture or the caption.
	if cooldown>0:
		draw_rect(Rect2(25,31,24,23),Tokens.NANQUIM)
		draw_string(Tokens.label(),Vector2(32,49),str(ceili(cooldown)),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Tokens.PAPEL)
	# Cost stays inside the button; energy no longer resembles an external charge bar.
	var cost_color := Tokens.PAPEL if enough_energy else Tokens.RABIOLA
	var shift := Vector2(4,-13 if special else 0)
	draw_line(Vector2(32,101)+shift,Vector2(73,101)+shift,Tokens.TINTA_3,1,true)
	var bolt := PackedVector2Array([Vector2(43,92),Vector2(37,100),Vector2(42,100),Vector2(39,108),Vector2(48,97),Vector2(43,97)])
	for i in bolt.size(): bolt[i]+=shift
	draw_colored_polygon(bolt,Tokens.SOL if enough_energy else Tokens.RABIOLA)
	draw_string(Tokens.label(),Vector2(51,107)+shift,str(cost),HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(17,readable),cost_color)
	# Glyph and caption never share the cooldown region. Keep the configured glyph native.
	draw_rect(Rect2(77,13,34,7),color)
	var glyph := Controls.glyph(action_id)
	if glyph != null: draw_texture_rect(glyph,Hud.fit_texture(glyph,Rect2(79,0,31,31)),false)
	else: draw_string(Tokens.label(),Vector2(78,18),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(17,readable),Tokens.PAPEL)
	var caption := "ESPECIAL" if action_id=="signature" else title.to_upper()
	var font_size := maxi(18,readable)
	var w := Tokens.label().get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string_outline(Tokens.label(),Vector2((112-w)/2,126),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Tokens.NANQUIM)
	draw_string(Tokens.label(),Vector2((112-w)/2,126),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Tokens.PAPEL)
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

func _draw_mural() -> void:
	var paper=preload("res://scripts/ui_mural/paper_layout.gd")
	paper.begin(self)
	var scale:=text_scale
	var box:=Rect2(0,10,size.x,size.y-10)
	paper.frame(self,box,"MuralSunPanel" if selected or has_focus() else "MuralPaperPanel",.30)
	var safe:Rect2=paper.content(box,.30)
	var title_h:float=paper.height(roundi(18*scale))
	var state_h:float=paper.height(roundi(14*scale))
	var art_h:=safe.size.y-title_h-state_h-12
	var icon_size:=minf(safe.size.x,art_h)
	var icon_box:=Rect2(safe.position+Vector2((safe.size.x-icon_size)/2,0),Vector2.ONE*icon_size)
	paper.record(self,icon_box,safe,"action_icon")
	var tint:=Tokens.UNTINTED if enough_energy and lock_reason.is_empty() else Tokens.alpha(Tokens.UNTINTED,.4)
	if action_texture!=null:draw_texture_rect(action_texture,Hud.fit_texture(action_texture,icon_box),false,tint)
	var glyph:=Controls.glyph(action_id)
	if glyph!=null:draw_texture_rect(glyph,Hud.fit_texture(glyph,Rect2(size.x-30,0,28,28)),false)
	else:draw_string(Tokens.label(),Vector2(size.x-28,20),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Tokens.MURAL_INK)
	paper.label(self,Rect2(safe.position+Vector2(0,art_h+6),Vector2(safe.size.x,title_h)),title,roundi(18*scale),Tokens.MURAL_INK,true,safe)
	var state:=lock_reason if not lock_reason.is_empty() else "Sem energia" if not enough_energy else "%ds"%ceili(cooldown) if cooldown>0 else "%d energia"%cost
	paper.label(self,Rect2(safe.position+Vector2(0,art_h+title_h+12),Vector2(safe.size.x,state_h)),state,roundi(14*scale),Tokens.MURAL_RED if not enough_energy else Tokens.MURAL_INK,true,safe)
	if charge>0:draw_line(Vector2(safe.position.x,size.y-5),Vector2(safe.position.x+safe.size.x*charge,size.y-5),Tokens.MURAL_TEAL,3,true)
	if has_focus():draw_line(Vector2(safe.position.x,size.y-3),Vector2(safe.end.x,size.y-3),Tokens.MURAL_INK,3,true)
