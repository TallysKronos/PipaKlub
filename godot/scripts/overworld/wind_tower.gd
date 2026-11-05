extends Node2D
## Mounted on existing blocked rock. The mast and receiver share one feet anchor.
const GROUND := Vector2(30.0,6.5)
const HEIGHT := 7.0
const RECEIVER := Vector2(0,-232)
var rotor: Node2D
var lamp: Polygon2D
var active := false
var reduced_motion := false

func configure(model, geometry: bool) -> void:
	name="WindTower"
	position=model.project(GROUND,false)
	set_meta("scenery",true)
	set_meta("ground_point",GROUND)
	var structure:=Node2D.new()
	structure.name="Structure"
	structure.position.y=-model.height_at(GROUND)*64.0
	add_child(structure)
	if geometry:
		for face in [
			{"points":[Vector2(-48,-120),Vector2(0,-144),Vector2(48,-120),Vector2(0,-96)],"color":"#aaa1bd"},
			{"points":[Vector2(-48,-120),Vector2(0,-96),Vector2(0,24),Vector2(-48,0)],"color":"#756880"},
			{"points":[Vector2(0,-96),Vector2(48,-120),Vector2(48,0),Vector2(0,24)],"color":"#90819c"}]:
			var block:=Polygon2D.new()
			block.polygon=PackedVector2Array(face.points)
			block.color=Color(face.color)
			structure.add_child(block)
	else:
		var stone:=Sprite2D.new()
		stone.texture=preload("res://assets/overworld/kits/camara-do-elo-v1/pilar.png")
		stone.offset=Vector2(0,-stone.texture.get_height()*.5+8)
		structure.add_child(stone)
	var mast:=Line2D.new()
	mast.width=10
	mast.default_color=Color("#3e3445")
	mast.points=PackedVector2Array([Vector2(0,-120),RECEIVER+Vector2(0,28)])
	structure.add_child(mast)
	rotor=Node2D.new()
	rotor.name="Rotor"
	rotor.position=RECEIVER
	structure.add_child(rotor)
	var colors: Array=preload("res://scripts/campaign/ui_tokens.gd").WIND_RIBBONS
	for index in 4:
		var sail:=Polygon2D.new()
		sail.polygon=PackedVector2Array([Vector2(0,0),Vector2(10,-53),Vector2(50,-35),Vector2(31,-14)])
		sail.color=colors[index].darkened(.2)
		sail.rotation=float(index)*PI*.5
		rotor.add_child(sail)
		var fold:=Polygon2D.new()
		fold.polygon=PackedVector2Array([Vector2(0,0),Vector2(10,-53),Vector2(31,-14)])
		fold.color=colors[index]
		sail.add_child(fold)
		var edge:=Line2D.new()
		edge.width=2.5
		edge.default_color=Color("#292533")
		edge.points=sail.polygon
		edge.closed=true
		sail.add_child(edge)
	lamp=Polygon2D.new()
	lamp.polygon=PackedVector2Array([Vector2(0,-10),Vector2(9,0),Vector2(0,10),Vector2(-9,0)])
	rotor.add_child(lamp)
	set_active(false)

func receptor_position() -> Vector2:
	return position+Vector2(0,-HEIGHT*64.0)+RECEIVER

func set_active(value: bool, reduced: bool=false) -> void:
	active=value
	reduced_motion=reduced
	if is_instance_valid(lamp):lamp.color=Color("#fff1b0") if active else Color("#665a70")
	set_process(active and not reduced_motion)

func _process(delta: float) -> void:
	rotor.rotation=fposmod(rotor.rotation+delta*.6,TAU)
