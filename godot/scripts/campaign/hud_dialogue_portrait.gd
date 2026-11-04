extends TextureRect
## Static halftone lives behind the portrait, never behind functional text.
const Hud=preload("res://scripts/campaign/hud.gd")
const Art=preload("res://scripts/campaign/recorte_ink.gd")
var emotion:=""
var reaction:=""
var active:=true
func _ready() -> void:
	mouse_filter=MOUSE_FILTER_IGNORE
	expand_mode=EXPAND_IGNORE_SIZE
	stretch_mode=STRETCH_KEEP_ASPECT_CENTERED
	var backing:=Control.new()
	backing.show_behind_parent=true
	backing.mouse_filter=MOUSE_FILTER_IGNORE
	add_child(backing)
	backing.draw.connect(func():
		for y in range(10,int(size.y)-10,12):
			for x in range(10,int(size.x)-10,12):backing.draw_circle(Vector2(x,y),1.4,Color(Hud.BLACK,.15*(1-float(y)/maxf(1,size.y)))))
	resized.connect(func():backing.queue_redraw();queue_redraw())
func _draw() -> void:
	if not emotion.is_empty():draw_texture_rect(Art.texture(emotion),Rect2(size.x*.68,10,54,54),false)
	if not reaction.is_empty():
		draw_string_outline(Hud.lettering(),Vector2(10,58),reaction,HORIZONTAL_ALIGNMENT_LEFT,-1,48,4,Hud.BLACK)
		draw_string(Hud.lettering(),Vector2(10,58),reaction,HORIZONTAL_ALIGNMENT_LEFT,-1,48,Hud.PAPER)
