extends SceneTree
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Boss=preload("res://scripts/campaign/boss_presentation.gd")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for i in 4:await process_frame
func capture(label:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/boss-presentation-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run() -> void:
	root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.preferences.storage_path="user://boss-presentation-test.cfg"
	root.add_child(app)
	for reduced in [false,true]:
		app.preferences.reduced_motion=reduced
		for viewport in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(800,600)]:
			root.size=viewport
			Fixtures.show(app,"boss-intro");await settle()
			var view:Control=app.battle
			view.set_physics_process(false);view.paused=false
			view.model.intro=2.2;view._physics_process(0);await settle()
			check(is_instance_valid(view.boss_intro) and view.boss_intro.visible,"boss banner present")
			check(view.move_cards.all(func(card:Dictionary):return not card.node.visible),"commands hidden before release")
			var before:Dictionary=view.model.snapshot()
			view.pointer_held={"cut":true,"skill":true};view._physics_process(.05)
			check(view.model.p.x==before.p.x and view.model.p.hp==before.p.hp and view.model.q.hp==before.q.hp and view.model.duration==before.duration,"intro freezes fighters, damage and fight clock")
			view.suspend_actions();var remaining:float=view.model.intro
			view._physics_process(.05)
			check(view.model.intro==remaining and not view.boss_intro.visible,"pause suspends banner and countdown")
			view.paused=false;view._physics_process(0);await settle()
			check(view.boss_intro.visible,"resume preserves banner")
			check(Rect2(Vector2.ZERO,Vector2(viewport)).encloses(Boss.meter_rect(Vector2(viewport))),"boss HUD fits viewport")
			if viewport.x==1280:await capture("banner-"+("reduced" if reduced else "normal"))
			view.pointer_held={"cut":true}
			view.model.intro=.01;view._physics_process(.02)
			check(view.model.intro==0 and not view.boss_intro.visible,"banner ends before combat")
			view.pointer_held={"cut":true};view._physics_process(.02)
			check(view.model.p.attackCooldown==0,"held intro input cannot fire on release")
			view.pointer_held.clear();view._physics_process(.02)
			check(not view.require_action_release,"released controls rearm combat")
			view.model.q.hp=view.model.q.stats.line*.42;view.model.q.hull=view.model.q.stats.line*.73;view.model.q.phase=2
			view._physics_process(0);await settle()
			check(view.move_cards.all(func(card:Dictionary):return card.node.visible),"commands return for combat")
			if viewport.x==1280 and not reduced:await capture("boss-hud-phase-2")
			view.model.outcome="won";view._physics_process(0);await settle()
			check(not view.boss_intro.visible and is_instance_valid(view.reward_card),"victory replaces boss presentation")
	Fixtures.show(app,"battle");await settle()
	check(not is_instance_valid(app.battle.boss_intro) and not app.battle.model.q.boss,"wild battle keeps ordinary HUD")
	app.free();await settle()
	print("BOSS PRESENTATION: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
