extends Node2D
const Story=preload("res://scripts/campaign/mormaco_story.gd")
var view:Node2D
var root:Node2D
var sprite:Sprite2D
var age:=0.0
var was_free:=false
var initialized:=false
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
 var old_texture:Texture2D=sprite.texture
 sprite.texture=load("res://assets/campaign/mormaco-v1/"+("free.png" if free else "bound.png"))
 sprite.scale=Vector2.ONE*320/sprite.texture.get_width();sprite.offset=Vector2(0,-sprite.texture.get_height()*.5)
 root.queue_redraw()
 view.exploration_hud.objective.text=Story.objective(view.saved_player)
 if initialized and free and not was_free and not view.reduced_motion:
  var ghost:=Sprite2D.new();ghost.texture=old_texture;ghost.scale=sprite.scale;ghost.offset=sprite.offset;root.add_child(ghost)
  sprite.modulate.a=0
  var fade:=create_tween().set_parallel(true);fade.tween_property(ghost,"modulate:a",0.0,1.2);fade.tween_property(sprite,"modulate:a",1.0,1.2)
  fade.chain().tween_callback(ghost.queue_free)
 was_free=free;initialized=true
func _process(delta:float)->void:
 if not view.paused:age+=delta
 sprite.position.y=0 if view.reduced_motion else sin(age*1.3)*2
