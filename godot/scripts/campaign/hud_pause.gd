extends Control
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Option=preload("res://scripts/ui_mural/dialogue_option.gd")
var text_scale:=1.0
func _init() -> void:set_meta("owns_ui_theme",true)
signal chosen(action:String)
var player:Dictionary={}
var battle_paused:=false
var partner_portrait:Texture2D
var focus_action:="team"
var buttons:Dictionary={}
var canvas:Control
var description:Label
const OPTIONS=[
	["Pipamons","team","team","Gerencie seus Pipamons e cuide dos seus parceiros."],
	["Itens","bag","bag","Consulte materiais, itens e lembranças da jornada."],
	["Missões","missions","missoes","Veja seus objetivos e os próximos passos da aventura."],
	["Emblemas","emblems","tail","Reveja as conquistas contra os chefes de bairro."],
	["Tamer","identity","info","Sua identidade, experiência e história como pipeiro."],
	["Oficina","workshop","line","Confira suas rabiolas e construa novos elos no ateliê."],
	["Salvar","save","save","Guarde a jornada sem sair do lugar."],
	["Config.","settings","settings","Ajuste vídeo, áudio, controles e acessibilidade."]]

class Tile extends Button:
	var text_scale:=1.0
	var art:Texture2D
	var illustrated:=false
	var accent:Color=Hud.CYAN
	var selected:=false
	func _ready() -> void:
		set_meta("recorte_decorated",true)
		for state in ["normal","hover","pressed","focus","disabled"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:add_theme_color_override(state,Color.TRANSPARENT)
		focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		Paper.begin(self)
		var active:bool=has_focus() or is_hovered() or selected
		var rect:=Rect2(8,8,size.x-16,size.y-16)
		Paper.frame(self,rect,"MuralSunPanel" if active else "MuralPaperPanel",.3)
		if art!=null:
			var target:=Hud.fit_texture(art,Rect2(24,-6,size.x-48,92))
			draw_texture_rect(art,target,false,Color(1,1,1,.4 if disabled else 1))
		var safe:=Paper.content(rect,.3)
		Paper.label(self,Rect2(36,90,size.x-72,50),text,roundi(24*text_scale),Tokens.MURAL_MUTED if disabled else Tokens.MURAL_INK,true,safe)
	func shape(r:Rect2,fill:Color,edge:Color,width:float) -> void:
		var a:=r.position;var b:=r.end;var k:=15.0
		var p:=PackedVector2Array([a+Vector2(k,0),Vector2(b.x-k,a.y),Vector2(b.x,a.y+k),b-Vector2(0,k),b-Vector2(k,0),Vector2(a.x+k,b.y),Vector2(a.x,b.y-k),a+Vector2(0,k)])
		draw_colored_polygon(p,fill);p.append(p[0]);draw_polyline(p,edge,width,true)

class DescriptionPlate extends Control:
	func _draw() -> void:
		Paper.frame(self,Rect2(0,0,size.x,size.y),"MuralInkPanel",.2)

func _ready() -> void:
	text_scale=maxf(text_scale,Mural.text_scale_for(self));Mural.install(self)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_STOP
	canvas=Control.new();canvas.size=Vector2(1280,720);add_child(canvas)
	var title:=label("LOBBY DO PIPEIRO",32,Tokens.MURAL_PAPER);canvas.add_child(title);at(title,Vector2(160,55),Vector2(690,64))
	var subtitle:=label("Batalha em pausa" if battle_paused else "Um respiro entre um elo e outro.",20,Hud.MUTED);canvas.add_child(subtitle);at(subtitle,Vector2(164,121),Vector2(650,30))
	var wallet:=label("%s · %d moedas"%[player.get("name","Kael"),int(player.get("coins",0))],22,Hud.GOLD);wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;wallet.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;canvas.add_child(wallet);at(wallet,Vector2(820,86),Vector2(294,38))
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);canvas.add_child(grid);at(grid,Vector2(160,177),Vector2(960,364))
	var colors:Array[Color]=[Hud.GOLD,Color("efa44e"),Color("8cd7f0"),Color("c285ed"),Color("69bce3"),Color("bd8bf0"),Color("b687ee"),Color("81bfcf")]
	for i in OPTIONS.size():
		var option:Array=OPTIONS[i]
		var tile:=Tile.new();tile.text=option[0];tile.custom_minimum_size=Vector2(228,174);tile.art=Hud.icon(option[2],true);tile.accent=colors[i]
		tile.text_scale=text_scale
		tile.art=Mural.icon({"team":"team","bag":"bag","missions":"missions","emblems":"emblems","identity":"identity","workshop":"workshop","save":"save","settings":"settings"}[option[1]])
		if option[1]=="team":tile.art=partner_portrait if partner_portrait!=null else Hud.ornament(0);tile.illustrated=true
		if option[1]=="identity":tile.art=load("res://assets/ui/key-items/carteira-pipeiro.png");tile.illustrated=true
		if option[1]=="emblems":tile.art=load("res://assets/ui/key-items/insignia-morro-do-sol.png");tile.illustrated=true
		if option[1]=="workshop":tile.art=load("res://assets/campaign/workshop-manga-v1/tesoura.png");tile.illustrated=true
		if option[1] in ["identity","emblems"]:tile.disabled=not preload("res://scripts/campaign/pipeiro_identity.gd").issued(player)
		if option[1]=="workshop":tile.disabled=battle_paused or int(player.get("journey",{}).get("lesson",0))<5
		tile.tooltip_text=option[3]
		if tile.disabled:tile.tooltip_text="Disponível após o treinamento com o professor." if option[1]=="workshop" else "Receba seus documentos com o professor."
		if option[1]=="workshop" and battle_paused:tile.tooltip_text="A oficina fica disponível fora das batalhas."
		grid.add_child(tile);buttons[option[1]]=tile
		var action:String=option[1];var copy:String=option[3]
		tile.pressed.connect(func():chosen.emit(action))
		tile.focus_entered.connect(func():describe(action,copy));tile.mouse_entered.connect(func():describe(action,copy));tile.mouse_exited.connect(_restore_description)
	var strip:=DescriptionPlate.new();canvas.add_child(strip);at(strip,Vector2(160,548),Vector2(960,80));strip.mouse_filter=MOUSE_FILTER_IGNORE
	description=label("Gerencie seus Pipamons e cuide dos seus parceiros.",22,Tokens.MURAL_PAPER);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;description.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;description.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;canvas.add_child(description);at(description,Vector2(191,566),Vector2(898,46));description.mouse_filter=MOUSE_FILTER_IGNORE
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",26);canvas.add_child(footer);at(footer,Vector2(166,632),Vector2(948,64))
	for option in [["Retomar","resume","back"],["Mapa","map","map"],["Sair ao título","menu","back"]]:
		var button:=Option.new();button.text_scale=text_scale;button.density=.1;button.font_base=18;button.text=option[0];button.custom_minimum_size=Vector2(240,44);button.size_flags_horizontal=SIZE_EXPAND_FILL;footer.add_child(button);buttons[option[1]]=button
		var action:String=option[1];button.pressed.connect(func():chosen.emit(action))
		var copy:String={"resume":"Feche o lobby e continue sua aventura.","map":"Consulte os caminhos e os lugares da sua jornada.","menu":"Volte ao título. Seu progresso salvo permanece guardado."}[action]
		button.focus_entered.connect(func():describe(action,copy));button.mouse_entered.connect(func():describe(action,copy));button.mouse_exited.connect(_restore_description)
	for i in OPTIONS.size():
		var button:Button=buttons[OPTIONS[i][1]]
		button.focus_neighbor_left=buttons[OPTIONS[(i/4)*4+posmod(i-1,4)][1]].get_path()
		button.focus_neighbor_right=buttons[OPTIONS[(i/4)*4+posmod(i+1,4)][1]].get_path()
		button.focus_neighbor_bottom=buttons[OPTIONS[i+4][1]].get_path() if i<4 else buttons.resume.get_path()
		button.focus_neighbor_top=buttons[OPTIONS[i-4][1]].get_path() if i>=4 else buttons.resume.get_path()
	buttons.resume.focus_neighbor_top=buttons.identity.get_path()
	buttons.map.focus_neighbor_top=buttons.save.get_path()
	buttons.menu.focus_neighbor_top=buttons.settings.get_path()
	var initial:Button=buttons.get(focus_action,buttons.team)
	if initial.disabled:initial=buttons.team
	Hud.focus_later(initial)
	resized.connect(fit);fit()
func describe(action:String,text:String) -> void:
	if not is_instance_valid(description):return
	description.text=text
	for key in buttons:
		if buttons[key] is Tile:buttons[key].selected=key==action;buttons[key].queue_redraw()
func _restore_description() -> void:
	var focus:=get_viewport().gui_get_focus_owner()
	for option in OPTIONS:
		if buttons[option[1]]==focus:describe(option[1],option[3]);return
func label(text:String,font_size:int,color:Color) -> Label:
	var result:=Label.new();result.text=text;result.add_theme_font_override("font",Tokens.label());result.add_theme_font_size_override("font_size",roundi(font_size*text_scale));result.add_theme_color_override("font_color",color);return result
func at(node:Control,point:Vector2,extent:Vector2) -> void:node.position=point;node.size=extent
func fit() -> void:
	var factor:=minf(size.x/1280,size.y/720);canvas.scale=Vector2.ONE*factor;canvas.position=(size-Vector2(1280,720)*factor)/2;queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Tokens.MURAL_GROUND)
	for y in range(24,int(size.y),36):draw_line(Vector2(0,y),Vector2(size.x,y),Tokens.alpha(Tokens.MURAL_MINT,.04),1)
