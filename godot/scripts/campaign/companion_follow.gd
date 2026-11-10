extends RefCounted
const RASTRO := "res://assets/campaign/rastro-dos-ventos-v1/overworld.png"
const Avatar = preload("res://scripts/kael_video_avatar.gd")

static func setup_overworld_art(sprite: Sprite2D, model_id: String, scale_factor := 1.0) -> bool:
	if model_id != "rastro-dos-ventos" or sprite == null: return false
	var texture := load(RASTRO) as Texture2D
	if texture == null: return false
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)
	sprite.offset = Vector2(0, -28)
	sprite.scale = Vector2.ONE * scale_factor
	return true

static func update_overworld_art(sprite: Sprite2D, movement: Vector2, clock: float) -> bool:
	if sprite.texture == null or sprite.texture.resource_path != RASTRO: return false
	var frame := floori(clock * 2.0) % 2
	if movement.length_squared() > .01:
		var travel := fposmod(float(sprite.get_meta("stride", 0.0)) + movement.length(), 24.0)
		sprite.set_meta("stride", travel)
		frame = 2 + floori(travel / 12.0)
		orient(sprite, Avatar.facing_for(movement, str(sprite.get_meta("facing", "se"))))
	sprite.region_rect.position.x = frame * 64
	return true

## Consume accepted footsteps, including multiple short steps in one tick.
static func advance(point:Vector2,trail:Array[Vector2],delta:float,speed:float,gap:float,safe:Callable) -> Vector2:
	var remaining:=0.0
	var previous:=point
	for step in trail:
		remaining+=previous.distance_to(step)
		previous=step
	var budget:=minf(maxf(0,delta)*speed,maxf(0,remaining-gap))
	while budget>.00001 and not trail.is_empty():
		var next:=point.move_toward(trail[0],budget)
		if not safe.call(point,next):break
		budget-=point.distance_to(next)
		point=next
		if point.distance_to(trail[0])<.00001:trail.remove_at(0)
		else:break
	return point

static func orient(sprite:Sprite2D,facing:String) -> void:
	# Current creature sheets have a right-facing view. Keep vertical movement's
	# last horizontal heading rather than rotate the entire creature or its pivot.
	if facing in ["sw","w","nw"]:sprite.flip_h=true
	elif facing in ["se","e","ne"]:sprite.flip_h=false
	sprite.set_meta("facing",facing)
