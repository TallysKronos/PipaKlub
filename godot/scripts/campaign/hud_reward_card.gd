extends PanelContainer
## Read-only receipt. Uncommitted projections never count up as already-earned XP.
const Hud=preload("res://scripts/campaign/hud.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var summary:Dictionary={}
var portrait_texture:AtlasTexture
var reduced_motion:=false
var text_scale:=1.0
var elapsed:=0.0
var shown:=-1
var earned:Label
var levels:Label
var progress:ProgressBar
var progress_caption:Label
var level_sticker:Label
var loot_cards:Array[Control]=[]
var tamer_progress:ProgressBar
var tamer_start:=0
var tamer_before:=0
var tamer_after:=0
var scroll:ScrollContainer
var partner_art:TextureRect
func _init() -> void:set_meta("owns_ui_theme",true)
func caption(value:String,parent:Node,font:int=18,role:String="") -> Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_override("font",T.label() if font>=24 else T.text());label.add_theme_font_size_override("font_size",roundi(font*text_scale));label.add_theme_color_override("font_color",T.MURAL_TEAL if role=="accent" else T.MURAL_MUTED if role=="muted" else T.MURAL_INK);parent.add_child(label);return label
func portrait(texture:Texture2D,parent:Node,extent:Vector2) -> TextureRect:
	var art:=TextureRect.new();art.texture=texture;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=extent;art.size_flags_vertical=SIZE_SHRINK_BEGIN;parent.add_child(art);return art
func meter(parent:Node,value:float,maximum:float) -> ProgressBar:
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=12;bar.max_value=maxf(1,maximum);bar.value=value
	var fill:=StyleBoxFlat.new();fill.bg_color=T.MURAL_TEAL;bar.add_theme_stylebox_override("fill",fill)
	var track:=StyleBoxFlat.new();track.bg_color=T.alpha(T.MURAL_INK,.18);bar.add_theme_stylebox_override("background",track);parent.add_child(bar);return bar
func column(parent:Node) -> VBoxContainer:
	var result:=VBoxContainer.new();result.size_flags_horizontal=SIZE_EXPAND_FILL;result.add_theme_constant_override("separation",10);parent.add_child(result);return result
func _ready() -> void:
	text_scale=maxf(text_scale,Mural.text_scale_for(self));Mural.install(self)
	var spacing:=StyleBoxEmpty.new()
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:spacing.set_content_margin(side,32)
	add_theme_stylebox_override("panel",spacing)
	scroll=ScrollContainer.new();scroll.follow_focus=true;scroll.focus_mode=FOCUS_ALL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.gui_input.connect(_scroll_input);add_child(scroll)
	var row:=HBoxContainer.new();row.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",24);scroll.add_child(row)
	var tamer:=column(row);tamer.size_flags_stretch_ratio=.8
	caption("PIPEIRO · PRÉVIA" if not summary.get("committed",false) else "PIPEIRO",tamer,18,"accent")
	var tamer_art:=AtlasTexture.new();tamer_art.atlas=load("res://assets/campaign/portrait-kael-manga-v4.png");tamer_art.region=Rect2(120,0,610,900);portrait(tamer_art,tamer,Vector2(120,142))
	var trainer:Dictionary=summary.get("tamer",{})
	caption(trainer.get("name","Kael"),tamer,24)
	var total:int=trainer.get("after",0);var tamer_level:=1
	while tamer_level<100 and total>=20*tamer_level+3*tamer_level*tamer_level:tamer_level+=1
	tamer_start=20*(tamer_level-1)+3*(tamer_level-1)*(tamer_level-1);tamer_before=trainer.get("before",total);tamer_after=total
	caption("Nv. %d · +%d XP"%[tamer_level,trainer.get("xp",0)],tamer,18,"accent")
	tamer_progress=meter(tamer,total-tamer_start,20*tamer_level+3*tamer_level*tamer_level-tamer_start)
	var middle:=column(row);middle.size_flags_stretch_ratio=1.4
	caption("PARCEIRO EM VOO",middle,18,"accent")
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",12);middle.add_child(hero)
	if portrait_texture!=null:partner_art=portrait(portrait_texture,hero,Vector2(100,132))
	var partner_info:=column(hero)
	levels=caption("",partner_info,26);earned=caption("",partner_info,22,"accent");progress=meter(partner_info,0,1);progress_caption=caption("",partner_info,16,"muted")
	level_sticker=caption("",middle,18,"accent");level_sticker.hide()
	for entry in summary.get("team",[]).slice(1):
		var level:=Model.level_for_xp(entry.get("xp",0))
		caption("%s · Nv. %d\nSem participação · 0 XP"%[entry.get("personalName",entry.get("modelId","Parceiro")),level],middle,16,"muted")
	var loot:=column(row);loot.size_flags_stretch_ratio=1.1
	caption("AO CONTINUAR" if not summary.get("committed",false) else "JORNADA GUARDADA",loot,18,"accent")
	caption("+%d moedas"%summary.coins if summary.get("coins",0)>0 else "Sem moedas",loot,24)
	if summary.get("stars",0)>0:caption("★".repeat(int(summary.stars))+" · %d estrelas"%summary.stars,loot,20)
	if summary.has("unlock"):caption(summary.unlock,loot,18,"accent")
	for item in summary.get("items",[]):
		var paper:=preload("res://scripts/ui_mural/menu_surface.gd").new();paper.density=.18;loot.add_child(paper);loot_cards.append(paper)
		var item_column:=column(paper)
		if item in summary.get("new_items",[]):caption("NOVO REGISTRO",item_column,16,"accent")
		caption(str(item),item_column,18)
	if summary.get("items",[]).is_empty():caption("Nenhum item nesta batalha.",loot,18,"muted")
	caption(summary.get("notice","A prévia será guardada ao continuar."),loot,16,"muted")
	resized.connect(queue_redraw);advance(0)
func advance(delta:float) -> void:
	elapsed+=maxf(0,delta)
	var fraction:=1.0 if reduced_motion or not summary.get("committed",false) else 1.0-pow(1.0-clampf(elapsed/1.1,0,1),3)
	for card in loot_cards:card.modulate.a=1
	if is_instance_valid(partner_art):partner_art.texture=portrait_texture
	if is_instance_valid(tamer_progress):tamer_progress.value=maxi(0,roundi(lerpf(tamer_before,tamer_after,fraction))-tamer_start)
	var amount:=roundi(summary.get("xp",0)*fraction)
	if shown==amount:return
	shown=amount
	var total:int=summary.get("before",0)+amount;var level:=Model.level_for_xp(total);var before_level:=Model.level_for_xp(summary.get("before",0))
	levels.text="%s\nNv. %d"%[summary.get("name","Seu parceiro"),before_level]+(" → %d"%level if level>before_level else "")
	earned.text=("+%d XP"%amount if amount>0 else "Sem XP")+(" · prévia" if not summary.get("committed",false) else "")
	level_sticker.visible=level>before_level;level_sticker.text="NOVO NÍVEL" if summary.get("committed",false) else "Próximo nível ao continuar"
	var base:=Model.xp_for_level(level);var threshold:=Model.xp_for_level(level+1) if level<50 else base+1
	progress.max_value=threshold-base;progress.value=total-base if level<50 else progress.max_value;progress_caption.text="%d / %d XP"%[total-base,threshold-base] if level<50 else "Nível máximo"
func _scroll_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		scroll.scroll_vertical+=roundi(64*text_scale)*(1 if event.is_action_pressed("ui_down") else -1);scroll.accept_event()
func _draw() -> void:Paper.frame(self,Rect2(Vector2.ZERO,size),"MuralPaperPanel",.4)
