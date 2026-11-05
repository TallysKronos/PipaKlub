extends RefCounted
const Shapes = preload("res://scripts/overworld/forest_structures.gd")

static func build(view, force_broken: bool = false) -> void:
	var flags: Dictionary = view.get("saved_player").get("flags",{}) if view.campaign_mode else {}
	var broken := bool(force_broken or flags.get("enamorDesperto",false) or flags.get("enamorDerrotado",false) or OS.get_environment("ELO_COLAPSO")=="1")
	if view.model.data.forest.get("gallery",false):
		_gallery_walls(view)
		_gallery_landmarks(view)
	else:
		_chamber_walls(view,broken)
	for piece: Dictionary in view.model.data.pieces:
		var at := Vector2(piece.u+piece.fu*.5,piece.v+piece.fv*.5)
		var node := Node2D.new()
		node.position = view.model.project(Vector2(piece.u+piece.fu-.5,piece.v+piece.fv-.5),false)
		var ground: Vector2 = view.model.project(at)-node.position
		node.set_meta("elo_chamber_art",true)
		view.actors.add_child(node)
		var fossil: bool = piece.asset=="elo-fossil"
		if fossil and not broken and OS.get_environment("KRONASTA_GEOMETRIA")!="1":
			var rim := PackedVector2Array()
			for cell in [Vector2(piece.u,piece.v),Vector2(piece.u+piece.fu,piece.v),Vector2(piece.u+piece.fu,piece.v+piece.fv),Vector2(piece.u,piece.v+piece.fv)]:
				rim.append(view.model.project(cell)-node.position)
			Shapes.quad(node,rim,Color("#282936"))
			Shapes.line(node,PackedVector2Array([rim[1],rim[2],rim[3]]),3,Color("#74635e"))
			var art := Sprite2D.new()
			art.texture = _awakening_frame(load("res://assets/overworld/kits/camara-do-elo-v1/enamor-despertar.png"),0)
			var image_size := art.texture.get_size()
			art.scale = Vector2.ONE * (rim[1].x-rim[3].x) / image_size.x
			art.centered = false
			art.offset = Vector2(-209,-392)
			art.position = ground.lerp(rim[2],.64)
			art.modulate = Color.WHITE
			art.name = "EnamorFossil"
			node.add_child(art)
			continue
		if not fossil and OS.get_environment("KRONASTA_GEOMETRIA")!="1":
			var asset: String = "fragmentos" if broken else piece.asset.trim_prefix("elo-")
			var art := Sprite2D.new()
			art.texture = load("res://assets/overworld/kits/camara-do-elo-v1/"+asset+".png")
			art.scale = Vector2.ONE * (140.0 if piece.asset=="elo-pilar" and piece.fu==1 else 58.0 if piece.fu==1 else 100.0) / art.texture.get_width()
			art.offset.y = -art.texture.get_height()*.5
			art.position = view.model.project(Vector2(at.x,piece.v+piece.fv))-node.position
			node.add_child(art)
			continue
		var width := 83.0 if fossil else 29.0
		var height := (33.0 if broken else 78.0) if fossil else (25.0 if broken else 96.0)
		if broken:
			_rubble(node,ground,fossil,piece.u<24)
		var a := ground+Vector2(-width,0)
		var b := ground+Vector2(0,14)
		var c := ground+Vector2(width,0)
		var peak := Vector2(0,-height)
		Shapes.quad(node,PackedVector2Array([a,b,b+peak,a+peak]),Color("#34364e"))
		Shapes.quad(node,PackedVector2Array([b,c,c+peak,b+peak]),Color("#252638"))
		Shapes.quad(node,PackedVector2Array([a+peak,b+peak,c+peak,ground+Vector2(0,-14)+peak]),Color("#65637b"))
		if broken:
			Shapes.line(node,PackedVector2Array([a,b+peak*.3,c+peak]),3,Color("#ac6db0"))
		else:
			Shapes.line(node,PackedVector2Array([b+Vector2(0,-8),b+peak+Vector2(0,7)]),2,Color("#bb985f"))

static func _wall(node: Node2D, end: Vector2, broken: bool, stone: bool = false) -> void:
	var rise := Vector2(0,-96)
	var segments := maxi(1,roundi(end.length()/65))
	for i in segments:
		var a := end*float(i)/segments
		var b := end*float(i+1)/segments
		var cap := rise+Vector2(0,18 if broken and i%4==2 else 0)
		var shade := Color("#413750").lightened(float(i%3)*.035)
		var face := PackedVector2Array([a,b,b+cap,a+cap])
		if stone and OS.get_environment("KRONASTA_GEOMETRIA")!="1":
			var panel := Polygon2D.new()
			panel.polygon = face
			panel.texture = load("res://assets/overworld/kits/cavernas-v3/surfaces/parede-basalto.png")
			panel.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			var phase := (node.position.x+node.position.y)*.5
			panel.uv = PackedVector2Array([Vector2(phase,96),Vector2(phase+end.length(),96),Vector2(phase+end.length(),0),Vector2(phase,0)])
			panel.color = Color("#898199")
			node.add_child(panel)
		else:
			Shapes.quad(node,face,shade)
		Shapes.line(node,PackedVector2Array([a,a+cap,b+cap]),2,Color("#686078"))
		Shapes.line(node,PackedVector2Array([a+Vector2(0,-12),b+Vector2(0,-12)]),2,Color("#9f754a"))
		if i%3==1 and not broken:
			var center := a.lerp(b,.5)+Vector2(0,-52)
			var wing := (b-a)*.34
			var sail := PackedVector2Array([center-Vector2(0,29),center+wing,center+Vector2(0,21),center-wing])
			Shapes.quad(node,sail,Color("#9b6556"))
			sail.append(sail[0])
			Shapes.line(node,sail,2,Color("#c7a16e"))
			Shapes.line(node,PackedVector2Array([sail[0],sail[2]]),1,Color("#dbc39a"))
		if broken and i%3==1:
			var p := a.lerp(b,.45)
			Shapes.line(node,PackedVector2Array([p+Vector2(0,-5),p+Vector2(7,-32),p+Vector2(-4,-47),p+Vector2(4,-70)]),2,Color("#9d64a6"))

static func _rubble(node: Node2D, ground: Vector2, fossil: bool, left: bool) -> void:
	var direction := -1.0 if left else 1.0
	var span := 130.0 if fossil else 44.0
	for i in 5:
		var at := ground+Vector2(direction*span*(.35+i*.16), 7.0+float(i%3)*8.0)
		var size := (31.0 if fossil else 18.0)-float(i)*2.0
		Shapes.quad(node,PackedVector2Array([at+Vector2(-size,0),at+Vector2(-4,-size),at+Vector2(size,-size*.3),at+Vector2(3,8)]),Color("#555063"))
		Shapes.line(node,PackedVector2Array([at+Vector2(-size,0),at+Vector2(-4,-size),at+Vector2(size,-size*.3)]),2,Color("#817587"))
	var start := ground+Vector2(direction*9,8)
	Shapes.line(node,PackedVector2Array([start,start+Vector2(direction*24,4),start+Vector2(direction*30,15),start+Vector2(direction*52,22)]),2,Color("#b179bb"))

static func _chamber_walls(view,broken: bool) -> void:
	var wall := Node2D.new()
	wall.set_meta("elo_chamber_art",true)
	wall.position = view.model.project(Vector2(15,11),false)
	view.actors.add_child(wall)
	_wall(wall,view.model.project(Vector2(15,36),false)-wall.position,broken)
	_wall(wall,view.model.project(Vector2(32,11),false)-wall.position,broken)

static func _gallery_walls(view) -> void:
	var model = view.model
	for v in int(model.data.h):
		for u in int(model.data.w):
			var cell := Vector2i(u,v)
			if model.cell_at(cell).material!="piso":continue
			for offset in [Vector2i.LEFT,Vector2i.UP]:
				if model.cell_at(cell+offset).get("material","")=="piso":continue
				# Leave the passage mouths open where the floor meets the map edge.
				if offset==Vector2i.UP and v==0:continue
				if offset==Vector2i.UP and v==5 and u in range(24,28) and str(model.data.id).ends_with("-c"):continue
				var wall := Node2D.new()
				wall.position = model.project(Vector2(cell),false)
				view.actors.add_child(wall)
				var edge := Vector2(-32,16) if offset==Vector2i.LEFT else Vector2(32,16)
				_wall(wall,edge,false,true)

static func _gallery_landmarks(view) -> void:
	var model = view.model
	var part: String = str(model.data.id).right(1)
	var encounter: Dictionary = model.data.events.filter(func(e):return int(e.id)==31002)[0]
	var center := Vector2(encounter.u+.5,encounter.v+.5)
	var marker := Node2D.new()
	marker.position = model.project(center)
	marker.z_index = -1
	view.actors.add_child(marker)
	var accent: Color = {"a":Color("#d29065"),"b":Color("#a885bc"),"c":Color("#edb978")}[part]
	for offset in [Vector2(-2,0),Vector2(0,-2),Vector2(2,0),Vector2(0,2)]:
		var edge: Vector2 = model.project(center+offset)-marker.position
		Shapes.line(marker,PackedVector2Array([edge,edge*.52+Vector2(0,5),edge*.22]),3,accent)
	if part!="c":
		return
	var gate := Node2D.new()
	gate.position = model.project(Vector2(26,5),false)
	view.actors.add_child(gate)
	var left := Vector2(-64,-32)
	var right := Vector2(64,32)
	var rise := Vector2(0,-134)
	Shapes.quad(gate,PackedVector2Array([left,right,right+rise,left+rise]),Color("#272337"))
	for shift in [0.0,.10,.90,1.0]:
		var jamb := left.lerp(right,shift)
		Shapes.line(gate,PackedVector2Array([jamb,jamb+rise]),3,accent)
	Shapes.line(gate,PackedVector2Array([left+rise,right+rise]),5,accent)
	var seal := Vector2(0,-68)
	Shapes.line(gate,PackedVector2Array([seal+Vector2(0,-22),seal+Vector2(18,9),seal+Vector2(0,22),seal-Vector2(18,9),seal+Vector2(0,-22)]),2,accent)


static func collapse(view) -> void:
	for child in view.actors.get_children():
		if child.has_meta("elo_chamber_art"):
			view.actors.remove_child(child)
			child.queue_free()
	build(view,true)

static func rupture(view) -> Node2D:
	var effect := Node2D.new()
	effect.z_index = 4
	effect.position = view.model.project(Vector2(24,15.5))
	view.add_child(effect)
	Shapes.line(effect,PackedVector2Array([Vector2(-70,9),Vector2(-43,-14),Vector2(-11,-8),Vector2(15,-49),Vector2(46,-37),Vector2(73,-74)]),3,Color("#dea3e8"))
	return effect

static func awakening_sprite(view) -> AnimatedSprite2D:
	var fossil: Sprite2D
	for child in view.actors.get_children():
		var candidate = child.get_node_or_null("EnamorFossil")
		if candidate is Sprite2D:
			fossil = candidate
			break
	if fossil == null:
		return null
	var atlas: Texture2D = load("res://assets/overworld/kits/camara-do-elo-v1/enamor-despertar.png")
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default",false)
	frames.set_animation_speed("default",10)
	for i in 8:
		frames.add_frame("default",_awakening_frame(atlas,i),[3.0,3.0,2.0,2.0,1.5,1.5,7.0,5.0][i])
	var art := AnimatedSprite2D.new()
	art.sprite_frames = frames
	art.centered = false
	art.scale = Vector2.ONE * (fossil.texture.get_width()*fossil.scale.x/443.0)
	art.position = fossil.position
	art.offset = fossil.offset
	art.modulate = fossil.modulate
	fossil.get_parent().add_child(art)
	fossil.hide()
	return art

static func _awakening_frame(atlas: Texture2D,index: int) -> AtlasTexture:
	var tile := AtlasTexture.new()
	tile.atlas = atlas
	tile.region = Rect2(index%4*443,floori(index/4.0)*443,443,443)
	tile.filter_clip = true
	return tile

static func prepare_rock_gag(view) -> Dictionary:
	var gag := Node2D.new()
	gag.position = view.model.project(Vector2(27.5,17.5))
	gag.z_index = 4
	view.add_child(gag)
	var culprit := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_speed("walk",8)
	for index in [0,1,0,2]:
		frames.add_frame("walk",load("res://assets/overworld/kits/camara-do-elo-v1/rato-"+str(index)+".png"))
	var idle_atlas: Texture2D = load("res://assets/overworld/kits/camara-do-elo-v1/rato-idle-eight.png")
	for index in 8:
		var idle := AtlasTexture.new()
		idle.atlas = idle_atlas
		idle.region = Rect2(index*64,0,64,96)
		idle.filter_clip = true
		frames.add_frame("default",idle)
	culprit.sprite_frames = frames
	culprit.frame = 7
	culprit.offset.y = -46
	culprit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gag.add_child(culprit)
	var rock := Node2D.new()
	rock.position = Vector2(-3,-150)
	gag.add_child(rock)
	Shapes.quad(rock,PackedVector2Array([Vector2(-17,-3),Vector2(-9,-22),Vector2(12,-21),Vector2(19,-5),Vector2(8,4),Vector2(-12,3)]),Color("#777086"))
	rock.hide()
	var reaction := Label.new()
	reaction.text = "Ai."
	reaction.position = Vector2(18,-54)
	reaction.hide()
	gag.add_child(reaction)
	return {"root":gag,"culprit":culprit,"rock":rock,"reaction":reaction}

static func drop_rock(gag: Dictionary, reduced_motion: bool) -> void:
	var rock: Node2D = gag.rock
	rock.show()
	var tween := rock.create_tween()
	tween.tween_property(rock,"position:y",-90.0,0.0 if reduced_motion else .16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		gag.culprit.scale.y = .72
		gag.rock.position = Vector2(gag.culprit.position.x,-13)
		gag.reaction.show())
	tween.tween_interval(.67)
	tween.tween_property(gag.root,"modulate:a",0.0,.17)
	tween.tween_callback(gag.root.queue_free)

static func eremor_advance(view) -> AnimatedSprite2D:
	var folder := "res://assets/overworld/kits/camara-do-elo-v1/"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder+"eremor-walk.json"))
	var species: Dictionary = data.species.eremor
	var atlas: Texture2D = load(folder+"eremor-walk.png")
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default",1000.0/float(species.frameMs))
	for index in species.animations.move[0]:
		var frame: Dictionary = species.frames[index]
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = Rect2(frame.x,frame.y,frame.w,frame.h)
		texture.margin = Rect2(Vector2(192,399)-Vector2(frame.footAnchor.x,frame.footAnchor.y),Vector2.ZERO)
		frames.add_frame("default",texture)
	var actor := AnimatedSprite2D.new()
	actor.sprite_frames = frames
	actor.centered = false
	actor.offset = Vector2(-192,-399)
	actor.scale = Vector2.ONE*.72
	actor.position = view.model.project(Vector2(24,15.5))
	actor.z_index = 2
	view.actors.add_child(actor)
	return actor

static func move_culprit(view, gag: Dictionary, reduced_motion: bool) -> void:
	var actor: Node2D = gag.root
	var culprit: AnimatedSprite2D = gag.culprit
	var model = view.model
	var event: Dictionary = model.data.events.filter(func(entry):return int(entry.id)==31002)[0]
	var start := Vector2(event.u+.5,event.v+.5)
	var seal := Vector2(26.5,16.5)
	var impact := Vector2(27.5,17.5)
	var original: Node = view.actors.get_node_or_null("Evento31002")
	if original is CanvasItem:original.hide()
	actor.position = model.project(start)
	for destination in [seal,impact]:
		var route: PackedVector2Array = model.path_to(start,destination)
		if route.is_empty():return
		if not reduced_motion:culprit.play("walk")
		for point in route:
			var target: Vector2 = model.project(point)
			var delta := target-actor.position
			if delta.length()<.01:continue
			culprit.flip_h = delta.x>0
			var movement := actor.create_tween()
			movement.tween_property(actor,"position",target,delta.length()/145.0 if not reduced_motion else 0.0)
			await movement.finished
		culprit.pause()
		culprit.animation = "default"
		culprit.frame = 7
		if destination==seal:
			var seal_flash := Node2D.new()
			seal_flash.position = Vector2(0,-45)
			actor.add_child(seal_flash)
			Shapes.line(seal_flash,PackedVector2Array([Vector2(-12,0),Vector2(0,-9),Vector2(12,0),Vector2(0,9),Vector2(-12,0)]),2,Color("#f6ba79"))
			var flash := actor.create_tween()
			flash.tween_property(seal_flash,"modulate:a",0.0,.35)
			await flash.finished
			seal_flash.queue_free()
		start=destination
	culprit.flip_h=false

static func evacuate(view) -> void:
	var exit_point := Vector2(25.5, 37.5)
	var cast := [
		["res://assets/campaign/tyler-clareira-v1/tyler-overworld-idle-eight.png", true, 80.0],
		["res://assets/npc-ds/nina.png", true, 76.0],
		["res://assets/overworld/kits/camara-do-elo-v1/mikka-0.png", false, 76.0],
		["res://assets/overworld/kits/camara-do-elo-v1/jamile-0.png", false, 76.0],
		["res://assets/campaign/beira-canal-v1/grampo-idle-eight.png", true, 80.0],
		["res://assets/campaign/beira-canal-v1/platyx-overworld-eight.png", true, 52.0],
	]
	var group: Tween = view.create_tween().set_parallel()
	var slots := [
		Vector2(24.5, 26.5), Vector2(26.5, 24.5),
		Vector2(23.5, 24.5), Vector2(26.5, 22.5),
		Vector2(23.5, 21.5), Vector2(25.5, 20.5),
	]
	var last_clearance := {}
	for i in cast.size():
		var start: Vector2 = slots[i]
		if not view.model.point_walkable(start): continue
		var route: PackedVector2Array = view.model.path_to(start, exit_point)
		if route.is_empty(): continue
		var sprite := Sprite2D.new()
		sprite.texture = load(cast[i][0])
		if cast[i][1]:
			sprite.region_enabled = true
			sprite.region_rect = Rect2(sprite.texture.get_width() * .75, sprite.texture.get_height() * .5, sprite.texture.get_width() * .25, sprite.texture.get_height() * .5)
		var height := sprite.region_rect.size.y if cast[i][1] else float(sprite.texture.get_height())
		sprite.scale = Vector2.ONE * float(cast[i][2]) / height
		sprite.offset.y = -height * .5 + (4.0 if cast[i][1] else 0.0)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 1
		var lane := -.33 if i % 2 == 0 else .33
		var shift := Vector2(lane, 0)
		sprite.position = view.model.project(start + shift)
		view.actors.add_child(sprite)
		var departure := i * .62
		var travel := 0.0
		var last_point := start
		for point in route:
			departure = maxf(departure, float(last_clearance.get(point, 0.0)) - travel)
			travel += last_point.distance_to(point) * .18
			last_point = point
		var elapsed := departure
		var previous := start
		for point in route:
			var duration := previous.distance_to(point) * .18
			var from_screen: Vector2 = view.model.project(previous)
			var to_screen: Vector2 = view.model.project(point)
			var lane_offset: Vector2 = view.model.project(point + shift, false) - view.model.project(point, false)
			group.tween_property(sprite, "position", to_screen + lane_offset, duration).set_delay(elapsed).from(from_screen + lane_offset)
			elapsed += duration
			last_clearance[point] = elapsed + .48
			previous = point
		group.tween_property(sprite, "modulate:a", 0.0, .22).set_delay(elapsed)
		group.tween_callback(sprite.queue_free).set_delay(elapsed + .22)
	if group.is_valid(): await group.finished

static func untie_prisoner(view) -> void:
	for actor in view.npc_nodes:
		var event: Dictionary = actor.root.get_meta("event")
		if event.props.get("acao") != "ruinasRefem": continue
		var prisoner: Node2D = actor.root
		var cord := Line2D.new()
		cord.default_color = Color("#e0af69")
		cord.width = 3.0
		cord.points = PackedVector2Array([Vector2(-12, -35), Vector2(0, -32), Vector2(12, -35)])
		cord.z_index = 1
		prisoner.add_child(cord)
		var release := prisoner.create_tween()
		release.tween_property(cord, "position", Vector2(8, 31), .34).set_ease(Tween.EASE_IN)
		release.parallel().tween_property(cord, "rotation", .48, .34)
		release.tween_property(cord, "modulate:a", 0.0, .25)
		await release.finished
		cord.queue_free()
		return

## Playtest: after the Eremor falls, a short shot shows the Elo key breaking at the
## altar, so the victory text no longer has to carry it.
static func shatter_key(view, reduced_motion: bool) -> void:
	var altar: Vector2 = view.model.project(Vector2(24,15.5))
	var shards := Node2D.new()
	shards.name = "EloKeyShards"
	shards.z_index = 4
	shards.position = altar+Vector2(0,-36)
	view.actors.add_child(shards)
	var pieces: Array[Line2D] = []
	for i in 5:
		var piece := Line2D.new()
		piece.width = 3.0
		piece.default_color = Color("#dea3e8")
		piece.points = PackedVector2Array([Vector2(-5,0),Vector2(0,-7),Vector2(5,0)])
		piece.position = Vector2(-10+i*5,0)
		shards.add_child(piece)
		pieces.append(piece)
	var camera: Camera2D = view.camera
	var back: Vector2 = camera.position
	if reduced_motion:
		for i in pieces.size():pieces[i].position = Vector2(-26+i*13,30)
		return
	var focus: Tween = view.create_tween()
	focus.tween_property(camera,"position",altar,.4).set_trans(Tween.TRANS_SINE)
	await focus.finished
	var fall: Tween = view.create_tween().set_parallel()
	for i in pieces.size():
		fall.tween_property(pieces[i],"position",Vector2(-26+i*13,30+(i%2)*6),.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.tween_property(pieces[i],"rotation",(i-2)*.6,.45)
	await fall.finished
	await view.get_tree().create_timer(.5).timeout
	if not is_instance_valid(camera):return
	await view.create_tween().tween_property(camera,"position",back,.35).set_trans(Tween.TRANS_SINE).finished
