extends RefCounted
## One projection for combat and teaching. Gameplay keeps its existing world limits.
static func origin(viewport:Vector2) -> Vector2:
	return Vector2(50,maxf(96,viewport.y*.13))
static func scale_for(viewport:Vector2) -> Vector2:
	return Vector2(maxf(.5,(viewport.x-100)/1000),maxf(.32,(viewport.y*.84-origin(viewport).y)/585))
