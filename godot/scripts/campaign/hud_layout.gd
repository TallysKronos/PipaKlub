extends RefCounted
## One layout contract for every HUD screen (Switch and Steam first).
##
## The project renders at a 1280x720 base (stretch canvas_items, aspect expand), so all
## values here are base units, not physical pixels. Switch handheld shows that base 1:1
## on a 6.2-7" screen; docked and PC 1080p scale it 1.5x; Steam Deck adds 80 units of
## height (16:10); ultrawide adds width.
##
## Rules (art/ui/hud-recorte-v1/ESPECIFICACAO.md, sections 1-2):
## - Persona structure: corner plates on one shared safe rectangle, 12 degree cuts,
##   titles may break out of their plate, focus by inversion.
## - Everything snaps to a 4-unit grid; gaps come from SPACE, text sizes from TYPE.
## - Handheld legibility: no functional text below 15 units (about 2.4 mm on a Switch
##   Lite), body text 18+, numbers 18+.
## - Ultrawide keeps the HUD inside a centred 16:9 column so corner plates stay in the
##   player's field of view.

const BASE := Vector2(1280, 720)
## Title-safe margins. Handheld (Switch portable, Steam Deck) needs only bezel room;
## TV (Switch docked, PC on a television) keeps 5% horizontal overscan room.
const MARGIN_HANDHELD := Vector2(36, 28)
const MARGIN_TV := Vector2(56, 36)
const SPACE := {"xs": 4, "s": 8, "m": 12, "l": 16, "xl": 24, "xxl": 32}
const TYPE := {"display": 34, "title": 26, "heading": 22, "label": 20, "body": 18, "small": 16, "micro": 15}
const MAX_HUD_ASPECT := 16.0 / 9.0

## "auto" picks handheld for screens of 800 lines or fewer (Switch 720p, Steam Deck 800p)
## and TV otherwise. Tests and the settings screen can pin it.
static var profile_override := "auto"

static func profile() -> String:
	if profile_override in ["handheld", "tv"]: return profile_override
	if DisplayServer.get_name() == "headless": return "handheld"
	var screen := DisplayServer.screen_get_size()
	return "handheld" if screen.y <= 800 else "tv"

static func margin() -> Vector2:
	return MARGIN_HANDHELD if profile() == "handheld" else MARGIN_TV

## The rectangle every HUD corner aligns to. On ultrawide it is a centred 16:9 column.
static func safe_rect(extent: Vector2) -> Rect2:
	var width := extent.x
	if extent.x / maxf(extent.y, 1.0) > MAX_HUD_ASPECT + .01: width = extent.y * MAX_HUD_ASPECT
	var left := (extent.x - width) / 2.0
	var edge := margin()
	return Rect2(Vector2(left, 0) + edge, Vector2(width, extent.y) - edge * 2)

static func space(name: String) -> float:
	return float(SPACE.get(name, 12))

## Text size for a role; handheld adds 2 so body text never falls under 20 on Switch
## portable, where the base is shown 1:1.
static func type(role: String) -> int:
	var value: int = TYPE.get(role, 18)
	return value + (2 if profile() == "handheld" and value < 26 else 0)

static func snap(value: float) -> float:
	return roundf(value / 4.0) * 4.0

static func snap_v(value: Vector2) -> Vector2:
	return Vector2(snap(value.x), snap(value.y))
