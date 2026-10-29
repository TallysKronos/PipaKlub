extends SceneTree
## Visual fixture only. Fictitious state in memory, no save or campaign operations.
const Flow=preload("res://scripts/campaign/tutorial_staging.gd")
const OUT="res://../documentation/professor-identity-v3/"
var campaign:Control
func _initialize()->void:call_deferred("start")
func start()->void:
	root.size=Vector2i(1280,720)
	var destination:=OUT+"overworld-v4/" if "--overworld-v4" in OS.get_cmdline_user_args() else OUT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	campaign=load("res://scenes/campaign.tscn").instantiate()
	root.add_child(campaign)
	campaign.preferences.crt=false
	campaign._apply_preferences()
	campaign.session._snapshot=preload("res://scripts/campaign/state.gd").fresh("slot-3")
	var room:=Flow.professor_stage(campaign,Vector2(1152,864))
	room.face_actor(room.mother_point)
	Flow.talk(campaign,"Sr. Assis: Cada pipa começa com um cuidado. Vamos descobrir o que o vento preparou para você?","Continuar")
	await create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(destination+"dialogo-professor.png"))
	print("Professor identity visual capture saved; no save operations executed.")
	quit()
