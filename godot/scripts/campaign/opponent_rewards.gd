extends RefCounted
## Creature XP depends only on defeated species/level, never on its owner.
const SPECIES_XP := {"rascunho-bicho-pau":Vector2i(14,4),"rascunho-joaninha":Vector2i(18,5),"basica":Vector2i(10,3),"mata":Vector2i(14,4),"raio":Vector2i(18,5),"lacertubo":Vector2i(80,20)}
static func xp(species:String,level:int) -> int:
	var values:Vector2i=SPECIES_XP.get(species,Vector2i(10,3))
	return values.x+(clampi(level,1,50)-1)*values.y
static func trainer_bonus(level:int) -> Dictionary:
	var rank:=clampi(level,1,50)
	return {"coins":10+5*rank,"tamerXp":5+3*rank}
