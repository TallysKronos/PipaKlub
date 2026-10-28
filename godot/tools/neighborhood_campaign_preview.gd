extends SceneTree
## Render the real campaign route with a fictitious in-memory snapshot only.
## Does not create a slot, walk, trigger interactions, or exercise saving.
func _initialize() -> void:call_deferred("start")
func start() -> void:
	root.size=Vector2i(1280,720)
	var campaign: Control=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	var snapshot: Dictionary=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	snapshot.checkpoint={"kind":"world","scene":"quintal","position":[480,768]}
	snapshot.player.partners=[{"id":"visual-only-rabbito","modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100},"origin":"visual-only","certification":"unverified"}]
	snapshot.player.equippedPartnerId="visual-only-rabbito"
	campaign.session._snapshot=snapshot
	campaign._show_saved()
	if not is_instance_valid(campaign.park) or not is_instance_valid(campaign.park.world):quit(1);return
	for i in range(20):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/overworld/bairro-inicial-v2/campanha-1280x720.png"))
	print("Campaign city frame captured from an in-memory fixture; no save or gameplay tests.")
	campaign.session.close_session()
	quit()
