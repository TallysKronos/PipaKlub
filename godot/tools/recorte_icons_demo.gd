extends Control
## Isolated PIP-65 visual lab. No campaign, save slots or preference writes.
const Hud = preload("res://scripts/campaign/hud.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
var capture := false
var selected_family := "kbd"
var remap := false
var use_real_input := false
var family_choice: OptionButton

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Hud.Recorte.install(self,true)
	for arg in OS.get_cmdline_user_args():
		if arg == "--capture": capture = true
		if arg == "--remap-cut=z": remap = true
		if arg.begins_with("--family="): selected_family = arg.trim_prefix("--family=")
	if selected_family not in ["kbd","xbox","ps","switch"]: selected_family = "kbd"
	Controls.install()
	if remap:
		var keys := Controls.bindings.duplicate()
		keys.cut = KEY_Z
		Controls.install(keys)
	set_family(selected_family)
	var backdrop := ColorRect.new()
	backdrop.color = Tokens.TINTA
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,32)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",14)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "RECORTE / SÍMBOLOS PARA JOGAR"
	title.theme_type_variation = "RecorteTitle"
	stack.add_child(title)
	var row := HBoxContainer.new()
	stack.add_child(row)
	family_choice = OptionButton.new()
	for name in ["Teclado","Xbox","PlayStation","Nintendo Switch"]: family_choice.add_item(name)
	family_choice.select(["kbd","xbox","ps","switch"].find(selected_family))
	family_choice.item_selected.connect(func(index: int): set_family(["kbd","xbox","ps","switch"][index]))
	row.add_child(family_choice)
	var remap_button := Button.new()
	remap_button.text = "Corte: Z → Espaço" if remap else "Corte: Espaço → Z"
	remap_button.pressed.connect(func():
		var keys := Controls.bindings.duplicate()
		keys.cut = KEY_Z if keys.cut == KEY_SPACE else KEY_SPACE
		Controls.install(keys)
		remap_button.text = "Corte: Z → Espaço" if keys.cut == KEY_Z else "Corte: Espaço → Z")
	row.add_child(remap_button)
	var real := CheckButton.new()
	real.text = "Usar entrada real"
	real.toggled.connect(func(value: bool): use_real_input = value)
	row.add_child(real)
	var panel := PanelContainer.new()
	stack.add_child(panel)
	var hints := HFlowContainer.new()
	panel.add_child(hints)
	for item in [["interact","Interagir"],["cut","Cortar"],["skill","Habilidade"],["dodge","Esquiva"],["line","Puxão"],["guard","Guarda"],["signature","Assinatura"],["pause","Pausa"]]: Hud.input_hint(hints,item[0],item[1])
	var note := Label.new()
	note.text = "Prévia de símbolos · nenhuma campanha é criada. No controle Switch, A à direita confirma e B embaixo volta. X e Y mantêm as posições físicas das ações."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/recorte-v1/icons/manifest.json"))
	for asset in manifest.assets:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(cell)
		var image := TextureRect.new()
		image.texture = Hud.icon(asset.id,true)
		image.custom_minimum_size = Vector2(96,64)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(image)
		var label := Label.new()
		label.text = asset.id
		label.add_theme_font_size_override("font_size",16)
		cell.add_child(label)
	if capture: snapshot.call_deferred()

func set_family(value: String) -> void:
	selected_family = value
	Controls.gamepad = value != "kbd"
	Controls.family_override = "auto" if value == "kbd" else value
	Controls.events.changed.emit()

func _input(event: InputEvent) -> void:
	if use_real_input: Controls.observe(event)

func snapshot() -> void:
	for frame in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://assets/ui/recorte-v1/mockups/revisao/"
	DirAccess.make_dir_recursive_absolute(directory)
	var filename := "input-"+selected_family+("-remap" if remap else "")
	get_viewport().get_texture().get_image().save_png(directory+filename+".png")
	var metadata := {"family":Controls.family(),"cut_prompt":Controls.prompt("cut"),"cut_glyph":Controls.glyph_id("cut"),"scope":"Isolated visual preview; no physical controller validation"}
	var file := FileAccess.open(directory+filename+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata,"\t"))
	print("PIP-65 visual preview: ",metadata)
	get_tree().quit()
