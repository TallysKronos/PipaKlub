extends SceneTree
const City=preload("res://scripts/campaign/neighborhood_view.gd")
const OUTPUT="res://../art/professor-laboratorio-v2/fachada/integracao/"
var play:Node2D
var checks:=0
var failures:Array[String]=[]
var steps:=0
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func set_actor(point:Vector2) -> void:
	play.cell=point
	play.surface=play.world.cell_id(floori(point.x),floori(point.y))
	play.elevation=play.world.surface_height(play.world.find_surface(play.surface),point,true)
	play.follower=point+Vector2(-.6,.6)
	play.follower_height=play.world.support(play.follower)
	play.follower_surface=play.world.cell_id(floori(play.follower.x),floori(play.follower.y))
	play.distance_walked=0
	play.trail.assign([{"p":play.follower,"h":play.follower_height,"surface":play.follower_surface,"distance":-.7},{"p":point,"h":play.elevation,"surface":play.surface,"distance":0.0}])
	play._refresh_visuals()
	play._update_hint()
func walk_to(point:Vector2,label:String) -> void:
	for tick in 700:
		var delta:Vector2=point-play.cell
		if delta.length()<.025:break
		var old:Vector2=play.cell
		play.walk(delta.limit_length(.025))
		steps+=1
		if play.cell.distance_to(old)<.00001:break
	check(play.cell.distance_to(point)<.04,label+" chegou a "+str(point)+" (parou em "+str(play.cell)+")")
	play._refresh_visuals()
func shot(name:String,point:Vector2,zoom:float=1.0) -> void:
	set_actor(point)
	play.camera.zoom=Vector2.ONE*zoom
	play.camera.position=play.world.iso(Vector2(7,-3),56)-Vector2(0,130)
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+name+".png")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	play=City.new()
	play.saved_player={"partners":[{"id":"review","modelId":"rabbito","name":"Rabbito","level":1,"line":100,"structure":100}],"equippedPartnerId":"review"}
	play.checkpoint_position=Vector2(7.25,-1)
	root.add_child(play)
	play.set_physics_process(false)
	play.set_process(false)
	play.camera.position_smoothing_enabled=false
	play.camera.zoom=Vector2.ONE
	play.camera.position=play.world.iso(Vector2(7,-3),56)-Vector2(0,130)
	check(play.avatar.scale==Vector2.ONE,"Kael em escala nativa")
	check(play.world.houses.any(func(h):return h.id=="professor" and h.door==Vector2(7.25,-1)),"entrada canônica nova")
	check(play.world.parts.filter(func(p):return p.get("surface")=="professor-v2").size()==26,"24 peças nativas em 26 faces integradas")
	for part in play.world.parts:
		if part.get("surface")=="professor-v2":check(part.node.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest preservado: "+str(part.professor_piece))
	set_actor(Vector2(7.25,-1))
	for p in [Vector2(6.75,-2.44),Vector2(7.03,-3.78),Vector2(6.75,-4.55)]:walk_to(p,"ida pela escada")
	check(play.elevation>=79,"pés chegam ao patamar elevado")
	play._update_hint()
	check(play.near_house.get("id")=="professor","porta física interativa")
	var action:={"id":""}
	play.action_requested.connect(func(id):action.id=id)
	play.interact()
	check(action.id=="professor-home","interação emite entrada no interior existente")
	for p in [Vector2(7.03,-3.78),Vector2(6.75,-2.44),Vector2(7.25,-1)]:walk_to(p,"volta pela escada")
	set_actor(Vector2(3.6,-2.1))
	for p in [Vector2(3.6,-2.6),Vector2(5.3,-3.65),Vector2(6.75,-3.82),Vector2(6.75,-4.55)]:walk_to(p,"ida pela rampa")
	for p in [Vector2(6.75,-3.82),Vector2(5.3,-3.65),Vector2(3.6,-2.6),Vector2(3.6,-2.1)]:walk_to(p,"volta pela rampa")
	set_actor(Vector2(7.25,-1))
	for p in [Vector2(2,-1),Vector2(7.25,-1),Vector2(13.8,-1)]:walk_to(p,"calçada livre")
	for p in [Vector2(3,-6),Vector2(7,-6),Vector2(11.6,-3.8)]:check(play._obstructed(p,""),"parede/equipamento sólido: "+str(p))
	set_actor(Vector2(6.75,-4.55))
	for p in [Vector2(7.5,-4.6),Vector2(9,-4.6),Vector2(9.8,-4.8),Vector2(11.6,-4.8)]:walk_to(p,"acesso ao pátio")
	await shot("depois",Vector2(7.25,-1))
	await shot("patamar",Vector2(6.75,-4.55))
	await shot("rampa",Vector2(4.45,-3.125))
	await shot("patio-atras-cabine",Vector2(11.6,-4.8))
	await shot("patio-frente-cabine",Vector2(12,-2.6))
	play.player_root.hide();play.partner_root.hide()
	play.hud_root.hide()
	play.camera.zoom=Vector2.ONE*1.5
	play.camera.position=play.world.iso(Vector2(7,-2.5),56)-Vector2(0,10)
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+"acessos-sem-personagens.png")
	var proof:={"checks":checks,"failures":failures,"movement_steps":steps,"actor_native_scale":1,"gameplay":"movimento real walk/resolve_step, interação por proximidade; sem sessão de save"}
	var f:=FileAccess.open(OUTPUT+"testes.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(proof,"\t"))
	print(JSON.stringify(proof))
	quit(0 if failures.is_empty() else 1)
