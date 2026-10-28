extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Corners=preload("res://scripts/campaign/battle_corner_hud.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,label:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for frame in 6:await process_frame
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://corner-checks-"+State.new_id())
	front.preferences.storage_path="user://corner-checks-"+State.new_id()+".cfg"
	root.add_child(front)
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip70")
	if capture:DirAccess.make_dir_recursive_absolute(output)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		for fixture in ["battle","boss-intro","morro-battle"]:
			Fixtures.show(front,fixture);await settle()
			var view:Control=front.battle
			view.model.intro=0;view.paused=false;view.launch_age=1
			view._physics_process(0);await settle()
			var actors:Array=view.model.actors if view.model.get("actors")!=null else [view.model.p,view.model.q]
			var boxes:Dictionary=Corners.regions(view.size,actors.size()-1)
			for rect:Rect2 in boxes.values():check(view.get_global_rect().encloses(rect),"corner inside screen")
			check(not boxes.pilot.intersects(boxes.clock) and not boxes.rivals.intersects(boxes.clock),"corner and clock separation")
			check(not boxes.weather.intersects(boxes.clock),"wind chip separated")
			check(view._field_scale().y*585>=view.size.y*.7,"flight projection occupies at least 70 percent height")
			for command in view.move_cards:check(not boxes.partner.intersects(command.tile.get_global_rect()),"partner and action tile stay separate")
			check(not boxes.partner.intersects(view.resume_button.get_global_rect()),"pause does not cover partner")
			check(view.flee_button.visible==(fixture!="morro-battle"),"flee only appears in wild encounter")
			for actor in actors.slice(1):
				var public:Dictionary=Corners.rival_summary(actor)
				var copy:Dictionary=actor.duplicate(true)
				copy.energy=0;copy.skillCooldown=99;copy.signatureCooldown=99
				check(public==Corners.rival_summary(copy),"rival energy and cooldown never enter presentation data")
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png"%[fixture,viewport.x,viewport.y]))
			view.model.duration=8;view.model.p.hp=view.model.p.stats.line*.2
			view.queue_redraw();await settle()
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s-alerta-%dx%d.png"%[fixture,viewport.x,viewport.y]))
			view.model.intro=2;view.model.duration=60
			view.model.p.hp=view.model.p.stats.line
			view.queue_redraw();await settle()
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s-intro-%dx%d.png"%[fixture,viewport.x,viewport.y]))
			if fixture=="morro-battle":
				view.model.intro=0;view.model.intermission=2
				view.model.round_message=view.model.p.name+" venceu a rodada 1"
				view.model.p.rounds=1
				view.queue_redraw();await settle()
				if capture:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("morro-cortou-%dx%d.png"%[viewport.x,viewport.y]))
	Fixtures.show(front,"battle");await settle()
	var view:Control=front.battle
	for connection in view.save_requested.get_connections():view.save_requested.disconnect(connection.callable)
	var saved:Array=[]
	view.save_requested.connect(func(state:Dictionary):saved.append(state))
	view.model.intro=0;view.paused=false
	Input.action_release("campaign_interact");view._step_flee(0)
	Input.action_press("campaign_interact")
	view._step_flee(.5)
	check(view.model.outcome.is_empty(),"half second does not flee")
	Input.action_release("campaign_interact");view._step_flee(0)
	check(view.flee_hold==0,"release cancels flee progress")
	Input.action_press("campaign_interact");view._step_flee(.6)
	view.suspend_actions();view._step_flee(0);view.paused=false;view._step_flee(.6)
	check(view.model.outcome.is_empty(),"held flee cannot cross pause")
	Input.action_release("campaign_interact");view._step_flee(0)
	Input.action_press("campaign_interact");view._step_flee(.5);view._step_flee(.5)
	check(view.model.outcome=="fled" and saved.size()==1,"one second emits one normal flee snapshot")
	Input.action_release("campaign_interact")
	check(Controls.bindings.interact!=Controls.bindings.signature,"flee uses interaction without conflicting with special")
	check(Corners.line_color(.2)!=Corners.line_color(.4) and Corners.line_color(.4)!=Corners.line_color(.8),"line thresholds have distinct palette tokens")
	front.free()
	print("BATTLE CORNERS: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
