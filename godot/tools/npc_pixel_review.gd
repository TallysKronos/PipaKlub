extends SceneTree
## Real campaign views; injected workspace test profile, no production save writes.
const Front = preload("res://scripts/campaign/front_end.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Pixels = preload("res://scripts/npc_pixel_sprite.gd")
var front: Control
var checks:=0
var failures: Array[String]=[]
var output: String
var seen: Dictionary={}
var kael_scale:=0.0
func _initialize() -> void:call_deferred("review")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func inspect(node: Node) -> void:
	if node is Sprite2D and node.has_meta("pixel_npc"):
		var id: String=node.get_meta("pixel_npc")
		seen[id]=true
		check(node.texture.resource_path=="res://assets/npc-ds/"+id+".png",id+": runtime texture")
		check(node.region_rect.size==Vector2(64,96),id+": single cell")
		check(node.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,id+": nearest")
		check(node.offset==Vector2(0,-46),id+": foot pivot")
		var actual_height: float=node.texture.get_image().get_region(Rect2i(node.region_rect)).get_used_rect().size.y*node.scale.y
		var expected: float=Pixels.height_for(id,kael_scale)
		check(absf(actual_height-expected)<expected*.035,id+": opaque body height matches Kael proportion")
	for child in node.get_children():inspect(child)
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func review() -> void:
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../documentation/pixelgen/npc-in-game-v1")
	DirAccess.make_dir_recursive_absolute(output)
	front=Front.new()
	var fixture=ProjectSettings.globalize_path("res://../tmp/npc-runtime-fixture")
	front.session._store=load("res://scripts/campaign/save_store.gd").new(fixture)
	front.preferences.storage_path=fixture.path_join("settings.cfg")
	root.add_child(front);front.preferences.reduced_motion=true
	for scene in ["opening-5","opening-11","professor","street","park","morro","morro-area-2","morro-area-3","morro-area-4","morro-area-5"]:
		Fixtures.show(front,scene)
		for i in 5:await process_frame
		var attempts:=0
		while (front.flow_busy or front.opening_busy or is_instance_valid(front.scene_loading)) and attempts<1200:
			await create_timer(.02).timeout;attempts+=1
		check(not front.flow_busy and not front.opening_busy and not is_instance_valid(front.scene_loading),scene+": scene ready")
		var active: Node2D=front.room if is_instance_valid(front.room) else front.park
		kael_scale=active.avatar.scale.y
		inspect(front)
		if scene=="morro-area-3":
			active.player=active.npc_sprites[0].position+Vector2(120,0)
			active.follower=active.player+Vector2(30,20)
			active.avatar.position=active.player
			active.avatar.facing="se"
		if is_instance_valid(front.room) and is_instance_valid(front.room.mother_sprite):
			var room: Node2D=front.room
			if scene=="opening-5":
				check(room.mother_reveal>.99 and room.mother_sprite.visible,"mother arrived through stairs")
				for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					room.face_mother(room.mother_point+direction*100);room.opening_pose()
					check(Rect2(0,0,256,192).encloses(room.mother_sprite.region_rect),"mother direction stays in atlas")
				room.face_mother(room.actor);room.opening_pose()
			if scene=="opening-11":check(not room.mother_sprite.visible,"mother leaves through stairs")
		if scene=="street":
			var world: Node2D=front.park.world
			for person in world.people:
				check(person.image.begins_with("res://assets/npc-ds/"),"city identity "+person.id)
				if person.id=="lia":check(person.image.ends_with("/lia.png"),"shopkeeper uses Lia instead of Bia")
		for i in 3:await process_frame
		# Veredas has an independent stabilized capture in npc_park_review.gd.
		if scene!="park":await capture(scene)
	for id in Pixels.HEIGHTS:check(seen.has(id),"observed NPC "+id)
	FileAccess.open(output.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"seen":seen,"usesProductionSave":false},"  "))
	print("NPC pixel integration: checks=",checks," failures=",failures.size())
	front.session.close_session();front.free();quit(0 if failures.is_empty() else 1)
