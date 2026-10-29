extends Control
## Only shown after Journey confirms the birth; never awards a partner itself.
signal continued
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var partner_name:="Parceiro"
var partner_texture:Texture2D
var frames:Array=[]
var outcome:Dictionary={}
var variant:=false
var reduced_motion:=false
var age:=0.0
var accepted:=false
var clock:=0.0
var action:Button
var background:Texture2D
func _ready()->void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	background=load("res://assets/campaign/workshop-manga-v1/bancada.png")
	action=Button.new()
	action.text="Conhecer meu parceiro"
	Hud.navigation_button(action)
	action.disabled=true
	action.pressed.connect(func():
		if accepted or action.disabled:return
		accepted=true
		action.disabled=true
		continued.emit())
	add_child(action)
	resized.connect(_layout)
	_layout()
func _layout()->void:
	action.position=Vector2(size.x*.5-180,size.y-92)
	action.size=Vector2(360,56)
func _process(delta:float)->void:
	clock+=delta
	if not get_window().has_focus():return
	age+=minf(delta,.05)
	if action.disabled and not accepted and age>=(.15 if reduced_motion else 1.1):
		action.disabled=false
		Hud.focus_later(action)
	queue_redraw()
func _draw()->void:
	if background==null:return
	var scale_factor:=maxf(size.x/background.get_width(),size.y/background.get_height())
	draw_texture_rect(background,Rect2((size-background.get_size()*scale_factor)*.5,background.get_size()*scale_factor),false)
	draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.07,.1,.75))
	var center:=Vector2(size.x*.5,size.y*.42)
	var reveal:=1.0 if reduced_motion else smoothstep(0,.9,age)
	var radius:=minf(125,size.y*.17)
	draw_circle(center,radius+20,Color(.18,.6,.61,.13*reveal))
	for i in 3:
		draw_arc(center,radius+12+i*9,0,TAU,64,Color(.9,.74,.35,(.35-float(i)*.09)*reveal),2,true)
	if partner_texture!=null and not frames.is_empty():
		var frame:Dictionary=frames[int(clock*12)%frames.size()]
		# Fixed envelope: every species remains inside its presentation space.
		var extent:=Vector2.ONE*radius*1.65*(.92+.08*reveal)
		var float_offset:=0.0 if reduced_motion else sin(clock*2)*4
		draw_texture_rect_region(partner_texture,Rect2(center-extent*.5+Vector2(0,float_offset),extent),Rect2(frame.x,frame.y,frame.w,frame.h),Color(1,1,1,reveal))
	var heading:="%s nasceu!"%partner_name
	draw_string(Hud.display(),Vector2(0,center.y+radius+66),heading,HORIZONTAL_ALIGNMENT_CENTER,size.x,36,Hud.PAPER)
	draw_string(Hud.font(),Vector2(0,64),"DA SUA MÃO, UM NOVO ELO",HORIZONTAL_ALIGNMENT_CENTER,size.x,19,Hud.GOLD)
	var bonus:float=outcome.get("craftBonus",{}).get("totalPercent",0)
	var detail:="Bônus da montagem · +%.1f%% nos atributos"%bonus
	draw_string(Hud.font(),Vector2(0,center.y+radius+101),detail,HORIZONTAL_ALIGNMENT_CENTER,size.x,21,Hud.PAPER)
	if variant:draw_string(Hud.font(true),Vector2(0,105),"Uma variante rara despertou",HORIZONTAL_ALIGNMENT_CENTER,size.x,22,Hud.GOLD)
