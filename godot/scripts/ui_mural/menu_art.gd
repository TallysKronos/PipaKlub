extends RefCounted
## Source pixels stay fixed at corners. Only the quiet middle stretches.
const ROOT="res://assets/ui/mural-v1/menus-v2/"
const CUTS={"cloth":[300,220,170,240],"dex":[220,240,150,230],"evolution":[260,230,200,220],"case":[220,220,170,170],"tag":[300,300,140,120]}
static var styles:Dictionary={}
static func density(kind:String) -> float:return .15 if kind=="tag" else .24
static func padding(kind:String) -> Array:
	var result:Array=[]
	for cut in CUTS[kind]:result.append(ceilf(cut*density(kind))+10)
	return result
static func style(kind:String) -> StyleBoxTexture:
	if not styles.has(kind):
		var box:=StyleBoxTexture.new();box.texture=load(ROOT+kind+".png")
		for index in 4:box.set_texture_margin([SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM][index],CUTS[kind][index])
		styles[kind]=box
	return styles[kind]
static func frame(canvas:CanvasItem,rect:Rect2,kind:String) -> void:
	canvas.draw_set_transform(rect.position,0,Vector2.ONE*density(kind));canvas.draw_style_box(style(kind),Rect2(Vector2.ZERO,rect.size/density(kind)));canvas.draw_set_transform(Vector2.ZERO)
