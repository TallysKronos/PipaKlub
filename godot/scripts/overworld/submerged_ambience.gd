extends Node2D
var model
var clock:=0.0
var frozen:=false
var anchors:Array[Vector2]=[]
func _ready() -> void:
 z_index=20
 frozen=OS.get_environment("SUBMERSO_CAPTURE")=="1"
 for v in range(7,int(model.data.h)-5,7):
  for u in range(7,int(model.data.w)-5,9):
   var c:Dictionary=model.cell_at(Vector2i(u,v))
   if int(c.level)>=0 and c.ramp==null:anchors.append(Vector2(u+.5,v+.5))
 queue_redraw()
func _process(delta:float) -> void:
 if frozen:return
 clock+=delta;queue_redraw()
func _draw() -> void:
 for i in anchors.size():
  var base:Vector2=model.project(anchors[i]);var phase:float=fmod(clock*12+i*17,110.0)
  var pos:Vector2=base+Vector2(sin(clock*.7+i)*8,-phase-12)
  var alpha:float=.24*(1.0-phase/140.0)
  draw_arc(pos,2.0+i%3,0,TAU,14,Color(.67,.94,1.,alpha),1.1,true)
  draw_circle(base+Vector2(sin(i*4.1)*28,-15-cos(i*2.)*12),1.2,Color(.53,.85,.91,.19))
