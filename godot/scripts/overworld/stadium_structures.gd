extends RefCounted

const KIT := "res://assets/overworld/kits/estadio-lobby-v2/"
const Structures = preload("res://scripts/overworld/forest_structures.gd")

static func build(view) -> void:
	var model = view.model
	var geometry := OS.get_environment("KRONASTA_GEOMETRIA")=="1"
	var wall := Node2D.new()
	wall.position = model.project(Vector2(16,3))
	view.actors.add_child(wall)
	var far: Vector2 = model.project(Vector2(33,3))-wall.position
	var side: Vector2 = model.project(Vector2(16,18))-wall.position
	var jamb_left: Vector2 = model.project(Vector2(27,3))-wall.position
	var jamb_right: Vector2 = model.project(Vector2(31,3))-wall.position
	var cream := Color("#d8c5a8") if not geometry else Color("#939b9f")
	_face(wall, Vector2.ZERO, jamb_left, cream)
	_face(wall, jamb_right, far, cream)
	var threshold_left: Vector2 = model.project(Vector2(27,5))-wall.position
	var threshold_right: Vector2 = model.project(Vector2(31,5))-wall.position
	Structures.quad(wall,PackedVector2Array([jamb_left,jamb_right,threshold_right,threshold_left]),Color("#26374b"))
	var lintel := Vector2(0,-100)
	var top := Vector2(0,-112)
	Structures.quad(wall,PackedVector2Array([jamb_left+lintel,jamb_right+lintel,jamb_right+top,jamb_left+top]),cream)
	Structures.quad(wall,PackedVector2Array([jamb_left,jamb_right,jamb_right+lintel,jamb_left+lintel]),Color("#172435"))
	Structures.line(wall,PackedVector2Array([jamb_left,jamb_left+lintel,jamb_right+lintel,jamb_right]),6,Color("#b99458"))
	if not geometry:
		var aperture := PackedVector2Array([jamb_left,jamb_right,jamb_right+lintel,jamb_left+lintel])
		var back_left := jamb_left + Vector2(46,-23)
		var back_right := jamb_right + Vector2(46,-23)
		for fragment in Geometry2D.intersect_polygons(PackedVector2Array([jamb_left,jamb_right,back_right,back_left]),aperture):
			Structures.quad(wall,fragment,Color("#3e5165"))
		for fragment in Geometry2D.intersect_polygons(PackedVector2Array([jamb_left,back_left,back_left+lintel,jamb_left+lintel]),aperture):
			Structures.quad(wall,fragment,Color("#354459"))
		Structures.line(wall,PackedVector2Array([jamb_left,jamb_right]),4,Color("#deb678"))
		for t in [.24,.57]:
			var lamp: Vector2 = jamb_left.lerp(back_left,t)+Vector2(0,-55)
			Structures.line(wall,PackedVector2Array([lamp,lamp+Vector2(0,9)]),5,Color("#f6cc83"))
	var sign := Label.new()
	sign.text = "ACESSO À ARENA"
	sign.add_theme_font_size_override("font_size", 12)
	sign.position = (jamb_left+jamb_right)*.5 + Vector2(-48,-84)
	wall.add_child(sign)
	if not geometry:
		_crest(wall,Vector2.ZERO.lerp(jamb_left,8.5/11.0)+Vector2(0,-76))
	_face(wall, Vector2.ZERO, side, Color("#bba890") if not geometry else Color("#778288"))
	for piece: Dictionary in model.data.pieces:
		var foot := Vector2(piece.u+piece.fu*.5,piece.v+piece.fv)
		var node := Node2D.new()
		node.position = model.project(foot)
		view.actors.add_child(node)
		if geometry:
			var corners := PackedVector2Array()
			for point in [Vector2(piece.u,piece.v),Vector2(piece.u+piece.fu,piece.v),Vector2(piece.u+piece.fu,piece.v+piece.fv),Vector2(piece.u,piece.v+piece.fv)]:
				corners.append(model.project(point)-node.position)
			Structures.quad(node,corners,Color("#596b79"))
			continue
		if piece.asset=="painel":
			_bracket_mural(node,model.project(Vector2(16.04,6))-node.position)
			continue
		var shadow := PackedVector2Array()
		var center := Vector2(piece.u+piece.fu*.5,piece.v+piece.fv*.5)
		for i in 16:
			var angle := TAU*i/16.0
			var p := center+Vector2(cos(angle)*piece.fu*.45,sin(angle)*piece.fv*.43)
			shadow.append(model.project(p)-node.position)
		Structures.quad(node,shadow,Color(.15,.12,.09,.18))
		var sprite := Sprite2D.new()
		sprite.texture = load(KIT+piece.asset+".png")
		sprite.scale = Vector2.ONE * float(piece.props.width) / sprite.texture.get_width()
		sprite.offset.y = -sprite.texture.get_height() * .5
		node.add_child(sprite)

static func _face(node: Node2D, a: Vector2, b: Vector2, color: Color) -> void:
	var top := Vector2(0,-112)
	var trim := Vector2(0,-36)
	Structures.quad(node,PackedVector2Array([a,b,b+top,a+top]),color)
	Structures.quad(node,PackedVector2Array([a,b,b+trim,a+trim]),Color("#26374b"))
	Structures.line(node,PackedVector2Array([a+trim,b+trim]),3,Color("#aa8650"))
	Structures.line(node,PackedVector2Array([a+top,b+top]),4,color.lightened(.18))
	if OS.get_environment("KRONASTA_GEOMETRIA")=="1":
		return
	var count := maxi(1,roundi(a.distance_to(b)/98.0))
	for i in count:
		var left := a.lerp(b,(i+.08)/count)
		var right := a.lerp(b,(i+.92)/count)
		var molding := PackedVector2Array([left+Vector2(0,-7),right+Vector2(0,-7),right+Vector2(0,-28),left+Vector2(0,-28),left+Vector2(0,-7)])
		Structures.line(node,molding,1,Color("#a18151"))
		if i % 2 == 0:
			var lamp := left.lerp(right,.5)+Vector2(0,-71)
			Structures.line(node,PackedVector2Array([lamp-Vector2(0,5),lamp+Vector2(0,6)]),6,Color("#916a39"))
			Structures.line(node,PackedVector2Array([lamp-Vector2(0,4),lamp+Vector2(0,3)]),3,Color("#ffe0a0"))




static func _crest(node: Node2D, at: Vector2) -> void:
	for size in [Vector2(25,31),Vector2(21,26),Vector2(13,18)]:
		var color := Color("#c39b59") if size.x != 21 else Color("#223a50")
		Structures.quad(node,PackedVector2Array([at-Vector2(0,size.y),at+Vector2(size.x,0),at+Vector2(0,size.y),at-Vector2(size.x,0)]),color)

static func trim_floor(node: Node2D, points: PackedVector2Array, u: int) -> void:
	if points.size()!=4:
		return
	var runner := u in [23,24,25]
	if not runner:
		for i in 4:
			var center := points[0].lerp(points[2],.5)+Vector2((i*19%23)-11,(i*13%11)-5)
			Structures.line(node,PackedVector2Array([center,center+Vector2(2,1)]),1,Color(.51,.39,.27,.19))
		Structures.line(node,PackedVector2Array([points[0],points[1],points[2]]),1,Color("#bca582"))
	if u in [23,25]:
		var edge := .13 if u==23 else .87
		Structures.line(node,PackedVector2Array([points[0].lerp(points[1],edge),points[3].lerp(points[2],edge)]),2,Color("#c8a66d"))
	if u==24:
		var center := points[0].lerp(points[2],.5)
		var diamond := PackedVector2Array([center+Vector2(0,-7),center+Vector2(13,0),center+Vector2(0,7),center-Vector2(13,0),center+Vector2(0,-7)])
		Structures.line(node,diamond,1,Color("#718394"))

static func _bracket_mural(node: Node2D, anchor: Vector2) -> void:
	var axis := Vector2(-32,16)
	var a := anchor+Vector2(0,-42)
	var b := a+axis*3.8
	var rise := Vector2(0,-64)
	Structures.quad(node,PackedVector2Array([a,b,b+rise,a+rise]),Color("#b89154"))
	var left := b-axis*.10+Vector2(0,-4)
	var right := a+axis*.10+Vector2(0,-4)
	Structures.quad(node,PackedVector2Array([left,right,right+Vector2(0,-56),left+Vector2(0,-56)]),Color("#142943"))
	var gold := Color("#edcc8e")
	for offset in [0.10,0.57]:
		var start := left.lerp(right,offset)+Vector2(0,-11)
		var step := (right-left)*.10
		for i in 4:
			var pin := start+step*i
			Structures.line(node,PackedVector2Array([pin-Vector2(0,6),pin,pin+step*.7,pin+step*.7-Vector2(0,6)]),1,gold)
		for i in [0,2]:
			var base: Vector2 = start+step*(float(i)+.35)
			Structures.line(node,PackedVector2Array([base-Vector2(0,6),base-Vector2(0,15),base+step-Vector2(0,15),base+step-Vector2(0,6)]),1,gold)
		var middle := start+step*.85
		Structures.line(node,PackedVector2Array([middle-Vector2(0,15),middle-Vector2(0,25),middle+step*2-Vector2(0,25),middle+step*2-Vector2(0,15)]),1,gold)
	var crest := left.lerp(right,.5)+Vector2(0,-45)
	Structures.quad(node,PackedVector2Array([crest-Vector2(0,7),crest+Vector2(7,0),crest+Vector2(0,7),crest-Vector2(7,0)]),gold)

