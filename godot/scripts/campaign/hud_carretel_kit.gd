extends Control
class_name CarretelMenuKit
## Shared Carretel menu canvas. Logical 1280x720, fitted as one unit.
const Hud = preload("res://scripts/campaign/hud.gd")
const SIZE := Vector2(1280,720)
const BLUE := Color("092a51")
const DEEP := Color("04172f")
const EDGE := Color("2467a5")
const CYAN := Color("43dafa")
const WHITE := Color("edfaff")
const MUTED := Color("9fc5e3")
var canvas := Control.new()
static var menu_icon_cache: Dictionary = {}
static func menu_icon(id: String, _high_density: bool = true) -> Texture2D:
	var key: String = {"missoes":"missions","tail":"emblems","info":"identity","line":"workshop"}.get(id,id)
	var path := "res://assets/ui/carretel-menu-v1/"+key+".png"
	if key in ["heart","evolve","folder","mount"]: path = "res://assets/ui/carretel-menu-v1/"+key+".svg"
	if not menu_icon_cache.has(path): menu_icon_cache[path] = load(path) if ResourceLoader.exists(path) else Hud.icon(id,true)
	return menu_icon_cache[path]
static var panel_gradient: GradientTexture2D
static var selected_gradient: GradientTexture2D

static func gradient(light: bool) -> GradientTexture2D:
	if panel_gradient == null:
		panel_gradient = GradientTexture2D.new()
		panel_gradient.gradient = Gradient.new()
		panel_gradient.gradient.colors = PackedColorArray([Color("103f73"),Color("06214a"),Color("0c3964")])
		panel_gradient.gradient.offsets = PackedFloat32Array([0,.55,1])
		panel_gradient.fill_from = Vector2.ZERO
		panel_gradient.fill_to = Vector2.ONE
		selected_gradient = GradientTexture2D.new()
		selected_gradient.gradient = Gradient.new()
		selected_gradient.gradient.colors = PackedColorArray([Color("f1fcff"),Color("72ddfa")])
	return selected_gradient if light else panel_gradient

static func plate(target: CanvasItem, rect: Rect2, active: bool = false, light: bool = false) -> void:
	var a := rect.position
	var b := rect.end
	var points := PackedVector2Array([a+Vector2(12,0),Vector2(b.x,a.y),b-Vector2(12,0),Vector2(a.x,b.y),a+Vector2(12,0)])
	var uv := PackedVector2Array()
	for point in points: uv.append((point-a)/rect.size)
	target.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,gradient(light))
	target.draw_polyline(points,WHITE if active else EDGE,3 if active else 2,true)
	target.draw_line(a+Vector2(13,2),a+Vector2(rect.size.x*.65,2),CYAN,3,true)
	target.draw_line(Vector2(a.x+3,b.y-2),Vector2(b.x-14,b.y-2),CYAN if active else EDGE,2,true)
	target.draw_colored_polygon(PackedVector2Array([Vector2(b.x-rect.size.x*.4,a.y),Vector2(b.x-rect.size.x*.28,a.y),Vector2(a.x+rect.size.x*.42,b.y),Vector2(a.x+rect.size.x*.30,b.y)]),Color(CYAN,.045))
	for x in range(20,70,8):
		for y in range(12,36,8): target.draw_circle(Vector2(b.x-x,b.y-y),1,Color(CYAN,.12))

static func write(target: CanvasItem, value: String, point: Vector2, font_size: int, color: Color = WHITE, width: float = -1, bold: bool = false) -> void:
	target.draw_string(Hud.font(bold),point,value,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)

static func image(target: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	if texture != null: target.draw_texture_rect(texture,Hud.fit_texture(texture,rect),false,tint)

static func bar(target: CanvasItem, rect: Rect2, percentage: float, color: Color) -> void:
	target.draw_rect(rect,Color("031124"))
	target.draw_rect(Rect2(rect.position+Vector2.ONE,Vector2(maxf(0,rect.size.x-2)*clampf(percentage/100,0,1),maxf(1,rect.size.y-2))),color)

class Card extends Button:
	var art: Texture2D
	var subtitle := ""
	var detail := ""
	var badge := ""
	var selected := false
	var managed_selection := false
	var compact := false
	var light := false
	var creature := false
	var item := false
	var compact_font_size := 22
	var folder_style := false
	var number := ""
	var line := 100.0
	var structure := 100.0
	var equipped := false
	var mount := false
	func _ready() -> void:
		set_meta("recorte_decorated",true)
		for state in ["normal","hover","pressed","focus","disabled"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]: add_theme_color_override(state,Color(0,0,0,0))
		focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
		mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw)
		mouse_default_cursor_shape = CURSOR_ARROW
	func _draw() -> void:
		var active := not disabled and (selected if managed_selection else has_focus() or is_hovered() or selected or button_pressed)
		if disabled and text.is_empty():
			var r := Rect2(7,7,size.x-14,size.y-14)
			draw_rect(r,Color("061c37"))
			for pair in [[r.position,Vector2(r.end.x,r.position.y)],[Vector2(r.end.x,r.position.y),r.end],[r.end,Vector2(r.position.x,r.end.y)],[Vector2(r.position.x,r.end.y),r.position]]: draw_dashed_line(pair[0],pair[1],Color("28557a"),2,8)
			draw_line(size*.5-Vector2(11,0),size*.5+Vector2(11,0),Color("28557a"),3)
			draw_line(size*.5-Vector2(0,11),size*.5+Vector2(0,11),Color("28557a"),3)
			return
		if active: CarretelMenuKit.plate(self,Rect2(2,2,size.x-4,size.y-4),true,light)
		else: CarretelMenuKit.plate(self,Rect2(4,4,size.x-8,size.y-8),false,light)
		var color := Color("0a2944") if light else WHITE
		if disabled: color = Color("71899e")
		if compact:
			if folder_style:
				CarretelMenuKit.image(self,art,Rect2(13,16,28,29))
				CarretelMenuKit.write(self,text,Vector2(48,27),16,color,size.x-61,true)
				CarretelMenuKit.write(self,subtitle,Vector2(48,48),13,MUTED,size.x-61)
				return
			if size.x < 120:
				var extent := Hud.font(true).get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,compact_font_size)
				CarretelMenuKit.write(self,text,Vector2((size.x-extent.x)*.5,size.y*.5+8),compact_font_size,color)
				return
			if art != null: CarretelMenuKit.image(self,art,Rect2(18,9,34,size.y-18))
			CarretelMenuKit.write(self,text,Vector2(62 if art != null else 24,size.y*.5+8),compact_font_size,color,size.x-(92 if art != null else 48),true)
			if size.x>120: CarretelMenuKit.write(self,"›",Vector2(size.x-30,size.y*.5+9),28,color)
			return
		if item:
			CarretelMenuKit.image(self,art,Rect2(22,12,size.x-44,91))
			draw_multiline_string(Hud.font(true),Vector2(14,130),text,HORIZONTAL_ALIGNMENT_LEFT,size.x-28,18,2,color)
			CarretelMenuKit.write(self,detail,Vector2(size.x-57,101),15,CYAN,45,true)
			if not badge.is_empty(): CarretelMenuKit.write(self,badge,Vector2(size.x-63,25),12,Color("ffcf60"),58,true)
			return
		if creature:
			CarretelMenuKit.image(self,art,Rect2(16,21,size.x-32,102),Color(1,1,1,.35 if disabled else 1))
			draw_rect(Rect2(9,7,28,32),DEEP)
			CarretelMenuKit.write(self,number,Vector2(17,31),21,CYAN,32,true)
			if equipped: CarretelMenuKit.write(self,"◆",Vector2(size.x-28,27),18,CYAN)
			if mount: CarretelMenuKit.image(self,CarretelMenuKit.menu_icon("mount"),Rect2(size.x-31,98,22,22))
			CarretelMenuKit.write(self,text,Vector2(16,143),20,color,size.x-30,true)
			CarretelMenuKit.write(self,subtitle,Vector2(16,163),15,MUTED,size.x-30)
			CarretelMenuKit.bar(self,Rect2(17,176,size.x-34,7),line,Color("53dca5"))
			CarretelMenuKit.bar(self,Rect2(17,190,size.x-34,7),structure,Color("ffcf60"))
		else:
			var center := Vector2(size.x*.5,size.y*.31)
			draw_colored_polygon(PackedVector2Array([center-Vector2(0,58),center+Vector2(62,0),center+Vector2(0,58),center-Vector2(62,0)]),Color(CYAN,.065))
			CarretelMenuKit.image(self,art,Rect2(29,10,size.x-58,size.y*.55),Color(1,1,1,.3 if disabled else 1))
			CarretelMenuKit.write(self,text,Vector2(23,size.y*.69),25,color,size.x-46,true)
			if not subtitle.is_empty():
				draw_multiline_string(Hud.font(),Vector2(23,size.y*.69+23),subtitle,HORIZONTAL_ALIGNMENT_LEFT,size.x-56,16,2,MUTED)
			if not detail.is_empty(): CarretelMenuKit.write(self,detail,Vector2(size.x-57,size.y*.49),15,CYAN,45,true)
			if not badge.is_empty(): CarretelMenuKit.write(self,badge,Vector2(size.x-66,25),13,Color("ffcf60"),60,true)
			CarretelMenuKit.write(self,"›",Vector2(size.x-34,size.y-21),28,CYAN)

class Surface extends Control:
	var title := ""
	func _ready() -> void: mouse_filter = MOUSE_FILTER_IGNORE
	func _draw() -> void:
		CarretelMenuKit.plate(self,Rect2(1,1,size.x-2,size.y-2))
		if not title.is_empty():
			draw_rect(Rect2(12,2,size.x-28,36),Color("103d69"))
			CarretelMenuKit.write(self,title,Vector2(24,27),21,CYAN,size.x-48,true)

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	canvas.size = SIZE
	add_child(canvas)
	resized.connect(fit)
	fit()

func fit() -> void:
	var zoom := minf(size.x/SIZE.x,size.y/SIZE.y)
	canvas.scale = Vector2.ONE*zoom
	canvas.position = (size-SIZE*zoom)*.5
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),DEEP)
	for i in 8:
		var origin := Vector2(size.x*(i*.23-.7),0)
		draw_colored_polygon(PackedVector2Array([origin,origin+Vector2(110,0),origin+Vector2(size.y*.9,size.y),origin+Vector2(size.y*.9-110,size.y)]),Color("09294f") if i%2 else Color("072140"))
	for y in range(0,int(size.y),14):
		for x in range(0,100,14): draw_circle(Vector2(x,y),1,Color(CYAN,.07))

func label(value: String, rect: Rect2, font_size: int = 20, color: Color = WHITE, bold: bool = false) -> Label:
	var node := Label.new()
	node.text = value
	node.mouse_filter = MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",Hud.lettering() if font_size >= 38 else Hud.font(bold))
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.max_lines_visible = maxi(1,floori(rect.size.y/(node.get_theme_font("font").get_height(font_size)+2)))
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	canvas.add_child(node)
	place(node,rect)
	node.set_deferred("size",rect.size)
	return node

func panel(rect: Rect2, title: String = "") -> Surface:
	var node := Surface.new()
	node.title = title
	canvas.add_child(node)
	place(node,rect)
	return node

func card(value: String, rect: Rect2, texture: Texture2D = null, compact: bool = false) -> Card:
	var node := Card.new()
	node.text = value
	node.tooltip_text = value
	node.art = texture
	node.compact = compact
	canvas.add_child(node)
	place(node,rect)
	return node

func texture(texture_value: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture_value
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = MOUSE_FILTER_IGNORE
	canvas.add_child(node)
	place(node,rect)
	return node

static func place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size

func header(title: String, subtitle: String, icon: Texture2D) -> void:
	texture(icon,Rect2(32,20,72,72))
	label(title,Rect2(116,20,680,51),42,WHITE,true)
	label(subtitle,Rect2(118,73,720,27),18,MUTED)
	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation",22)
	canvas.add_child(hints)
	place(hints,Rect2(940,27,308,45))
	Hud.input_hint(hints,"accept","Confirmar")
	Hud.input_hint(hints,"back","Voltar")
