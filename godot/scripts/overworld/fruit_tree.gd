extends Node2D
## Editable Soulgen environmental rig. No inventory, persistence or map input coupling.
signal fruit_landed(species: String, world_position: Vector2)
@export_file("*.json") var rig_path: String = ""
var project: Dictionary = {}
var joints: Dictionary = {}
var definitions: Dictionary = {}
var elapsed: float = 0.0
var current_clip: String = "idle"
var busy := false
var released := false

func _ready() -> void:
	if not rig_path.is_empty(): configure(rig_path)

func configure(path: String) -> void:
	rig_path = path
	project = JSON.parse_string(FileAccess.get_file_as_string(path))
	for child in get_children(): child.queue_free()
	joints.clear()
	definitions.clear()
	for part: Dictionary in project.parts:
		definitions[part.id] = part
	for part: Dictionary in project.parts:
		var joint := Node2D.new()
		joint.name = part.id
		var parent_pivot := Vector2(project.rootPivot[0],project.rootPivot[1])
		var parent_node: Node2D = self
		if part.parent != null:
			parent_node = joints[part.parent]
			var ancestor: Dictionary = definitions[part.parent]
			parent_pivot = Vector2(ancestor.pivot[0],ancestor.pivot[1])
		parent_node.add_child(joint)
		joint.position = Vector2(part.pivot[0],part.pivot[1])-parent_pivot
		joints[part.id] = joint
		var art := Sprite2D.new()
		art.texture = load(path.get_base_dir().path_join(part.asset+".png"))
		art.centered = false
		art.position = Vector2(part.rect[0]-part.pivot[0],part.rect[1]-part.pivot[1])
		art.scale = Vector2(float(part.rect[2])/art.texture.get_width(),float(part.rect[3])/art.texture.get_height())
		joint.add_child(art)
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array([Vector2(0,-16),Vector2(32,0),Vector2(0,16),Vector2(-32,0)])
	body.add_child(shape)
	add_child(body)
	elapsed = 0.0
	current_clip = "idle"
	busy = false
	show_pose("idle",0.0)

func _process(delta: float) -> void:
	if project.is_empty(): return
	elapsed += delta
	show_pose(current_clip,elapsed)
	if busy:
		if not released and elapsed >= float(project.environment.dropTime):
			released = true
			_release_fruit()
		if elapsed >= float(project.clips.hit.seconds):
			busy = false
			current_clip = "idle"
			elapsed = 0.0

func fruit_count() -> int:
	var count := 0
	for id: String in joints:
		if id.begins_with("fruit") and joints[id].visible: count += 1
	return count

func hit() -> bool:
	if busy or project.is_empty(): return false
	preload("res://scripts/campaign/sound_director.gd").cue(self, "world.tree_hit")
	preload("res://scripts/campaign/sound_director.gd").cue(self, "world.canopy")
	busy = true
	released = false
	current_clip = "hit"
	elapsed = 0.0
	return true

func _release_fruit() -> void:
	for id: String in joints:
		if not id.begins_with("fruit") or not joints[id].visible: continue
		var attached: Node2D = joints[id]
		var drop := attached.duplicate() as Node2D
		var original_transform := attached.global_transform
		attached.hide()
		preload("res://scripts/campaign/sound_director.gd").cue(self, "world.fruit_fall")
		get_parent().add_child(drop)
		drop.global_transform = original_transform
		drop.z_index = 5
		var start := drop.global_position
		var destination := Vector2(start.x+22.0,global_position.y+8.0)
		var flight := create_tween()
		flight.tween_property(drop,"global_position",destination,.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.parallel().tween_property(drop,"rotation",drop.rotation+.9,.45)
		flight.tween_property(drop,"global_position",destination+Vector2(5,-8),.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(drop,"global_position",destination+Vector2(9,0),.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_callback(func() -> void: fruit_landed.emit(str(project.environment.species),drop.global_position))
		return

func show_pose(clip_id: String,time: float) -> void:
	var clip: Dictionary = project.clips[clip_id]
	var t := fposmod(time,float(clip.seconds)) if clip.loop else clampf(time,0.0,float(clip.seconds))
	var frames: Array = clip.frames
	var first: Dictionary = frames[0]
	var second: Dictionary = frames[-1]
	for i in range(1,frames.size()):
		if float(frames[i].t)>=t:
			first = frames[i-1]
			second = frames[i]
			break
	var duration := float(second.t)-float(first.t)
	var weight := clampf((t-float(first.t))/duration,0.0,1.0) if duration>0 else 0.0
	if first.get("ease","smooth")=="smooth":weight = weight*weight*(3.0-2.0*weight)
	for id: String in joints:
		var a: Dictionary = first.values.get(id,{})
		var b: Dictionary = second.values.get(id,{})
		var part: Dictionary = definitions[id]
		var parent_pivot := Vector2(project.rootPivot[0],project.rootPivot[1])
		if part.parent != null:
			var parent_part: Dictionary = definitions[part.parent]
			parent_pivot = Vector2(parent_part.pivot[0],parent_part.pivot[1])
		var joint: Node2D = joints[id]
		joint.position = Vector2(part.pivot[0],part.pivot[1])-parent_pivot+Vector2(lerpf(a.get("x",0),b.get("x",0),weight),lerpf(a.get("y",0),b.get("y",0),weight))
		joint.rotation_degrees = lerpf(a.get("rotation",0),b.get("rotation",0),weight)
		joint.scale = Vector2(lerpf(a.get("scaleX",1),b.get("scaleX",1),weight),lerpf(a.get("scaleY",1),b.get("scaleY",1),weight))
