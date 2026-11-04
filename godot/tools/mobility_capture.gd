extends SceneTree
const View=preload("res://scripts/overworld/mobility_preview.gd")
const OUT="res://../documentation/overworld/encosta-mobilidade/captures/"
var view:Node2D
func _initialize() -> void:call_deferred("run")
func shot(name:String,at:Vector2,zoom:float) -> void:
	view.camera.position=view.model.project(at);view.camera.zoom=Vector2.ONE*zoom
	view.camera.reset_smoothing();view.camera.force_update_scroll()
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	root.size=Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	view=View.new();root.add_child(view);view.set_physics_process(false)
	view.interface.hide();view.hide_characters()
	for style in ["geometria","arte"]:
		OS.set_environment("KRONASTA_GEOMETRIA","1" if style=="geometria" else "0")
		view.load_area(view.area_id);view.hide_characters()
		await shot(style+"-geral",Vector2(15,13),.65)
		for p in [["chegada",10,21],["salto",17,12],["mirante",9,7],["retorno",22,18]]:
			await shot(style+"-jogo-"+p[0],Vector2(p[1],p[2]),1)
		for p in [["rampa1-topo",11,17],["rampa1-pe",11,21],["rampa2-topo",12,7],["rampa2-pe",16,7],["rampa3-topo",23,17],["rampa3-pe",23,21],["salto-oeste",15.5,12.5],["salto-leste",18.5,12.5],["descida",20.5,17.5],["canto-1",4,4],["canto-2",12,4],["canto-3",12,10],["canto-4",4,10],["canto-5",16,11],["canto-6",18,11],["canto-7",16,17],["canto-8",18,17],["canto-9",27,17],["canto-10",4,17]]:
			await shot(style+"-detalhe-"+p[0],Vector2(p[1],p[2]),2.2)
		if style=="arte":
			# Additional diagnostic: keep textured terrain but remove foreground canopies.
			for node in view.occluders:node.hide()
			await shot("arte-diagnostico-canto9-sem-copas",Vector2(27,17),2.2)
			await shot("arte-diagnostico-rampa3-sem-copas",Vector2(23,21),2.2)
			for node in view.occluders:node.show()
	view.player_root.show();view.follower_root.show()
	var link:Dictionary=view.model.data.mobility.links[0]
	var a:Vector2=view.Traversal.point(link.from)
	view.player=a;view.follower=a
	view.traversal.begin(view.model,link,a)
	for p in [["preparo",.07],["salto",.40],["pouso",.76],["parceiro",.96]]:
		view.traversal.elapsed=p[1];view._render_traversal();view.marks.queue_redraw()
		await shot("movimento-"+p[0],Vector2(17,12.5),1.6)
	view.recover();view.interface.show();view.notice_until=0;view._update_hint()
	await shot("arte-jogavel",Vector2(17,12.5),1)
	view.free();print("MOBILITY CAPTURES: 55 native frames saved");quit()
