extends SceneTree
## Presentation fixtures only: no Journey mutations, slot creation or reward calls.
const Flow=preload("res://scripts/campaign/tutorial_staging.gd")
const Flight=preload("res://scripts/campaign/first_flight_view.gd")
var campaign:Control
const OUT="res://../documentation/tutorial-fluido/"
func _initialize()->void:call_deferred("start")
func hold(seconds:float)->void:
	var time:=0.0
	while time<seconds:
		await process_frame
		time+=minf(root.get_process_delta_time(),.05)
func capture(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func start()->void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	campaign=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.preferences.crt=false
	campaign._apply_preferences()
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	var room:=Flow.professor_stage(campaign,Vector2(1056,1232))
	Flow.approach(room,Vector2(1152,864))
	for i in 20:
		await hold(.125)
		await capture("aproximacao-%02d"%i)
	room.face_actor(room.mother_point)
	Flow.talk(campaign,"Kael: Professor, o Rabbito ganhou vida! Quero aprender a voar com ele.\n\nSr. Assis: Então vamos começar juntos. Nozinho vai ajudar você a sentir o vento.","Vamos ao treino")
	await hold(.5)
	await capture("conversa-professor")
	campaign._clear("practice")
	var arena:=Flight.new()
	arena.configure(campaign.content,0)
	campaign.add_child(arena)
	await hold(.3)
	arena.model.complete=true
	await hold(.15)
	await capture("licao-concluida")
	arena.prepare_lesson(1)
	for i in 8:
		await hold(.1)
		await capture("licao-transicao-%02d"%i)
	arena.reel_in()
	for i in 10:
		await hold(.1)
		await capture("recolha-%02d"%i)
	campaign._clear("world:professor-home")
	room=Flow.professor_stage(campaign,Vector2(1152,864))
	preload("res://scripts/campaign/opening_staging.gd").pass_tail(room,room.mother_point,room.actor)
	await hold(.35)
	await capture("entrega-rabiola")
	await hold(.4)
	Flow.approach(room,Vector2(1440,672))
	for i in 20:
		await hold(.125)
		await capture("bancada-%02d"%i)
	campaign._clear("workshop:birth")
	var birth:=preload("res://scripts/campaign/workshop_birth_view.gd").new()
	birth.partner_name="Azulão"
	birth.partner_texture=load("res://assets/campaign/"+campaign.content.combat["basic-azulao"].image)
	birth.frames=campaign.content.combat["basic-azulao"].animations.idle
	birth.outcome={"craftBonus":{"totalPercent":8.4}}
	campaign.add_child(birth)
	await hold(1.3)
	await capture("nascimento")
	print("Native tutorial presentation captured. No campaign operations or saves executed.")
	quit()
