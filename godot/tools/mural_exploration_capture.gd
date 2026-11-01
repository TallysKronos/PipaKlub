extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	root.content_scale_size=Vector2i.ZERO
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-132/capturas")
	DirAccess.make_dir_recursive_absolute(output)
	var app:=Front.new()
	app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/pip132-capture"))
	app.preferences.storage_path=ProjectSettings.globalize_path("res://../tmp/pip132-capture.cfg")
	root.add_child(app);app.preferences.reduced_motion=true
	var before:="--before" in OS.get_cmdline_user_args()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in ([1.0] if before else [1.0,1.5]):
			app.preferences.text_scale=scale;app._apply_preferences()
			app.session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/pip132-capture-"+str(Time.get_ticks_usec())))
			app.session._store.create_slot("slot-1")
			Fixtures.show(app,"trail")
			for frame in 600:
				await process_frame
				if not app.flow_busy and not is_instance_valid(app.scene_loading):break
			for frame in 10:await process_frame
			if is_instance_valid(app.park):app.park.set_physics_process(false)
			for hud in get_nodes_in_group("exploration_hud"):
				hud.area_age=1;hud.objective_age=0;hud.idle_age=0
				hud._layout()
			await RenderingServer.frame_post_draw
			var prefix:=("antes-" if before else "")+"%dx%d-"%[dimensions.x,dimensions.y]
			var suffix:="-150" if scale>1 else ""
			root.get_texture().get_image().save_png(output.path_join(prefix+"exploracao"+suffix+".png"))
			if not before and dimensions==Vector2i(1280,720) and scale==1.0:
				for hud in get_nodes_in_group("exploration_hud"):
					hud._input(InputEventMouseMotion.new())
					hud.prompt.text="Examinar o marco de pedra"
					hud.push_notice("Progresso salvo","saved")
					hud.push_notice("Fragmento de papel encontrado","item")
					hud.push_notice("Não foi possível salvar. Tente novamente.","error")
					hud._process(0);hud._layout()
				for frame in 10:await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join(prefix+"interacao.png"))
				if "--interaction-only" in OS.get_cmdline_user_args():app.free();quit();return
			app.session._snapshot.revision=app.session._store.load_slot("slot-1").data.revision
			app._show_map()
			for frame in 8:await process_frame
			if scale>1:
				for child in app.get_children():
					if child.get_script()==load("res://scripts/campaign/hud_kronasta_map.gd"):child.select(9)
				for frame in 8:await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(prefix+"kronasta"+suffix+".png"))
		if before:break
	app.free();quit()

