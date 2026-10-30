extends RefCounted
## One authoritative curve for stats, collection, rewards and save migration.
const MAX_LEVEL := 50

static func xp_for_level(level: int) -> int:
	var n:=clampi(level,1,MAX_LEVEL)-1
	# Next-level cost at Lv.L: 20 + 15L + 5L². Sum the costs, never round per frame.
	return int(20*n+15*n*(n+1)/2+5*n*(n+1)*(2*n+1)/6)

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
