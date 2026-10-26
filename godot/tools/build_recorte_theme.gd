extends SceneTree
## Reproducible Theme builder: palette and font resources come exclusively from PIP-62.
const Tokens = preload("res://scripts/campaign/ui_tokens.gd")
const ROOT := "res://assets/ui/recorte-v1/theme/"
var result := Theme.new()
var styles: Dictionary = {}

func box(id: String, fill: Color, margins: Vector4 = Vector4(22, 12, 22, 12), shadow: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.skew = Vector2(.21, 0)
	style.set_corner_radius_all(0)
	style.set_border_width_all(0)
	style.shadow_color = Tokens.alpha(Tokens.NANQUIM, .9)
	style.shadow_offset = Vector2(6, 6) if shadow else Vector2.ZERO
	style.shadow_size = 0
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	style.resource_name = id
	ResourceSaver.save(style, ROOT + "styles/" + id + ".tres", ResourceSaver.FLAG_CHANGE_PATH)
	styles[id] = style
	return style

func named(id: String) -> StyleBoxFlat:
	return styles[id]

func variation(id: String, base: String) -> void:
	result.set_type_variation(id, base)

func button_type(id: String, fill: Color, text: Color, selected: bool = false) -> void:
	if id != "Button": variation(id, "Button")
	var normal := box(id + "-normal", fill)
	var hover := box(id + "-hover", Tokens.PAPEL)
	var pressed := box(id + "-pressed", Tokens.PAPEL if selected else Tokens.RABIOLA, Vector4(22,12,22,12), false)
	var disabled := box(id + "-disabled", Tokens.TINTA_3)
	result.set_stylebox("normal", id, normal)
	result.set_stylebox("hover", id, hover)
	result.set_stylebox("hover_pressed", id, hover)
	result.set_stylebox("focus", id, hover)
	result.set_stylebox("pressed", id, pressed)
	result.set_stylebox("disabled", id, disabled)
	result.set_color("font_color", id, text)
	for state in ["hover", "focus", "pressed", "hover_pressed"]: result.set_color("font_" + state + "_color", id, Tokens.NANQUIM)
	result.set_color("font_disabled_color", id, Tokens.alpha(Tokens.PAPEL_2,.6))
	result.set_font("font", id, Tokens.label())
	result.set_font_size("font_size", id, 24)
	result.set_constant("outline_size", id, 0)
	result.set_constant("h_separation", id, 12)

func marker(id: String) -> Texture2D:
	return load(ROOT + "markers/" + id + ".svg")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "styles"))
	result.resource_name = "Recorte · Theme único"
	result.default_font = Tokens.text()
	result.default_font_size = 22
	button_type("Button", Tokens.RABIOLA, Tokens.NANQUIM)
	button_type("RecorteSecondaryButton", Tokens.TINTA_2, Tokens.PAPEL)
	button_type("RecorteTabButton", Tokens.TINTA_2, Tokens.PAPEL_2, true)
	button_type("RecorteListButton", Tokens.alpha(Tokens.TINTA,0), Tokens.PAPEL, true)
	button_type("RecorteIconButton", Tokens.TINTA_2, Tokens.PAPEL)
	variation("RecortePreviewHover","Button")
	result.set_stylebox("normal","RecortePreviewHover",named("Button-hover"))
	result.set_color("font_color","RecortePreviewHover",Tokens.NANQUIM)
	result.set_color("font_color", "Label", Tokens.PAPEL)
	result.set_color("default_color", "RichTextLabel", Tokens.PAPEL)
	for pair in [["RecortePaperText",Tokens.TINTA],["RecorteMutedText",Tokens.PAPEL_2],["RecorteAccentText",Tokens.CEU],["RecorteGoldText",Tokens.SOL],["RecorteWorldText",Tokens.PAPEL]]:
		variation(pair[0],"Label")
		result.set_color("font_color",pair[0],pair[1])
	result.set_color("font_outline_color","RecorteWorldText",Tokens.NANQUIM)
	result.set_color("font_shadow_color","RecorteWorldText",Tokens.NANQUIM)
	result.set_constant("outline_size","RecorteWorldText",3)
	variation("RecorteTitle","Label")
	result.set_font("font","RecorteTitle",Tokens.display())
	result.set_font_size("font_size","RecorteTitle",42)
	variation("RecorteLettering","Label")
	result.set_font("font","RecorteLettering",Tokens.lettering())
	result.set_font_size("font_size","RecorteLettering",64)
	result.set_constant("outline_size","RecorteLettering",6)
	result.set_color("font_outline_color","RecorteLettering",Tokens.NANQUIM)
	for pair in [["PanelContainer",Tokens.TINTA_2,Vector4(22,16,22,18)],["RecortePaperPanel",Tokens.PAPEL,Vector4(48,16,48,18)],
		["RecorteDialoguePanel",Tokens.TINTA_2,Vector4(22,22,22,20)],["RecorteNamePanel",Tokens.PAPEL,Vector4(22,6,22,6)],
		["RecorteBroadcastPanel",Tokens.TINTA_2,Vector4(22,8,22,10)],["RecorteBattlePanel",Tokens.TINTA,Vector4(28,12,28,12)]]:
		if pair[0] != "PanelContainer": variation(pair[0],"PanelContainer")
		result.set_stylebox("panel",pair[0],box(pair[0],pair[1],pair[2]))
	variation("RecorteEmptyPanel","PanelContainer")
	result.set_stylebox("panel","RecorteEmptyPanel",StyleBoxEmpty.new())
	var track := box("bar-track",Tokens.TINTA_2,Vector4(0,0,0,0),false)
	track.border_color = Tokens.TINTA
	track.set_border_width_all(2)
	ResourceSaver.save(track,ROOT+"styles/bar-track.tres")
	result.set_stylebox("background","ProgressBar",track)
	result.set_stylebox("fill","ProgressBar",box("bar-life",Tokens.FOLHA,Vector4.ZERO,false))
	result.set_font("font","ProgressBar",Tokens.label())
	result.set_color("font_color","ProgressBar",Tokens.PAPEL)
	for pair in [["RecorteXPBar",Tokens.SOL],["RecorteEnergyBar",Tokens.CEU]]:
		variation(pair[0],"ProgressBar")
		result.set_stylebox("fill",pair[0],box(pair[0],pair[1],Vector4.ZERO,false))
	var field := box("field-normal",Tokens.TINTA_2)
	var field_focus := box("field-focus",Tokens.TINTA_2)
	field_focus.border_color = Tokens.CEU
	field_focus.set_border_width_all(3)
	ResourceSaver.save(field_focus,ROOT+"styles/field-focus.tres")
	result.set_stylebox("normal","LineEdit",field)
	result.set_stylebox("focus","LineEdit",field_focus)
	result.set_stylebox("read_only","LineEdit",named("Button-disabled"))
	for key in ["font_color","caret_color"]: result.set_color(key,"LineEdit",Tokens.PAPEL)
	result.set_color("font_placeholder_color","LineEdit",Tokens.PAPEL_2)
	result.set_color("font_uneditable_color","LineEdit",Tokens.alpha(Tokens.PAPEL_2,.6))
	result.set_color("selection_color","LineEdit",Tokens.CEU)
	result.set_color("font_selected_color","LineEdit",Tokens.NANQUIM)
	result.set_font_size("font_size","LineEdit",22)
	result.set_stylebox("panel","ItemList",named("PanelContainer"))
	for state in ["selected","selected_focus","hovered"]: result.set_stylebox(state,"ItemList",named("Button-hover"))
	var focus_ring := box("focus-ring",Tokens.alpha(Tokens.PAPEL,0),Vector4.ZERO,false)
	focus_ring.draw_center=false
	focus_ring.border_color=Tokens.PAPEL
	focus_ring.set_border_width_all(3)
	ResourceSaver.save(focus_ring,ROOT+"styles/focus-ring.tres")
	result.set_stylebox("focus","ItemList",focus_ring)
	result.set_color("font_color","ItemList",Tokens.PAPEL)
	result.set_color("font_selected_color","ItemList",Tokens.NANQUIM)
	result.set_color("font_disabled_color","ItemList",Tokens.alpha(Tokens.PAPEL_2,.6))
	result.set_font("font","ItemList",Tokens.label())
	result.set_constant("v_separation","ItemList",12)
	for state in ["tab_selected","tab_hovered","tab_focus"]: result.set_stylebox(state,"TabBar",named("Button-hover"))
	result.set_stylebox("tab_unselected","TabBar",named("RecorteSecondaryButton-normal"))
	result.set_stylebox("tab_disabled","TabBar",named("Button-disabled"))
	for key in ["font_selected_color","font_hovered_color","font_focus_color"]: result.set_color(key,"TabBar",Tokens.NANQUIM)
	result.set_color("font_unselected_color","TabBar",Tokens.PAPEL_2)
	result.set_color("font_disabled_color","TabBar",Tokens.alpha(Tokens.PAPEL_2,.6))
	result.set_font("font","TabBar",Tokens.label())
	result.set_font_size("font_size","TabBar",24)
	for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]: result.set_stylebox(state,"OptionButton",result.get_stylebox(state,"Button"))
	result.set_font("font","OptionButton",Tokens.label())
	result.set_font_size("font_size","OptionButton",24)
	result.set_color("font_color","OptionButton",Tokens.NANQUIM)
	result.set_stylebox("panel","PopupMenu",named("PanelContainer"))
	result.set_stylebox("hover","PopupMenu",named("Button-hover"))
	result.set_color("font_color","PopupMenu",Tokens.PAPEL)
	result.set_color("font_hover_color","PopupMenu",Tokens.NANQUIM)
	for type in ["HSlider","VSlider"]:
		var slider_track := box(type+"-track",Tokens.TINTA_3,Vector4(0,3,0,3),false)
		result.set_stylebox("slider",type,slider_track)
		result.set_stylebox("grabber_area",type,box(type+"-area",Tokens.CEU,Vector4(0,3,0,3),false))
		result.set_stylebox("grabber_area_highlight",type,box(type+"-area-focus",Tokens.PAPEL,Vector4(0,3,0,3),false))
		result.set_icon("grabber",type,marker("diamond-normal"))
		result.set_icon("grabber_highlight",type,marker("diamond-focus"))
		result.set_icon("grabber_disabled",type,marker("diamond-disabled"))
	for type in ["CheckButton","CheckBox"]:
		for state in ["normal","hover","pressed","hover_pressed","disabled"]: result.set_stylebox(state,type,StyleBoxEmpty.new())
		result.set_stylebox("focus",type,focus_ring)
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]: result.set_color(key,type,Tokens.PAPEL)
		result.set_color("font_disabled_color",type,Tokens.PAPEL_2)
		result.set_font("font",type,Tokens.label())
		for state in ["checked","unchecked","checked_disabled","unchecked_disabled"]:
			result.set_icon(state,type,marker(("toggle-" if type=="CheckButton" else "check-")+("off" if state.begins_with("unchecked") else "on")+("-disabled" if state.ends_with("disabled") else "-normal")))
	for type in ["ScrollBar","HScrollBar","VScrollBar"]:
		result.set_stylebox("scroll",type,box(type+"-track",Tokens.TINTA_2,Vector4(4,4,4,4),false))
		for state in ["grabber","grabber_highlight","grabber_pressed"]: result.set_stylebox(state,type,box(type+"-"+state,Tokens.PAPEL,Vector4(5,5,5,5),false))
		for icon in ["increment","decrement","increment_highlight","decrement_highlight","increment_pressed","decrement_pressed"]: result.set_icon(icon,type,marker("empty"))
	result.set_stylebox("panel","TooltipPanel",box("tooltip",Tokens.PAPEL,Vector4(14,10,14,10)))
	variation("RecorteTooltipPanel","PanelContainer")
	result.set_stylebox("panel","RecorteTooltipPanel",named("tooltip"))
	result.set_color("font_color","TooltipLabel",Tokens.TINTA)
	result.set_font_size("font_size","TooltipLabel",22)
	for type in ["AcceptDialog","ConfirmationDialog"]: result.set_stylebox("panel",type,named("PanelContainer"))
	var window_frame := box("window",Tokens.TINTA_2,Vector4(20,36,20,20))
	window_frame.expand_margin_top=36
	ResourceSaver.save(window_frame,ROOT+"styles/window.tres")
	for key in ["embedded_border","embedded_unfocused_border"]: result.set_stylebox(key,"Window",window_frame)
	result.set_color("title_color","Window",Tokens.PAPEL)
	result.set_font("title_font","Window",Tokens.label())
	for type in ["VBoxContainer","HBoxContainer"]: result.set_constant("separation",type,12)
	var error := ResourceSaver.save(result,ROOT+"recorte_theme.tres")
	print("Recorte Theme export: ",error,"; ",styles.size()," named flat styles")
	quit(error)
