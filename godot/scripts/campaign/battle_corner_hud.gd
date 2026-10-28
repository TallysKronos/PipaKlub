extends RefCounted
## Shared battle / lesson corner presentation. Opponent energy is never consumed here.
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const PILOT=preload("res://assets/campaign/portrait-kael.png")
static func regions(size:Vector2,rivals:int=1) -> Dictionary:
	return {"pilot":Rect2(20,14,300,66),"partner":Rect2(20,size.y-126,400,108),"clock":Rect2(size.x/2-45,12,90,90),"weather":Rect2(size.x/2-100,138,200,28),"rivals":Rect2(size.x-320,14,300,104 if rivals==1 else 66*rivals)}
static func text(c:CanvasItem,p:Vector2,value:String,font_size:int=16,color:Color=T.PAPEL) -> void:
	c.draw_string(Hud.font(true),p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
static func line_color(fraction:float) -> Color:
	return T.RABIOLA if fraction<.25 else T.SOL if fraction<.5 else T.FOLHA
static func rival_summary(actor:Dictionary) -> Dictionary:
	return {"name":actor.get("name","Selvagem"),"hp":actor.hp,"hull":actor.hull,"stats":{"line":actor.stats.line},"rounds":actor.get("rounds",0)}
static func bar(c:CanvasItem,rect:Rect2,fraction:float,color:Color) -> void:
	c.draw_colored_polygon(Ink.shape(rect,3),T.TINTA_3)
	if rect.size.x*clampf(fraction,0,1)>.5:c.draw_colored_polygon(Ink.shape(Rect2(rect.position,Vector2(rect.size.x*clampf(fraction,0,1),rect.size.y)),3),color)
static func diamonds(c:CanvasItem,start:Vector2,won:int,total:int,color:Color) -> void:
	for index in mini(total,5):
		var p:=start+Vector2(index*18,0)
		var shape:=PackedVector2Array([p+Vector2(0,-5),p+Vector2(5,0),p+Vector2(0,5),p+Vector2(-5,0)])
		c.draw_colored_polygon(shape,color if index<won else T.TINTA_3)
static func draw_on(c:Control,actors:Array,faces:Array,names:Array,player:Dictionary,seconds:float,round_no:int,rounds:int,wind:float,cost:int=0,lesson:int=-1,footer_top:float=-1) -> void:
	var boxes:=regions(c.size,actors.size()-1)
	if footer_top>=0:boxes.partner.position.y=footer_top-116
	if actors[0].hp/actors[0].stats.line<.25:
		var thickness:float=minf(c.size.x,c.size.y)*.06
		for r in [Rect2(0,0,c.size.x,thickness),Rect2(0,c.size.y-thickness,c.size.x,thickness),Rect2(0,0,thickness,c.size.y),Rect2(c.size.x-thickness,0,thickness,c.size.y)]:c.draw_rect(r,T.alpha(T.TINTA,.3))
	var pilot:Rect2=boxes.pilot
	Ink.plate(c,pilot,T.TINTA,T.CEU,10)
	c.draw_texture_rect_region(PILOT,Rect2(pilot.position+Vector2(8,4),Vector2(54,58)),Rect2(160,10,460,500))
	text(c,pilot.position+Vector2(72,25),Ink.ellipsis(player.get("name","Kael"),Hud.font(true),20,205),20)
	var xp:int=player.get("tamerXp",0)
	var level:=1
	while level<100 and xp>=20*level+3*level*level:level+=1
	text(c,pilot.position+Vector2(72,48),"Tamer · Nv. %d"%level,14,T.PAPEL_2)
	diamonds(c,pilot.position+Vector2(240,46),actors[0].get("rounds",0),rounds,T.CEU)
	for index in range(1,actors.size()):
		var a:Dictionary=rival_summary(actors[index])
		var compact:bool=actors.size()>2
		var box:=Rect2(boxes.rivals.position+Vector2(0,(index-1)*66),Vector2(300,60 if compact else 104))
		Ink.plate(c,box,T.TINTA,T.RABIOLA,10)
		var title:String=a.get("name","Selvagem")
		text(c,box.position+Vector2(14,21),Ink.ellipsis(title+" · "+names[index],Hud.font(true),18,270),18)
		var fraction:float=a.hp/a.stats.line
		text(c,box.position+Vector2(14,43),"Linha",14)
		bar(c,Rect2(box.position+Vector2(66,32),Vector2(164,10)),fraction,line_color(fraction))
		text(c,box.position+Vector2(240,43),"%d%%"%roundi(fraction*100),14)
		if compact:diamonds(c,box.position+Vector2(210,55),a.get("rounds",0),rounds,T.RABIOLA)
		else:
			text(c,box.position+Vector2(14,67),"Armação",14,T.PAPEL_2)
			bar(c,Rect2(box.position+Vector2(80,57),Vector2(150,7)),a.hull/a.stats.line,T.PAPEL_2)
			text(c,box.position+Vector2(240,67),"%d%%"%roundi(a.hull/a.stats.line*100),14)
			text(c,box.position+Vector2(14,91),"Parceiro rival",14,T.PAPEL_2)
	var p:Dictionary=actors[0]
	var card:Rect2=boxes.partner
	Ink.plate(c,card,T.TINTA,T.CEU,12)
	if faces[0]!=null:c.draw_texture_rect(faces[0],Hud.fit_texture(faces[0],Rect2(card.position+Vector2(5,5),Vector2(76,98))),false)
	text(c,card.position+Vector2(90,23),Ink.ellipsis(names[0],Hud.font(true),20,290),20)
	var f:float=p.hp/p.stats.line
	text(c,card.position+Vector2(90,46),"Linha",14)
	bar(c,Rect2(card.position+Vector2(154,34),Vector2(174,14)),f,line_color(f))
	text(c,card.position+Vector2(339,46),"%d%%"%roundi(f*100),14)
	text(c,card.position+Vector2(90,68),"Armação",14,T.PAPEL_2)
	bar(c,Rect2(card.position+Vector2(154,58),Vector2(174,6)),p.hull/p.stats.line,T.PAPEL_2)
	text(c,card.position+Vector2(339,68),"%d%%"%roundi(p.hull/p.stats.line*100),14)
	text(c,card.position+Vector2(90,92),"Energia",14)
	for cell in 10:
		var cell_rect:=Rect2(card.position+Vector2(154+cell*18,79),Vector2(15,10))
		c.draw_rect(cell_rect,T.CEU if p.energy/p.stats.energy>cell/10.0 else T.TINTA_3)
		if cell<ceili(cost/p.stats.energy*10) and cost>0:c.draw_rect(cell_rect.grow(1),T.SOL,false,1)
	text(c,card.position+Vector2(339,92),"%d%%"%roundi(p.energy/p.stats.energy*100),14)
	var center:Vector2=boxes.clock.get_center()
	var diamond:=PackedVector2Array([center+Vector2(0,-45),center+Vector2(55,0),center+Vector2(0,45),center+Vector2(-55,0)])
	c.draw_colored_polygon(diamond,T.TINTA)
	diamond.append(diamond[0]);c.draw_polyline(diamond,T.PAPEL,3,true)
	var color:=T.RABIOLA if seconds<=10 and lesson<0 else T.SOL
	text(c,center+Vector2(-23,9),str(int(ceilf(seconds))) if lesson<0 else "%d/5"%(lesson+1),32,color)
	Ink.plate(c,Rect2(center+Vector2(-60,49),Vector2(120,24)),T.TINTA,T.TINTA,4)
	text(c,center+Vector2(-35,66),"RODADA %d"%round_no if lesson<0 else "TREINO",14)
	Ink.plate(c,boxes.weather,T.TINTA,T.TINTA,6)
	text(c,boxes.weather.position+Vector2(14,20),"Vento %s · %s"%["leve" if absf(wind)<6 else "moderado","→" if wind>=0 else "←"],14,T.PAPEL_2)
	if seconds<=10 and lesson<0:
		text(c,Vector2(c.size.x/2-57,187),"ÚLTIMOS 10 s",16,T.RABIOLA)
