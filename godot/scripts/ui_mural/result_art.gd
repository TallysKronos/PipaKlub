extends RefCounted
const T=preload("res://scripts/campaign/ui_tokens.gd")
static var boxes:Dictionary={}
const BANDS={"won":Vector2(.32,.76),"lost":Vector2(.16,.82),"fled":Vector2(.20,.84)}
static func skin(outcome:String) -> StyleBoxTexture:
	if not boxes.has(outcome):
		var box:=StyleBoxTexture.new();box.texture=load("res://assets/ui/mural-v1/results-v1/"+outcome+".png");box.texture_margin_left=330;box.texture_margin_right=300;boxes[outcome]=box
	return boxes[outcome]
static func layout(extent:Vector2,scale:float,outcome:String) -> Dictionary:
	var texture:Texture2D=skin(outcome).texture
	var font:=roundi(44*scale);var height:=T.label().get_height(font)
	var band:Vector2=BANDS[outcome];var density:float=(height+20)/(texture.get_height()*(band.y-band.x))
	var width:=minf(1180,extent.x-48);var rect:=Rect2((extent.x-width)/2,8,width,texture.get_height()*density)
	var safe:=Rect2(rect.position+Vector2(330*density+10,rect.size.y*band.x),Vector2(rect.size.x-630*density-20,rect.size.y*(band.y-band.x)))
	return {"rect":rect,"safe":safe,"density":density,"font":font,"bottom":rect.end.y+T.label().get_height(roundi(18*scale))+30}
static func draw(canvas:CanvasItem,layout:Dictionary,outcome:String) -> void:
	canvas.draw_set_transform(layout.rect.position,0,Vector2.ONE*layout.density);canvas.draw_style_box(skin(outcome),Rect2(Vector2.ZERO,layout.rect.size/layout.density));canvas.draw_set_transform(Vector2.ZERO)
