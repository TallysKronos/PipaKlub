extends PanelContainer
## Fixed-size painted corners; native containers own the safe content region.
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const Art=preload("res://scripts/ui_mural/menu_art.gd")
var family:="":
	set(value):
		family=value
		if is_node_ready():_fit();queue_redraw()
var variant:="MuralPaperPanel"
var density:=.4
func _ready() -> void:
	_fit()
	resized.connect(queue_redraw)
func _fit() -> void:
	var space:=StyleBoxEmpty.new()
	var edges:=[SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]
	for index in 4:space.set_content_margin(edges[index],Art.padding(family)[index] if not family.is_empty() else Paper.inset(density))
	add_theme_stylebox_override("panel",space)
func _draw() -> void:
	if not family.is_empty():Art.frame(self,Rect2(Vector2.ZERO,size),family)
	else:Paper.frame(self,Rect2(Vector2.ZERO,size),variant,density)
