extends SceneTree
const Lab=preload("res://scripts/campaign/professor_interior_v2.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const OUT="res://../art/professor-laboratorio-v2/interior/integracao/"
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var folder:=ProjectSettings.globalize_path("res://.godot/professor-v2-capture-"+State.new_id())
	var front:Control=load("res://scripts/campaign/front_end.gd").new()
	front.session._store=Store.new(folder)
	front.preferences.storage_path=folder+"/preferences.cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	if front.session.start("slot-3").status!="ok":quit(1);return
	var player:Dictionary=front.session.snapshot().player
	player.partners=[{"id":"review","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="review"
	player.journey={"lesson":5,"phase":"complete"}
	player["starter"]={"completed":true}
	if front.session.checkpoint({"kind":"world","scene":"professor-home","position":[1104,1120]},player).status!="ok":quit(1);return
	front._show_saved()
	for i in range(1800):
		if is_instance_valid(front.room) and not front.flow_busy and not is_instance_valid(front.scene_loading):
			break
		await process_frame
	if not is_instance_valid(front.room) or front.room.get_meta("professor_art")!="interior-v2" or front.stage.scale!=Vector2.ONE:
		push_error("Ateliê não abriu em escala 1× pelo frontend")
		quit(1)
		return
	var room:Node2D=front.room
	room.can_walk=true
	for shot in [
		["depois",Vector2(1104,1120),Lab.point_at(5.80,2.40)],
		["atrás-da-bancada",Lab.point_at(8.44,6.17),Lab.point_at(7.72,6.33)],
		["bancada-de-criacao",Lab.WORKBENCH,Lab.point_at(9.50,1.78)],
		["estoque",Lab.point_at(11.42,6.36),Lab.point_at(11.55,5.16)],
	]:
		if not room._safe(shot[1]) or not room._safe(shot[2]):push_error("Ponto inválido: "+shot[0]);quit(1);return
		room.actor=shot[1]
		room.companion_point=shot[2]
		room.trail.assign([room.companion_point,room.actor])
		room.face_actor(Lab.WORKBENCH_FACE)
		room.companion.position=room.project(room.companion_point)
		room.opening_pose()
		for i in 3:await process_frame
		await RenderingServer.frame_post_draw
		var error:=root.get_texture().get_image().save_png(OUT+shot[0]+".png")
		if error!=OK:quit(error);return
	room.actor=Lab.WORKBENCH
	room.opening_pose()
	await process_frame
	room._process(0.0)
	if room.near!="workbench":push_error("Bancada sem ação de proximidade: "+str([room.near,room.actor,room.story_paused,room.data.hotspots]));quit(1);return
	var interact:=InputEventKey.new()
	interact.physical_keycode=KEY_E
	interact.pressed=true
	room._unhandled_input(interact)
	for i in 16:await process_frame
	if not front.find_children("*","Label",true,false).any(func(node):return node.text=="SUAS RABIOLAS"):
		push_error("E na bancada não abriu a oficina")
		quit(1)
		return
	front.session.close_session()
	front.free()
	print("ATELIÊ V2: 4 capturas do frontend, escala 1×")
	quit()
