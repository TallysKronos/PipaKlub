extends SceneTree
## Rendered, accelerated round recordings using injected joypad events and isolated saves.
## This is controller-path simulation, never evidence of a physical controller test.
const Front = preload("res://scripts/campaign/front_end.gd")
const Fixtures = preload("res://tools/player_audit_fixtures.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var output := ""
var report: Array = []
var input_counts := {"cut":0,"skill":0,"dodge":0,"line":0,"guard":0,"signature":0,"movement":0}
func _initialize() -> void:call_deferred("run")
func freeze(node:Node) -> void:
	node.set_process(false);node.set_physics_process(false)
	for child in node.get_children():freeze(child)
func button(action:String,pressed:bool) -> void:
	var event:=InputEventJoypadButton.new()
	event.device=0;event.button_index=Controls.PAD[action];event.pressed=pressed
	Input.parse_input_event(event);Controls.observe(event)
func axis(which:int,value:float) -> void:
	var event:=InputEventJoypadMotion.new()
	event.device=0;event.axis=which;event.axis_value=value
	Input.parse_input_event(event);Controls.observe(event)
func frame(path:String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(path))
func run() -> void:
	if DisplayServer.get_name()=="headless":printerr("Renderer required");quit(1);return
	root.size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../mockups/revisao/rodadas")
	DirAccess.make_dir_recursive_absolute(output)
	var front:=Front.new()
	front.session._store=Store.new("user://round-review-"+State.new_id())
	front.preferences.storage_path="user://round-review-"+State.new_id()+".cfg"
	root.add_child(front)
	for fixture in ["battle","morro-battle","boss-intro"]:
		front.session._store=Store.new("user://round-review-"+State.new_id())
		var created:Dictionary=front.session._store.create_slot("slot-1")
		if created.status!="ok":printerr("Cannot create isolated replay slot");quit(1);return
		Fixtures.show(front,fixture)
		# Static visual fixtures omit operation metadata; make this replay a valid isolated save.
		var saved:Dictionary=front.session.snapshot()
		saved.revision=created.data.revision
		saved.player.encounter.id=State.new_id()
		saved.player.encounter.returnPoint=[208,816]
		if fixture=="morro-battle":saved.player.encounter.scene="morro-area-3"
		front.session._snapshot=saved
		var initial:Dictionary=front.session.checkpoint(saved.checkpoint,saved.player)
		if initial.status!="ok":printerr("Invalid replay fixture: ",initial);quit(1);return
		for i in 5:await process_frame
		freeze(front)
		Controls.configure_device(0,"Xbox simulated capture",1118)
		var view:Control=front.battle
		view.paused=false
		var start_round:int=int(view.model.get("round_number")) if view.model.get("round_number")!=null else 1
		var trace:Array=[]
		var frames:Array=[]
		var previous_danger:=false
		for tick in 4000:
			var time:=tick*.05
			# A deterministic player script drives the real mapped controls, not model commands.
			axis(JOY_AXIS_LEFT_X,sin(time*.65)*.85)
			axis(JOY_AXIS_LEFT_Y,cos(time*.8)*.65)
			for action in Controls.PAD:
				if action not in input_counts:continue
				var period:int={"cut":18,"skill":100,"dodge":60,"line":80,"guard":42,"signature":240}[action]
				button(action,tick%period< (6 if action=="guard" else 2))
				if Controls.held(action):input_counts[action]+=1
			if Controls.direction().length()>.1:input_counts.movement+=1
			view.paused=false
			view._physics_process(.05)
			for command in view.move_cards:command.tile._process(.05)
			var rivals:Array=view.model.actors.slice(1) if view.model.get("actors")!=null else [view.model.q]
			var danger:bool=rivals.any(func(actor:Dictionary):return actor.signatureWindup>0 or view.model.attack_notice(actor).active)
			trace.append({"time":time,"player":[view.model.p.x,view.model.p.y],"hp":view.model.p.hp,"energy":view.model.p.energy,"danger":danger,"outcome":view.model.outcome})
			var ended:bool=not view.model.outcome.is_empty() or (view.model.get("intermission")!=null and view.model.intermission>0)
			if tick%60==0 or (danger and not previous_danger) or ended:
				var file:="%s-%04d.png"%[fixture,tick]
				await frame(file);frames.append(file)
			previous_danger=danger
			if ended:
				view._physics_process(0)
				view._update_result(.5)
				view.impacts.step(.6)
				view._layout_actions()
				await create_timer(.5).timeout
				await frame(fixture+"-final.png")
				break
		var ended:bool=(not view.model.outcome.is_empty() or (view.model.get("intermission")!=null and view.model.intermission>0)) and not view.blocked
		report.append({"fixture":fixture,"round":start_round,"ended":ended,"simulatedSeconds":trace.size()*.05,"outcome":view.model.outcome,"frames":frames,"trace":trace})
		for action in input_counts:
			if Controls.PAD.has(action):button(action,false)
		axis(JOY_AXIS_LEFT_X,0);axis(JOY_AXIS_LEFT_Y,0)
	var success:bool=report.all(func(record:Dictionary):return record.ended) and input_counts.values().all(func(count:int):return count>0)
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"input":"injected Godot joypad events; no physical controller","isolatedSaves":true,"inputCounts":input_counts,"success":success,"rounds":report},"  "))
	file.close()
	front.free()
	print("ROUND CAPTURE: ",report.size()," complete=",success,"; input=",input_counts)
	quit(0 if success else 1)
