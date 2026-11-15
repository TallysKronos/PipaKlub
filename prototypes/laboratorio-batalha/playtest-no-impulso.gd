extends SceneTree

var arena

func _initialize() -> void:
	call_deferred("_run")

func _wait(frames:int) -> void:
	for i in frames: await physics_frame

func _key(key:Key,pressed:bool) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=key
	event.pressed=pressed
	Input.parse_input_event(event)

func _impulse(direction:Key) -> void:
	_key(direction,true)
	_key(KEY_SHIFT,true)
	await _wait(3)
	_key(KEY_SHIFT,false)
	_key(direction,false)
	await _wait(13)

func _shot(name:String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://%s.png" % name))

func _run() -> void:
	arena=load("res://arena.tscn").instantiate()
	root.add_child(arena)
	await _wait(3)
	var pilot:Dictionary=arena.actors[0]
	var rival:Dictionary=arena.actors[1]
	pilot.pos=Vector2(485,300)
	pilot.anchor=Vector2(455,510)
	pilot.rope.reset(pilot.anchor,pilot.pos)
	rival.pos=Vector2(530,150)
	rival.anchor=Vector2(530,505)
	rival.rope.reset(rival.anchor,rival.pos)
	rival.guard=0
	rival.dodge=1.1
	rival.vel=Vector2.ZERO
	arena.rival_recovery=1.2
	await _impulse(KEY_RIGHT)
	var right_ok:bool=pilot.facing==1 and not arena.dash_crossing.is_empty()
	print("Ida com Shift e seta direita: ",right_ok," posição ",pilot.pos)
	await _wait(33)
	for i in 8:
		if pilot.defense<=0:break
		await _wait(1)
	await _shot("faixa-retorno")
	await _impulse(KEY_LEFT)
	var left_ok:bool=pilot.facing==-1 and not arena.dash_knot.is_empty()
	print("Volta com Shift e seta esquerda: ",left_ok," posição ",pilot.pos)
	if left_ok and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://no-de-impulso.png"))
	var saved_knot:Dictionary=arena.dash_knot.duplicate()
	var damage:=100-float(rival.hull)
	if left_ok:
		await _wait(9)
		_key(KEY_E,true)
		await _wait(3)
		_key(KEY_E,false)
		damage=100-float(rival.hull)
	print("Tempestade após o Nó: ",damage," de estabilidade")
	var escape_ok:=false
	if left_ok:
		arena.special_flash=0
		arena.notice_clock=0
		arena.bursts.clear()
		arena.knot_release.clear()
		rival.exposed=0
		rival.flash=0
		rival.hull=100
		arena.dash_knot=saved_knot
		arena.dash_knot.escape_at=arena.elapsed
		arena.dash_knot.until=arena.elapsed+3
		rival.dodge=0.0
		rival.defense=0.0
		for n in 70:
			await _wait(1)
			if arena.knot_escape_notice>0 and n<4:await _shot("aviso-fuga")
			if arena.dash_knot.is_empty():
				escape_ok=not arena.knot_release.is_empty()
				break
	print("IA avisou e desfez o nó em movimento: ",escape_ok)
	arena._start(0)
	pilot=arena.actors[0]
	rival=arena.actors[1]
	_key(KEY_UP,true)
	await _wait(4)
	var up_ok:bool=pilot.heading==Vector2.UP
	if DisplayServer.get_name()!="headless":
		rival.heading=Vector2.DOWN
		rival.vel=Vector2.ZERO
		rival.dodge=.3
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://voo-subida-mergulho.png"))
	_key(KEY_UP,false)
	_key(KEY_DOWN,true)
	await _wait(4)
	var down_ok:bool=pilot.heading==Vector2.DOWN
	_key(KEY_DOWN,false)
	print("Seta para cima e para baixo na batalha: ",up_ok and down_ok)
	arena.sound_player.stop()
	arena.sound_player.stream=null
	await process_frame
	quit(0 if right_ok and left_ok and absf(damage-42.9)<.05 and up_ok and down_ok and escape_ok else 1)
