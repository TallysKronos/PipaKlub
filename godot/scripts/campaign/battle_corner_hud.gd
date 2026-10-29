extends RefCounted
## Shared battle / lesson corner presentation. Opponent energy is never consumed here.
const Hud=preload("res://scripts/campaign/hud.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const PILOT=preload("res://assets/campaign/portrait-kael.png")
static func regions(size:Vector2,rivals:int=1) -> Dictionary:
	return {"pilot":Rect2(20,14,300,70),"partner":Rect2(20,size.y-114,380,98),"clock":Rect2(size.x/2-45,12,90,90),"weather":Rect2(size.x/2-125,108,250,30),"rivals":Rect2(size.x-330,14,310,112 if rivals==1 else 66*rivals)}
static func text(c:CanvasItem,p:Vector2,value:String,font_size:int=16,color:Color=T.PAPEL) -> void:
	c.draw_string(Hud.font(true),p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
static func line_color(fraction:float) -> Color:
	return T.RABIOLA if fraction<.25 else T.SOL if fraction<.5 else T.FOLHA
static func rival_summary(actor:Dictionary) -> Dictionary:
	return {"name":actor.get("name","Selvagem"),"hp":actor.hp,"hull":actor.hull,"stats":{"line":actor.stats.line},"rounds":actor.get("rounds",0)}
static func bar(c:CanvasItem,rect:Rect2,fraction:float,color:Color) -> void:
	c.draw_colored_polygon(Ink.shape(rect,3),T.TINTA_3)
	if rect.size.x*clampf(fraction,0,1)>.5:c.draw_colored_polygon(Ink.shape(Rect2(rect.position,Vector2(rect.size.x*clampf(fraction,0,1),rect.size.y)),3),color)
# Label · bar · value row used by every card (uppercase Barlow, value aligned right).
static func row(c:CanvasItem,origin:Vector2,label:String,fraction:float,color:Color,value:String,thickness:float=9) -> void:
	text(c,origin,label,14)
	bar(c,Rect2(origin+Vector2(78,-thickness-1),Vector2(168,thickness)),fraction,color)
	text(c,origin+Vector2(256,0),value,14)
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
	# Approved board: names in Lilita, uppercase Barlow labels, bars with the value on the right.
	var pilot:Rect2=boxes.pilot
	Ink.plate(c,pilot,T.TINTA,T.CEU,14)
	var face:=Rect2(pilot.position+Vector2(12,11),Vector2(48,48))
	c.draw_rect(face.grow(2),T.NANQUIM)
	c.draw_texture_rect_region(PILOT,face,Rect2(160,10,460,500))
	c.draw_string(Hud.display(),pilot.position+Vector2(74,36),Ink.ellipsis(player.get("name","Kael"),Hud.display(),24,150),HORIZONTAL_ALIGNMENT_LEFT,-1,24,T.PAPEL)
	var xp:int=player.get("tamerXp",0)
	var level:=1
	while level<100 and xp>=20*level+3*level*level:level+=1
	text(c,pilot.position+Vector2(74,58),"TAMER · NV. %d"%level,15,T.PAPEL_2)
	diamonds(c,pilot.position+Vector2(222,54),actors[0].get("rounds",0),rounds,T.CEU)
	for index in range(1,actors.size()):
		var a:Dictionary=rival_summary(actors[index])
		var compact:bool=actors.size()>2
		var box:=Rect2(boxes.rivals.position+Vector2(0,(index-1)*66),Vector2(310,60 if compact else 112))
		Ink.plate(c,box,T.TINTA,T.RABIOLA,14)
		var parts:PackedStringArray=str(names[index]).split(" · ")
		var species:String=parts[0]
		var tag:=(str(a.get("name","Selvagem"))+(" · "+" · ".join(parts.slice(1)) if parts.size()>1 else "")).to_upper()
		var tag_width:=Hud.font(true).get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		text(c,Vector2(box.end.x-18-tag_width,box.position.y+24),tag,14,T.RABIOLA)
		c.draw_string(Hud.display(),box.position+Vector2(16,30),Ink.ellipsis(species,Hud.display(),24,box.size.x-tag_width-44),HORIZONTAL_ALIGNMENT_LEFT,-1,24,T.PAPEL)
		var fraction:float=a.hp/a.stats.line
		if compact:
			bar(c,Rect2(box.position+Vector2(16,42),Vector2(190,9)),fraction,line_color(fraction))
			diamonds(c,box.position+Vector2(226,47),a.get("rounds",0),rounds,T.RABIOLA)
		else:
			row(c,box.position+Vector2(16,60),"LINHA",fraction,line_color(fraction),"%d%%"%roundi(fraction*100),10)
			row(c,box.position+Vector2(16,86),"ARMAÇÃO",a.hull/a.stats.line,T.PAPEL_2,"%d%%"%roundi(a.hull/a.stats.line*100),7)
	var p:Dictionary=actors[0]
	var card:Rect2=boxes.partner
	Ink.plate(c,card,T.TINTA,T.CEU,14)
	if faces[0]!=null:c.draw_texture_rect(faces[0],Hud.fit_texture(faces[0],Rect2(card.position+Vector2(8,10),Vector2(64,80))),false)
	var title_parts:PackedStringArray=str(names[0]).split(" · ")
	c.draw_string(Hud.display(),card.position+Vector2(84,30),Ink.ellipsis(title_parts[0],Hud.display(),22,200),HORIZONTAL_ALIGNMENT_LEFT,-1,22,T.PAPEL)
	if title_parts.size()>1:
		var level_tag:=title_parts[1].to_upper()
		text(c,Vector2(card.end.x-18-Hud.font(true).get_string_size(level_tag,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x,card.position.y+26),level_tag,15,T.PAPEL_2)
	var f:float=p.hp/p.stats.line
	row(c,card.position+Vector2(84,52),"LINHA",f,line_color(f),"%d%%"%roundi(f*100),10)
	row(c,card.position+Vector2(84,71),"ARMAÇÃO",p.hull/p.stats.line,T.PAPEL_2,"%d%%"%roundi(p.hull/p.stats.line*100),7)
	text(c,card.position+Vector2(84,90),"ENERGIA",14)
	for cell in 10:
		var cell_rect:=Rect2(card.position+Vector2(162+cell*16,81),Vector2(13,9))
		c.draw_rect(cell_rect,T.CEU if p.energy/p.stats.energy>cell/10.0 else T.TINTA_3)
		if cell<ceili(cost/p.stats.energy*10) and cost>0:c.draw_rect(cell_rect.grow(1),T.SOL,false,1)
	text(c,card.position+Vector2(card.size.x-40,90),str(roundi(p.energy/p.stats.energy*10)),15)
	var center:Vector2=boxes.clock.get_center()
	var diamond:=PackedVector2Array([center+Vector2(0,-45),center+Vector2(55,0),center+Vector2(0,45),center+Vector2(-55,0)])
	c.draw_colored_polygon(diamond,T.TINTA)
	diamond.append(diamond[0]);c.draw_polyline(diamond,T.PAPEL,3,true)
	var color:=T.RABIOLA if seconds<=10 and lesson<0 else T.SOL
	text(c,center+Vector2(-23,9),str(int(ceilf(seconds))) if lesson<0 else "%d/5"%(lesson+1),32,color)
	# One paper plate under the clock: round and wind read together (approved HUD board).
	var plate:Rect2=boxes.weather
	Ink.plate(c,plate,T.PAPEL,T.NANQUIM,6)
	var label:String=("RODADA %d"%round_no if lesson<0 else "TREINO")+" · VENTO %s %s"%["LEVE" if absf(wind)<6 else "MODERADO","→" if wind>=0 else "←"]
	var width:float=Hud.font(true).get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
	text(c,Vector2(plate.get_center().x-width/2,plate.position.y+21),label,15,T.TINTA)
	if seconds<=10 and lesson<0:
		text(c,Vector2(c.size.x/2-57,187),"ÚLTIMOS 10 s",16,T.RABIOLA)
