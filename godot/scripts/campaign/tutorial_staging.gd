extends RefCounted
## Presentation only. Receipts, checkpoints and rewards stay in Journey.
const Walk=preload("res://scripts/campaign/opening_staging.gd")

static func valid(front:Control,generation:int)->bool:
	return is_instance_valid(front) and front.is_inside_tree() and front.opening_generation==generation

static func line_clear(room:Node2D,a:Vector2,b:Vector2)->bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/8.0))
	for i in range(1,steps+1):
		if not room._safe(a.lerp(b,float(i)/steps)):return false
	return true

static func route(room:Node2D,target:Vector2)->Array:
	if not room._safe(target):return []
	if line_clear(room,room.actor,target):return [target]
	# Four-way navigation over the real floor; never walk straight through furniture.
	var origin:=Vector2(room.data.layout.floor.x,room.data.layout.floor.y)
	var count:=Vector2i(ceili(room.data.layout.floor.w/48.0),ceili(room.data.layout.floor.h/48.0))
	var cells:Dictionary={}
	var start:=Vector2i(-1,-1)
	var goal:=start
	var start_distance:=INF
	var goal_distance:=INF
	for y in count.y:
		for x in count.x:
			var cell:=Vector2i(x,y)
			var point:=origin+Vector2(cell)*48+Vector2(24,24)
			if not room._safe(point):continue
			cells[cell]=point
			var distance:float=point.distance_to(room.actor)
			if distance<start_distance and line_clear(room,room.actor,point):start=cell;start_distance=distance
			distance=point.distance_to(target)
			if distance<goal_distance and line_clear(room,point,target):goal=cell;goal_distance=distance
	if start.x<0 or goal.x<0:return []
	var pending:Array[Vector2i]=[start]
	var parents:Dictionary={start:start}
	var head:=0
	while head<pending.size() and not parents.has(goal):
		var current:=pending[head]
		head+=1
		for delta:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:=current+delta
			if not cells.has(next) or parents.has(next):continue
			if not line_clear(room,cells[current],cells[next]):continue
			parents[next]=current
			pending.append(next)
	if not parents.has(goal):return []
	var points:Array=[target,cells[goal]]
	var cursor:=goal
	while cursor!=start:
		cursor=parents[cursor]
		points.append(cells[cursor])
	points.reverse()
	var simplified:Array=[]
	var from:Vector2=room.actor
	var index:=0
	while index<points.size():
		var end:=index
		for i in range(index+1,points.size()):
			if line_clear(room,from,points[i]):end=i
		simplified.append(points[end]);from=points[end];index=end+1
	return simplified

static func approach(room:Node2D,target:Vector2)->bool:
	if not Walk.alive(room):return false
	var points:=route(room,target)
	if points.is_empty():return false
	room.can_walk=false
	await Walk.walk(room,"kael",points,240)
	return Walk.alive(room)

static func talk(front:Control,text:String,action:String="Avançar")->bool:
	var generation:int=front.opening_generation
	var dialog:Control=front._dialog("Sr. Assis",text,action)
	dialog.allow_cancel=false
	var receipt:Dictionary={"done":false}
	dialog.confirmed.connect(func():receipt.done=true)
	dialog.popup_centered()
	var tree:SceneTree=front.get_tree()
	while valid(front,generation) and is_instance_valid(dialog) and not receipt.done:
		await tree.process_frame
	if is_instance_valid(dialog):dialog.queue_free()
	return valid(front,generation) and receipt.done

static func meet_professor(front:Control)->void:
	if front.flow_busy or not is_instance_valid(front.room):return
	front.flow_busy=true
	var generation:int=front.opening_generation
	var room:Node2D=front.room
	if not await approach(room,Vector2(1152,864)):
		if valid(front,generation):room.can_walk=true;front.flow_busy=false
		return
	if not valid(front,generation):return
	room.face_actor(room.mother_point)
	var complete:bool=front.session.snapshot().player.get("journey",{}).get("phase")=="complete"
	if complete:
		if front._result(front.exploration.repair()):
			await talk(front,"Sr. Assis: Vamos cuidar da linha e da armação. Um parceiro bem cuidado voa mais longe.\n\nSr. Assis: Pronto! Sua equipe está recuperada.","Obrigado, professor")
		if valid(front,generation):room.can_walk=true;front.flow_busy=false
		return
	if front.session.snapshot().player.get("journey",{}).get("lesson",0)>=5:
		if await talk(front,"Sr. Assis: Nosso treino já está completo. Falta escolher sua rabiola e construir a pipa.","Escolher rabiola"):
			if valid(front,generation):
				if front._result(front.journey.practice()):front._show_saved()
				else:front.flow_busy=false;room.can_walk=true
		return
	if not await talk(front,"Kael: Professor, o Rabbito ganhou vida! Quero aprender a voar com ele.\n\nSr. Assis: Então vamos começar juntos. Lá fora, Nozinho vai ajudar você a sentir o vento. Primeiro, movimento; depois, os encontros de linha.","Vamos ao treino"):return
	if not valid(front,generation):return
	if not await approach(room,Vector2(1056,1240)):
		if valid(front,generation):room.can_walk=true;front.flow_busy=false
		return
	if valid(front,generation):
		if front._result(front.journey.practice()):front._show_saved.call_deferred()
		else:front.flow_busy=false;room.can_walk=true

static func professor_stage(front:Control,position:Vector2)->Node2D:
	front._clear("world:professor-home")
	front._stage_container()
	var room:Node2D=preload("res://scripts/campaign/room_view.gd").new()
	front.stage.add_child(room)
	room.configure(front.content.rooms.professor,[position.x,position.y],false,"",true,true)
	front.room=room
	front._equip_room_companion()
	front.flow_busy=true
	return room

static func after_practice(front:Control)->void:
	var room:=professor_stage(front,Vector2(1056,1232))
	var generation:int=front.opening_generation
	if not await approach(room,Vector2(1152,864)):
		if valid(front,generation):front._show_starter()
		return
	if not valid(front,generation):return
	room.face_actor(room.mother_point)
	if not await talk(front,"Sr. Assis: Muito bem, Kael. Você aprendeu a guiar, cruzar linhas e proteger seu parceiro.\n\nSr. Assis: Agora escolha uma destas quatro rabiolas. Vamos à bancada montar sua primeira pipa comigo.","Ver as rabiolas"):return
	if valid(front,generation):front._show_starter()

static func handoff(front:Control,starter:bool=true)->void:
	var room:=professor_stage(front,Vector2(1152,864))
	var generation:int=front.opening_generation
	room.face_actor(room.mother_point)
	if starter:
		await Walk.pass_tail(room,room.mother_point,room.actor)
		if not valid(front,generation):return
		if not await talk(front,"Sr. Assis: Cuide desta rabiola. A alma já tem um caminho; falta você construir a pipa.\n\nSr. Assis: Leve-a à bancada. Vamos começar pela armação.","Ir à bancada"):return
	if not valid(front,generation):return
	if not await approach(room,Vector2(1440,672)):
		if valid(front,generation):front._show_saved()
		return
	if not valid(front,generation):return
	room.face_actor(Vector2(1440,480))
	await Walk.wait(room,.25)
	if valid(front,generation):front._show_saved()

static func return_after_birth(front:Control,first_partner:bool)->void:
	front._show_saved()
	if not is_instance_valid(front.room):return
	front.flow_busy=true
	front.room.can_walk=false
	var generation:int=front.opening_generation
	var room:Node2D=front.room
	if not await approach(room,Vector2(1248,768)):
		if valid(front,generation):front.flow_busy=false;room.can_walk=true
		return
	if not valid(front,generation):return
	room.face_actor(room.mother_point)
	var text:="Sr. Assis: Seu novo parceiro já está com você. Cuide da linha e da armação; passe aqui sempre que precisar de reparos."
	if first_partner:text+="\n\nSr. Assis: Nosso primeiro treino termina aqui. O parque e o Morro do Sol esperam por vocês. Vá no seu ritmo, Kael."
	if not await talk(front,text,"Explorar com meu parceiro"):return
	if valid(front,generation):front.flow_busy=false;room.can_walk=true

static func open_workbench(front:Control)->void:
	if front.flow_busy or not is_instance_valid(front.room):return
	front.flow_busy=true
	var generation:int=front.opening_generation
	var room:Node2D=front.room
	if not await approach(room,Vector2(1440,672)):
		if valid(front,generation):front.flow_busy=false;room.can_walk=true
		return
	if not valid(front,generation):return
	room.face_actor(Vector2(1440,480))
	var player:Dictionary=front.session.snapshot().player
	if player.get("journey",{}).get("lesson",0)<5:
		await talk(front,"Sr. Assis: Antes da bancada, vamos sentir o vento com Nozinho. Venha conversar comigo para começar o treino.")
		if valid(front,generation):front.flow_busy=false;room.can_walk=true
	elif player.get("starter",{}).get("completed",false):
		front._show_tail_workshop()
		if valid(front,generation):front.flow_busy=false;room.can_walk=true
	elif front._result(front.journey.practice()):front._show_saved()
	else:front.flow_busy=false;room.can_walk=true

static func enter_atelier(front:Control)->void:
	if front.flow_busy or not is_instance_valid(front.room):return
	front.flow_busy=true
	var generation:int=front.opening_generation
	var room:Node2D=front.room
	await approach(room,Vector2(1104,1120))
	if valid(front,generation):front.flow_busy=false;room.can_walk=true

static func leave_atelier(front:Control)->void:
	if front.flow_busy or not is_instance_valid(front.room):return
	front.flow_busy=true
	var generation:int=front.opening_generation
	var room:Node2D=front.room
	if not await approach(room,Vector2(1056,1296)):
		if valid(front,generation):front.flow_busy=false;room.can_walk=true
		return
	if not valid(front,generation):return
	if front._result(front.journey.enter_world("quintal",Vector2(1376,740))):front._show_saved()
	else:front.flow_busy=false;room.can_walk=true
