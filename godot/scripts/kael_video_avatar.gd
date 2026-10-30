extends Node2D
## Video-derived pixel study: runtime translation/height belongs to the map controller.
const DIRECTIONS := ["s","sw","w","nw","n","ne","e","se"]
const BODY_SCALE := 1.12 # Old composed silhouette 96 px; new directional body about 86 px.
const STANDING_HEIGHT := 86.0 # Measured SE standing silhouette; excludes transparent cell margin.
var facing := "se"
var moving := false
var clock := 0.0
var jump_time := -1.0
var walking: Texture2D
var jumping: Texture2D
var jump_frames: Dictionary
var item_frames: Dictionary
var item_texture: Texture2D
var item_time := -1.0
var item_facing := "se"
var motion_action := ""
var was_stepping := false

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
	walking=PixelgenSprites.texture("res://assets/kael-video/kael-walk-eight.png")
	jumping=PixelgenSprites.texture("res://assets/kael-video/kael-jump.png")
	jump_frames=JSON.parse_string(FileAccess.get_file_as_string("res://assets/kael-video/jump.json"))
	item_texture=PixelgenSprites.texture("res://assets/kael-video/kael-item.png")
	item_frames=JSON.parse_string(FileAccess.get_file_as_string("res://assets/kael-video/item.json"))

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
	var stepping := moving or not motion_action.is_empty()
	if stepping:
		if not was_stepping:clock=0
		clock+=delta
	else:clock=0
	was_stepping=stepping
	queue_redraw()
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
			draw_texture_rect_region(walking,Rect2(-32,-94,64,96),Rect2(0,row*96,64,96))
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
		draw_texture_rect_region(walking,Rect2(-32,-94,64,96),Rect2(index*64,row*96,64,96))
		return
	row=1 if facing in ["ne","nw","n"] else 0
	var count: int=jump_frames.framesPerDirection
	index=count-1
	var elapsed := 0.0
	for i in count:
		elapsed+=jump_frames.durationsMs[i]
		if jump_time*jump_frames.durationMs<elapsed:
			index=i
			break
	var mirror := facing in ["sw","nw","w"]
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if mirror else 1,1))
	var cell := Vector2(jump_frames.cell[0],jump_frames.cell[1])
	var pivot := Vector2(jump_frames.pivot[0],jump_frames.pivot[1])
	draw_texture_rect_region(jumping,Rect2(-pivot,cell),Rect2(Vector2(index,row)*cell,cell))
