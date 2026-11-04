extends "res://scripts/overworld/view.gd"
## Independent trial: the campaign renderer and ordinary movement remain unchanged.
const Traversal=preload("res://scripts/overworld/mobility_traversal.gd")
const Marks=preload("res://scripts/overworld/mobility_marks.gd")
var traversal:=Traversal.new()
var pending:Dictionary={}
var gathering:=0.0
var safe_position:=Vector2.ZERO
var marks:Node2D
var completed:Dictionary={}
var avatar_base_scale:=Vector2.ONE

func _ready() -> void:
	area_id="encosta-dos-ventos-piloto"
	art_preview=true
	campaign_mode=true # Ignore global preview arguments; no campaign state is created.
	super._ready()
	selector.hide()
	for connection in art_toggle.toggled.get_connections():art_toggle.toggled.disconnect(connection.callable)
	art_toggle.text="Ver geometria";art_toggle.set_pressed_no_signal(false)
	art_toggle.toggled.connect(func(geometry:bool):
		if traversal.active or not pending.is_empty():recover()
		var at:=player
		OS.set_environment("KRONASTA_GEOMETRIA","1" if geometry else "0")
		load_area(area_id);player=at;follower=at;safe_position=at;_refresh_positions()
		art_toggle.set_pressed_no_signal(geometry))
	marks=Marks.new();marks.view=self;marks.z_index=5;add_child(marks)
	message("Encosta dos Ventos · experimente as rampas e os saltos marcados em azul.")

func load_area(id:String, entrance:Variant="") -> void:
	if traversal.active:traversal.cancel()
	pending.clear()
	super.load_area(id,entrance)
	avatar_base_scale=avatar.scale
	safe_position=player

func closest_link() -> Dictionary:
	for entry:Dictionary in model.data.get("mobility",{}).get("links",[]):
		var at:=Traversal.point(entry.from)
		if player.distance_to(at)<.85 and model.clear_segment(player,at) and Traversal.valid(model,entry):return entry
	return {}

func request_link(entry:Dictionary) -> bool:
	if traversal.active or not pending.is_empty() or not Traversal.valid(model,entry):return false
	if not model.data.mobility.links.has(entry):return false
	var at:=Traversal.point(entry.from)
	if player.distance_to(at)>.85 or not model.clear_segment(player,at):return false
	safe_position=at;pending=entry.duplicate(true);gathering=0
	path=model.path_to(player,at)
	if follower_trail.is_empty() and follower.distance_to(player)>.01:follower_trail.append(player)
	return true

func interact() -> void:
	if traversal.active or not pending.is_empty():return
	var entry:=closest_link()
	if not entry.is_empty():request_link(entry);return
	super.interact()

func walk_to(point:Vector2) -> bool:
	if traversal.active or not pending.is_empty():return false
	return super.walk_to(point)

func recover() -> void:
	if traversal.active:safe_position=traversal.cancel()
	pending.clear();path.clear();follower_trail.clear()
	player=safe_position;follower=safe_position
	avatar.stop_jump();avatar.scale=avatar_base_scale
	_refresh_positions()
	message("Kael e parceiro voltaram ao último chão firme. Nenhum save foi alterado.")

func _physics_process(delta:float) -> void:
	if traversal.active:
		clock+=delta;traversal.advance(delta)
		_render_traversal()
		if not traversal.active:
			player=traversal.finish;follower=player;safe_position=player
			follower_trail.clear();avatar.stop_jump();avatar.scale=avatar_base_scale
			completed[traversal.link.id]=true
			_refresh_positions();message("Travessia concluída · o parceiro chegou com você.")
	elif not pending.is_empty():
		clock+=delta;gathering+=delta
		var at:=Traversal.point(pending.from)
		var next:=player.move_toward(at,delta*3)
		if model.clear_segment(player,next):_adopt_player_step(next)
		follower=CompanionFollow.advance(follower,follower_trail,delta,6.3,0,model.clear_segment)
		avatar.moving=player.distance_to(at)>.01;avatar.running=false
		_refresh_positions()
		if player.distance_to(at)<.01 and follower.distance_to(at)<.08:
			var entry:=pending.duplicate(true);pending.clear();path.clear();follower_trail.clear()
			if not traversal.begin(model,entry,player):recover()
			else:
				avatar.moving=false;avatar.face_motion(model.project(traversal.finish,false)-model.project(traversal.start,false))
		elif gathering>6:recover()
	else:
		super._physics_process(delta)
		if not nearby.is_empty():
			var target:=Vector2(nearby.u+.5,nearby.v+.5)
			if not model.clear_segment(player,target):nearby={}
		safe_position=player
	_update_hint()
	if is_instance_valid(marks):marks.queue_redraw()

func _render_traversal() -> void:
	var p:Dictionary=traversal.sample()
	var f:Dictionary=traversal.sample(true)
	player=p.point;follower=f.point
	_refresh_positions()
	for actor in [[player_root,avatar,p],[follower_root,companion,f]]:
		var ground:Vector2=model.project(actor[2].point,false)
		actor[0].position=ground
		actor[1].position=Vector2(0,-float(actor[2].height)*64-float(actor[2].lift))
	avatar.jump_pose(clampf(traversal.elapsed/(Traversal.WINDUP+Traversal.FLIGHT+Traversal.LANDING),0,1))
	camera.position=model.project(player,false)-Vector2(0,float(p.height)*64)

func _update_hint() -> void:
	if traversal.active:hint.text="Travessia · parceiro a caminho   Esc · recuperar chão firme";return
	if not pending.is_empty():hint.text="Preparando o salto · aguardando o parceiro";return
	if clock<notice_until:hint.text=notice;return
	var entry:=closest_link()
	if not entry.is_empty():hint.text=Controls.prompt("interact")+" · "+("Descer a borda · mão única" if entry.kind=="drop" else "Saltar para o outro lado");return
	hint.text=Controls.prompt("interact")+" · "+str(nearby.name) if not nearby.is_empty() else "Setas / analógico · explorar   "+Controls.prompt("run")+" · correr   Azul · travessia opcional"

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		recover();get_viewport().set_input_as_handled();return
	if traversal.active or not pending.is_empty():
		Controls.observe(event);return
	super._unhandled_input(event)
