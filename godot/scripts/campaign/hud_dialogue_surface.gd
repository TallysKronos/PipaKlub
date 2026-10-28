extends PanelContainer
## Shared skin for opening, modal speech and the compact lesson coach.
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Art=preload("res://scripts/campaign/recorte_ink.gd")
const EMOTIONS={"suor":"sweat","raiva":"anger","brilho":"sparkle","surpresa":"surprise","duvida":"question","suspiro":"sigh"}
var shouted:=false
func _ready() -> void:
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	var spacing:=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT]:spacing.set_content_margin(side,28)
	for side in [SIDE_TOP,SIDE_BOTTOM]:spacing.set_content_margin(side,20)
	add_theme_stylebox_override("panel",spacing)
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_box(self,size,shouted)
static func draw_box(canvas:CanvasItem,extent:Vector2,shout:bool=false) -> void:
	Ink.plate(canvas,Rect2(Vector2.ZERO,extent),Hud.INK,Hud.PAPER,clampf(extent.y*.2126,12,52))
	if shout:
		for x in range(36,int(extent.x)-20,72):
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x-10,1),Vector2(x,-10),Vector2(x+12,1)]),Hud.PAPER)
static func parse_tags(text:String) -> Dictionary:
	var regex:=RegEx.new()
	regex.compile("\\[(emo|reacao|voz)=([^\\]]+)\\]")
	var result:={"text":text,"emotion":"","reaction":"","shout":false}
	for match_tag in regex.search_all(text):
		var value:String=match_tag.get_string(2)
		match match_tag.get_string(1):
			"emo":result.emotion=EMOTIONS.get(value,"")
			"reacao":result.reaction=value.left(16)
			"voz":result.shout=value=="grito"
	result.text=regex.sub(text,"",true).strip_edges()
	return result
static func text_pages(text:String,font:Font,font_size:int,width:float) -> Array[String]:
	var lines:Array[String]=[]
	var line:=""
	for word in text.replace("\n"," ").split(" ",false):
		var candidate:=word if line.is_empty() else line+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width and not line.is_empty():lines.append(line);line=word
		else:line=candidate
	if not line.is_empty():lines.append(line)
	var result:Array[String]=[]
	for start in range(0,lines.size(),3):result.append("\n".join(lines.slice(start,mini(start+3,lines.size()))))
	if result.is_empty():result.append("")
	return result
