extends Node2D
## A subdued Soulmonster remains in its street instead of vanishing after its duel.
var art: Sprite2D
var desalmado: Sprite2D
var frames: Array=[]
var age:=0.0
var life:=0.0
var reduced_motion:=false
var shade: ShaderMaterial

func configure(content: Dictionary, species: String, gray_sprite: Sprite2D) -> void:
	name="CitySoul"
	desalmado=gray_sprite
	var atlas: Dictionary=content.combat[species]
	art=Sprite2D.new()
	art.texture=load("res://assets/campaign/"+atlas.image)
	var image: Image=art.texture.get_image()
	var crop:=Rect2i()
	for frame: Dictionary in atlas.animations.idle:
		var used: Rect2i=image.get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
		if used.has_area():crop=used if not crop.has_area() else crop.merge(used)
	for frame: Dictionary in atlas.animations.idle:
		frames.append(Rect2(frame.x+crop.position.x,frame.y+crop.position.y,crop.size.x,crop.size.y))
	art.region_enabled=true
	art.region_rect=frames[0]
	art.offset.y=-crop.size.y*.5
	art.scale=Vector2.ONE*84.0/crop.size.y
	shade=ShaderMaterial.new()
	shade.shader=preload("res://shaders/city_soul.gdshader")
	art.material=shade
	add_child(art)
	set_life(0.0)

func set_life(value: float) -> void:
	life=clampf(value,0.0,1.0)
	shade.set_shader_parameter("life",life)
	art.position.y=-life*5.0
	art.visible=life>0.0
	art.modulate.a=life
	desalmado.visible=life<1.0
	desalmado.modulate.a=1.0-life
	if reduced_motion:desalmado.position.y=0.0

func _process(delta: float) -> void:
	if reduced_motion:return
	age+=delta
	if life<.99:
		desalmado.position.y=-3.0+sin(age*3.0)*3.0
		return
	art.region_rect=frames[int(age*6.0)%frames.size()]
	art.position.y=-5.0+sin(age*2.0)*1.5

static func refresh(view: Node2D) -> void:
	var flags: Dictionary=view.saved_player.get("flags",{})
	for actor: Dictionary in view.npc_nodes:
		var event: Dictionary=actor.root.get_meta("event",{})
		var step: String=event.get("props",{}).get("step","")
		if step not in ["desalmado-centro","desalmado-lajes"]:continue
		var soul=actor.visual.get_node_or_null("CitySoul")
		if soul==null:
			var gray_sprite := actor.visual.get_child(0) as Sprite2D
			soul=load("res://scripts/campaign/city_soul.gd").new()
			soul.configure(view.content,"lacertubo" if step=="desalmado-centro" else "basic-raio-de-sol",gray_sprite)
			actor.visual.add_child(soul)
		soul.reduced_motion=view.reduced_motion
		soul.set_life(1.0 if flags.get("geradorLigado",false) else 0.0)
		actor.root.visible=flags.get("tylerCreatedKnown",false) or flags.get("geradorLigado",false)
		soul.set_meta("step",step)
