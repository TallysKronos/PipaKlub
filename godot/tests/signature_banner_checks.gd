extends SceneTree
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for frame in 4:await process_frame
func capture(id:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var out:=ProjectSettings.globalize_path("res://../documentation/qa/signature-banners-v1")
	DirAccess.make_dir_recursive_absolute(out)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id+".png"))
func run() -> void:
	root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	app.preferences.storage_path="user://signature-banner-test.cfg"
	root.add_child(app)
	for reduced in [false,true]:
		app.preferences.reduced_motion=reduced
		for viewport in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(800,600)]:
			root.size=viewport;Fixtures.show(app,"boss-intro");await settle()
			var view:Control=app.battle
			view.set_physics_process(false);view.paused=false;view.model.intro=0
			view.model.p.x=400;view.model.q.x=600
			view.model.p.signatureCooldown=0;view.model.q.signatureCooldown=10
			view.require_action_release=false
			view.pointer_tapped={"signature":true};view._physics_process(.016)
			var banner:Control=view.signature_banner
			check(banner.visible and banner.active_id=="rabbito" and not banner.enemy,"accepted player special announces")
			check(view.model.p.signatureWindup>0 and view.model.p.energy<100,"actual paid special started")
			banner.advance(.22);await settle()
			check(root.get_visible_rect().encloses(banner.banner_rect()),"banner fits rendered viewport")
			if viewport.x==1280 and not reduced:await capture("rabbito")
			var age:float=banner.age
			view.suspend_actions();view._physics_process(.1)
			check(not banner.visible and banner.age==age,"pause hides and freezes banner")
			view.paused=false;view._physics_process(0)
			check(banner.visible and banner.age==age,"resume does not replay announcement")
			banner.advance(1)
			view.model._signature_hit(view.model.p,view.model.q,.016,true,[])
			check(not banner.visible,"held or cooling-down special never announces")
			view.model.q.signatureCooldown=0
			view.model._signature_hit(view.model.q,view.model.p,.016,true,[])
			check(banner.active_id=="lacertubo" and banner.enemy,"accepted enemy special announces")
			banner.advance(.22);await settle()
			if viewport.x==1280 and not reduced:await capture("lacertubo")
			banner.announce("rabbito",false)
			check(banner.active_id=="lacertubo","simultaneous player event cannot obscure enemy warning")
			banner.advance(1)
			view.model.p.signatureWindup=0;view.model.p.signatureCooldown=0;view.model.p.signatureHeld=false;view.model.p.energy=0
			view.model._signature_hit(view.model.p,view.model.q,.016,true,[])
			check(not banner.visible,"no energy does not announce")
			banner.announce("nozinho");banner.advance(.22);await settle()
			check(banner.images.nozinho!=null and banner.entries.nozinho.move=="Nó de Vendaval","Nozinho approved presentation ready")
			if viewport.x==1280 and not reduced:await capture("nozinho-preview")
			banner.advance(0,false,true)
			check(not banner.visible and banner.active_id.is_empty(),"results clear announcement")
			view.model.restore(view.model.snapshot())
			check(not banner.visible,"restoring state does not replay special")
	Fixtures.show(app,"morro-battle");await settle()
	check(is_instance_valid(app.battle.signature_banner),"Morro shares banner component")
	app.free();await settle()
	print("SIGNATURE BANNERS: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
