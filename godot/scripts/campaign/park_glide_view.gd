extends "res://scripts/campaign/park_overworld_view.gd"
## Campaign-only glide presentation. Persistent operations remain in NinaGlide.
const Glide=preload("res://scripts/campaign/nina_glide.gd")
const DEPART:=.45
const FLIGHT:=2.0
const SETTLE:=.4
const FOLLOW_DELAY:=.25
var glide_record:Dictionary={}
var glide_elapsed:=0.0
var landing_wait:=false
var loan_root:Node2D
var loan_sprite:Sprite2D
var landing_sent:=false
func _ready()->void:
	super._ready()
	_build_glide_marks()
	if saved_checkpoint.scene=="park-veredas" and preload("res://scripts/campaign/canal_gate.gd").available(saved_player):
		var wheel:=Node2D.new();wheel.position=model.project(preload("res://scripts/campaign/canal_gate.gd").AT);actors.add_child(wheel)
		wheel.draw.connect(func():
			wheel.draw_line(Vector2.ZERO,Vector2(0,-26),Color("36566a"),6)
			wheel.draw_arc(Vector2(0,-30),10,0,TAU,20,Color("e5b66d"),3,true)
			wheel.draw_line(Vector2(-9,-30),Vector2(9,-30),Color("e5b66d"),2))
func _build_events()->void:
	for e:Dictionary in Glide.events(saved_checkpoint.scene):
		if not interaction_events.any(func(old):return int(old.id)==int(e.id)):interaction_events.append(e)
	super._build_events()
func _build_glide_marks()->void:
	for entry:Dictionary in Glide.data().links:
		if Glide.scene_for(entry)!=saved_checkpoint.scene:continue
		var marker:=Node2D.new();marker.position=model.project(Glide.point(entry.from));marker.z_index=4;actors.add_child(marker)
		marker.draw.connect(func():
			var color:=Color("65c8ef") if Glide.allowed(saved_player) else Color("82959b")
			marker.draw_arc(Vector2.ZERO,15,0,TAU,24,color,2,true)
			var direction:Vector2=(model.project(Glide.point(entry.to))-model.project(Glide.point(entry.from))).normalized()
			var side:=direction.orthogonal()
			marker.draw_colored_polygon(PackedVector2Array([direction*13,direction*-5+side*7,direction*-5-side*7]),color))
func checkpoint_point()->Vector2:
	return Glide.point(Glide.link(glide_record.link).from) if not glide_record.is_empty() else player
func _process(delta:float)->void:
	super._process(delta)
	if glide_record.is_empty():return
	exploration_hud.run_button.hide();exploration_hud.mount_button.hide()
	hint.text="Carcará da Nina · Planando" if not landing_wait else Controls.prompt("interact")+" · Tentar salvar a chegada"
func toggle_run()->void:
	if glide_record.is_empty():super.toggle_run()
func can_run()->bool:return glide_record.is_empty()
func play_glide(flight:Dictionary)->void:
	glide_record=flight.duplicate(true);glide_elapsed=0;landing_wait=false;landing_sent=false;path.clear();follower_trail.clear()
	player=Glide.point(Glide.link(flight.link).from);follower=player
	avatar.moving=false;avatar.running=false
	loan_root=Node2D.new();actors.add_child(loan_root)
	loan_sprite=Sprite2D.new();loan_root.add_child(loan_sprite)
	loan_sprite.texture=load("res://assets/campaign/"+content.combat["basic-carcara"].image);loan_sprite.region_enabled=true
	loan_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var region:Dictionary=content.combat["basic-carcara"].animations.idle[0]
	loan_sprite.region_rect=Rect2(region.x,region.y,region.w,region.h);loan_sprite.scale=Vector2.ONE*110/maxf(region.w,region.h)
	var tether:=Line2D.new();tether.width=1.8;tether.default_color=Color("e2dab8");tether.points=PackedVector2Array([Vector2(0,-93),Vector2(0,-22)]);loan_root.add_child(tether)
func finish_glide()->void:
	var entry:=Glide.link(glide_record.link);player=Glide.point(entry.to);follower=player
	glide_record.clear();landing_wait=false;landing_sent=false;follower_trail.clear();avatar.stop_jump()
	if is_instance_valid(loan_root):loan_root.queue_free()
	_refresh_positions();encounter_grace=8.0
	exploration_hud.push_notice("Planar aprendido · Carcará voltou para a Nina","saved")
func _physics_process(delta:float)->void:
	if glide_record.is_empty():
		super._physics_process(delta);return
	if paused:return
	glide_elapsed+=maxf(0,delta);clock+=delta
	var entry:=Glide.link(glide_record.link);var a:=Glide.point(entry.from);var b:=Glide.point(entry.to)
	var t:=clampf((glide_elapsed-DEPART)/FLIGHT,0,1)
	var follower_t:=clampf((glide_elapsed-DEPART-FOLLOW_DELAY)/FLIGHT,0,1)
	player=a.lerp(b,t);follower=a.lerp(b,follower_t)
	_refresh_positions()
	var height:float=model.height_at(a)
	var lift:=sin(PI*t)*92
	player_root.position=model.project(player,false);avatar.position=Vector2(0,-height*64-lift)
	follower_root.position=model.project(follower,false);companion.position=Vector2(0,-height*64-sin(PI*follower_t)*65)
	avatar.face_motion(model.project(b,false)-model.project(a,false));avatar.jump_pose(t)
	if is_instance_valid(loan_root):
		loan_root.position=model.project(player,false)-Vector2(0,height*64+lift);loan_root.z_index=player_root.z_index+1
		loan_sprite.position=Vector2(0,-108)
		var frame:Dictionary=content.combat["basic-carcara"].animations.idle[int(clock*12)%content.combat["basic-carcara"].animations.idle.size()]
		loan_sprite.region_rect=Rect2(frame.x,frame.y,frame.w,frame.h)
	camera.position=model.project(player,false)-Vector2(0,height*64+lift*.45)
	hint.text="Carcará da Nina · Planando" if not landing_wait else Controls.prompt("interact")+" · Tentar salvar a chegada"
	if glide_elapsed>=DEPART+FLIGHT+SETTLE+FOLLOW_DELAY and not landing_sent:
		landing_wait=true;landing_sent=true;action_requested.emit("glide-land:"+str(glide_record.id))
func interact()->void:
	if not glide_record.is_empty():
		if landing_wait:action_requested.emit("glide-land:"+str(glide_record.id))
		return
	super.interact()
func walk_to(point:Vector2)->bool:
	if not glide_record.is_empty():return false
	return super.walk_to(point)
