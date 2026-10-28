extends SceneTree
const Front = preload("res://scripts/campaign/front_end.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const Signals = preload("res://scripts/campaign/battle_signals.gd")
const Impacts = preload("res://scripts/campaign/hud_impacts.gd")
var checks := 0
var failures: Array = []
func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures.append(label);printerr("FAIL "+label)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 5: await process_frame
func run() -> void:
	var model := Model.new()
	var situations := 0
	for x in range(280,941,55):
		for y in range(80,470,65):
			model.p.x=x;model.p.y=y;model.q.x=410;model.q.y=160
			model.p.vx=120 if x%2==0 else 0;model.p.counter=0
			var crossing := model.contact(model.p,model.q)
			var state := Signals.state(model,model.q)
			check(state.contact==crossing,"contact is model result")
			if crossing.is_empty(): continue
			situations+=1
			var quality: Dictionary=state.quality
			check(quality.angle==(crossing.angle>=.85),"angle predicate")
			check(quality.center==crossing.perfect,"center predicate")
			check(quality.moving==(Vector2(model.p.vx,model.p.vy).length()>=110),"moving predicate")
			var clone: Dictionary=model.p.duplicate(true)
			var expected: float=(24.0 if crossing.perfect else 18.0)*(1.75 if quality.critical else 1+(.2 if crossing.angle>=.85 else 0)-(.2 if crossing.angle<.45 else 0)+(.15 if quality.moving else 0))
			check(is_equal_approx(model._damage(clone,crossing),expected),"rendered quality agrees with actual damage rule")
	check(situations>=20,"at least 20 actual intersections")
	var impacts := Impacts.new()
	for i in 8: impacts.add({"amount":18,"point":Vector2.ZERO,"body":false,"player":true})
	check(impacts.bursts.size()==3,"at most 3 damage numbers")
	impacts.step(1.0);check(impacts.bursts.is_empty(),"no ink after one second")
	impacts.reduced_motion=true;impacts.add({"amount":1});impacts.step(.081)
	check(impacts.bursts.is_empty(),"reduced motion 80ms fade")
	var front := Front.new()
	front.session._store=Store.new("user://battle-recorte-"+State.new_id())
	front.preferences.storage_path="user://battle-recorte-"+State.new_id()+".cfg"
	root.add_child(front)
	var captures := "--capture" in OS.get_cmdline_user_args()
	var output := ProjectSettings.globalize_path("res://../mockups/revisao")
	if captures: DirAccess.make_dir_recursive_absolute(output)
	var quick := "--quick" in OS.get_cmdline_user_args()
	var viewports := [Vector2i(1280,720)] if quick else [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]
	var fixtures := ["battle"] if quick else ["battle","morro-battle","boss-intro"]
	for viewport in viewports:
		root.size=viewport
		for fixture in fixtures:
			Fixtures.show(front,fixture)
			await settle()
			var battle: Control=front.battle
			battle.paused=false;battle.model.intro=0;battle.launch_age=1
			battle._physics_process(0)
			await settle()
			check(battle.bottom_panel.size.y<=battle.size.y*.12+.5,"action bar <=12% "+fixture+str(viewport))
			check(not battle.status_row.visible,"tips hidden during combat")
			for state in ["ready","cooldown","energy","charge","active","locked"]:
				for item in battle.move_cards:
					var tile: Control=item.tile
					tile.cooldown=6 if state=="cooldown" else 0
					tile.enough_energy=state!="energy"
					tile.charge=.65 if state=="charge" else 0
					tile.active=state=="active"
					tile.lock_reason="prepare" if state=="locked" else ""
					tile.queue_redraw()
					var regions: Dictionary=tile.regions()
					check(not regions.caption.intersects(regions.state),"caption separated "+state)
					for fraction in [.01,.25,.5,.75,1.0]:
						for polygon in tile.fill_polygons(fraction):
							for vertex in polygon: check(Geometry2D.is_point_in_polygon(vertex,tile.button_polygon()),"fill is inside action silhouette")
					check(tile.get_global_rect().end.x<=battle.size.x,"action within viewport")
				if captures:
					await settle();await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("batalha-acoes-%s-%s-%dx%d.png"%[fixture,state,viewport.x,viewport.y]))
	if captures:
		root.size=Vector2i(1280,720)
		Fixtures.show(front,"battle")
		await settle()
		var battle: Control=front.battle
		battle.model.intro=0;battle.paused=false
		for presentation in ["contact","danger","evade","counter","impact","reduced"]:
			battle.model.p.x=750;battle.model.p.y=170;battle.model.p.vx=140
			battle.model.q.x=320;battle.model.q.y=180
			battle.model.q.signatureWindup=.8 if presentation=="danger" else 0
			battle.model.q.signatureAim=Vector2(battle.model.p.x,battle.model.p.y)
			battle.model.q.telegraph=.8 if presentation=="evade" else 0
			battle.model.p.counter=1.4 if presentation=="counter" else 0
			battle.impacts.bursts.clear()
			battle.impacts.reduced_motion=presentation=="reduced"
			if presentation in ["impact","reduced"]: battle.impacts.add({"amount":42,"point":Vector2(500,410),"color":0,"player":false,"body":false,"critical":true})
			battle.queue_redraw()
			await settle();await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("batalha-sinais-"+presentation+".png"))
	front.free()
	print("BATTLE RECORTE: ",checks," checks, ",failures.size()," failures; ",situations," contact cases")
	quit(0 if failures.is_empty() else 1)
