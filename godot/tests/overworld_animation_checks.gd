extends SceneTree
const Follow = preload("res://scripts/campaign/companion_follow.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ",label)

func _initialize() -> void:
	var sprite := Sprite2D.new()
	check(Follow.setup_overworld_art(sprite,"azulfazo",Follow.Avatar.OVERWORLD_SCALE),"equip pilot")
	Follow.animate(sprite,.4,0)
	check(sprite.get_meta("animation_state")=="idle","stationary breath")
	check(sprite.region_rect.position.x==112,"nonuniform idle timing")
	Follow.animate(sprite,.01,.5)
	check(sprite.get_meta("animation_state")=="walk","actual follower displacement selects walk")
	check(sprite.region_rect.position.x==224,"quarter stride selects frame2")
	var frame := sprite.region_rect.position.x
	Follow.animate(sprite,.5,2.0)
	check(sprite.region_rect.position.x==frame,"full distance cycle returns same pose independent of delta")
	for facing in ["sw","w","nw","n","ne","e","se","s"]:
		Follow.orient(sprite,facing)
		var rear: bool = facing in ["nw","n","ne"]
		check(sprite.region_rect.position.y==(112 if rear else 0),"direction row " + facing)
		check(sprite.offset==Vector2(0,-44) and sprite.scale==Vector2.ONE,"anchor/scale " + facing)
		var cell := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
		var bounds := Rect2(cell.get_used_rect())
		if sprite.flip_h: bounds.position.x=112-bounds.end.x
		bounds.position+=Vector2(-56,-100)
		check(Follow.visible_bounds(sprite)==bounds,"occlusion follows current animated pose " + facing)
	Follow.animate(sprite,.02,0)
	check(sprite.get_meta("animation_state")=="idle" and sprite.region_rect.position.x==0,"stop returns to rest without phase carry")
	Follow.setup_overworld_art(sprite,"papisco",Follow.Avatar.OVERWORLD_SCALE)
	check(sprite.get_meta("animation_state")=="" and not sprite.has_meta("animated_bounds"),"equipment clears old pose and phase")
	Follow.animate(sprite,1,.5)
	check(sprite.get_meta("animation_state")=="walk","new equipment starts own locomotion")
	check(sprite.texture.resource_path==Follow.animation_manifest.papisco.walk,"new model uses own animation")
	check(Follow.overworld_portrait("azulfazo").atlas.resource_path==Follow.PILOT_SHEET,"portrait stays static")
	check(Follow.animation_manifest.size()==Follow.reviewed_sheets.size(),"all reviewed models have idle/walk")
	for id: String in Follow.reviewed_sheets:
		Follow.setup_overworld_art(sprite,id,Follow.Avatar.OVERWORLD_SCALE)
		for state in ["idle","walk"]:
			Follow.animate(sprite,.01,0 if state=="idle" else .1)
			check(sprite.texture.resource_path==Follow.animation_manifest[id][state],"state texture " + id + state)
			check(sprite.texture.get_size()==Vector2(896,224),"atlas contract " + id + state)
			for facing in ["sw","nw","ne","se"]:
				Follow.orient(sprite,facing)
				check(sprite.region_rect.position.y==(112 if facing in ["nw","ne"] else 0),"two view playback " + id + state + facing)
				check(sprite.offset==Vector2(0,-44) and sprite.scale==Vector2.ONE,"native anchor " + id + state + facing)
	sprite.free()
	print("OVERWORLD ANIMATION ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
