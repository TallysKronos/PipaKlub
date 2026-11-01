extends RefCounted
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
