extends PanelContainer
const Hud=preload("res://scripts/campaign/hud.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
static var moved:=false
var subject:Node2D
var movement:Control
func _ready() -> void:
	anchor_top=1;anchor_bottom=1
	offset_left=24;offset_right=400;offset_top=-88;offset_bottom=-24
	theme_type_variation="RecortePromptPanel"
	mouse_filter=MOUSE_FILTER_IGNORE
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);add_child(row)
	movement=Hud.input_hint(row,"left","Mover")
	Hud.input_hint(row,"interact","Interagir")
func _process(_delta:float) -> void:
	if Controls.direction().length_squared()>0:moved=true
	movement.visible=not moved
	visible=is_instance_valid(subject) and subject.can_walk and (not moved or not str(subject.near).is_empty())
