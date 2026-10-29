extends SceneTree
## Visual capture with fictitious in-memory state. No slot or campaign operations.
const OUT="res://../documentation/neighborhood-loading/"
var campaign:Control
var reduced:=false
func _initialize()->void:call_deferred("start")
func capture(name:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+("reduced/" if reduced else "")+name+".png"))
func start()->void:
	root.size=Vector2i(1280,720)
	reduced="--reduced-motion" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+("reduced/" if reduced else "")))
	campaign=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.preferences.crt=false
	campaign.preferences.reduced_motion=reduced
	campaign._apply_preferences()
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	campaign.session._snapshot.checkpoint={"kind":"world","scene":"quintal","position":[4.4,17.4]}
	var started:=Time.get_ticks_msec()
	campaign._show_neighborhood()
	var covered:=false
	var sliding:=false
	while is_instance_valid(campaign.scene_loading):
		var overlay=campaign.scene_loading
		if not covered and overlay.phase=="loading":
			covered=true
			await capture("01-cobertura")
		elif not sliding and overlay.phase=="revealing" and ((reduced and overlay.opacity<.65) or (not reduced and overlay.slide>.35)):
			sliding=true
			await capture("02-saida-esquerda")
		await process_frame
	await capture("03-rua-pronta")
	print("Native loading visual capture complete in %d ms. No slot operations."%(Time.get_ticks_msec()-started))
	quit()
