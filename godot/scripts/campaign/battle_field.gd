extends RefCounted
## One projection for combat and teaching. Gameplay keeps its existing world limits.
const Layout = preload("res://scripts/campaign/hud_layout.gd")
## The action bar takes 12% of the height and sits on the safe rectangle's bottom edge.
const ACTION_BAR := .12
## Room between the lowest string anchor and the top of the action bar.
const BAR_CLEARANCE := 16.0

static func origin(viewport:Vector2) -> Vector2:
	return Vector2(50,maxf(96,viewport.y*.13))

## Lowest field row (world y 585): 84% of the height, raised when the action bar on
## the safe margin would otherwise cover the string anchors.
static func floor_y(viewport:Vector2) -> float:
	var bar_top := Layout.safe_rect(viewport).end.y - viewport.y * ACTION_BAR
	return minf(viewport.y * .84, bar_top - BAR_CLEARANCE)

static func scale_for(viewport:Vector2) -> Vector2:
	return Vector2(maxf(.5,(viewport.x-100)/1000),maxf(.32,(floor_y(viewport)-origin(viewport).y)/585))
