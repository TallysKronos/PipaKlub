extends RefCounted
## Public fighter values only; ornament bleed is excluded by Paper.content().
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Pilot=preload("res://assets/campaign/portrait-kael-manga-v4.png")
static func action_size(scale:float) -> Vector2:return Vector2(minf(156,124*scale),168+48*(scale-1))
static func density(scale:float) -> float:return .35
static func line_height(scale:float,font:int=16) -> float:return Paper.height(roundi(font*scale))+3
static func regions(size:Vector2,rivals:int=1,scale:float=1.0) -> Dictionary:
	var pad:=Paper.inset(density(scale))
	var title_h:=line_height(scale,20)
	var row_h:=line_height(scale)
	var h:=pad*2+title_h+row_h*3+8
	var stacked:=size.x<1160 or scale>1.1
	var card_y:float=size.y-24-h-(action_size(scale).y+20 if stacked else 0)
	if scale>1.1:card_y=18
	var top_h:=pad*2+line_height(scale,22)+line_height(scale,16)+4
	var rival_h:=pad*2+line_height(scale,20)+row_h*3+6
	var timer_h:=pad*2+line_height(scale,32)+line_height(scale,14)+4
	var clock_width:=maxf(120,120*scale)
	var pilot_width:=minf(300*scale,size.x*.30)
	var rival_width:=minf(340*scale,size.x*.32)
	var weather_y:float=maxf(timer_h,h)+26 if scale>1.1 else 18+timer_h+8
	return {"pilot":Rect2(24,18,pilot_width,top_h),"partner":Rect2(24,card_y,minf(380*scale,size.x*(.36 if scale>1.1 else .49)),h),"clock":Rect2(size.x/2-clock_width/2,18,clock_width,timer_h),"weather":Rect2(size.x/2-120*scale,weather_y,240*scale,pad*2+line_height(scale,16)),"rivals":Rect2(size.x-rival_width-24,18,rival_width,(rival_h+8)*rivals),"rival_height":rival_h}
static func paper(c:CanvasItem,box:Rect2,variant:String="MuralPaperPanel") -> void:Paper.frame(c,box,variant,.35)
static func text(c:CanvasItem,at:Vector2,value:String,width:float,font:int=18,color:Color=T.MURAL_INK) -> void:
	Paper.label(c,Rect2(at-Vector2(0,Paper.height(font)),Vector2(width,Paper.height(font))),value,font,color)
static func bar(c:CanvasItem,box:Rect2,fraction:float,kind:String="line") -> void:
	var value:=clampf(fraction,0,1)
	c.draw_rect(box,T.alpha(T.MURAL_INK,.15))
	if kind=="line":c.draw_rect(Rect2(box.position,Vector2(box.size.x*value,box.size.y)),T.MURAL_RED if value<.35 else T.MURAL_TEAL)
	else:
		for index in 10:
			if index>=ceili(value*10):continue
			c.draw_rect(Rect2(box.position+Vector2(index*box.size.x/10,0),Vector2(maxf(1,box.size.x/10-2),box.size.y)),T.MURAL_INK if kind=="hull" else T.MURAL_TEAL)
static func row(c:CanvasItem,safe:Rect2,y:float,title:String,fraction:float,scale:float,kind:String="line") -> void:
	var font:=roundi(16*scale)
	var h:=line_height(scale)
	var label_w:=T.label().get_string_size("Armação",HORIZONTAL_ALIGNMENT_LEFT,-1,font).x+8
	var value_w:=T.label().get_string_size("100%",HORIZONTAL_ALIGNMENT_LEFT,-1,font).x+6
	var available:=safe.size.x-label_w-value_w-14
	if available<24:
		Paper.label(c,Rect2(safe.position+Vector2(0,y),Vector2(safe.size.x,h)),title+" %d%%"%roundi(clampf(fraction,0,1)*100),font,T.MURAL_INK,false,safe)
		return
	Paper.label(c,Rect2(safe.position+Vector2(0,y),Vector2(label_w,h)),title,font,T.MURAL_INK,false,safe)
	var track:=Rect2(safe.position+Vector2(label_w,y+(h-8)/2),Vector2(available,8))
	bar(c,track,fraction,kind)
	Paper.record(c,track,safe,"bar:"+title)
	Paper.label(c,Rect2(Vector2(track.end.x+8,safe.position.y+y),Vector2(value_w,h)),"%d%%"%roundi(clampf(fraction,0,1)*100),font,T.MURAL_INK,false,safe)
static func draw_on(c:Control,actors:Array,faces:Array,names:Array,player:Dictionary,seconds:float,round_no:int,rounds:int,wind:float,scale:float=1.0,champion:bool=false) -> void:
	Paper.begin(c)
	var boxes:=regions(c.size,actors.size()-1,scale)
	var pilot:Rect2=boxes.pilot
	if scale<=1.1:draw_pilot(c,pilot,player,actors,rounds,scale)
	var safe:=Rect2()
	var first_h:=0.0
	var card:Rect2=boxes.partner
	paper(c,card);safe=Paper.content(card,.35)
	var face_width:=minf(84,safe.size.x*.26)
	if faces[0]!=null:c.draw_texture_rect(faces[0],Hud.fit_texture(faces[0],Rect2(Vector2(card.position.x-8,safe.position.y-8),Vector2(face_width+24,safe.size.y+16))),false)
	safe.position.x+=face_width;safe.size.x-=face_width
	first_h=line_height(scale,20)
	Paper.label(c,Rect2(safe.position,Vector2(safe.size.x,first_h)),names[0],roundi(20*scale),T.MURAL_INK,false,safe)
	var p:Dictionary=actors[0]
	for index in 3:row(c,safe,first_h+8+line_height(scale)*index,["Linha","Armação","Energia"][index],[p.hp/p.stats.line,p.hull/p.stats.line,p.energy/p.stats.energy][index],scale,["line","hull","energy"][index])
	if champion or (actors.size()==2 and actors[1].get("boss",false)):
		draw_boss(c,actors[1],faces[1],names[1],seconds,rounds,scale,champion,wind)
		return
	for index in range(1,actors.size()):
		var actor:Dictionary=actors[index]
		var rival:=Rect2(boxes.rivals.position+Vector2(0,(index-1)*(boxes.rival_height+8)),Vector2(boxes.rivals.size.x,boxes.rival_height))
		paper(c,rival);safe=Paper.content(rival,.35)
		first_h=line_height(scale,20)
		Paper.label(c,Rect2(safe.position,Vector2(safe.size.x,first_h)),actor.get("name","Rival")+" · "+names[index],roundi(20*scale),T.MURAL_INK,false,safe)
		row(c,safe,first_h+6,"Linha",actor.hp/actor.stats.line,scale)
		row(c,safe,first_h+6+line_height(scale),"Armação",actor.hull/actor.stats.line,scale,"hull")
		Paper.label(c,Rect2(safe.position+Vector2(0,first_h+6+line_height(scale)*2),Vector2(safe.size.x,line_height(scale))),"Rodadas %d/%d"%[actor.get("rounds",0),rounds],roundi(16*scale),T.MURAL_INK,false,safe)
	var timer:Rect2=boxes.clock
	paper(c,timer,"MuralSunPanel");safe=Paper.content(timer,.35)
	first_h=line_height(scale,32)
	Paper.label(c,Rect2(safe.position,Vector2(safe.size.x,first_h)),str(ceili(seconds)),roundi(32*scale),T.MURAL_RED if seconds<=10 else T.MURAL_INK,true,safe)
	Paper.label(c,Rect2(safe.position+Vector2(0,first_h+4),Vector2(safe.size.x,line_height(scale,14))),"RODADA %d"%round_no,roundi(14*scale),T.MURAL_INK,true,safe)
	var weather:Rect2=boxes.weather
	paper(c,weather);safe=Paper.content(weather,.35)
	Paper.label(c,safe,"Vento %s · %s"%["leve" if absf(wind)<6 else "moderado","→" if wind>=0 else "←"],roundi(16*scale),T.MURAL_INK,true,safe)
static func boss_region(size:Vector2,scale:float) -> Rect2:
	var x:float=regions(size,1,scale).partner.end.x+16 if scale>1.1 else regions(size,1,scale).pilot.end.x+16
	return Rect2(x,18,size.x-x-24,Paper.inset(.35)*2+line_height(scale,20)*2+line_height(scale)*3+8)
static func draw_boss(c:Control,actor:Dictionary,face:Texture2D,name:String,seconds:float,rounds:int,scale:float,champion:bool,wind:float) -> void:
	var box:=boss_region(c.size,scale)
	paper(c,box,"MuralSunPanel")
	var safe:=Paper.content(box,.35)
	if face!=null:c.draw_texture_rect(face,Hud.fit_texture(face,Rect2(safe.position-Vector2(20,10),Vector2(84,safe.size.y+20))),false)
	safe.position.x+=80;safe.size.x-=80
	var h:=line_height(scale,20)
	var heading:="CAMPEÃ · MORRO DO SOL" if champion else "BOSS · FASE %d"%actor.get("phase",1)
	Paper.label(c,Rect2(safe.position,Vector2(safe.size.x,h)),heading,roundi(20*scale),T.MURAL_INK,false,safe)
	Paper.label(c,Rect2(safe.position+Vector2(0,h),Vector2(safe.size.x,h)),(str(actor.get("name","Mikka")) if champion else name)+" · %d s"%ceili(seconds),roundi(20*scale),T.MURAL_INK,false,safe)
	row(c,safe,h*2+4,"Linha",actor.hp/actor.stats.line,scale)
	row(c,safe,h*2+4+line_height(scale),"Armação",actor.hull/actor.stats.line,scale,"hull")
	Paper.label(c,Rect2(safe.position+Vector2(0,h*2+4+line_height(scale)*2),Vector2(safe.size.x,line_height(scale))),"Rodadas %d/%d · Vento %s"%[actor.get("rounds",0),rounds,"→" if wind>=0 else "←"],roundi(16*scale),T.MURAL_INK,false,safe)


static func draw_pilot(c:Control,pilot:Rect2,player:Dictionary,actors:Array,rounds:int,scale:float) -> void:
	paper(c,pilot)
	var safe:=Paper.content(pilot,.35)
	var art_width:=54.0
	c.draw_texture_rect_region(Pilot,Rect2(safe.position-Vector2(12,16),Vector2(art_width+16,safe.size.y+24)),Rect2(100,0,550,560))
	safe.position.x+=art_width;safe.size.x-=art_width
	var first_h:=line_height(scale,22)
	Paper.label(c,Rect2(safe.position,Vector2(safe.size.x,first_h)),player.get("name","Kael"),roundi(22*scale),T.MURAL_INK,false,safe)
	var level:=preload("res://scripts/campaign/pipeiro_identity.gd").tamer_level(player.get("tamerXp",0))
	Paper.label(c,Rect2(safe.position+Vector2(0,first_h+4),Vector2(safe.size.x,line_height(scale,16))),"Tamer · Nv. %d · %d/%d"%[level,actors[0].get("rounds",0),rounds],roundi(16*scale),T.MURAL_INK,false,safe)
