extends "res://scripts/campaign/park_overworld_view.gd"
const Row=preload("res://scripts/campaign/marisol_row_trip.gd")
const Motion=preload("res://scripts/campaign/row_motion.gd")
var row_record:Dictionary={}
var row_motion:RefCounted
var row_sent:=false
var paddle_pointer:=false
var raft:Node2D
var capy:Node2D
var capy_sprite:Sprite2D
var towline:Line2D
var paddle_button:Button
func _ready()->void:
 super._ready()
 paddle_button=Button.new();paddle_button.text="Segurar · Remar";paddle_button.position=Vector2(30,590);paddle_button.size=Vector2(240,60);paddle_button.visible=false
 paddle_button.button_down.connect(func():paddle_pointer=true);paddle_button.button_up.connect(func():paddle_pointer=false)
 exploration_hud.add_child(paddle_button)
 for entry:Dictionary in Row.data().links:
  var marker:=Node2D.new();marker.position=model.project(Row.point(entry.from));actors.add_child(marker)
  marker.draw.connect(func():
   var direction:Vector2=(model.project(Row.point(entry.to))-marker.position).normalized();var side:=direction.orthogonal();var tint:=Color("65c8ef") if Row.allowed(saved_player) else Color("82959b")
   marker.draw_arc(Vector2.ZERO,18,0,TAU,24,tint,2,true)
   marker.draw_colored_polygon(PackedVector2Array([direction*15,direction*-6+side*7,direction*-6-side*7]),tint))
func _build_events()->void:
 for e:Dictionary in Row.events():
  if not interaction_events.any(func(old):return int(old.id)==int(e.id)):interaction_events.append(e)
 super._build_events()
func checkpoint_point()->Vector2:return Row.point(Row.link(row_record.link).from) if not row_record.is_empty() else player
func can_run()->bool:return row_record.is_empty()
func toggle_run()->void:
 if row_record.is_empty():super.toggle_run()
func play_row(record:Dictionary)->void:
 row_record=record.duplicate(true);row_motion=Motion.new(record.id,record.link);row_sent=false;paddle_pointer=false;path.clear();follower_trail.clear()
 avatar.moving=false;avatar.running=false;follower_root.hide();exploration_hud.show_partner=false;exploration_hud.partner_panel.hide()
 raft=Node2D.new();actors.add_child(raft)
 raft.draw.connect(func():
  var outline:=PackedVector2Array([Vector2(-40,0),Vector2(0,-20),Vector2(40,0),Vector2(0,20)])
  raft.draw_colored_polygon(outline,Color("a97e4c"));raft.draw_polyline(PackedVector2Array([outline[0],outline[1],outline[2],outline[3],outline[0]]),Color("513e30"),2,true)
  for i in [-2,-1,0,1,2]:raft.draw_line(Vector2(-28+i*5,-4-i*2),Vector2(14+i*5,17-i*2),Color("654e37"),1,true))
 towline=Line2D.new();towline.width=1.5;towline.default_color=Color("e8d9b4");raft.add_child(towline)
 capy=Node2D.new();actors.add_child(capy);capy_sprite=Sprite2D.new();capy.add_child(capy_sprite)
 capy.draw.connect(func():
  for side in [-1,1]:capy.draw_arc(Vector2(side*20,0),23,0,PI,18,Color(.65,.88,.78,.7),2,true))
 capy_sprite.texture=load("res://assets/campaign/marisol-row-v1/capivara-d-swim.png");capy_sprite.region_enabled=true;capy_sprite.scale=Vector2.ONE*140/512;capy_sprite.offset=Vector2(0,-256)
 paddle_button.show();paddle_button.text="Segurar · Remar · "+Controls.prompt("interact")
func finish_row()->void:
 var end:=Row.point(Row.link(row_record.link).to);player=end;follower=end;row_record.clear();row_sent=false;paddle_pointer=false
 raft.queue_free();capy.queue_free();paddle_button.hide();follower_root.show();exploration_hud.show_partner=true;follower_trail.clear();_refresh_positions();encounter_grace=8
 exploration_hud.push_notice("Prática de Remar concluída · capivara de apoio de Marisol","saved")
func _process(delta:float)->void:
 super._process(delta)
 if row_record.is_empty():return
 exploration_hud.run_button.hide();exploration_hud.mount_button.hide()
 hint.text=("Chegada pronta · "+Controls.prompt("interact")+" para tentar salvar") if row_motion.complete else "Segure "+Controls.prompt("interact")+" para remar · solte para descansar · fôlego %d%%"%row_motion.energy
func _physics_process(delta:float)->void:
 if row_record.is_empty():super._physics_process(delta);return
 if paused:return
 row_motion.tick(delta,paddle_pointer or Controls.held("interact"));clock+=minf(maxf(delta,0),.05)
 var entry:=Row.link(row_record.link);var a:=Row.point(entry.from);var b:=Row.point(entry.to);var t:float=row_motion.progress
 player=a.lerp(b,t);follower=player;_refresh_positions();avatar.face_motion(model.project(b,false)-model.project(a,false));avatar.moving=false;avatar.running=false
 var p:=model.project(player,false);var drift:=0.0 if reduced_motion else sin(clock*4)*1.5
 player_root.position=p;avatar.position=Vector2(0,-5+drift)
 raft.position=p+Vector2(0,3+drift);raft.z_index=player_root.z_index-1
 var swim:Vector2=a.move_toward(b,minf(a.distance_to(b)-.7,t*a.distance_to(b)+1.8))
 capy.position=model.project(swim,false)+Vector2(0,drift);capy.z_index=player_root.z_index
 towline.points=PackedVector2Array([Vector2(0,-4),capy.position-raft.position+Vector2(-15,-22)])
 var frame:int=int(clock*6)%4
 capy_sprite.region_rect=Rect2((frame%2)*768,(frame/2)*512,768,512);capy_sprite.flip_h=model.project(b,false).x>model.project(a,false).x
 camera.position=p
 if row_motion.complete and not row_sent:row_sent=true;action_requested.emit("row-land:"+str(row_record.id))
func interact()->void:
 if not row_record.is_empty():
  if row_motion.complete:action_requested.emit("row-land:"+str(row_record.id))
  return
 super.interact()
func walk_to(point:Vector2)->bool:
 if not row_record.is_empty():return false
 return super.walk_to(point)
