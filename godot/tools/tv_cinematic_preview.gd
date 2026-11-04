extends SceneTree
## Native movie presentation capture with an isolated in-memory opening fixture.
var campaign:Control
const OUT="res://../documentation/pipa-tv-cinematic-v1/"
func _initialize()->void:call_deferred("start")
func hold(seconds:float)->void:
	var elapsed:=0.0
	while elapsed<seconds:
		await process_frame
		elapsed+=minf(root.get_process_delta_time(),.05)
func capture(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+name+".png"))
func start()->void:
	root.size=Vector2i(1280,720)
	campaign=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.preferences.crt=false
	campaign._apply_preferences()
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	campaign.session._snapshot.checkpoint={"kind":"opening","step":0}
	campaign._show_opening()
	await hold(1)
	await capture("tv-nativa-01")
	await hold(2)
	await capture("tv-nativa-02")
	await hold(2)
	await capture("tv-nativa-03")
	campaign.session._snapshot.checkpoint={"kind":"opening","step":2}
	campaign._show_opening()
	await hold(.7)
	await capture("volta-ao-quarto")
	print("Native cinematic playback captured; no progression or save operations executed.")
	quit()
