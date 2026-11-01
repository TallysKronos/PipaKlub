extends SceneTree
## PIP-130: reuse the existing Theme's control coverage, override Mural semantics.
const T = preload("res://scripts/campaign/ui_tokens.gd")
const ROOT := "res://assets/ui/mural-v1/"
var result: Theme

func texture_box(id:String, content:=Vector4(24,22,24,18)) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(ROOT+"pieces/"+id+".png")
	for side in [SIDE_LEFT,SIDE_RIGHT]: box.set_texture_margin(side,28)
	box.set_texture_margin(SIDE_TOP,36)
	box.set_texture_margin(SIDE_BOTTOM,28)
	box.content_margin_left=content.x; box.content_margin_top=content.y
	box.content_margin_right=content.z; box.content_margin_bottom=content.w
	return box

func flat(color:Color, margin:=8.0) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=color
	box.content_margin_left=margin;box.content_margin_top=margin
	box.content_margin_right=margin;box.content_margin_bottom=margin
	return box

func variation(id:String,base:String) -> void:result.set_type_variation(id,base)

func _initialize() -> void:
	result=load("res://assets/ui/recorte-v1/theme/recorte_theme.tres").duplicate(true)
	result.resource_name="Mural de Kronasta · fundação ilustrada"
	result.default_font=T.text();result.default_font_size=20
	var paper:=texture_box("paper")
	var sun:=texture_box("selected")
	var ink:=texture_box("ink")
	var disabled:=texture_box("paper")
	disabled.modulate_color=T.alpha(T.MURAL_PAPER,.62)
	for type in ["Button","OptionButton","MenuButton","CheckBox","CheckButton"]:
		for state in ["normal","hover","pressed","disabled","focus"]:
			result.set_stylebox(state,type,StyleBoxEmpty.new() if state=="focus" else ink if state=="pressed" else sun if state=="hover" else disabled if state=="disabled" else paper)
		for pair in [["font_color",T.MURAL_INK],["font_hover_color",T.MURAL_INK],["font_pressed_color",T.MURAL_PAPER],["font_hover_pressed_color",T.MURAL_PAPER],["font_disabled_color",T.MURAL_MUTED],["font_focus_color",T.MURAL_INK]]:
			result.set_color(pair[0],type,pair[1])
		result.set_font("font",type,T.label());result.set_font_size("font_size",type,25)
		result.set_constant("icon_max_width",type,64);result.set_constant("h_separation",type,12)
		result.set_constant("outline_size",type,0)
	# Generic native buttons retain a focus outline; MuralButton adds a kite marker
	# and changes the normal face to the full yellow poster when focused.
	var focus:=flat(T.alpha(T.MURAL_INK,0),0)
	focus.border_color=T.MURAL_TEAL;focus.set_border_width_all(3)
	result.set_stylebox("focus","Button",focus)
	variation("MuralButton","Button")
	# Native text reserves the illustration's independent left-hand footprint.
	for state in ["normal","hover","pressed","disabled"]:
		var face:=result.get_stylebox(state,"Button").duplicate() as StyleBoxTexture
		face.content_margin_left=92
		result.set_stylebox(state,"MuralButton",face)
	variation("MuralMintButton","MuralButton")
	var mint:=texture_box("paper");mint.modulate_color=T.MURAL_MINT
	mint.content_margin_left=92
	result.set_stylebox("normal","MuralMintButton",mint)
	variation("MuralInkButton","MuralButton")
	var menu_ink:=ink.duplicate() as StyleBoxTexture;menu_ink.content_margin_left=92
	result.set_stylebox("normal","MuralInkButton",menu_ink)
	result.set_color("font_color","MuralInkButton",T.MURAL_PAPER)
	variation("MuralSunButton","MuralButton")
	var menu_sun:=sun.duplicate() as StyleBoxTexture;menu_sun.content_margin_left=92
	result.set_stylebox("normal","MuralSunButton",menu_sun)
	variation("MuralFocusButton","MuralButton")
	result.set_stylebox("normal","MuralFocusButton",menu_sun)
	result.set_stylebox("focus","MuralButton",StyleBoxEmpty.new())
	result.set_stylebox("focus","MuralFocusButton",StyleBoxEmpty.new())
	for type in ["Label","RichTextLabel","LineEdit","TextEdit","ItemList","TabBar","ProgressBar"]:
		result.set_color("font_color",type,T.MURAL_INK)
		result.set_font_size("font_size",type,20)
	result.set_color("default_color","RichTextLabel",T.MURAL_INK)
	result.set_constant("outline_size","Label",0)
	for pair in [["MuralTitle",T.lettering(),38],["MuralHeading",T.label(),28],["MuralBody",T.text(),20],["MuralCaption",T.text(),18]]:
		variation(pair[0],"Label");result.set_font("font",pair[0],pair[1]);result.set_font_size("font_size",pair[0],pair[2])
	variation("MuralMutedText","Label");result.set_color("font_color","MuralMutedText",T.MURAL_MUTED)
	variation("MuralInverseText","Label");result.set_color("font_color","MuralInverseText",T.MURAL_PAPER)
	variation("MuralErrorText","Label");result.set_color("font_color","MuralErrorText",T.MURAL_RED)
	variation("MuralSuccessText","Label");result.set_color("font_color","MuralSuccessText",T.MURAL_TEAL)
	var content_paper:=texture_box("board-paper",Vector4(48,48,48,32))
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:content_paper.set_texture_margin(side,60)
	for type in ["PanelContainer","PopupPanel","TooltipPanel"]: result.set_stylebox("panel",type,content_paper)
	variation("MuralPaperPanel","PanelContainer");result.set_stylebox("panel","MuralPaperPanel",content_paper)
	var content_ink:=texture_box("board-ink",Vector4(48,48,48,32))
	var content_sun:=texture_box("board-sun",Vector4(48,48,48,32))
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		content_ink.set_texture_margin(side,60);content_sun.set_texture_margin(side,60)
	variation("MuralInkPanel","PanelContainer");result.set_stylebox("panel","MuralInkPanel",content_ink)
	variation("MuralSunPanel","PanelContainer");result.set_stylebox("panel","MuralSunPanel",content_sun)
	variation("MuralTitlePanel","PanelContainer")
	var title:=texture_box("title-paper",Vector4(40,58,32,28))
	title.set_texture_margin(SIDE_TOP,55)
	title.set_texture_margin(SIDE_LEFT,112)
	result.set_stylebox("panel","MuralTitlePanel",title)
	for type in ["LineEdit","TextEdit","ItemList"]:
		result.set_stylebox("normal",type,paper)
		result.set_stylebox("focus",type,focus)
		result.set_color("caret_color",type,T.MURAL_INK)
		result.set_color("font_selected_color",type,T.MURAL_INK)
		result.set_color("selection_color",type,T.MURAL_SUN)
	result.set_color("font_placeholder_color","LineEdit",T.MURAL_MUTED)
	result.set_stylebox("background","ProgressBar",flat(T.alpha(T.MURAL_INK,.18),0))
	result.set_stylebox("fill","ProgressBar",flat(T.MURAL_TEAL,0))
	for pair in [["MuralHullBar",T.MURAL_INK],["MuralEnergyBar",T.MURAL_TEAL],["MuralXPBar",T.MURAL_SUN]]:
		variation(pair[0],"ProgressBar");result.set_stylebox("fill",pair[0],flat(pair[1],0))
	for type in ["HSlider","VSlider","HScrollBar","VScrollBar"]:
		result.set_stylebox("slider" if type.ends_with("Slider") else "scroll",type,flat(T.MURAL_GROUND,0))
		result.set_stylebox("grabber_area" if type.ends_with("Slider") else "grabber",type,flat(T.MURAL_SUN,0))
	for state in ["tab_selected","tab_unselected","tab_hovered","tab_disabled"]:result.set_stylebox(state,"TabBar",sun if state=="tab_selected" else paper)
	for color in ["font_selected_color","font_unselected_color","font_hovered_color"]:result.set_color(color,"TabBar",T.MURAL_INK)
	result.set_color("font_disabled_color","TabBar",T.MURAL_MUTED)
	result.set_stylebox("panel","PopupMenu",content_paper)
	result.set_stylebox("hover","PopupMenu",sun)
	result.set_color("font_color","PopupMenu",T.MURAL_INK)
	result.set_color("font_hover_color","PopupMenu",T.MURAL_INK)
	result.set_color("font_disabled_color","PopupMenu",T.MURAL_MUTED)
	var error:=ResourceSaver.save(result,ROOT+"theme/mural_theme.tres")
	print("MURAL THEME BUILT: ",error)
	quit(error)
