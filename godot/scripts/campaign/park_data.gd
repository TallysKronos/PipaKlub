extends RefCounted
## Positions belong to the approved illustrated plate, not the old JS map grid.
const ENTRY := Vector2(224, 810)
const NINA := Vector2(816, 480)
const BOSS := Vector2(1300, 154)
const TAIL := Vector2(1260, 195)
const GRASS := [Rect2(110, 397, 175, 65), Rect2(640, 112, 145, 45), Rect2(1100, 553, 185, 52)]

static func in_grass(point: Vector2) -> bool:
	for area in GRASS:
		if area.has_point(point): return true
	return false
const CHESTS := {
	"lookout": {"point": Vector2(300, 115), "item": "rabiola-azulao", "amount": 1},
	"woodland": {"point": Vector2(440, 730), "item": "coins", "amount": 25},
	"canal": {"point": Vector2(1040, 775), "item": "rabiola-mata", "amount": 1},
	"ridge": {"point": Vector2(810, 206), "item": "rabiola-raio", "amount": 1},
	"courtyard": {"point": Vector2(1220, 180), "item": "coins", "amount": 60}}

static func objective(player: Dictionary) -> String:
	if player.flags.get("ninaReturned", false): return ""
	if player.flags.get("ninaTail", false): return "Devolva a rabiola para Nina."
	if not player.flags.get("ninaAccepted", false): return ""
	return "Recolha a rabiola no pátio." if player.flags.get("guardianDefeated", false) else "Recupere a rabiola do Carcará de Nina."
