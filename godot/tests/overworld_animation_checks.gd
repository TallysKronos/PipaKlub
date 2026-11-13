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
	check(Follow.setup_overworld_art(sprite,"farpim",Follow.Avatar.OVERWORLD_SCALE),"equip timing fixture")
	var idle_durations: Array = Follow.animation_manifest.farpim.get("idle_durations",[.32,.14,.22,.32,.14,.22,.20,.24])
	var fixture_walk_count: int = Follow.animation_manifest.farpim.get("frame_counts",{}).get("walk",8)
	Follow.animate(sprite,float(idle_durations[0])+.001,0)
	check(sprite.get_meta("animation_state")=="idle","stationary breath")
	check(sprite.region_rect.position.x==112,"nonuniform idle timing")
	Follow.animate(sprite,.01,.5)
	check(sprite.get_meta("animation_state")=="walk","actual follower displacement selects walk")
	check(sprite.region_rect.position.x==int(fixture_walk_count*.25)*112,"quarter stride selects corresponding pose")
	var frame := sprite.region_rect.position.x
	Follow.animate(sprite,.5,2.0)
	check(sprite.region_rect.position.x==frame,"full distance cycle returns same pose independent of delta")
	for facing in ["sw","w","nw","n","ne","e","se","s"]:
		Follow.orient(sprite,facing)
		var rear: bool = facing in ["nw","n","ne"]
		check(sprite.region_rect.position.y==(112 if rear else 0),"direction row " + facing)
		check(sprite.offset==Vector2(0,-44) and is_equal_approx(sprite.scale.y,Follow.Avatar.OVERWORLD_SCALE),"anchor/scale " + facing)
		var cell := sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
		var bounds := Rect2(cell.get_used_rect())
		if sprite.flip_h: bounds.position.x=112-bounds.end.x
		bounds.position+=Vector2(-56,-100)
		bounds=Rect2(bounds.position*sprite.scale,bounds.size*sprite.scale)
		check(Follow.visible_bounds(sprite).is_equal_approx(bounds),"occlusion follows current animated pose " + facing)
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
			var count: int = Follow.animation_manifest[id].get("frame_counts",{}).get(state,8)
			check(sprite.texture.get_size()==Vector2(count*112,224),"atlas contract " + id + state)
			for facing in ["sw","nw","ne","se"]:
				Follow.orient(sprite,facing)
				check(sprite.region_rect.position.y==(112 if facing in ["nw","ne"] else 0),"two view playback " + id + state + facing)
				check(sprite.offset==Vector2(0,-44) and is_equal_approx(sprite.scale.y,Follow.Avatar.OVERWORLD_SCALE),"native anchor " + id + state + facing)
		if Follow.animation_manifest[id].get("art_version", "").begins_with("hybrid-") or Follow.animation_manifest[id].get("art_version", "").begins_with("sheet-"):
			var durations: Array = Follow.animation_manifest[id].idle_durations
			var idle_count: int = Follow.animation_manifest[id].frame_counts.idle
			check(durations.size()==idle_count,"hybrid durations match poses " + id)
			Follow.setup_overworld_art(sprite,id,Follow.Avatar.OVERWORLD_SCALE)
			Follow.animate(sprite,0,0)
			for pose in idle_count:
				check(sprite.region_rect.position.x==pose*112,"hybrid idle timing " + id + str(pose))
				Follow.animate(sprite,float(durations[pose])+.000001,0)
			check(sprite.region_rect.position.x==0,"hybrid idle wraps " + id)
			var walk_count: int = Follow.animation_manifest[id].frame_counts.walk
			Follow.animate(sprite,.01,.0001)
			Follow.animate(sprite,.01,2.0-.0002)
			check(sprite.region_rect.position.x==(walk_count-1)*112,"hybrid complete walk cycle " + id)
			Follow.animate(sprite,.01,.0002)
			check(sprite.region_rect.position.x==0,"hybrid walk period " + id)
	Follow.setup_overworld_art(sprite,"viuva-young",Follow.Avatar.OVERWORLD_SCALE)
	Follow.animate(sprite,.399,0)
	check(sprite.region_rect.position.x==0,"hybrid idle holds400ms")
	Follow.animate(sprite,.002,0)
	check(sprite.region_rect.position.x==112,"hybrid idle next pose after400ms")
	Follow.animate(sprite,.15,0)
	check(sprite.region_rect.position.x==224,"hybrid idle uses short transition")
	Follow.animate(sprite,.001,1.99)
	check(sprite.region_rect.position.x==560,"hybrid last walk frame")
	Follow.animate(sprite,.001,.02)
	check(sprite.region_rect.position.x==0,"hybrid walk wraps without unused columns")
	Follow.orient(sprite,"nw")
	check(sprite.region_rect.position.y==112,"hybrid back keeps current phase")
	sprite.free()
	print("OVERWORLD ANIMATION ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
