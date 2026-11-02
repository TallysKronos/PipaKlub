extends RefCounted
## Measured 2D panels using the same warehouse palette; no forest arena fallback.
static func draw_on(c:CanvasItem,size:Vector2)->void:
 var wall:=size.y*.46
 var ink:=Color("30494f")
 c.draw_rect(Rect2(Vector2.ZERO,size),Color("8f9993"))
 c.draw_rect(Rect2(0,0,size.x,wall),Color("60777d"))
 var bay:=size.x/8
 for i in 8:
  var x:=i*bay
  c.draw_rect(Rect2(x+12,size.y*.10,bay-24,size.y*.12),Color("a2c7cb"))
  c.draw_rect(Rect2(x+12,size.y*.10,bay-24,size.y*.12),ink,false,3)
  c.draw_line(Vector2(x+bay*.5,size.y*.10),Vector2(x+bay*.5,size.y*.22),ink,3)
  c.draw_line(Vector2(x,0),Vector2(x,wall),ink,8)
  c.draw_line(Vector2(x+8,size.y*.33),Vector2(x+bay-8,size.y*.33),Color("b49765"),4)
 c.draw_rect(Rect2(0,wall-10,size.x,10),ink)
 var texture:Texture2D=load("res://assets/overworld/kits/industrial-v1/superficies/concreto.png")
 if texture:c.draw_texture_rect(texture,Rect2(0,wall,size.x,size.y-wall),true,Color(.72,.78,.78))
 for i in range(-4,14):c.draw_line(Vector2(size.x*.5+(i-4)*bay*.3,wall),Vector2(i*bay,size.y),Color(ink,.22),1)
 for t in [.16,.36,.64,.97]:c.draw_line(Vector2(0,lerpf(wall,size.y,t)),Vector2(size.x,lerpf(wall,size.y,t)),Color(ink,.18),1)
 for i in 18:
  var x:=i*size.x/18
  c.draw_colored_polygon(PackedVector2Array([Vector2(x,wall),Vector2(x+size.x/36,wall),Vector2(x+size.x/36-8,wall+12),Vector2(x-8,wall+12)]),Color("d0ac5f"))
