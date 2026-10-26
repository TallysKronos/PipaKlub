extends SceneTree
const View = preload("res://scripts/overworld/view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280,720)
	var folder := "escadas-encaixes" if "--stairs" in OS.get_cmdline_user_args() else "muros-morro"
	if "--stairwell" in OS.get_cmdline_user_args(): folder = "escada-abertura"
	var destination := ProjectSettings.globalize_path("res://../documentation/overworld/"+folder+"/after")
	DirAccess.make_dir_recursive_absolute(destination)
	var view := View.new()
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	var records: Array = []
	for area in ["morro-praca-da-chegada","morro-escadaria-da-sombra","morro-parque-dos-ventos"]:
		view.load_area(area)
		view.set_physics_process(false)
		view.camera.position_smoothing_enabled = false
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(destination.path_join(area+"-1280x720.png"))
		records.append({"area":area,"size":[1280,720],"retainingFaces":view.model.data.cliffs.size(),"finishComponents":view.get_meta("wall_finish_components",[]),"stairBevels":view.stair_bevels.size(),"scope":"art preview, no saves or navigation changes"})
		if area == "morro-praca-da-chegada":
			var nearest: Dictionary = {}
			var distance := INF
			for face in view.model.data.cliffs:
				var d: float = view.player.distance_to(Vector2(face.u+1,face.v+1))
				if d < distance:
					distance = d
					nearest = face
			if not nearest.is_empty():
				view.camera.position = view.model.project(Vector2(nearest.u+1,nearest.v+1),false)-Vector2(0,(nearest.top+nearest.bottom)*32)
				view.camera.zoom = Vector2(1.7,1.7)
				for frame in 8: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(destination.path_join("muros-detalhe-1280x720.png"))
				if folder in ["escadas-encaixes","escada-abertura"]:
					var old_player := view.player
					view.player = Vector2(12.95,4.5)
					view._refresh_positions()
					view.camera.position = view.model.project(Vector2(nearest.u+1,nearest.v+1),false)-Vector2(0,(nearest.top+nearest.bottom)*32)
					for frame in 8: await process_frame
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(destination.path_join("kael-na-escada-1280x720.png"))
					view.player = old_player
					if folder == "escada-abertura":
						var framing := view.camera.position
						view.player = Vector2(12.5,5.5)
						view.follower = Vector2(13.5,5.5)
						for target: Vector2 in [Vector2(12.5,3.5),Vector2(12.5,5.5)]:
							var accepted: bool = view.walk_to(target)
							for tick in 100:
								view._physics_process(1.0/60)
								view.camera.position = framing
								if tick in [20,40,60,99]:
									await process_frame
									await RenderingServer.frame_post_draw
									root.get_texture().get_image().save_png(destination.path_join(("subida" if target.y<4 else "descida")+"-"+str(tick)+".png"))
							var arrived: bool = view.player.distance_to(target)<.05
							records.append({"target":[target.x,target.y],"pathAccepted":accepted,"arrived":arrived,"follower":[view.follower.x,view.follower.y]})
							assert(accepted and arrived,"Stair passage failed")
						var originals: Array = []
						for item in view.terrain.find_children("*","Polygon2D",true,false):
							originals.append([item,item.texture,item.material,item.vertex_colors,item.color])
							item.texture = null
							item.material = null
							item.vertex_colors = PackedColorArray()
							var kind: String = item.get_meta("stair_face","")
							item.color = Color("E1E4DC") if kind == "tread" else Color("41534A") if kind == "cheek" else Color("A7B0A2") if item.polygon.size()==4 and absf(item.polygon[0].y-item.polygon[3].y)>20 else Color("C5CCBC")
						for frame in 3: await process_frame
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png(destination.path_join("geometria-sem-texturas-1280x720.png"))
						for record in originals:
							record[0].texture=record[1];record[0].material=record[2];record[0].vertex_colors=record[3];record[0].color=record[4]
	var output := FileAccess.open(destination.path_join("capture.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(records,"\t"))
	if folder == "escadas-encaixes":
		view.hide()
		view.interface.hide()
		view.camera.enabled = false
		for direction in ["u+","u-","v+","v-"]:
			var stage := Node2D.new()
			root.add_child(stage)
			view.actors = stage
			var footprint := Vector2i(1,2) if direction.begins_with("u") else Vector2i(2,1)
			view._draw_stone_stairs(Vector2i.ZERO,footprint,{"ramp":direction,"level":0})
			var camera := Camera2D.new()
			camera.position = Vector2((footprint.x-footprint.y)*16,-8)
			camera.zoom = Vector2(3,3)
			stage.add_child(camera)
			RenderingServer.set_default_clear_color(Color("314B3C"))
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(destination.path_join("escada-"+direction+"-1280x720.png"))
			stage.free()
	view.free()
	print("MORRO WALL CAPTURES: 3 areas + retaining-wall detail at 1280x720")
	quit()
