extends SceneTree
const View=preload("res://scripts/campaign/park_overworld_view.gd")
const Battle=preload("res://scripts/campaign/encounter_view.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const QA=preload("res://scripts/campaign/qa_jump.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr(message)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,720)
	var content: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var fixture: Dictionary=QA.build("trovareta")
	var navalha: Vector2=preload("res://scripts/campaign/endgame_story.gd").point(fixture.checkpoint.scene,Vector2i(24,24))
	fixture.checkpoint.position=[navalha.x-1.5,navalha.y]
	var view:=View.new()
	view.saved_checkpoint=fixture.checkpoint
	view.saved_player=fixture.player
	view.content=content
	root.add_child(view)
	view.paused=true
	view.set_physics_process(false)
	var cast: Node2D=view.actors.get_node("StormCast")
	var mon: Sprite2D=cast.get_node("TrovaretaBound")
	check(mon.texture.resource_path.ends_with("trovareta-v1/soulgen-atlas.png"),"bound guardian uses her approved atlas")
	check(cast.has_node("CarretelLine"),"Navalha holds the black line")
	check(mon.offset.y!=0.0,"guardian has a measured anchor")
	var anchor: Vector2=mon.offset
	var first: Rect2=mon.region_rect
	mon._process(.6)
	check(mon.region_rect!=first,"idle advances through the Soulgen frames")
	check(mon.offset==anchor,"animation preserves the support anchor")
	mon.reduced_motion=true
	first=mon.region_rect
	mon._process(.8)
	check(mon.region_rect==first,"reduced motion holds the pose")
	view.exploration_hud.hide()
	if is_instance_valid(view.exploration_hud.map):view.exploration_hud.map.hide()
	view.camera.position_smoothing_enabled=false
	view.camera.position=(view.model.project(view.player)+mon.position)*.5+Vector2(0,-35)
	view.camera.zoom=Vector2.ONE
	await capture("bound")
	var free_player: Dictionary=fixture.player.duplicate(true)
	free_player.flags.trovaretaLivre=true
	view.refresh(free_player)
	await process_frame
	cast=view.actors.get_node("StormCast")
	check(cast.has_node("RatoWatching") and not cast.has_node("TrovaretaBound"),"release replaces the bound guardian with Rato's appearance")
	var rato: Sprite2D=cast.get_node("RatoWatching")
	check(absf(view.model.height_at(rato.get_meta("ground_point"))-view.model.height_at(navalha))<.25,"Rato stays on the visible street level")
	check(rato.position.distance_to(view.model.project(view.player))>=85,"Rato stays separate from Kael")
	check(not view.exploration_hud.get_parent().has_node("StoryRain"),"release clears the storm without needing a scene reload")
	for actor: Dictionary in view.npc_nodes:
		if actor.root.get_meta("event",{}).get("props",{}).get("step","")=="trovareta":check(not actor.root.visible,"Navalha does not remain after the completed duel")
	view.refresh(free_player)
	check(view.actors.get_node("StormCast")==cast,"refresh does not duplicate the cast")
	await capture("rato")
	free_player.flags.reuniaoCampeoes=true
	view.refresh(free_player)
	check(not view.actors.has_node("StormCast"),"meeting clears the earlier storm cast")
	view.queue_free()
	await process_frame
	var state:=Model.new(fixture.player.partners[0],{"modelId":"raio","level":31})
	state.q.name="Trovareta"
	state.q.boss=true
	var battle:=Battle.new()
	battle.configure(content,state.snapshot())
	root.add_child(battle)
	battle.paused=true
	battle.model.intro=0
	check(battle.art_ids[1]=="trovareta","duel uses Trovareta instead of Raio art")
	check(battle.model.enemy_model_id=="raio" and battle.model.enemy_level==31,"saved combat identity and level stay compatible")
	var q: Dictionary=battle.model.q
	q.attackCooldown=1.0
	battle.sprite_clock=0
	var start: Dictionary=battle._sprite_frame(1,q,"attack")
	battle.sprite_clock=.5
	check(battle._sprite_frame(1,q,"attack")!=start,"battle plays the authored attack")
	battle.sprite_clock=4.0
	check(battle._sprite_frame(1,q,"attack")==content.combat.trovareta.animations.attack[-1],"one-shot attack holds the last frame")
	battle.paused=false
	battle.launch_age=1.0
	battle.set_physics_process(false)
	battle._physics_process(0.0)
	await capture("battle")
	battle.queue_free()
	await process_frame
	print("TROVARETA PRESENTATION: %d checks; %d failures"%[checks,failures])
	quit(int(failures>0))
func capture(filename: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args() or DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../tmp/trovareta-review")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(filename+".png"))
