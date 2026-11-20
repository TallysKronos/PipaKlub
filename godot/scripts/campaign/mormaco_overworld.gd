extends Node2D
const Story=preload("res://scripts/campaign/mormaco_story.gd")
const LakeFx=preload("res://scripts/campaign/mormaco_lake_fx.gd")
const NORMAL=preload("res://assets/campaign/mormaco-v1/submerged.png")
const POSSESSED=preload("res://assets/campaign/mormaco-v1/submerged-possession.png")
const NPC=preload("res://scripts/npc_pixel_sprite.gd")
const Arena=preload("res://scripts/overworld/mormaco_arena.gd")
const CASTER=preload("res://assets/overworld/kits/camara-do-elo-v1/capanga-feminina-idle-eight.png")
var view:Node2D
var root:Node2D
var sprite:Sprite2D
var effect:Node2D
var shore_effect:Node2D
var waterline:ShaderMaterial
var lake_center:Vector2
var reveal_camera:Dictionary={}
var age:=0.0
var jet_clock:=0.0
var was_free:=false
var initialized:=false
var staging:=false
var revealed:=false
var reveal_phase:=""
var tyler:Sprite2D
var rai:Sprite2D
var caster:Node2D
func _ready()->void:
 view=get_parent()
 root=Node2D.new()
 var basin:Dictionary=view.model.data.get("blockout",{})
 var center:Array=basin.get("guardian",[24,18])
 lake_center=Vector2(center[0],center[1])
 root.position=view.model.project(lake_center,false)-Vector2(0,float(basin.get("waterElevation",-24)))
 view.actors.add_child(root)
 effect=LakeFx.new()
 effect.sprite_has_wake=view.model.data.has("celLake")
 effect.cast_origin=Arena.cast_foot(view.model)+Arena.HAND-root.position
 root.add_child(effect)
 sprite=Sprite2D.new()
 sprite.region_enabled=true
 sprite.region_filter_clip_enabled=true
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 sprite.scale=Vector2.ONE*(1.3 if view.model.data.has("celLake") else 1.04)
 sprite.offset=Vector2(0,-142)
 waterline=ShaderMaterial.new()
 waterline.shader=preload("res://shaders/overworld/mormaco_waterline.gdshader")
 sprite.material=waterline
 root.add_child(sprite)
 shore_effect=LakeFx.new()
 shore_effect.position=root.position
 shore_effect.z_index=3
 shore_effect.hide()
 view.actors.add_child(shore_effect)
 var flags:Dictionary=view.saved_player.get("flags",{})
 revealed=flags.get("mormacoEmboscada",false) or flags.get("mormacoTylerChegou",false) or Story.won(view.saved_player) or view.saved_player.has("lastMormaco")
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
 sprite.texture=POSSESSED if possessed else NORMAL
 _set_jets(true)
 _set_frame(4 if possessed else 0)
 _set_immersion(0)
 sprite.visible=revealed
 effect.mode="settled" if revealed else "still"
 view.exploration_hud.objective.text=Story.objective(view.saved_player)
 if initialized and free and not was_free and not view.reduced_motion:
  var ghost:=Sprite2D.new();ghost.texture=old_texture;ghost.scale=sprite.scale;ghost.offset=sprite.offset;root.add_child(ghost)
  sprite.modulate.a=0
  var fade:=create_tween().set_parallel(true);fade.tween_property(ghost,"modulate:a",0.0,1.2);fade.tween_property(sprite,"modulate:a",1.0,1.2)
  fade.chain().tween_callback(ghost.queue_free)
 was_free=free;initialized=true
 if possessed and not Story.won(view.saved_player):show_tyler()
func _process(delta:float)->void:
 if not view.reduced_motion and (staging or not view.paused or not reveal_camera.is_empty()):
  jet_clock+=delta
  waterline.set_shader_parameter("jet_clock",jet_clock)
 if staging:return
 if not view.paused:age+=delta
 var possessed:bool=not was_free and (Story.won(view.saved_player) or view.saved_player.flags.get("mormacoTylerChegou",false))
 var frame:=4 if possessed else 0
 var cycle:=fmod(age,10.0)
 effect.progress=.42 if view.reduced_motion else fmod(age*.39,1.0)
 if not view.reduced_motion:
  if cycle<8.0:
   frame=4 if possessed else int(cycle*2.0)%4
  else:
   frame=4+mini(int((cycle-8.0)*2.0),3)
 _set_frame(frame)

func _set_frame(frame:int)->void:
 waterline.set_shader_parameter("possessed",sprite.texture==POSSESSED)
 sprite.region_rect=Rect2((frame%4)*320,floori(frame/4.0)*320,320,320)

func _set_immersion(pixels:float)->void:
 sprite.position.y=roundf(pixels)
 effect.body_depth=sprite.position.y
 waterline.set_shader_parameter("waterline",(13.0-sprite.position.y)/sprite.scale.y)
 effect.surfacing_width=126.0*(1.0-smoothstep(20.0,152.0,pixels)) if pixels>0 else 0.0

func _set_jets(visible_now:bool)->void:
 waterline.set_shader_parameter("jets_visible",visible_now)

func _set_shore()->void:
 var contour:Array=view.model.data.get("blockout",{}).get("waterContour",[])
 var bank:Vector2=lake_center.lerp(view.player,.85)
 for index in contour.size():
  var a:Array=contour[index]
  var b:Array=contour[(index+1)%contour.size()]
  var crossing:Variant=Geometry2D.segment_intersects_segment(lake_center,view.player,Vector2(a[0],a[1]),Vector2(b[0],b[1]))
  if crossing is Vector2:
   bank=crossing
   break
 shore_effect.bank=view.model.project(bank,false)-root.position+Vector2(0,13)
 var feet:Vector2=view.model.project(view.player)-root.position
 shore_effect.pipeiro=feet
 effect.pipeiro=feet

func _react_to_wave()->void:
 var avatar:Node2D=view.avatar
 var partner:Sprite2D=view.companion
 var step:Vector2=(shore_effect.pipeiro-shore_effect.bank).normalized()
 var kael_start:=avatar.position
 var partner_start:=partner.position
 if not avatar.mounted:avatar.jump_pose(.22)
 var flinch:=create_tween().set_parallel(true)
 flinch.tween_property(avatar,"position",(kael_start+step*5).round(),.11)
 flinch.tween_property(partner,"position",(partner_start+step*15+Vector2(0,-7)).round(),.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 if not avatar.mounted:flinch.tween_callback(func():avatar.jump_pose(.80)).set_delay(.11)
 flinch.chain().set_parallel(true)
 flinch.tween_property(avatar,"position",kael_start,.22)
 flinch.tween_property(partner,"position",partner_start,.30).set_trans(Tween.TRANS_SINE)
 flinch.chain().tween_callback(avatar.stop_jump)
 _cue("world.splash",-6)

func _cue(id:String,gain:float)->void:
 var director:=get_tree().get_first_node_in_group("soul_sound")
 if director!=null:director.play_event(id,gain)

func _camera_to(position:Vector2,zoom:Vector2,duration:float)->void:
 if view.reduced_motion:
  view.camera.position=position
  view.camera.reset_smoothing()
  return
 var move:=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 move.tween_property(view.camera,"position",position,duration)
 move.tween_property(view.camera,"zoom",zoom,duration)
 await move.finished

func _focus()->Vector2:
 var shore:Vector2=view.model.project(view.player)
 return shore.lerp(root.position,.61)+Vector2(5,-87)

func play_reveal()->void:
 if revealed or staging:return
 staging=true
 var camera:Camera2D=view.camera
 var original_zoom:=camera.zoom
 var hud:CanvasLayer=view.exploration_hud.get_parent()
 reveal_camera={"position":camera.position,"zoom":original_zoom,"smoothing":camera.position_smoothing_enabled,"hud":hud.visible}
 var screen_center:=camera.get_screen_center_position()
 camera.position_smoothing_enabled=false
 hud.hide()
 view.avatar.face_motion(root.position-view.model.project(view.player))
 view._refresh_positions()
 camera.position=screen_center
 _set_shore()
 effect.mode="underwater"
 effect.progress=0
 reveal_phase="wake"
 var focus:=_focus()+Vector2(0,57)
 if view.reduced_motion:
  await _camera_to(focus,original_zoom,0)
  _set_immersion(0)
  sprite.show()
  shore_effect.mode="ribbon"
  shore_effect.show()
  shore_effect.progress=0
  await get_tree().process_frame
 else:
  var approach:=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
  approach.tween_property(camera,"position",focus,.73)
  approach.tween_property(camera,"zoom",original_zoom*1.07,.73)
  approach.tween_property(effect,"progress",1.0,.69)
  approach.tween_callback(_cue.bind("world.splash",-14)).set_delay(.29)
  await approach.finished
  effect.mode="reveal"
  effect.progress=.22
  _set_jets(false)
  _set_immersion(125)
  _set_frame(0)
  sprite.show()
  reveal_phase="surface"
  var wake:=create_tween().set_parallel(true)
  wake.tween_property(effect,"progress",.58,.98)
  wake.tween_method(_set_immersion,125.0,11.0,.82).set_trans(Tween.TRANS_SINE)
  await wake.finished
  reveal_phase="geysers"
  _cue("world.splash",-2)
  shore_effect.mode="shore"
  shore_effect.progress=0
  shore_effect.show()
  var geysers:=create_tween().set_parallel(true)
  geysers.tween_property(effect,"progress",1.0,1.12)
  geysers.tween_property(shore_effect,"progress",1.0,1.16)
  geysers.tween_method(_set_immersion,11.0,-5.0,.20).set_trans(Tween.TRANS_QUAD)
  geysers.tween_method(_set_immersion,-5.0,0.0,.29).set_delay(.2)
  geysers.tween_callback(_set_jets.bind(true)).set_delay(.09)
  geysers.tween_callback(_set_frame.bind(5)).set_delay(.13)
  geysers.tween_callback(_set_frame.bind(6)).set_delay(.35)
  geysers.tween_callback(_react_to_wave).set_delay(.74)
  geysers.tween_callback(_set_frame.bind(7)).set_delay(.78)
  await geysers.finished
  reveal_phase="breath"
  shore_effect.mode="ribbon"
  shore_effect.progress=0
  effect.mode="breath"
  _set_frame(2)
  _set_jets(false)
  var breath:=create_tween().set_parallel(true)
  breath.tween_property(effect,"progress",1.0,.81).from(0.0)
  breath.tween_callback(_set_frame.bind(0)).set_delay(.48)
  breath.tween_callback(_set_jets.bind(true)).set_delay(.61)
  await breath.finished
 _set_frame(0)
 effect.mode="settled"
 effect.progress=0
 revealed=true
 age=0
 reveal_phase=""
 staging=false

func finish_reveal()->void:
 if reveal_camera.is_empty():return
 var camera:Camera2D=view.camera
 camera.position_smoothing_enabled=reveal_camera.smoothing
 camera.position=reveal_camera.position
 camera.zoom=reveal_camera.zoom
 if view.reduced_motion:camera.reset_smoothing()
 view.exploration_hud.get_parent().visible=reveal_camera.hud
 shore_effect.hide()
 reveal_camera.clear()

func play_possession()->void:
 staging=true
 var camera:Camera2D=view.camera
 var previous_camera:=camera.position
 var previous_zoom:=camera.zoom
 var smoothing:=camera.position_smoothing_enabled
 var hud:CanvasLayer=view.exploration_hud.get_parent()
 var hud_was_visible:=hud.visible
 camera.position_smoothing_enabled=false
 hud.hide()
 view.avatar.face_motion(root.position-view.model.project(view.player))
 view._refresh_positions()
 effect.mode="ambush"
 effect.z_index=2
 effect.progress=0
 _set_frame(5)
 _set_jets(true)
 if view.reduced_motion:
  _show_caster(false)
  sprite.texture=POSSESSED
  _set_frame(4)
  effect.progress=.73
  show_tyler()
  await get_tree().create_timer(.42).timeout
 else:
  _show_caster(true)
  var shot_center:=_focus()+Vector2(131,4)
  var shot_zoom:=previous_zoom*.93
  if view.model.data.has("celLake"):
   var shot:=Rect2(view.model.project(view.player),Vector2.ZERO)
   shot=shot.expand(caster.position+Vector2(0,-82)).expand(root.position+Vector2(0,-220)).grow(75)
   var viewport_size:=get_viewport_rect().size
   shot_center=shot.get_center()
   shot_zoom=Vector2.ONE*minf(shot_zoom.x,minf(viewport_size.x/shot.size.x,viewport_size.y/shot.size.y))
  await _camera_to(shot_center,shot_zoom,.45)
  var seizure:=create_tween().set_parallel(true)
  seizure.tween_property(effect,"progress",1.0,2.68)
  seizure.tween_callback(func():
   _set_frame(0)
   _set_jets(false)).set_delay(1.04)
  seizure.tween_callback(_cue.bind("world.splash",-7)).set_delay(1.11)
  seizure.tween_callback(show_tyler.bind(true)).set_delay(1.32)
  seizure.tween_method(_set_immersion,0.0,22.0,.23).set_delay(1.50).set_trans(Tween.TRANS_CUBIC)
  seizure.tween_callback(func():
   sprite.texture=POSSESSED
   _set_frame(4)
   _cue("battle.boss_phase",-6)).set_delay(1.78)
  seizure.tween_method(_set_immersion,22.0,0.0,.38).set_delay(1.80).set_trans(Tween.TRANS_SINE)
  seizure.tween_callback(_set_jets.bind(true)).set_delay(1.97)
  seizure.tween_callback(_set_frame.bind(5)).set_delay(2.03)
  seizure.tween_callback(_set_frame.bind(4)).set_delay(2.45)
  await seizure.finished
  await _camera_to(previous_camera,previous_zoom,.50)
 camera.position_smoothing_enabled=smoothing
 hud.visible=hud_was_visible
 effect.mode="settled"
 effect.z_index=0
 effect.progress=0
 staging=false

func _show_caster(entering:bool)->void:
 if is_instance_valid(caster):return
 caster=Node2D.new()
 var mark:=Arena.cast_foot(view.model)
 caster.position=mark
 caster.z_index=2
 view.actors.add_child(caster)
 var body:=Sprite2D.new()
 body.texture=CASTER
 body.region_enabled=true
 body.region_filter_clip_enabled=true
 body.region_rect=Rect2(64,0,64,96)
 body.offset=Vector2(0,-42)
 body.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 caster.add_child(body)
 var reel:=Node2D.new()
 caster.add_child(reel)
 reel.draw.connect(func():_draw_held_reel(reel))
 if not entering:return
 caster.position=mark+Vector2(23,-11)
 var step:=create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 step.tween_property(caster,"position",mark,.37)

func _draw_held_reel(actor:Node2D)->void:
 var hand:=Arena.HAND
 # Jacket sleeve, glove, reel flanges and a wound band. The line starts at the exposed end.
 actor.draw_line(Vector2(1,-40),Vector2(-8,-34),Color("#283e32"),6)
 actor.draw_line(Vector2(0,-41),Vector2(-8,-35),Color("#54835a"),3)
 actor.draw_rect(Rect2(hand+Vector2(-3,-6),Vector2(12,12)),Color("#211a35"))
 actor.draw_rect(Rect2(hand+Vector2(0,-4),Vector2(7,8)),Color("#6e4380"))
 actor.draw_rect(Rect2(hand+Vector2(-3,-4),Vector2(3,8)),Color("#a365bc"))
 actor.draw_rect(Rect2(hand+Vector2(6,-5),Vector2(3,10)),Color("#88539b"))
 actor.draw_rect(Rect2(hand+Vector2(1,-3),Vector2(5,1)),Color("#d8a3db"))

func show_tyler(entering:bool=false)->void:
 if is_instance_valid(tyler):return
 var tyler_at:=Story.AT+Vector2(-.78,1.45)
 var rai_at:=Story.AT+Vector2(.75,-.55)
 tyler=_ally("tyler",tyler_at)
 rai=_ally("rai",rai_at)
 if not entering:return
 var rai_end:=rai.position
 var tyler_end:=tyler.position
 var rai_start:Vector2=view.model.project(rai_at+Vector2(.34,1.64))
 var tyler_start:Vector2=view.model.project(tyler_at+Vector2(.34,1.34))
 rai.position=rai_start
 tyler.position=tyler_start
 NPC.face_motion(rai,rai_end-rai_start)
 NPC.face_motion(tyler,tyler_end-tyler_start)
 var entry:=create_tween().set_parallel(true)
 entry.tween_method(func(t:float):rai.position=(rai_start.lerp(rai_end,t)+Vector2(0,-sin(t*PI)*9)).round(),0.0,1.0,.34)
 entry.tween_property(tyler,"position",tyler_end,.48).set_delay(.12)
 entry.tween_callback(func():NPC.face_motion(rai,root.position-rai_end)).set_delay(.34)
 entry.tween_callback(func():NPC.face_motion(tyler,root.position-tyler_end)).set_delay(.60)

func _ally(id:String,at:Vector2)->Sprite2D:
 var ally:=Sprite2D.new()
 ally.texture=load("res://assets/campaign/tyler-clareira-v1/"+id+"-overworld-idle-eight.png")
 ally.region_enabled=true
 ally.offset=Vector2(0,-44)
 ally.scale=Vector2.ONE*.85
 ally.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 ally.position=view.model.project(at)
 NPC.face_motion(ally,root.position-ally.position)
 view.actors.add_child(ally)
 return ally

func reset_possession()->void:
 for ally in [tyler,rai,caster]:
  if is_instance_valid(ally):ally.queue_free()
 tyler=null
 rai=null
 caster=null
 initialized=false
 refresh()
