extends Node2D
const Exam=preload("res://scripts/campaign/blue_exam.gd")
const Escort=preload("res://scripts/campaign/blue_escort_model.gd")
var view:Node2D
var course:RefCounted
var running:=false
var root:Node2D
var art:Sprite2D
var age:=0.0
var frames:Array=[]
var caption:Label
func _ready()->void:
 view=get_parent();course=Escort.new(int(Exam.record(view.saved_player).escort))
 root=Node2D.new();root.name="CarcaraDaLiga";view.actors.add_child(root)
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
 var entry:Dictionary=content.combat["basic-carcara"];frames=entry.animations.idle
 art=Sprite2D.new();art.texture=load("res://assets/campaign/"+entry.image);art.region_enabled=true;root.add_child(art)
 caption=Label.new();caption.text="Carcará da Liga";caption.add_theme_font_size_override("font_size",14);caption.add_theme_color_override("font_outline_color",Color.BLACK);caption.add_theme_constant_override("outline_size",5);root.add_child(caption)
 for i in Escort.ROUTE.size():
  var marker:=Node2D.new();marker.position=view.model.project(Escort.ROUTE[i]);view.actors.add_child(marker)
  var ring:=Line2D.new();ring.width=2;ring.default_color=Color("43c5df")
  for n in 33:ring.add_point(Vector2(cos(TAU*n/32)*19,sin(TAU*n/32)*9))
  marker.add_child(ring)
  var number:=Label.new();number.text=str(i+1);number.position=Vector2(-4,-24);number.add_theme_color_override("font_outline_color",Color.BLACK);number.add_theme_constant_override("outline_size",4);marker.add_child(number)
 _process(0)
func begin()->void:
 course=Escort.new(0 if Exam.promoted(view.saved_player) else int(Exam.record(view.saved_player).escort));running=not course.complete
func _process(delta:float)->void:
 if not is_instance_valid(view) or frames.is_empty():return
 if not view.paused:age+=delta
 var point:Vector2=Exam.OBSERVE if not Exam.record(view.saved_player).care else course.position
 root.position=view.model.project(point,false)
 var f:Dictionary=frames[int(age*6)%frames.size()]
 art.region_rect=Rect2(f.x,f.y,f.w,f.h);art.scale=Vector2.ONE*76/float(f.h);art.offset=Vector2(0,-float(f.h)*.5);art.position.y=-view.model.height_at(point)*64
 art.flip_h=view.player.x<point.x
 caption.position=Vector2(-55,art.position.y-98)
 if running and not view.paused:
  course.tick(delta,view.player)
  view.exploration_hud.objective.text=course.message
  if course.ready:
   running=false;view.action_requested.emit("blue-exam-checkpoint")
