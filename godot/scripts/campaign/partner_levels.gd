extends RefCounted
## One authoritative curve for stats, collection, rewards and save migration.
const MAX_LEVEL := 50

static func xp_for_level(level: int) -> int:
	var n:=clampi(level,1,MAX_LEVEL)-1
	# Next-level cost at Lv.L: 20 + 15L + 5L². Sum the costs, never round per frame.
	return int(20*n+15*n*(n+1)/2+5*n*(n+1)*(2*n+1)/6)

## Story and championship wins (BIBLIA §8: Kael's curve follows the rivals', 8 → 50).
## A win pays a share of what the rival's level costs to climb, more when Kael is
## behind and less when ahead, so the curve corrects itself: walked with real duels,
## Kael stays about 0 to +3 levels from each rival (tools/duel_balance.gd).
const WIN_SHARE := {"lieutenant": .45, "champion": .9, "story": .6}
static func win_xp(foe_level: int, partner_level: int, role: String) -> int:
	var foe:=clampi(foe_level,1,MAX_LEVEL)
	var cost:=xp_for_level(mini(foe+1,MAX_LEVEL))-xp_for_level(foe)
	if foe>=MAX_LEVEL: cost=xp_for_level(MAX_LEVEL)-xp_for_level(MAX_LEVEL-1)
	var scale:=clampf(1.0-.2*(partner_level-foe),.2,1.5)
	return roundi(cost*float(WIN_SHARE.get(role,.6))*scale)

static func level_for_xp(xp: float) -> int:
	var level:=1
	while level<MAX_LEVEL and xp>=xp_for_level(level+1): level+=1
	return level

static func from_legacy(xp: int) -> int:
	var level:=1
	while level<MAX_LEVEL and xp>=40*level+10*level*level: level+=1
	if level==MAX_LEVEL: return xp_for_level(MAX_LEVEL)
	var n:=level-1
	var before:=40*n+10*n*n
	var next:=40*level+10*level*level
	var fraction:=clampf(float(xp-before)/(next-before),0,1)
	return xp_for_level(level)+floori(fraction*(xp_for_level(level+1)-xp_for_level(level)))
