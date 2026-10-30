extends VBoxContainer
## A small virtual-pet care scene, using the equipped creature's existing art.
signal completed(steps:Array)
signal supplies_requested
signal back_requested
const Hud=preload("res://scripts/campaign/hud.gd")
const Care=preload("res://scripts/campaign/partner_care.gd")
var partner:Dictionary={}
var kits:=0
var coins:=0
var welcome:=true
var reduced_motion:=false
var steps:Array=[]
var saved:=false
var busy:=false
var clock:=0.0
var reaction:=0.0
var body_height:=1
var kit_texture:Texture2D
var stage:Control
var creature:Sprite2D
var frames:Array=[]
var message:Label
var stock:Label
var condition:Label
var action:Button
var pet:Button
var supply:Button
var back:Button
var meters:Array[ProgressBar]=[]
const ACTIONS := ["Limpar o papel","Reforçar a armação","Ajustar a linha"]
const IDS := ["clean","frame","line"]
func copy(text:String,parent:Node,font_size:int=18) -> Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label
func button(text:String,parent:Node,callback:Callable) -> Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=48
	Hud.navigation_button(result,true);parent.add_child(result);result.pressed.connect(callback);return result
func _ready() -> void:
	kit_texture=Hud.item_art(Care.ITEM)
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	stock=copy("",self,18)
	var plate=load("res://scripts/campaign/hud_result_plate.gd").new()
	plate.size_flags_vertical=Control.SIZE_EXPAND_FILL;plate.accent=Hud.CYAN;add_child(plate)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);plate.add_child(column)
	copy(partner.get("personalName",partner.get("modelId","Parceiro")),column,26)
	stage=Control.new();stage.custom_minimum_size.y=140;stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(stage)
	stage.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:_pet())
	stage.draw.connect(_draw_stage)
	creature=Sprite2D.new();creature.region_enabled=true;stage.add_child(creature)
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var id:String={"basica":"basic-carcara","mata":"basic-mata-verde","azulao":"basic-azulao","raio":"basic-raio-de-sol"}.get(partner.get("modelId","rabbito"),partner.get("modelId","rabbito"))
	var art:Dictionary=catalog.combat.get(id,catalog.combat.rabbito)
	creature.texture=load("res://assets/campaign/"+art.image);frames=art.animations.idle
	var frame:Dictionary=frames[0];creature.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
	var bounds:Rect2i=creature.texture.get_image().get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
	body_height=maxi(1,bounds.size.y)
	creature.scale=Vector2.ONE*175.0/maxi(1,bounds.size.y)
	creature.offset=Vector2(frame.w*.5-bounds.get_center().x,frame.h*.5-bounds.end.y)
	condition=copy("",column,17)
	for color in [Hud.LINE,Hud.GOLD]:
		var bar:=ProgressBar.new();bar.custom_minimum_size.y=10;bar.show_percentage=false
		var fill:=StyleBoxFlat.new();fill.bg_color=color;bar.add_theme_stylebox_override("fill",fill)
		column.add_child(bar);meters.append(bar)
	message=copy("",self,18);message.custom_minimum_size.y=48
	var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",18);row.add_theme_constant_override("v_separation",8);add_child(row)
	action=button(ACTIONS[0],row,_care);action.custom_minimum_size.x=280
	pet=button("Fazer carinho",row,_pet);pet.custom_minimum_size.x=180
	supply=button("",row,func():supplies_requested.emit());supply.custom_minimum_size.x=300
	back=button("Voltar",self,func():back_requested.emit())
	refresh_stock(kits,coins,welcome)
	stage.resized.connect(_place);_place()
	action.grab_focus() if not action.disabled else supply.grab_focus()
func _place() -> void:
	if is_instance_valid(creature):
		creature.position=Vector2(stage.size.x*.5,stage.size.y*.9)
		var height:=minf(190,stage.size.y*.9)
		creature.scale=Vector2.ONE*height/body_height
func refresh_stock(count:int,money:int,first:bool) -> void:
	kits=count;coins=money;welcome=first
	stock.text="Kit de Remendo × %d   ·   %d moedas   ·   Reparo completo da linha e da armação"%[kits,coins]
	supply.text="Pegar kit de boas-vindas" if welcome else "Comprar kit · %d moedas"%Care.PRICE
	supply.disabled=busy or (not welcome and coins<Care.PRICE)
	_update()
func _update() -> void:
	var data:Dictionary=partner.get("condition",{"line":100,"structure":100})
	var healthy:bool=float(data.line)>=100 and float(data.structure)>=100
	meters[0].value=100 if saved else float(data.line)
	meters[1].value=100 if saved else float(data.structure)
	condition.text="Linha %d%%    ·    Armação %d%%"%[meters[0].value,meters[1].value]
	action.disabled=busy or saved or healthy or kits<=0
	action.text="Reparo concluído" if saved else "Já está bem cuidado" if healthy else ACTIONS[mini(steps.size(),2)]
	if saved:message.text="Prontinho! Seu parceiro está recuperado e pronto para explorar."
	elif healthy:message.text="Seu parceiro está bem! Você pode passar um tempo com ele e fazer carinho."
	elif kits<=0:message.text="Pegue um Kit de Remendo para cuidar do seu parceiro. Nada é gasto antes de concluir."
	elif steps.is_empty():message.text="Vamos com calma: primeiro tire a poeira do papel. Cancelar preserva o kit."
	stage.queue_redraw()
func _care() -> void:
	if action.disabled or busy:return
	reaction=1.0
	steps.append(IDS[steps.size()])
	if steps.size()==3:
		busy=true;_update();completed.emit(steps.duplicate())
	else:
		message.text="Papel limpinho! Agora vamos firmar a armação." if steps.size()==1 else "Armação firme! Falta ajustar a linha para voltar a voar."
		_update()
func _pet() -> void:
	reaction=1.5;message.text="Ele se aproxima de você. Um carinho também faz parte do cuidado!"
	stage.queue_redraw()
func finish_result(ok:bool,text:String="") -> void:
	busy=false;saved=ok
	if not ok:steps=IDS.slice(0,2)
	_update()
	if not ok:message.text=text
	back.grab_focus() if ok else action.grab_focus()
func _process(delta:float) -> void:
	clock+=delta;reaction=maxf(0,reaction-delta)
	if not frames.is_empty():
		var frame:Dictionary=frames[int(clock*8)%frames.size()];creature.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
	_place()
	if not reduced_motion:creature.position.y-=sin(clock*3)*2+sin(clampf(reaction,0,1)*PI)*8
	stage.queue_redraw()
func _draw_stage() -> void:
	var center:=Vector2(stage.size.x*.5,stage.size.y*.9)
	var field:=Rect2(Vector2(4,4),stage.size-Vector2(8,8))
	stage.draw_rect(field,Color(.035,.09,.12,.55))
	for x in range(24,int(stage.size.x),32):
		for y in range(20,int(stage.size.y),32):stage.draw_circle(Vector2(x,y),1,Color(.35,.7,.7,.14))
	if kit_texture!=null:stage.draw_texture_rect(kit_texture,Rect2(Vector2(stage.size.x-92,16),Vector2(64,64)),false)
	stage.draw_style_box(_mat(),Rect2(center-Vector2(150,20),Vector2(300,35)))
	if reaction>0:
		for side in [-1,1]:
			var point:=center+Vector2(side*100,-85-reaction*12)
			stage.draw_circle(point,5,Hud.GOLD)
			stage.draw_line(point-Vector2(0,10),point+Vector2(0,10),Hud.GOLD,2)
			stage.draw_line(point-Vector2(10,0),point+Vector2(10,0),Hud.GOLD,2)
	if steps.size()>0:
		stage.draw_string(Hud.font(),Vector2(12,24),"✓ Papel limpo" if not saved else "✓ Bem cuidado",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Hud.CYAN)
	if steps.size()>1:stage.draw_string(Hud.font(),Vector2(12,48),"✓ Armação firme",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Hud.GOLD)
	if saved:stage.draw_string(Hud.font(),Vector2(12,72),"✓ Linha ajustada",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Hud.LINE)
	if reaction>0 and not steps.is_empty() and not saved:
		var tool:=center+Vector2(sin(clock*9)*45,-65)
		if steps.size()==1:
			stage.draw_line(tool,tool+Vector2(25,-25),Hud.GOLD,5,true)
			stage.draw_circle(tool,9,Hud.PAPER)
		else:
			stage.draw_line(tool-Vector2(10,30),tool+Vector2(10,-30),Hud.GOLD,5,true)
			stage.draw_arc(tool,17,0,TAU,24,Hud.CYAN,2,true)
func _mat() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color(.12,.28,.30,.7)
	style.corner_radius_top_left=20;style.corner_radius_top_right=20;style.corner_radius_bottom_left=20;style.corner_radius_bottom_right=20
	return style
