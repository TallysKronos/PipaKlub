extends RefCounted
## Ornament bleed is excluded from content. Density scales the art, never the text.
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const CORNER:=60.0
const CLEARANCE:=8.0
static var audit:Dictionary={}
static var auditing:=false
static func inset(density:float=.45) -> float:return ceilf(CORNER*density+CLEARANCE)
static func content(frame:Rect2,density:float=.45) -> Rect2:return frame.grow(-inset(density))
static func height(font:int) -> float:return ceilf(T.label().get_height(font))
static func frame(c:CanvasItem,rect:Rect2,variant:String="MuralPaperPanel",density:float=.45) -> void:
	c.draw_set_transform(rect.position,0,Vector2.ONE*density)
	c.draw_style_box(Mural.shared().get_stylebox("panel",variant),Rect2(Vector2.ZERO,rect.size/density))
	c.draw_set_transform(Vector2.ZERO)
static func begin(c:CanvasItem) -> void:
	if auditing:audit[c.get_instance_id()]=[]
static func record(c:CanvasItem,rect:Rect2,safe:Rect2,kind:String) -> void:
	if audit.has(c.get_instance_id()):audit[c.get_instance_id()].append({"text":kind,"glyphs":rect,"slot":rect,"safe":safe})
static func label(c:CanvasItem,slot:Rect2,value:String,font:int,color:Color=T.MURAL_INK,center:bool=false,safe:Rect2=Rect2()) -> void:
	var face:=T.label()
	var fitted:=Ink.ellipsis(value,face,font,slot.size.x)
	var width:=face.get_string_size(fitted,HORIZONTAL_ALIGNMENT_LEFT,-1,font).x
	var height:=face.get_height(font)
	var origin:=slot.position+Vector2((slot.size.x-width)/2 if center else 0,(slot.size.y-height)/2+face.get_ascent(font))
	c.draw_string(face,origin,fitted,HORIZONTAL_ALIGNMENT_LEFT,-1,font,color)
	if audit.has(c.get_instance_id()):audit[c.get_instance_id()].append({"text":value,"glyphs":Rect2(origin-Vector2(0,face.get_ascent(font)),Vector2(width,height)),"slot":slot,"safe":safe})
