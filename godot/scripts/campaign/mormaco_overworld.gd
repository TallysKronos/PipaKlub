extends Node2D
const Story=preload("res://scripts/campaign/mormaco_story.gd")
var view:Node2D
var root:Node2D
var sprite:Sprite2D
var age:=0.0
var was_free:=false
var initialized:=false
var staging:=false
var tyler:Sprite2D
func _ready()->void:
 view=get_parent();root=Node2D.new();root.position=view.model.project(Vector2(24,18),false)+Vector2(0,24);view.actors.add_child(root)
 sprite=Sprite2D.new();root.add_child(sprite)
 root.draw.connect(func():
  root.draw_set_transform(Vector2.ZERO,0,Vector2(1,.3))
  root.draw_arc(Vector2.ZERO,105,0,TAU,64,Color(.25,.52,.44,.7),3,true)
  root.draw_arc(Vector2.ZERO,125,.15,PI-.15,32,Color(.4,.64,.52,.5),2,true))
 refresh()
func refresh()->void:
 var free:bool=Story.freed(view.saved_player)
 if initialized and free==was_free:
  view.exploration_hud.objective.text=Story.objective(view.saved_player);return
 var old_texture:=AtlasTexture.new()
 old_texture.atlas=sprite.texture
 old_texture.region=sprite.region_rect
 age=0.0
 var possessed:bool=not free and (Story.won(view.saved_player) or view.saved_player.flags.get("mormacoTylerChegou",false))
 sprite.texture=load("res://assets/campaign/mormaco-v1/"+("submerged-possession.png" if possessed else "submerged.png"))
 sprite.region_enabled=true
 sprite.region_filter_clip_enabled=true
 sprite.region_rect=Rect2(0,0,320,320)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale=Vector2.ONE*1.15
 sprite.offset=Vector2(0,-142)
 root.queue_redraw()
 view.exploration_hud.objective.text=Story.objective(view.saved_player)
 if initialized and free and not was_free and not view.reduced_motion:
  var ghost:=Sprite2D.new();ghost.texture=old_texture;ghost.scale=sprite.scale;ghost.offset=sprite.offset;root.add_child(ghost)
  sprite.modulate.a=0
  var fade:=create_tween().set_parallel(true);fade.tween_property(ghost,"modulate:a",0.0,1.2);fade.tween_property(sprite,"modulate:a",1.0,1.2)
  fade.chain().tween_callback(ghost.queue_free)
 was_free=free;initialized=true
 if possessed and not Story.won(view.saved_player):show_tyler()
func _process(delta:float)->void:
 if staging:return
 if not view.paused:age+=delta
 var possessed:bool=not was_free and (Story.won(view.saved_player) or view.saved_player.flags.get("mormacoTylerChegou",false))
 var frame:=4 if possessed else 0
 if not view.reduced_motion:
  var cycle:=fmod(age,10.0)
  if cycle<8.0:
   frame=4 if possessed else int(cycle*2.0)%4
  else:
   frame=4+mini(int((cycle-8.0)*2.0),3)
 sprite.region_rect.position=Vector2((frame%4)*320,floori(frame/4.0)*320)


func play_possession()->void:
 staging=true
 var previous_camera:Vector2=view.camera.position
 var focus:Vector2=root.position+Vector2(30,-115)
 if view.reduced_motion:
  view.camera.position=focus
  view.camera.reset_smoothing()
 else:
  await create_tween().tween_property(view.camera,"position",focus,.45).set_trans(Tween.TRANS_SINE).finished
 var spool:=Node2D.new()
 root.add_child(spool)
 spool.position=Vector2(230,-150)
 spool.z_index=1
 spool.draw.connect(func():
  spool.draw_rect(Rect2(-13,-8,26,16),Color("#352240"))
  spool.draw_circle(Vector2(-13,0),9,Color("#8956a7"))
  spool.draw_circle(Vector2(13,0),9,Color("#593369")))
 if not view.reduced_motion:
  var flight:=create_tween()
  flight.tween_property(spool,"position",Vector2(105,-225),.35).set_trans(Tween.TRANS_SINE)
  flight.tween_property(spool,"position",Vector2(0,-100),.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  await flight.finished
 else:
  spool.position=Vector2(0,-100)
  await get_tree().create_timer(.35).timeout
 spool.queue_free()
 sprite.texture=load("res://assets/campaign/mormaco-v1/submerged-possession.png")
 for frame in 5:
  sprite.region_rect.position=Vector2((frame%4)*320,floori(frame/4.0)*320)
  await get_tree().create_timer(.35 if view.reduced_motion else .5).timeout
 show_tyler()
 if view.reduced_motion:
  view.camera.position=previous_camera
  view.camera.reset_smoothing()
 else:
  await create_tween().tween_property(view.camera,"position",previous_camera,.45).set_trans(Tween.TRANS_SINE).finished

func show_tyler()->void:
 if is_instance_valid(tyler):return
 tyler=Sprite2D.new()
 tyler.texture=load("res://assets/campaign/tyler-clareira-v1/tyler-overworld-idle-eight.png")
 tyler.region_enabled=true
 tyler.region_rect=Rect2(192,96,64,96)
 tyler.offset=Vector2(0,-44)
 tyler.scale=Vector2.ONE*.85
 tyler.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 tyler.position=view.model.project(view.player,false)+Vector2(-48,6)
 view.actors.add_child(tyler)
 var rai:=Sprite2D.new()
 rai.texture=load("res://assets/campaign/tyler-clareira-v1/rai-overworld-idle-eight.png")
 rai.region_enabled=true
 rai.region_rect=Rect2(192,96,64,96)
 rai.offset=Vector2(0,-44)
 rai.scale=Vector2.ONE*.85
 rai.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 rai.position=tyler.position+Vector2(-36,14)
 view.actors.add_child(rai)
