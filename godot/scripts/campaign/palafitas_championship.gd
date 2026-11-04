extends RefCounted
## Additive campaign events; reviewed map geometry remains untouched.
const Rules=preload("res://scripts/campaign/district_rules.gd")
static func events(scene:String)->Array:
	var out:Array=[]
	for stage:Dictionary in Rules.definition("palafitas").stages:
		if stage.get("scene","")!=scene:continue
		out.append({"id":19800+int(stage.id.right(1)),"type":"npc","name":stage.name,"u":stage.point[0],"v":stage.point[1],"props":{"acao":"districtDuel","district":"palafitas","duel":stage.id,"storySpritePath":stage.storySpritePath}})
	return out
