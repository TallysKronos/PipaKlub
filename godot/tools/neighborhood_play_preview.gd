extends SceneTree
var play: Node2D
var output := "res://../documentation/overworld/bairro-inicial-v2/jogavel"
var observations: Array=[]
func _initialize() -> void:call_deferred("start")
func capture(id: String) -> void:
	play._refresh_visuals();play._update_hint()
	play.camera.position=play.player_root.position-Vector2(0,45)
	play.camera.reset_smoothing()
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output.path_join(id+".png")))
func travel(target: Vector2) -> void:
	for i in range(6000):
		if play.cell.distance_to(target)<.02:break
		var before: Vector2=play.cell
		play.walk((target-play.cell).normalized()*minf(.025,play.cell.distance_to(target)))
		if play.cell.distance_to(before)<.00001:break
	observations.append({"target":[target.x,target.y],"position":[play.cell.x,play.cell.y],"height":play.elevation,"surface":play.surface,"arrived":play.cell.distance_to(target)<.03})
func talk() -> void:
	play.interact()
	if not play.conversation.is_empty():await capture("dialogo-"+str(play.near_person.get("id","casa")))
	play.interact()
func start() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	play=load("res://scenes/overworld/neighborhood/bairro-jogavel.tscn").instantiate()
	if not play.has_method("walk"):quit(1);return
	root.add_child(play);current_scene=play
	await capture("01-casa-kael")
	for p in [Vector2(4.4,19.5),Vector2(6.3,19.7)]:travel(p)
	await talk()
	for p in [Vector2(12.1,19.1),Vector2(12.1,9.5)]:travel(p)
	await capture("02-ladeira")
	for p in [Vector2(12.1,6.5),Vector2(9.5,6.5),Vector2(9.5,.5),Vector2(4.9,.5),Vector2(4.9,-.65),Vector2(5.9,-.65)]:travel(p)
	await talk()
	await capture("03-professor")
	for p in [Vector2(4.9,-.65),Vector2(4.9,.5),Vector2(25.9,.5)]:travel(p)
	await talk()
	await capture("04-lojinha")
	for p in [Vector2(20.5,.5),Vector2(20.5,6.5),Vector2(18.4,6.5),Vector2(18.4,18.7),Vector2(22,18.5)]:travel(p)
	await talk()
	await capture("05-pracinha")
	for p in [Vector2(18.4,18.7),Vector2(18.4,17),Vector2(11.5,17),Vector2(10.5,19.3),Vector2(6.3,19.0),Vector2(4.4,19.5),Vector2(4.4,17.4)]:travel(p)
	await capture("06-retorno")
	for p in [Vector2(4.4,17.4),Vector2(8.1,17.4),Vector2(10.1,13),Vector2(10.3,11.5),Vector2(8.7,11.5),Vector2(8.7,8.5),Vector2(8.7,6.5)]:travel(p)
	await capture("07-escadaria-atalho")
	FileAccess.open(output.path_join("percurso.json"),FileAccess.WRITE).store_string(JSON.stringify({"observations":observations,"greeted":play.greeted,"campaignIntegrated":false},"  "))
	print("Neighborhood walkthrough recorded: "+str(observations.size())+" points, greeted "+str(play.greeted))
	quit()
