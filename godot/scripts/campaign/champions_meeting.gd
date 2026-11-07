extends RefCounted
const Tokens=preload("res://scripts/campaign/ui_tokens.gd")
## Identifies a speaker on the actual world cast, without polling the dialogue.
var world: Node2D
var members: Dictionary={}
var marker: Node2D
var label: Label
var camera_before: Vector2
var zoom_before: Vector2
var smoothing_before:=false

func configure(view: Node2D) -> void:
	world=view
	camera_before=view.camera.position
	zoom_before=view.camera.zoom
	smoothing_before=view.camera.position_smoothing_enabled
	view.camera.position_smoothing_enabled=false
	var staging: Node2D=view.actors.get_node("EndgameStaging")
	for actor: Node2D in staging.get_children():
		members[str(actor.name)]={"node":actor,"point":actor.get_meta("ground_point"),"color":actor.modulate}
	for actor: Dictionary in view.npc_nodes:
		if actor.root.get_meta("event",{}).get("props",{}).get("step","")=="reuniao":
			members.Mikka={"node":actor.root,"point":actor.point,"color":actor.root.modulate}
	marker=Node2D.new()
	marker.name="MeetingSpeaker"
	marker.z_index=3
	view.actors.add_child(marker)
	var ring:=Line2D.new()
	ring.width=2.0
	ring.default_color=Tokens.MEETING_RING
	for index in 33:
		var angle:=TAU*float(index)/32.0
		ring.add_point(Vector2(cos(angle)*23,sin(angle)*11))
	marker.add_child(ring)
	label=Label.new()
	label.add_theme_font_size_override("font_size",16)
	label.add_theme_color_override("font_color",Tokens.MEETING_NAME)
	label.add_theme_color_override("font_outline_color",Tokens.MEETING_NAME_OUTLINE)
	label.add_theme_constant_override("outline_size",5)
	marker.add_child(label)
	var center:=Vector2.ZERO
	for record: Dictionary in members.values():center+=view.model.project(record.point)
	view.camera.position=center/maxi(1,members.size())+Vector2(0,105)
	view.camera.zoom=Vector2.ONE
	view.camera.reset_smoothing()

func focus(speaker: String) -> void:
	var known:=members.has(speaker)
	marker.visible=known
	for name: String in members:
		var actor: CanvasItem=members[name].node
		actor.modulate=members[name].color if not known or name==speaker else Tokens.MEETING_LISTENER
	if not known:return
	marker.position=world.model.project(members[speaker].point)
	label.text=speaker
	label.reset_size()
	label.position=Vector2(-label.size.x*.5,-112)
	marker.set_meta("speaker",speaker)

func dispose() -> void:
	for record: Dictionary in members.values():
		if is_instance_valid(record.node):
			var color: Color=record.color
			color.a=record.node.modulate.a
			record.node.modulate=color
	if is_instance_valid(world):
		world.camera.position=camera_before
		world.camera.zoom=zoom_before
		world.camera.position_smoothing_enabled=smoothing_before
		world.camera.reset_smoothing()
	if is_instance_valid(marker):marker.queue_free()
