extends "res://scripts/campaign/hud_dialogue_surface.gd"
var title:Label
var body:Label
var short:Label
var portrait:TextureRect
var pinned:=false
var compact:=false
var full_title:=""
var short_title:="Sr. Assis"
var content_column:VBoxContainer
func _ready() -> void:
	set_meta("recorte_decorated",true)
	theme_type_variation="RecorteEmptyPanel"
	var style:=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT]:style.set_content_margin(side,16)
	for side in [SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,12)
	add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	add_child(row)
	portrait=load("res://scripts/campaign/hud_dialogue_portrait.gd").new()
	portrait.texture=load("res://assets/campaign/portrait-assis.png")
	portrait.custom_minimum_size=Vector2(58,74)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var column:=VBoxContainer.new()
	content_column=column
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",6)
	row.add_child(column)
	var heading:=HBoxContainer.new()
	column.add_child(heading)
	title=Label.new()
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font",Hud.font(true))
	title.add_theme_font_size_override("font_size",18)
	title.add_theme_color_override("font_color",Hud.GOLD)
	heading.add_child(title)
	var toggle:=Button.new()
	toggle.text="Dica"
	toggle.toggle_mode=true
	Hud.secondary_button(toggle)
	toggle.add_theme_font_size_override("font_size",14)
	toggle.custom_minimum_size=Vector2(68,32)
	toggle.toggled.connect(func(on:bool):pinned=on)
	heading.add_child(toggle)
	body=Label.new()
	short=Label.new()
	for label in [body,short]:
		label.add_theme_font_size_override("font_size",16)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
	short.hide()
	resized.connect(queue_redraw)
func add_advance(button:Button)->void:
	Hud.focus_space(content_column).add_child(button)
func set_compact(value:bool) -> void:
	compact=value and not pinned
	title.text=short_title if compact else full_title
	body.visible=not compact
	short.visible=compact
	portrait.custom_minimum_size=Vector2(40,42) if compact else Vector2(58,74)
func _draw() -> void:
	draw_box(self,size)
	var tail:=PackedVector2Array([Vector2(28,size.y-2),Vector2(18,size.y+12),Vector2(52,size.y-2)])
	draw_colored_polygon(tail,Hud.INK)
	draw_line(tail[0],tail[1],Hud.PAPER,2,true)
	draw_line(tail[1],tail[2],Hud.PAPER,2,true)
