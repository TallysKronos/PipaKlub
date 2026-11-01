extends "res://scripts/kael_video_avatar.gd"
var mounted:=false
var mount_rig:Node2D
var mount_definition_path:="res://assets/mounts/doberman-c-v1/mount.json"
## Shared campaign/prototype entry point. Coordinates and foot anchors stay with each scene.
func _ready() -> void:
	super()
	scale=Vector2.ONE*.85*BODY_SCALE

func set_mounted(value:bool) -> void:
	mounted=value
	if value and not is_instance_valid(mount_rig):
		mount_rig=load("res://scripts/mount_rig.gd").new()
		mount_rig.definition_path=mount_definition_path
		add_child(mount_rig)
	if is_instance_valid(mount_rig):mount_rig.visible=value;mount_rig.set_facing(facing)
	queue_redraw()

func travel_multiplier() -> float:
	return 1.35 if mounted else 1.0

func _process(delta:float) -> void:
	super(delta)
	if mounted and is_instance_valid(mount_rig):mount_rig.set_facing(facing)

func _draw() -> void:
	if not mounted:super()

func jump_pose(t:float) -> void:
	if mounted:set_mounted(false)
	super(t)

func item_pose(t:float,from_facing:String) -> void:
	if mounted:set_mounted(false)
	super(t,from_facing)

func set_motion_action(action:String) -> void:
	if mounted and not action.is_empty():set_mounted(false)
	super(action)
