extends SceneTree
## Native presentation capture. Isolated model; no session, rewards or save calls.
const View=preload("res://scripts/campaign/workshop_view.gd")
const Hud=preload("res://scripts/campaign/hud.gd")
var view:Control
func _initialize()->void:call_deferred("start")
func start()->void:
	root.size=Vector2i(1280,720)
	preload("res://scripts/campaign/controls.gd").install()
	var shell:=Control.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.theme=preload("res://scripts/campaign/recorte_theme.gd").shared()
	root.add_child(shell)
	view=View.new()
	view.configure("comum",7)
	shell.add_child(view)
	if "--play" in OS.get_cmdline_user_args():return
	view.set_process(false)
	view.bottom_panel.hide()
	var folder:=ProjectSettings.globalize_path("res://../documentation/workshop-manga-v1/")
	DirAccess.make_dir_recursive_absolute(folder)
	for stage in 5:
		view.model.run.stage=stage
		view.model._start_stage()
		view.last_stage=stage
		view.feedback_age=3
		view.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"etapa-%d-1280x720.png"%stage)
	shell.queue_free()
	await process_frame
	var campaign:Control=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.preferences.crt=false
	campaign._apply_preferences()
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	campaign._show_starter()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"escolha-1280x720.png")
	print("Workshop presentation captured; no save, rewards or gameplay tests executed.")
	quit()
