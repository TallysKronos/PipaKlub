extends SceneTree
## Visual capture only, with fictitious state in memory; never advances/saves a slot.
var campaign: Control
const OUT := "res://../documentation/overworld/bairro-inicial-v2/prologo/"
func _initialize() -> void:call_deferred("start")
func hold(seconds: float) -> void:
	var elapsed:=0.0
	while elapsed<seconds:
		await process_frame
		elapsed+=minf(root.get_process_delta_time(),.05)
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func show_step(step: int) -> void:
	campaign.session._snapshot.checkpoint={"kind":"opening","step":step}
	campaign._show_opening()
	await process_frame
func start() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	campaign=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	await show_step(0)
	await hold(.8)
	await capture("01-tv-no-quarto")
	await show_step(2);await hold(.6)
	await show_step(3)
	campaign.room.actor=Vector2(1200,528)
	await show_step(4);await hold(.6)
	await show_step(5)
	for i in range(36):
		await hold(.125)
		await capture("entrada-%02d"%i)
	await capture("02-conversa")
	await show_step(7);await hold(.8)
	await capture("presente")
	await show_step(8);await hold(1.8)
	await show_step(9);await hold(1.2)
	await capture("03-nascimento")
	await show_step(11)
	for i in range(26):
		await hold(.125)
		await capture("saida-%02d"%i)
	await show_step(12)
	await hold(3.5)
	await capture("04-chegada-na-sala")
	print("Opening staging frames captured; no progression, rewards, save or gameplay tests executed.")
	campaign.session.close_session()
	quit()
