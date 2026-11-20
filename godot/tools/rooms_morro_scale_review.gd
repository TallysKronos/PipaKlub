extends SceneTree
const Pixels = preload("res://scripts/npc_pixel_sprite.gd")
const Avatar = preload("res://scripts/kael_video_avatar.gd")
const Room = preload("res://scripts/campaign/room_view.gd")
const View = preload("res://scripts/campaign/park_overworld_view.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const OUTPUT := "res://../documentation/qa/rooms-morro-scale/"
var report: Array[Dictionary] = []
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func inspect(sprite: Sprite2D, avatar: Node2D, label: String, moving: bool = false) -> void:
	var image: Image = avatar.resting.get_image()
	var kael_height := image.get_region(Rect2i(0,7*96,64,96)).get_used_rect().size.y * avatar.scale.y
	var id: String = sprite.get_meta("pixel_npc","")
	var heights := []
	var feet := []
	var expected: float = Pixels.RELATIVE_HEIGHTS.get(id,1.0)
	for facing in Pixels.DIRECTIONS:
		Pixels.face(sprite,facing)
		var times := [0.0,.16,.29,.43] if moving else [0.0]
		for time in times:
			Pixels.animate_walk(sprite,moving,time)
			var pixels: Image = sprite.texture.get_image().get_region(Rect2i(sprite.region_rect))
			var bounds := pixels.get_used_rect()
			var height: float = bounds.size.y * sprite.scale.y
			var foot: float = (bounds.end.y - sprite.region_rect.size.y/2 + sprite.offset.y) * sprite.scale.y
			heights.append(height)
			feet.append(foot)
			if height/kael_height < expected*.92 or height/kael_height > expected*1.08:
				failures += 1
				printerr("SCALE ",label," ",facing," ",time," ",height/kael_height)
	if float(feet.max())-float(feet.min()) > 2.0:
		failures += 1
		printerr("FOOT DRIFT ",label," ",feet)
	report.append({"actor":label,"moving":moving,"samples":heights.size(),"kaelHeight":kael_height,"minHeight":heights.min(),"maxHeight":heights.max(),"expectedRatio":expected,"footRange":[feet.min(),feet.max()]})
	Pixels.animate_walk(sprite,false,0)
	Pixels.face(sprite,"se")
func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT+name+".png"))
func run() -> void:
	root.size=Vector2i(1280,720)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	for id in ["home","professor"]:
		var room:=Room.new()
		root.add_child(room)
		room.configure(content.rooms[id],[900,800],true,"*",true,false)
		room.set_process(false)
		room.avatar.set_process(false)
		inspect(room.mother_sprite,room.avatar,id)
		if id=="home":inspect(room.mother_sprite,room.avatar,"mother-walk",true)
		var near: Vector2=room.mother_point+Vector2(90,40)
		if room._safe(near):room.actor=near
		room._update_order()
		await shot(id)
		if id=="home":
			room.mother_walking=true
			room.clock=.29
			room.opening_pose()
			await shot("mother-walk")
		room.free()
	var player:Dictionary=State.fresh("slot-1").player
	player.journey={"lesson":5,"phase":"complete"}
	var district:Dictionary=Rules.definition("morro")
	var entry:Dictionary=Rules.entry(player,"morro")
	entry.qualification=district.stages.slice(0,4).map(func(stage):return stage.id)
	Rules.store(player,"morro",entry)
	for stage:Dictionary in district.stages:
		var view:=View.new()
		var event:Dictionary={}
		for candidate:Dictionary in CP.data(stage.scene).events:
			if candidate.props.get("duel","")==stage.id:event=candidate;break
		var point:=Vector2(event.u+.5,event.v+.5)
		view.saved_player=player.duplicate(true)
		view.saved_checkpoint=CP.make(stage.scene,CP.safe(stage.scene,point+Vector2(1,1)),CP.SPACE)
		view.content=content
		view.reduced_motion=true
		root.add_child(view)
		view.set_physics_process(false)
		view.avatar.set_process(false)
		for actor:Dictionary in view.npc_nodes:
			if actor.root.get_meta("event",{}).get("props",{}).get("duel","")!=stage.id:continue
			for child in actor.visual.get_children():
				if child is Sprite2D and child.has_meta("pixel_npc"):
					inspect(child,view.avatar,stage.id+"-"+str(child.get_meta("pixel_npc")))
					var original := view.player
					view.nearby = actor.root.get_meta("event", {})
					for i in Pixels.DIRECTIONS.size():
						var offset := [Vector2(1,1),Vector2(0,1),Vector2(-1,1),Vector2(-1,0),Vector2(-1,-1),Vector2(0,-1),Vector2(1,-1),Vector2(1,0)]
						view.player = actor.point + offset[i]
						view.interact()
						if child.get_meta("pixel_facing") != Pixels.DIRECTIONS[i]:
							failures += 1
							printerr("DIRECTION ",stage.id," ",i)
					view.player = original
					Pixels.face(child,"se")
		view.player=CP.safe(stage.scene,point+Vector2(1.5,0))
		view.follower=view.player+Vector2(-.5,.5)
		view._refresh_positions()
		view.exploration_hud.objective.text=""
		view.exploration_hud.objective_panel.hide()
		view.camera.position_smoothing_enabled=false
		view.camera.position=view.model.project(point)-Vector2(0,35)
		view.camera.reset_smoothing()
		await shot(stage.id)
		view.free()
	if report.size()!=9:
		failures += 1
		printerr("Expected mother, professor, maternal walking and six rivals")
	FileAccess.open(OUTPUT+"measurements.json",FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"actors":report},"  "))
	print("ROOMS/MORRO SCALE: ",report.size()," sequences; ",failures," failures")
	quit(int(failures>0))
