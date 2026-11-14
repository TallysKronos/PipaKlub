extends Node2D
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")

func configure(_view: Node2D, staging: Node2D, target: Vector2) -> void:
	name="WindRelease"
	z_index=2
	set_meta("target",target)
	var colors: Array=preload("res://scripts/campaign/ui_tokens.gd").WIND_RIBBONS
	for index in staging.get_child_count():
		var actor: Node2D=staging.get_child(index)
		var source: Vector2=actor.position+Vector2(0,-48)
		var stream:=Line2D.new()
		stream.name="Wind"+str(index)
		stream.width=3.0
		stream.default_color=colors[index%colors.size()]
		stream.set_meta("source",source)
		stream.set_meta("target",target)
		for step in 25:
			var t:=float(step)/24.0
			var at:=source.lerp(target,t)
			at.y-=sin(t*PI)*32.0
			stream.add_point(at)
		add_child(stream)
	var core:=Polygon2D.new()
	core.name="Convergence"
	core.color=Tokens.WIND_CORE
	core.position=target
	core.polygon=PackedVector2Array([Vector2(0,-12),Vector2(7,0),Vector2(0,12),Vector2(-7,0)])
	add_child(core)
