extends Node2D
## Video-derived pixel study: runtime translation/height belongs to the map controller.
const Pixelgen = preload("res://scripts/pixelgen_sprites.gd")
const LOCOMOTION_ASSETS := "res://assets/kael-video/iso-v2/"
const DIRECTIONS := ["s","sw","w","nw","n","ne","e","se"]
const BODY_SCALE := 1.12
const STANDING_HEIGHT := 70.0 # Visible height of the current front/three-quarter idle pose.
var facing := "se"
var moving := false
var running := false
var clock := 0.0
var jump_time := -1.0
var walking: Texture2D
var resting: Texture2D
var sprinting: Texture2D
const IDLE_TIMES := [480,150,320,150,480,150,320,150]
const RUN_TIMES := [80,80,80,80,80,80,80,80]
var locomotion_state := "idle"
var jumping: Texture2D
var jump_frames: Dictionary
var item_frames: Dictionary
var item_texture: Texture2D
var item_time := -1.0
var item_facing := "se"
var motion_action := ""

static func facing_for(direction: Vector2, previous: String="se") -> String:
	if direction.length_squared()<.000001:return previous
	var octant := posmod(roundi(direction.angle()/(PI/4)),8)
	return ["e","se","s","sw","w","nw","n","ne"][octant]

func face_motion(direction: Vector2) -> void:
	facing=facing_for(direction,facing)

func set_motion_action(action: String) -> void:
	# Existing stairs/cinematic controllers own translation and height. Keep stepping
	# in the current direction; never swap back to the old paper-doll character.
	if action not in ["","subir","descer"]:return
	if motion_action!=action:clock=0
	motion_action=action
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	walking=Pixelgen.load_texture(LOCOMOTION_ASSETS+"walk.png")
	resting=Pixelgen.load_texture(LOCOMOTION_ASSETS+"idle.png")
	sprinting=Pixelgen.load_texture(LOCOMOTION_ASSETS+"run.png")
	jumping=Pixelgen.load_texture(LOCOMOTION_ASSETS+"jump.png")
	jump_frames=JSON.parse_string(FileAccess.get_file_as_string(LOCOMOTION_ASSETS+"jump.json"))
	item_texture=Pixelgen.load_texture(LOCOMOTION_ASSETS+"item.png")
	item_frames=JSON.parse_string(FileAccess.get_file_as_string(LOCOMOTION_ASSETS+"item.json"))

func item_pose(t: float, from_facing: String) -> void:
	item_time=clampf(t,0,1)
	item_facing=from_facing
	queue_redraw()

func stop_item() -> void:
	item_time=-1
	facing="s"
	clock=0

func _timed_frame(metadata: Dictionary, t: float) -> int:
	var elapsed := 0.0
	for i in metadata.durationsMs.size():
		elapsed+=metadata.durationsMs[i]
		if t*metadata.durationMs<elapsed:return i
	return metadata.durationsMs.size()-1
func jump_pose(t: float) -> void:
	jump_time=clampf(t,0,1)
	queue_redraw()
func stop_jump() -> void:
	jump_time=-1
	clock=0
func _process(delta: float) -> void:
	var next_state := "walk" if not motion_action.is_empty() else "run" if moving and running else "walk" if moving else "idle"
	if next_state!=locomotion_state:clock=0
	locomotion_state=next_state
	clock+=delta
	queue_redraw()

func cycle_frame(durations: Array) -> int:
	var total := 0.0
	for duration in durations:total+=duration
	var time := fmod(clock*1000.0,total)
	for i in durations.size():
		time-=durations[i]
		if time<0:return i
	return 0
func _draw() -> void:
	if not is_instance_valid(walking):return
	if item_time>=0:
		# Use actual directional poses to turn from any starting angle, never rotate a flat sprite.
		var turn: float=item_frames.turnMs/float(item_frames.durationMs+item_frames.turnMs)
		if item_time<turn:
			var start: int=maxi(0,DIRECTIONS.find(item_facing))
			var steps: int=start if start<=4 else 8-start
			var used: int=mini(steps,int(item_time/turn*(steps+1)))
			var row: int=(start-used if start<=4 else start+used)%8
			draw_texture_rect_region(resting,Rect2(-32,-94,64,96),Rect2(0,row*96,64,96))
			return
		var t := (item_time-turn)/(1-turn)
		var cell := Vector2(item_frames.cell[0],item_frames.cell[1])
		var pivot := Vector2(item_frames.pivot[0],item_frames.pivot[1])
		var index := _timed_frame(item_frames,t)
		draw_texture_rect_region(item_texture,Rect2(-pivot,cell),Rect2(Vector2(index,0)*cell,cell))
		return
	var row: int=maxi(0,DIRECTIONS.find(facing))
	var index := int(clock*8)%8 if moving or not motion_action.is_empty() else 0
	if jump_time<0:
		var texture := walking
		if motion_action.is_empty():
			if not moving:
				texture=resting
				index=cycle_frame(IDLE_TIMES)
			elif running:
				texture=sprinting
				index=cycle_frame(RUN_TIMES)
		if is_instance_valid(texture):draw_texture_rect_region(texture,Rect2(-32,-94,64,96),Rect2(index*64,row*96,64,96))
		return
	index=_timed_frame(jump_frames,jump_time)
	var cell := Vector2(jump_frames.cell[0],jump_frames.cell[1])
	var pivot := Vector2(jump_frames.pivot[0],jump_frames.pivot[1])
	draw_texture_rect_region(jumping,Rect2(-pivot,cell),Rect2(Vector2(index,row)*cell,cell))
