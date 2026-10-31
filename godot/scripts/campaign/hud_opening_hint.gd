extends PanelContainer
const Hud=preload("res://scripts/campaign/hud.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var subject:Node2D
var movement:Label
var objective:Label
var interaction:Control
func _ready() -> void:
	anchor_top=1;anchor_bottom=1
	offset_left=24;offset_right=640;offset_top=-132;offset_bottom=-24
	theme_type_variation="RecortePromptPanel"
	mouse_filter=MOUSE_FILTER_IGNORE
	var column:=VBoxContainer.new();add_child(column)
	objective=Label.new();objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(objective)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",18);column.add_child(row)
	movement=Label.new();row.add_child(movement)
	interaction=Hud.input_hint(row,"interact","Interagir")
	Controls.events.changed.connect(_sync_movement)
	_sync_movement()
	get_viewport().size_changed.connect(_layout)
	_layout()
func _layout() -> void:
	offset_right=minf(640,get_viewport_rect().size.x-24)
func _sync_movement() -> void:
	movement.text="Analógico · Mover" if Controls.gamepad else "%s%s%s%s / setas · Mover"%[Controls.prompt("up"),Controls.prompt("left"),Controls.prompt("down"),Controls.prompt("right")]
func _process(_delta:float) -> void:
	visible=is_instance_valid(subject) and subject.can_walk
	if not visible:return
	objective.text={"desk":"Vá até a mesa para terminar o Rabbito.","stairs":"Leve Rabbito até a escada para descer.","exit":"Vá até a porta para sair de casa."}.get(subject.target_hotspot,"Explore o ambiente.")
	interaction.visible=not str(subject.near).is_empty()
