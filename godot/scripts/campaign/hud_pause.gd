extends Control
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
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
	["Tamer (Perfil)","identity","info","Sua identidade, experiência e história como pipeiro."],
	["Oficina","workshop","line","Confira suas rabiolas e construa novos elos no ateliê."],
	["Salvar","save","save","Guarde a jornada sem sair do lugar."],
	["Config.","settings","settings","Ajuste vídeo, áudio, controles e acessibilidade."]]

class Tile extends Button:
	var art:Texture2D
	var illustrated:=false
	var accent:Color=Hud.CYAN
	var selected:=false
	func _ready() -> void:
		set_meta("recorte_decorated",true)
		for state in ["normal","hover","pressed","focus","disabled"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:add_theme_color_override(state,Tokens.alpha(Tokens.NANQUIM,0.0))
		focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		var active:bool=has_focus() or is_hovered() or selected
		var edge:Color=Hud.GOLD if active else Hud.CYAN
		if disabled:edge=Tokens.LOBBY_DISABLED
		var r:=Rect2(4,4,size.x-8,size.y-10)
		shape(Rect2(r.position+Vector2(0,5),r.size),Tokens.LOBBY_SHADOW,Tokens.LOBBY_SHADOW,5)
		shape(r,Tokens.LOBBY_TILE_ACTIVE if active else Tokens.LOBBY_TILE,edge,4)
		shape(r.grow(-7),Tokens.LOBBY_INSET,Tokens.LOBBY_INSET_EDGE,1)
		for i in 6:draw_line(Vector2(size.x-22-i*8,12),Vector2(size.x-40-i*8,30),Color(edge,.3),2)
		for x in range(24,int(size.x)-20,12):draw_circle(Vector2(x,size.y-28+(x%3)*3),1,Tokens.LOBBY_DOTS)
		draw_line(Vector2(18,34),Vector2(34,16),edge,5)
		draw_line(Vector2(size.x-41,size.y-15),Vector2(size.x-22,size.y-34),Hud.GOLD if active else accent,5)
		if art!=null:
			var target:=Hud.fit_texture(art,Rect2(68,17,size.x-136,90))
			if illustrated:
				draw_texture_rect(art,target,false,Tokens.alpha(Tokens.UNTINTED,.4 if disabled else 1.0))
			else:
				for offset in [Vector2(-3,0),Vector2(3,0),Vector2(0,-3),Vector2(0,3)]:draw_texture_rect(art,Rect2(target.position+offset,target.size),false,Hud.BLACK)
				draw_texture_rect(art,target,false,Tokens.LOBBY_DISABLED_ART if disabled else accent.lightened(.3))
		var font:=Hud.font(true);var font_size:=28
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		draw_string(font,Vector2((size.x-width)/2+2,139+2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Hud.BLACK)
		draw_string(font,Vector2((size.x-width)/2,139),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Hud.MUTED if disabled else Hud.PAPER)
		if active:draw_line(Vector2(26,size.y-19),Vector2(size.x-52,size.y-19),Hud.GOLD,2)
	func shape(r:Rect2,fill:Color,edge:Color,width:float) -> void:
		var a:=r.position;var b:=r.end;var k:=15.0
		var p:=PackedVector2Array([a+Vector2(k,0),Vector2(b.x-k,a.y),Vector2(b.x,a.y+k),b-Vector2(0,k),b-Vector2(k,0),Vector2(a.x+k,b.y),Vector2(a.x,b.y-k),a+Vector2(0,k)])
		draw_colored_polygon(p,fill);p.append(p[0]);draw_polyline(p,edge,width,true)

class DescriptionPlate extends Control:
	func _draw() -> void:
		Ink.plate(self,Rect2(0,0,size.x,size.y),Tokens.LOBBY_STRIP,Hud.CYAN,20)
		draw_line(Vector2(20,size.y-5),Vector2(size.x-38,size.y-5),Tokens.LOBBY_STRIP_LINE,1)

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT);mouse_filter=MOUSE_FILTER_STOP
	canvas=Control.new();canvas.size=Vector2(1280,720);add_child(canvas)
	var title:=label("LOBBY DO PIPEIRO",52,Hud.PAPER);canvas.add_child(title);at(title,Vector2(160,55),Vector2(690,64))
	var subtitle:=label("Batalha em pausa" if battle_paused else "Um respiro entre um elo e outro.",20,Hud.MUTED);canvas.add_child(subtitle);at(subtitle,Vector2(164,121),Vector2(650,30))
	var wallet:=label("%s · %d moedas"%[player.get("name","Kael"),int(player.get("coins",0))],22,Hud.GOLD);wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;wallet.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;canvas.add_child(wallet);at(wallet,Vector2(820,86),Vector2(294,38))
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",16);canvas.add_child(grid);at(grid,Vector2(160,177),Vector2(960,364))
	var colors:Array[Color]=[Hud.GOLD]+Tokens.LOBBY_ACCENTS
	for i in OPTIONS.size():
		var option:Array=OPTIONS[i]
		var tile:=Tile.new();tile.text=option[0];tile.custom_minimum_size=Vector2(228,174);tile.art=Hud.icon(option[2],true);tile.accent=colors[i]
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
	var strip:=DescriptionPlate.new();canvas.add_child(strip);at(strip,Vector2(160,566),Vector2(960,54));strip.mouse_filter=MOUSE_FILTER_IGNORE
	description=label("Gerencie seus Pipamons e cuide dos seus parceiros.",22,Hud.PAPER);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;description.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;canvas.add_child(description);at(description,Vector2(191,571),Vector2(898,42));description.mouse_filter=MOUSE_FILTER_IGNORE
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",26);canvas.add_child(footer);at(footer,Vector2(166,650),Vector2(948,46))
	for option in [["Retomar","resume","back"],["Mapa","map","map"],["Sair ao título","menu","back"]]:
		var button:=Button.new();button.text=option[0];button.custom_minimum_size=Vector2(240,44);button.size_flags_horizontal=SIZE_EXPAND_FILL;Hud.navigation_button(button,true,option[2]);footer.add_child(button);buttons[option[1]]=button
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
	var result:=Label.new();result.text=text;result.add_theme_font_override("font",Hud.lettering() if font_size>=40 else Hud.font(true));result.add_theme_font_size_override("font_size",font_size);result.add_theme_color_override("font_color",color);return result
func at(node:Control,point:Vector2,extent:Vector2) -> void:node.position=point;node.size=extent
func fit() -> void:
	var factor:=minf(size.x/1280,size.y/720);canvas.scale=Vector2.ONE*factor;canvas.position=(size-Vector2(1280,720)*factor)/2;queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Tokens.LOBBY_BACKDROP)
	for x in range(0,int(size.x),32):draw_line(Vector2(x,0),Vector2(x,size.y),Tokens.LOBBY_GRID,1)
	for y in range(0,int(size.y),32):draw_line(Vector2(0,y),Vector2(size.x,y),Tokens.LOBBY_GRID,1)
	draw_line(Vector2(size.x*.65,size.y-6),Vector2(size.x,size.y*.76),Hud.CYAN,4,true)
	draw_line(Vector2(0,size.y*.23),Vector2(size.x*.2,0),Color(Hud.CYAN,.3),3,true)
