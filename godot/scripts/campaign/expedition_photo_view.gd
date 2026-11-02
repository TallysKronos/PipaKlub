extends Control
## Quiet inspection of an old photograph; existing manga dialogue remains the controller UI.
var photo:Texture2D=preload("res://assets/campaign/foto-expedicao-v1/foto.png")
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index=70
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,.03,.05,.88))
 var bounds:=Rect2(size.x*.10,20,size.x*.80,size.y*.59)
 var factor:float=minf(bounds.size.x/photo.get_width(),bounds.size.y/photo.get_height())
 var display:=Vector2(photo.get_size())*factor
 draw_texture_rect(photo,Rect2(bounds.get_center()-display*.5,display),false)
