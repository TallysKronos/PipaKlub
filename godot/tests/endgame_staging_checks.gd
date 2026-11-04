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
			check(crowd.get_child_count()==3,"three supporters at ending")
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
			await view.finish_endgame_scene(id)
			await process_frame
			check(view.actors.get_node_or_null("WindRelease")==null,"wind effect cleaned")
			view.clear_endgame_staging()
			await process_frame
			check(view.actors.get_node_or_null("EndgameStaging")==null,"staging cleaned")
		view.queue_free()
		await process_frame
	print("Endgame staging: ",failures.size()," failures")
	quit(int(not failures.is_empty()))
