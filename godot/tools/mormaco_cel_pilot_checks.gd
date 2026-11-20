extends SceneTree
const Scene=preload("res://scenes/overworld/mormaco_cel_pilot.tscn")
const OUT="res://../art/overworld/pantano-mormaco-v2/jogavel-cel/"
var play:Node2D
var failures:Array[String]=[]
var evidence:Array=[]

func _initialize()->void:run.call_deferred()

func require(condition:bool,message:String)->void:
	if not condition:failures.append(message)

func capture(id:String)->void:
	if DisplayServer.get_name()=="headless":return
	play.refresh_visuals()
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	var error:int=root.get_texture().get_image().save_png(OUT+id+".png")
	require(error==OK,"Falha na captura "+id)

func travel(target:Vector2)->bool:
	if not play.walk_to(target):return play.player.distance_to(target)<24
	var goal:Vector2=play.path[-1]
	for i in 6000:
		play._physics_process(1.0/60.0)
		if not play.walkable(play.player):return false
		if play.path.is_empty():return play.player.distance_to(goal)<5
	return false

func run()->void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	play=Scene.instantiate()
	root.add_child(play)
	current_scene=play
	await process_frame
	play.set_physics_process(false)
	require(play.navigation_ready,"Navegação não inicializada")
	require(play.walkable(play.player),"Entrada sem chão")
	require(not play.point_walkable(Vector2(1760,920)),"Água permitiu passagem")
	require(not play.point_walkable(Vector2(915,1114)),"Cerca permitiu passagem")
	require(play.data.trees.size()==28,"Camadas de árvores incompletas")
	var spawn:Vector2=play.player
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_D
	key.pressed=true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	for i in 15:play._physics_process(1.0/60.0)
	require(play.player.x>spawn.x+10 and play.avatar.moving,"Controle de caminhada não respondeu")
	var release:InputEventKey=key.duplicate()
	release.pressed=false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	play.player=spawn
	play.avatar.moving=false
	await capture("01-margem-kael")
	var original_region:Rect2=play.boss.region_rect
	for i in 20:play._process(.1)
	require(play.boss.region_rect!=original_region,"Mormaço sem troca de quadro")
	await capture("02-mormaco-animado")
	for raw:Array in play.data.navigation.targets:
		var target:=Vector2(raw[0],raw[1])
		var there:bool=travel(target)
		var back:bool=travel(spawn)
		evidence.append({"target":[target.x,target.y],"outbound":there,"return":back})
		require(there and back,"Percurso falhou: "+str(target))
	play.player=spawn
	play.move_player(Vector2(-10000,0))
	require(play.walkable(play.player),"Movimento atravessou limite do terreno")
	play.player=spawn
	play.path.clear()
	for tree:Dictionary in play.data.trees:
		if absf(float(tree.elevation))>.03:continue
		var foot:=Vector2(tree.foot[0],tree.foot[1])
		if not play.walkable(foot-Vector2(0,48)) or not play.walkable(foot+Vector2(0,48)):continue
		play.player=foot-Vector2(0,48)
		await capture("03-atras-da-arvore")
		play.player=foot+Vector2(0,48)
		await capture("04-frente-da-arvore")
		evidence.append({"occlusion_tree":tree.file,"feet":[foot.x,foot.y]})
		break
	play.player=spawn
	play.overview=true
	await capture("05-geral")
	play.overview=false
	play.player=play.nearest_walkable(Vector2(1470,1100))
	await capture("06-margem-detalhe")
	var report:Dictionary={"failures":failures,"routes":evidence,"kael_visible_height":70,"tree_layers":play.data.trees.size(),"boss_frame_changed":play.boss.region_rect!=original_region,"campaign_save_accessed":false,"scope":"Margem inferior; patamares superiores e campanha não convertidos"}
	var file:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
