extends SceneTree
var scene: Node2D
var output := "res://../documentation/overworld/bairro-inicial-v2"
func _initialize() -> void:call_deferred("start")
func capture(id: String) -> void:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func start() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	scene=load("res://scenes/overworld/neighborhood/bairro-inicial.tscn").instantiate()
	if not scene.has_method("support"):quit(1);return
	root.add_child(scene)
	scene.scale=Vector2.ONE*.47
	scene.position=Vector2(640,345)-scene.iso(Vector2(16,10),24)*.47
	await capture("bairro-geral-1280x720")
	for shot in [["casa-kael",Vector2(5,15),8],["professor",Vector2(5,-2),56],["lojinha",Vector2(26,-2),56],["ladeira",Vector2(15,9),24],["pracinha",Vector2(24,17),8],["escadaria",Vector2(9,8.5),32]]:
		scene.scale=Vector2.ONE*1.25
		scene.position=Vector2(640,425)-scene.iso(shot[1],shot[2])*1.25
		await capture(shot[0]+"-1280x720")
	for shot in [["rampa-baixa",Vector2(10,20.7),4],["rampa-alta",Vector2(10,.5),52],["escadaria-encaixes",Vector2(9,8.5),32],["escadaria-chegada-baixa",Vector2(9.8,11.5),8],["escadaria-chegada-alta",Vector2(9,6.9),56]]:
		scene.scale=Vector2.ONE*2.6
		scene.position=Vector2(640,400)-scene.iso(shot[1],shot[2])*2.6
		await capture(shot[0]+"-1280x720")
	for shot in [["base-canto-frontal",Vector2(31.5,27.5)],["base-ponto-onibus",Vector2(5.5,27.5)],["base-rua-alta",Vector2(31.7,1.5)]]:
		scene.scale=Vector2.ONE*1.8
		scene.position=Vector2(640,390)-scene.iso(shot[1],0)*1.8
		await capture(shot[0]+"-1280x720")
	# Native alignment evidence: two parallel ground edges, without a sprite
	# covering the foundation. The measured source wall edge maps onto cyan.
	scene.scale=Vector2.ONE*1.55
	scene.position=Vector2(640,430)-scene.iso(Vector2(5,16),8)*1.55
	var house: Dictionary=scene.houses[0]
	var bounds: Array=house.bounds
	var guides: Array[Node]=[]
	for row in [[Vector2(bounds[0]-.4,bounds[3]),Vector2(bounds[2]+2,bounds[3]),Color("47DCE0")],[Vector2(bounds[0]-.4,19),Vector2(bounds[2]+2,19),Color("F6CE64")]]:
		var guide:=Line2D.new()
		guide.points=PackedVector2Array([scene.iso(row[0],8),scene.iso(row[1],8)])
		guide.width=1.5;guide.default_color=row[2];guide.z_index=20
		scene.add_child(guide);guides.append(guide)
	await capture("casa-kael-alinhamento-1280x720")
	for guide in guides:guide.free()
	var plan := {"roads":scene.road_names,"surfaces":scene.surfaces.size(),"houses":scene.houses,"people":scene.people,"depth":scene.ordering_review,"campaignIntegrated":false}
	FileAccess.open(output.path_join("layout.json"),FileAccess.WRITE).store_string(JSON.stringify(plan,"  "))
	root.remove_child(scene)
	var geometry: Node2D=load("res://scenes/overworld/neighborhood/bairro-inicial.tscn").instantiate()
	geometry.geometry_only=true
	geometry.position=Vector2(640,345)-geometry.iso(Vector2(16,10),24)*.47
	geometry.scale=Vector2.ONE*.47
	root.add_child(geometry)
	await capture("geometria-1280x720")
	scene.free()
	print("Neighborhood native art captured.")
	quit()
