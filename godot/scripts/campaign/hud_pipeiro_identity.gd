extends Control
signal closed
const Hud=preload("res://scripts/campaign/hud.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
const Levels=preload("res://scripts/campaign/partner_levels.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var saved:Dictionary={}
var reduced_motion:=false
var backdrop_texture:Texture2D
var back:Button
var name_label:Label
var tabs:Array[Button]=[]
var pages:Array[Control]=[]
var canvas:Control
var selected_tab:=0

class Board extends Control:
	func _draw() -> void:
		var r:=Rect2(Vector2.ZERO,size)
		frame(r,Color("0a1424"),Hud.BLACK,8)
		frame(r.grow(-5),Color("203652"),Color("6489b8"),3)
		frame(r.grow(-14),Color("14243b"),Color("33516e"),3)
		for side in [0,1]:
			var x:=18.0 if side==0 else size.x-18
			for y in [22.0,size.y-100]:
				draw_line(Vector2(x,y),Vector2(x,y+70),Color("f49143"),9)
				draw_line(Vector2(x-2,y+3),Vector2(x-2,y+65),Hud.GOLD,2)
		draw_line(Vector2(42,7),Vector2(size.x-50,7),Hud.CYAN,2)
		draw_line(Vector2(178,20),Vector2(178,size.y-20),Color("071625"),6)
		draw_line(Vector2(182,22),Vector2(182,size.y-22),Color("506b90"),2)
		for x in range(30,int(size.x)-28,12):
			for y in [28,int(size.y)-30]:draw_circle(Vector2(x,y+(x%5)*2),1.5,Color("2b4664"))
		for i in 7:
			var p:=Vector2(size.x-190+i*21,38)
			draw_line(p,p+Vector2(-55,55),Color("294969"),3)
		var c:=Vector2(90,size.y-115)
		var kite:=PackedVector2Array([c+Vector2(0,-34),c+Vector2(34,0),c+Vector2(0,43),c+Vector2(-34,0),c+Vector2(0,-34)])
		draw_polyline(kite,Color("476789"),3,true)
		draw_line(c-Vector2(33,0),c+Vector2(33,0),Color("476789"),2)
		draw_line(c-Vector2(0,33),c+Vector2(0,42),Color("476789"),2)
	func frame(r:Rect2,fill:Color,edge:Color,width:float) -> void:
		var a:=r.position;var b:=r.end;var k:=20.0
		var p:=PackedVector2Array([a+Vector2(k,0),Vector2(b.x-k,a.y),Vector2(b.x,a.y+k),b-Vector2(0,k),b-Vector2(k,0),Vector2(a.x+k,b.y),Vector2(a.x,b.y-k),a+Vector2(0,k)])
		draw_colored_polygon(p,fill);p.append(p[0]);draw_polyline(p,edge,width,true)

class Photo extends Control:
	func _draw() -> void:
		var r:=Rect2(9,10,size.x-18,size.y-20)
		draw_rect(Rect2(r.position+Vector2(5,7),r.size),Color(0,0,0,.5))
		draw_rect(r,Hud.PAPER)
		var inner:=r.grow(-9)
		draw_rect(inner,Color("498fb1"))
		for i in 6:
			var p:=Vector2(inner.position.x+15+i*38,inner.position.y+24+(i%3)*55)
			draw_line(p,Vector2(minf(p.x+35,inner.end.x-3),p.y-10),Color("a5d8df"),3,true)
		var photo:=AtlasTexture.new()
		photo.atlas=preload("res://assets/campaign/portrait-kael-manga-v4.png")
		photo.region=Rect2(215,0,420,620)
		draw_texture_rect(photo,Hud.fit_texture(photo,inner),false)
		draw_rect(Rect2(25,0,87,17),Hud.GOLD)
		draw_line(Vector2(27,2),Vector2(108,2),Color("ffe6a1"),2)
		var icon:Texture2D=preload("res://assets/ui/key-items/carteira-pipeiro.png")
		draw_texture_rect(icon,Hud.fit_texture(icon,Rect2(size.x-68,size.y-65,64,64)),false)

class TitlePlate extends Control:
	func _draw() -> void:
		Ink.plate(self,Rect2(0,4,size.x,size.y-4),Hud.CYAN,Hud.CYAN,22)
		Ink.plate(self,Rect2(6,0,size.x-20,size.y-7),Color("0a1d33"),Color("486581"),22)
		for i in 5:draw_line(Vector2(size.x-55-i*7,4),Vector2(size.x-72-i*7,19),Hud.CYAN,2)

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	canvas=Control.new();canvas.size=Vector2(1280,720);add_child(canvas)
	var heading_art:=TitlePlate.new();place(heading_art,Vector2(28,20),Vector2(660,72));heading_art.mouse_filter=MOUSE_FILTER_IGNORE;canvas.add_child(heading_art)
	var board:=Board.new();board.position=Vector2(28,110);board.size=Vector2(1224,528);board.mouse_filter=MOUSE_FILTER_IGNORE
	# Keep decoration separate from the interactive content.
	canvas.add_child(board)
	var title:=copy("Identidade do Pipeiro",canvas,42)
	place(title,Vector2(56,28),Vector2(710,60))
	title.add_theme_color_override("font_color",Hud.PAPER)
	var player:Dictionary=saved.player
	var wallet:=copy("MOEDAS   %s"%format_number(int(player.get("coins",0))),canvas,28,Hud.GOLD)
	place(wallet,Vector2(910,36),Vector2(310,42));wallet.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	for i in 2:
		var tab:=Button.new();tab.text=["Perfil","Histórico"][i]
		tab.icon=Hud.icon(["info","salvar"][i]);tab.expand_icon=true
		tab.add_theme_constant_override("icon_max_width",24)
		tab.add_theme_font_size_override("font_size",23)
		tab.add_theme_font_override("font",Hud.font(true))
		tab.toggle_mode=true;tab.set_meta("recorte_decorated",true)
		canvas.add_child(tab);place(tab,Vector2(42,166+i*76),Vector2(166,62))
		for state in ["normal","hover","pressed","focus"]:tab.add_theme_stylebox_override(state,skin(Hud.GOLD if state=="pressed" else Color("20334c"),Hud.CYAN if state=="focus" else Color("527193")))
		tab.add_theme_color_override("font_pressed_color",Hud.INK)
		for state in ["font_color","font_hover_color","font_focus_color"]:tab.add_theme_color_override(state,Hud.PAPER)
		tab.add_theme_color_override("font_hover_pressed_color",Hud.INK)
		var index:=i
		tab.pressed.connect(func():
			select_tab(index))
		tabs.append(tab)
	for i in 2:
		var page:=VBoxContainer.new();page.add_theme_constant_override("separation",14)
		canvas.add_child(page);place(page,Vector2(238,146),Vector2(980,460));pages.append(page)
	profile(pages[0]);history(pages[1])
	var footer:=copy("SEU REGISTRO · KRONASTA    /    Dados da jornada salva",canvas,17,Hud.MUTED)
	place(footer,Vector2(44,662),Vector2(830,38))
	back=Button.new();back.text="Voltar";Hud.navigation_button(back)
	canvas.add_child(back);place(back,Vector2(1002,652),Vector2(220,48))
	back.pressed.connect(func():closed.emit())
	select_tab(0);Hud.focus_later(back)
	resized.connect(fit);fit()
	if not reduced_motion:
		canvas.modulate.a=0;create_tween().tween_property(canvas,"modulate:a",1,.2)

func profile(parent:Control) -> void:
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",22);top.custom_minimum_size.y=308;parent.add_child(top)
	var photo:=Photo.new();photo.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;photo.custom_minimum_size=Vector2(260,308);top.add_child(photo)
	var stats:=VBoxContainer.new();stats.size_flags_horizontal=SIZE_EXPAND_FILL;stats.add_theme_constant_override("separation",7);top.add_child(stats)
	var player:Dictionary=saved.player
	name_label=copy(player.get("name","Kael"),stats,44)
	name_label.add_theme_font_override("font",Hud.font(true))
	name_label.autowrap_mode=TextServer.AUTOWRAP_OFF;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.tooltip_text=player.get("name","Kael")
	copy("ID  #PIP-"+player.pipeiroIdentity.id,stats,19,Hud.MUTED)
	var xp:=int(player.get("tamerXp",0));var level:=Identity.tamer_level(xp)
	var base:=0 if level==1 else 20*(level-1)+3*(level-1)*(level-1)
	var ceiling:=20*level+3*level*level
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",20);stats.add_child(row)
	copy("Nv. %d"%level,row,42,Hud.GOLD)
	var progress:=VBoxContainer.new();progress.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(progress)
	var label:=copy("Nível máximo de tamer" if level==100 else "%s / %s XP de tamer"%[format_number(xp-base),format_number(ceiling-base)],progress,18,Hud.MUTED)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=20;bar.max_value=ceiling-base;bar.value=xp-base
	bar.add_theme_stylebox_override("background",skin(Color("0b172b"),Color("59769e")))
	bar.add_theme_stylebox_override("fill",skin(Hud.CYAN,Color("97e6ef")));progress.add_child(bar)
	if level==100:bar.value=bar.max_value
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",skin(Color("0c1d31"),Color("416385"),14));panel.size_flags_vertical=SIZE_EXPAND_FILL;stats.add_child(panel)
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",14);panel.add_child(grid)
	var seconds:=int(saved.get("playSeconds",0))
	field(grid,"TEMPO DE JOGO","%02d:%02d:%02d"%[seconds/3600,(seconds/60)%60,seconds%60])
	field(grid,"LOCAL ATUAL",location())
	var date:=Time.get_datetime_dict_from_unix_time(int(player.pipeiroIdentity.issuedAt))
	field(grid,"REGISTRO EMITIDO","%02d/%02d/%04d"%[date.day,date.month,date.year])
	field(grid,"SUA JORNADA",milestone())
	var bottom:=HBoxContainer.new();bottom.add_theme_constant_override("separation",18);bottom.size_flags_vertical=SIZE_EXPAND_FILL;parent.add_child(bottom)
	var team:=section(bottom,"Time atual",1.4)
	var cards:=HBoxContainer.new();cards.add_theme_constant_override("separation",7);cards.size_flags_vertical=SIZE_EXPAND_FILL;team.add_child(cards)
	var partners:Array=player.get("partners",[])
	for i in 5:
		var box:=PanelContainer.new();box.size_flags_horizontal=SIZE_EXPAND_FILL;box.add_theme_stylebox_override("panel",skin(Color("14263c"),Color("536783"),4));cards.add_child(box)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",0);box.add_child(column)
		if i>=partners.size():
			var empty:=copy("+",column,36,Color("4f6683"));empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			continue
		var partner:Dictionary=partners[i]
		var texture:=partner_art(partner.get("modelId",""))
		var image:=TextureRect.new();image.texture=texture;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size.y=60;image.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(image)
		var value:=copy("Nv. %d"%Levels.level_for_xp(partner.get("xp",0)),column,17,Hud.GOLD);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		box.tooltip_text=str(partner.get("personalName",partner.get("modelId","")))
	var collection:=section(bottom,"Coleção",1.0)
	var species:Dictionary={}
	for partner in partners:species[partner.modelId]=true
	copy("Espécies na equipe       %d"%species.size(),collection,20)
	copy("Parceiros na coleção       %d"%partners.size(),collection,20)
	var count:=0
	for key in ["carteira-pipeiro","porta-emblemas"]:
		if int(player.get("inventory",{}).get(key,0))>0:count+=1
	copy("Documentos da jornada   %d"%count,collection,19,Hud.MUTED)

func history(parent:Control) -> void:
	copy("Sua história até aqui",parent,36)
	copy("Marcos registrados nesta jornada",parent,20,Hud.GOLD)
	var events:Array[String]=["Carteira de Pipeiro emitida pelo Sr. Assis."]
	var player:Dictionary=saved.player
	if int(player.get("journey",{}).get("lesson",0))>=5:events.append("Treinamento com o professor concluído.")
	if player.get("flags",{}).get("guardianDefeated",false):events.append("Lacertubo vencido nas Veredas.")
	if player.get("flags",{}).get("ninaReturned",false):events.append("Nina voltou em segurança.")
	var wins:int=player.get("morro",{}).get("stars",{}).size()
	if wins>0:events.append("%d de 5 desafios do Morro do Sol concluídos."%wins)
	for emblem in player.get("districtEmblems",{}).values():events.append("%s conquistada."%emblem.name)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;parent.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",12);scroll.add_child(list)
	for event in events:
		var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",skin(Color("14283e"),Color("3d5876"),16));list.add_child(panel)
		copy("✓   "+event,panel,23)

func select_tab(index:int) -> void:
	selected_tab=index
	for i in pages.size():pages[i].visible=i==index
	for i in tabs.size():tabs[i].set_pressed_no_signal(i==index)
func location() -> String:
	var scene:String=saved.get("checkpoint",{}).get("scene",saved.player.get("encounter",{}).get("scene",""))
	if scene.begins_with("morro"):return "Morro do Sol"
	if scene.begins_with("kronasta-"):return {"bosque":"Bosque de Kronasta","pantano":"Pântano de Kronasta","montanha":"Montanhas de Kronasta","industrial":"Distrito Industrial"}.get(scene.split("-")[1],"Kronasta")
	return {"quintal":"Vila do Primeiro Vento","professor-home":"Ateliê do Sr. Assis","park-trail":"Jardim dos Ventos","park-clearing":"Clareira do Papel","park-veredas":"Veredas"}.get(scene,"Ateliê do Sr. Assis")
func milestone() -> String:
	if not saved.player.get("districtEmblems",{}).is_empty():return "Primeiro bairro conquistado"
	if saved.player.get("flags",{}).get("guardianDefeated",false):return "O guardião das Veredas"
	return "Os primeiros elos"
func partner_art(id:String) -> Texture2D:
	var key:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(id,id)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	if not content.combat.has(key):return null
	return Ink.portrait(load("res://assets/campaign/"+content.combat[key].image),key)
func field(parent:Control,title:String,value:String) -> void:
	var column:=VBoxContainer.new();column.size_flags_horizontal=SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",2);parent.add_child(column)
	copy(title,column,15,Hud.MUTED);copy(value,column,21)
func section(parent:Control,title:String,ratio:float) -> VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=SIZE_EXPAND_FILL;panel.size_flags_stretch_ratio=ratio;panel.add_theme_stylebox_override("panel",skin(Color("0e2036"),Color("4f6d90"),10));parent.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",2);panel.add_child(column);copy(title,column,25,Hud.GOLD);return column
func fit() -> void:
	var factor:=minf(size.x/1280,size.y/720);canvas.scale=Vector2.ONE*factor;canvas.position=(size-Vector2(1280,720)*factor)/2
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1422"))
	if backdrop_texture!=null:
		draw_texture_rect(backdrop_texture,Hud.fit_texture(backdrop_texture,Rect2(Vector2.ZERO,size)),false)
		draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.045,.08,.78))
func place(node:Control,point:Vector2,extent:Vector2) -> void:node.position=point;node.size=extent
static func format_number(value:int) -> String:
	var result:=str(value);var i:=result.length()-3
	while i>0:result=result.insert(i,".");i-=3
	return result
static func skin(fill:Color,edge:Color,padding:int=8) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=edge;style.set_border_width_all(2);style.set_corner_radius_all(3)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:style.set_content_margin(side,padding)
	return style
func copy(value:String,parent:Node,font_size:int,color:Color=Hud.PAPER) -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	if font_size>=25:label.add_theme_font_override("font",Hud.lettering())
	parent.add_child(label);return label
