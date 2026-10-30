extends Control
## Deterministic in-engine boss introduction. No rewards, saves or automatic battle.
signal finished
signal cue(event_id:String)
const Hud=preload("res://scripts/campaign/hud.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const DURATION=10.5
var park:Node2D
var reduced_motion:=false
var elapsed:=0.0
var done:=false
var portrait:Node2D
var portrait_layer:Control
var caption:Label
var name_label:Label
var subtitle:Label
var skip:Button
var initial_camera:=Vector2.ZERO
var initial_zoom:=Vector2.ONE
var initial_smoothing:=true
var initial_hud:=true
var initial_map:=true
var boss_at:=Vector2.ZERO
var called:Dictionary={}
var pipes:Array=[]
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	initial_camera=park.camera.position;initial_zoom=park.camera.zoom
	initial_smoothing=park.camera.position_smoothing_enabled
	initial_hud=park.exploration_hud.visible
	initial_map=park.exploration_hud.map.visible
	boss_at=park.model.project(Checkpoint.target("park-veredas","boss"))-Vector2(0,55)
	park.path.clear();park.paused=true;park.guardian_focus=true
	park.avatar.moving=false;park.avatar.running=false
	park.camera.position_smoothing_enabled=false;park.exploration_hud.hide()
	park.exploration_hud.map.hide()
	for piece in park.model.data.pieces:
		if piece.asset!="canos-patio":continue
		var node:Node2D=park.piece_nodes.get(str(piece.id))
		if is_instance_valid(node) and node.has_node("Art"):
			var art:Node2D=node.get_node("Art")
			pipes.append({"art":art,"position":art.position})
	portrait_layer=Control.new();add_child(portrait_layer);portrait_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	portrait=load("res://scripts/campaign/lacertubo_cinematic_actor.gd").new();portrait.configure("lacertubo");portrait.reduced_motion=reduced_motion;portrait_layer.add_child(portrait)
	name_label=Label.new();name_label.text="LACERTUBO";name_label.add_theme_font_override("font",Hud.font());add_child(name_label)
	name_label.add_theme_color_override("font_color",Color("f5deb1"))
	subtitle=Label.new();subtitle.text="GUARDIÃO DOS CANOS";subtitle.add_theme_color_override("font_color",Color("9bd0b6"));add_child(subtitle)
	caption=Label.new();caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(caption)
	caption.add_theme_color_override("font_color",Color("f4e8d0"))
	skip=Button.new();skip.text="Pular · Esc";skip.custom_minimum_size=Vector2(146,42);Hud.navigation_button(skip,true);add_child(skip);skip.pressed.connect(complete);skip.grab_focus()
	draw.connect(_draw_frame);resized.connect(_layout);_layout();advance(0)
func _layout() -> void:
	var scale_factor:=minf(size.x/1280,size.y/720)
	portrait_layer.position=Vector2(size.x*.26,size.y*.76)
	portrait.scale=Vector2.ONE*minf(size.y*.51,size.x*.30)/portrait.native_height
	name_label.position=Vector2(size.x*.53,size.y*.39);name_label.add_theme_font_size_override("font_size",int(62*scale_factor))
	subtitle.position=Vector2(size.x*.535,size.y*.51);subtitle.add_theme_font_size_override("font_size",int(24*scale_factor))
	caption.position=Vector2(size.x*.08,size.y*.80);caption.size=Vector2(size.x*.84,size.y*.12);caption.add_theme_font_size_override("font_size",maxi(17,int(23*scale_factor)))
	skip.position=Vector2(size.x-skip.size.x-24,16)
func _process(delta:float) -> void:advance(delta)
func advance(delta:float) -> void:
	if done:return
	elapsed=minf(DURATION,elapsed+delta)
	var reveal:=smoothstep(1.1,3.2,elapsed)
	var returning:=smoothstep(8.2,DURATION,elapsed)
	var destination:=initial_camera.lerp(boss_at,reveal)
	park.camera.position=destination.lerp(initial_camera,returning)
	park.camera.zoom=initial_zoom if reduced_motion else initial_zoom.lerp(Vector2.ONE*1.65,reveal).lerp(initial_zoom,returning)
	if not reduced_motion and elapsed>1 and elapsed<1.8:park.camera.offset=Vector2(sin(elapsed*45)*1.5,0)
	else:park.camera.offset=Vector2.ZERO
	for pipe in pipes:
		var tremor:=sin(elapsed*34)*1.8 if elapsed>=.8 and elapsed<2.8 and not reduced_motion else 0.0
		pipe.art.position=pipe.position+Vector2(tremor,0)
	var hero:bool=elapsed>=3.25 and elapsed<7.6
	portrait_layer.visible=hero;name_label.visible=hero;subtitle.visible=hero
	portrait_layer.modulate.a=smoothstep(3.25,3.65,elapsed)*(1-smoothstep(7.15,7.6,elapsed))
	portrait.perform(elapsed);portrait.animate(delta)
	name_label.modulate.a=portrait_layer.modulate.a;subtitle.modulate.a=portrait_layer.modulate.a
	caption.text="Os canos vibram… alguma coisa está ouvindo." if elapsed<2.8 else "" if elapsed<7.6 else "KAEL   A rabiola da Nina está atrás dele.\nVou esperar a vela baixar para encontrar uma abertura."
	if elapsed>=1.0:_cue("pipes","world.interact")
	if elapsed>=3.25:_cue("signature","battle.signature_lacertubo")
	if elapsed>=4.2:_cue("cry","creature.lacertubo")
	queue_redraw()
	if elapsed>=DURATION:complete()
func _cue(id:String,event_id:String) -> void:
	if called.has(id):return
	called[id]=true;cue.emit(event_id)
func complete() -> void:
	if done:return
	done=true;_restore();finished.emit()
func _restore() -> void:
	for pipe in pipes:
		if is_instance_valid(pipe.art):pipe.art.position=pipe.position
	if not is_instance_valid(park) or not is_instance_valid(park.camera):return
	park.camera.position=initial_camera;park.camera.zoom=initial_zoom;park.camera.offset=Vector2.ZERO
	park.camera.position_smoothing_enabled=initial_smoothing;park.camera.reset_smoothing()
	park.guardian_focus=false;park.paused=false;park.encounter_grace=maxf(park.encounter_grace,6)
	park.exploration_hud.visible=initial_hud
	park.exploration_hud.map.visible=initial_map
func _exit_tree() -> void:
	if not done:_restore()
func _input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled();complete()
func _draw_frame() -> void:
	var opening:=smoothstep(0,.45,elapsed)*(1-smoothstep(9.7,DURATION,elapsed))
	var bar:=size.y*.095*opening
	draw_rect(Rect2(0,0,size.x,bar),Color("101e28"));draw_rect(Rect2(0,size.y-bar,size.x,bar),Color("101e28"))
	if elapsed>=3.25 and elapsed<7.6:
		var alpha:=portrait_layer.modulate.a
		draw_rect(Rect2(Vector2.ZERO,size),Color(.035,.09,.12,.65*alpha))
		var polygon:=PackedVector2Array([Vector2(0,size.y*.22),Vector2(size.x,size.y*.16),Vector2(size.x,size.y*.72),Vector2(0,size.y*.79)])
		draw_colored_polygon(polygon,Color(.05,.17,.19,.97*alpha))
		draw_polyline(PackedVector2Array([polygon[0],polygon[1]]),Color(.85,.64,.33,alpha),3,true)
		draw_polyline(PackedVector2Array([polygon[2],polygon[3]]),Color(.85,.64,.33,alpha),3,true)
		for i in 14:
			var y:=size.y*(.23+i*.036)
			var drift:=0.0 if reduced_motion else fmod(elapsed*38,70)
			draw_line(Vector2(size.x*.48+drift,y),Vector2(size.x*(.68+float(i%3)*.11)+drift,y-12),Color(.48,.68,.60,.14*alpha),1,true)
	if not caption.text.is_empty():
		draw_rect(Rect2(size.x*.06,size.y*.795,size.x*.88,size.y*.12),Color(.04,.09,.13,.88))
