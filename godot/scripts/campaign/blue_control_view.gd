extends Control
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
signal finished
signal left
const Model=preload("res://scripts/campaign/blue_control_model.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var model:=Model.new()
var paused:=false
var pointer:=Vector2(-1,-1)
var buttons:={"line":false,"guard":false}
var sprite:Sprite2D
var frames:Array=[]
var age:=0.0
var message:Label
var energy:ProgressBar
var finish:Button
var pause_button:Button
var flight_input:Control
func field()->Rect2:return Rect2(40,205,maxf(240,size.x-80),maxf(180,size.y-390))
func _ready()->void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT);theme=Hud.make_theme();mouse_filter=MOUSE_FILTER_IGNORE
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,32)
 margin.mouse_filter=MOUSE_FILTER_IGNORE;add_child(margin)
 var column:=VBoxContainer.new();column.mouse_filter=MOUSE_FILTER_IGNORE;column.add_theme_constant_override("separation",12);margin.add_child(column)
 var title:=Label.new();title.text="LIGA · EXAME AZUL · CONTROLE";title.add_theme_font_override("font",Hud.display());title.add_theme_font_size_override("font_size",28);column.add_child(title)
 var help:=Label.new();help.text="Carcará emprestado · setas / analógico ou clique no campo para mover · Esc / Voltar para pausar";help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(help)
 message=Label.new();message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message.add_theme_font_size_override("font_size",22);column.add_child(message)
 energy=ProgressBar.new();energy.custom_minimum_size.y=20;energy.show_percentage=true;column.add_child(energy)
 for element:Control in [title,help,message,energy]:element.mouse_filter=MOUSE_FILTER_IGNORE
 var gap:=Control.new();gap.mouse_filter=MOUSE_FILTER_IGNORE;gap.size_flags_vertical=SIZE_EXPAND_FILL;column.add_child(gap)
 var footer:=HBoxContainer.new();footer.mouse_filter=MOUSE_FILTER_IGNORE;footer.add_theme_constant_override("separation",12);column.add_child(footer)
 for action in ["line","guard"]:
  var b:=Button.new();b.text=("Linha · " if action=="line" else "Defesa · ")+Controls.prompt(action);Hud.secondary_button(b);b.custom_minimum_size=Vector2(190,56);footer.add_child(b)
  b.button_down.connect(func():buttons[action]=true);b.button_up.connect(func():buttons[action]=false)
 pause_button=Button.new();pause_button.text="Pausar";Hud.secondary_button(pause_button);pause_button.custom_minimum_size=Vector2(140,56);footer.add_child(pause_button)
 pause_button.pressed.connect(toggle_pause)
 var leave:=Button.new();leave.text="Sair da etapa";Hud.secondary_button(leave);leave.custom_minimum_size=Vector2(170,56);footer.add_child(leave);leave.pressed.connect(func():left.emit())
 finish=Button.new();finish.text="Registrar controle";Hud.navigation_button(finish);finish.custom_minimum_size.y=56;column.add_child(finish)
 finish.disabled=true;finish.pressed.connect(func():
  if model.complete:finished.emit())
 flight_input=Control.new();flight_input.mouse_filter=MOUSE_FILTER_STOP;flight_input.mouse_default_cursor_shape=CURSOR_CROSS;add_child(flight_input)
 flight_input.gui_input.connect(func(event:InputEvent):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not paused:
   pointer=event.position/flight_input.size;flight_input.accept_event())
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"));var art:Dictionary=content.combat["basic-carcara"]
 sprite=Sprite2D.new();sprite.texture=load("res://assets/campaign/"+art.image);sprite.region_enabled=true;frames=art.animations.idle;add_child(sprite)
 pause_button.grab_focus()
func toggle_pause()->void:
 paused=not paused;pause_button.text="Retomar" if paused else "Pausar";buttons={"line":false,"guard":false}
func _process(delta:float)->void:
 flight_input.position=field().position;flight_input.size=field().size
 if not paused and get_window().has_focus():
  model.tick(delta,{"direction":Controls.direction(),"pointer":pointer,"line":buttons.line or Controls.held("line"),"guard":buttons.guard or Controls.held("guard"),"cut":Controls.held("cut")});age+=delta
 message.text="PAUSADO · nenhum tempo de avaliação está avançando." if paused else model.message
 energy.value=model.energy
 finish.disabled=not model.complete
 var f:Dictionary=frames[int(age*8)%frames.size()];sprite.region_rect=Rect2(f.x,f.y,f.w,f.h);sprite.scale=Vector2.ONE*96/float(f.h);sprite.position=field().position+model.position*field().size
 queue_redraw()
func _unhandled_input(event:InputEvent)->void:
 Controls.observe(event)
 if Controls.cancel(event):toggle_pause();get_viewport().set_input_as_handled()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Tokens.GUIDE_FIELD)
 draw_style_box(Hud.panel("dark"),field())
 var target:=Rect2(field().position+Model.TARGET.position*field().size,Model.TARGET.size*field().size)
 draw_rect(target,Tokens.GUIDE_TARGET);draw_rect(target,Tokens.GUIDE_CYAN_LINE,false,3)
 draw_line(Vector2(field().get_center().x,field().end.y),field().position+model.position*field().size,Tokens.GUIDE_TRACE,2,true)
