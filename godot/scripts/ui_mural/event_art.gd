extends RefCounted
## Distinct event silhouettes. The decorative end caps never stretch into text.
const ROOT:="res://assets/ui/mural-v1/events-v1/"
static var boxes:Dictionary={}
static func skin(id:String) -> StyleBoxTexture:
	if boxes.has(id):return boxes[id]
	var box:=StyleBoxTexture.new()
	box.texture=load(ROOT+id+".png")
	box.set_texture_margin(SIDE_LEFT,180)
	box.set_texture_margin(SIDE_RIGHT,160)
	box.set_texture_margin(SIDE_TOP,28)
	box.set_texture_margin(SIDE_BOTTOM,28)
	boxes[id]=box
	return box
static func draw(c:CanvasItem,rect:Rect2,id:String) -> void:
	# Art density is set by height, preserving knots and torn ends at wide sizes.
	var density:=density_for(rect,id)
	c.draw_set_transform(rect.position,0,Vector2.ONE*density)
	c.draw_style_box(skin(id),Rect2(Vector2.ZERO,rect.size/density))
	c.draw_set_transform(Vector2.ZERO)
static func content(rect:Rect2,id:String) -> Rect2:
	var density:=density_for(rect,id)
	# Left warning / boss caps sit behind the separate portrait. The teal cue
	# contains a thread knot and therefore reserves its entire illustrated cap.
	var left:float=(280 if id=="crossing" else 180)*density+12
	var right:float=(200 if id=="crossing" else 160)*density+12
	var vertical:=90.0 if id=="boss-warning" else 60.0 if id=="boss-status" else 36.0
	var bottom:=56.0 if id=="crossing" else vertical
	return Rect2(rect.position+Vector2(left,vertical),Vector2(rect.size.x-left-right,rect.size.y-vertical-bottom))
static func density_for(rect:Rect2,id:String) -> float:
	return .42 if id=="crossing" else minf(.65,rect.size.y/220) if id=="boss-status" else clampf(rect.size.y/220,.4,1.2)
