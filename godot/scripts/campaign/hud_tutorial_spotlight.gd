extends Control
## Visual guidance only: all highlighted gameplay controls remain interactive.
const Hud=preload("res://scripts/campaign/hud.gd")
var holes:Array[Rect2]=[]
var mask:ColorRect
var pointer:Control
func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter=MOUSE_FILTER_IGNORE;set_meta("ui_decorative",true);z_index=40
	mask=ColorRect.new();mask.set_anchors_and_offsets_preset(PRESET_FULL_RECT);mask.mouse_filter=MOUSE_FILTER_IGNORE;add_child(mask)
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
uniform vec2 extent=vec2(1280.0,720.0);
uniform vec4 holes[6];
uniform int count=0;
void fragment(){
 vec2 p=UV*extent;float shade=.64;
 for(int i=0;i<6;i++){
  if(i>=count){break;}
  vec2 center=holes[i].xy+holes[i].zw*.5;
  vec2 q=abs(p-center)-holes[i].zw*.5+vec2(10.0);
  float d=length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-10.0;
  shade*=smoothstep(-5.0,12.0,d);
 }
 COLOR=vec4(.015,.025,.05,shade);
}"""
	var material:=ShaderMaterial.new();material.shader=shader;mask.material=material
	pointer=Control.new();pointer.set_anchors_and_offsets_preset(PRESET_FULL_RECT);pointer.mouse_filter=MOUSE_FILTER_IGNORE;add_child(pointer)
	pointer.draw.connect(_draw_pointer)
func update_targets(rectangles:Array[Rect2]) -> void:
	holes=rectangles
	var packed:=PackedVector4Array()
	for i in 6:
		var r:Rect2=rectangles[i] if i<rectangles.size() else Rect2()
		packed.append(Vector4(r.position.x,r.position.y,r.size.x,r.size.y))
	mask.material.set_shader_parameter("extent",size)
	mask.material.set_shader_parameter("holes",packed)
	mask.material.set_shader_parameter("count",mini(6,rectangles.size()))
	pointer.queue_redraw()
func _draw_pointer() -> void:
	if holes.is_empty():return
	var r:=holes[0]
	pointer.draw_rect(r.grow(-2),Color(Hud.CYAN,.85),false,2)
	var head:=Vector2(r.get_center().x,r.position.y-8)
	pointer.draw_colored_polygon(PackedVector2Array([head,head+Vector2(-9,-12),head+Vector2(9,-12)]),Hud.GOLD)
