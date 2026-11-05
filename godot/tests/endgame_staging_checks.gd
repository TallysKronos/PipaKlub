extends SceneTree
const View=preload("res://scripts/campaign/park_overworld_view.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Story=preload("res://scripts/campaign/endgame_story.gd")
var failures: Array[String]=[]

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		printerr(message)

func run() -> void:
	for id in ["gerador","gollia-arrependimento","ending"]:
		var view=View.new()
		var scene: String=Story.STEPS[id].scene if id!="ending" else "kronasta-estadio-a"
		var point: Vector2=Story.point(scene,Story.STEPS[id].anchor)+Vector2(0,1) if id!="ending" else CP.spawn(scene)
		view.saved_checkpoint=CP.make(scene,point,CP.SPACE)
		view.saved_player=preload("res://scripts/campaign/state.gd").fresh("slot-1").player
		view.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
		root.add_child(view)
		view.set_physics_process(false)
		view.reduced_motion=true
		if id=="ending":
			await view.present_championship_victory()
			var crowd=view.actors.get_node("ChampionshipVictory")
			# Heleana, Assis, Tyler, Grampo with Platyx, Jamile and the title ribbon (F28).
			for cast in ["Grampo","Platyx","Jamile","TitleRibbon"]:check(crowd.has_node(cast),"ending staging has "+cast)
			check(crowd.get_child_count()==7,"supporters, Jamile and the ribbon at ending (got "+str(crowd.get_child_count())+")")
			var jamile: Node2D=crowd.get_node("Jamile")
			check(jamile.get_meta("ground_point").distance_to(view.player)<=1.01,"Jamile stands beside Kael")
			check(crowd.get_node("TitleRibbon").position.distance_to(view.model.project(view.player))<60,"ribbon ends at Kael's reel")
			await view.present_championship_victory()
			check(view.actors.get_node("ChampionshipVictory")==crowd,"ending staging is idempotent")
		else:
			view.stage_endgame(id)
			var staging=view.actors.get_node("EndgameStaging")
			check(staging.get_child_count()==(4 if id=="gerador" else 2),"cast present: "+id)
			for first in staging.get_children():
				for second in staging.get_children():
					if first!=second:check(first.position.distance_to(second.position)>=79,"cast separation")
			view.reduced_motion=false
			if id=="gollia-arrependimento":
				await view.animate_gollia_entrance()
				for npc in view.npc_nodes:
					if npc.point==Story.point(scene,Story.STEPS[id].anchor):
						check(npc.visual.position.length()<1,"Gollia returns to anchor")
			if id=="gerador":
				var sample:=preload("res://scripts/campaign/wind_release.gd").new()
				view.actors.add_child(sample)
				var tower: Node2D=view.actors.get_node("WindTower")
				check(not tower.active,"tower starts dormant")
				for cell in [Vector2(29.5,6.5),Vector2(30.5,6.5)]:
					check(not view.model.point_walkable(cell),"tower base is on blocked rock")
					check(is_equal_approx(view.model.height_at(cell),7.0),"tower has continuous support")
				check(not view.model.path_to(view.player,Vector2(24.5,10.5)).is_empty(),"summit route remains open")
				var target: Vector2=tower.receptor_position()
				sample.configure(view,staging,target)
				check(sample.get_child_count()==5,"four sources and one convergence")
				for index in 4:
					var stream: Line2D=sample.get_child(index)
					check(stream.points[0].distance_to(staging.get_child(index).position+Vector2(0,-48))<.01,"wind starts at its creature")
					check(stream.points[-1].distance_to(target)<.01,"wind reaches tower anchor")
				if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
					view.exploration_hud.hide()
					view.camera.position=view.model.project(view.player).lerp(target,.4)
					view.camera.zoom=Vector2.ONE
					await RenderingServer.frame_post_draw
					var folder:=ProjectSettings.globalize_path("res://../tmp/wind-review")
					DirAccess.make_dir_recursive_absolute(folder)
					root.get_texture().get_image().save_png(folder.path_join("convergencia.png"))
				sample.queue_free()
				await process_frame
			var before_camera: Vector2=view.camera.position
			await view.finish_endgame_scene(id)
			if id=="gerador":check(view.camera.position.distance_to(before_camera)<.01,"camera restores after activation")
			if id=="gerador":
				view.reduced_motion=true
				await view.finish_endgame_scene(id)
			await process_frame
			check(view.actors.get_node_or_null("WindRelease")==null,"wind effect cleaned")
			if id=="gerador":
				var tower: Node2D=view.actors.get_node("WindTower")
				check(tower.active and tower.reduced_motion,"tower remains active without rotation after reduced presentation")
				var saved: Dictionary=view.saved_player.duplicate(true)
				saved.flags.geradorLigado=true
				view.refresh(saved)
				check(tower.active,"refresh preserves the saved activation")
				saved.flags.geradorLigado=false
				view.refresh(saved)
				check(not tower.active,"refresh restores dormant state")
			view.clear_endgame_staging()
			await process_frame
			check(view.actors.get_node_or_null("EndgameStaging")==null,"staging cleaned")
		view.queue_free()
		await process_frame
	print("Endgame staging: ",failures.size()," failures")
	quit(int(not failures.is_empty()))
