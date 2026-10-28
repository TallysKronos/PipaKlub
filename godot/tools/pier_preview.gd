extends SceneTree
var scene: Node2D
var output: String

func _initialize() -> void:call_deferred("start")

func capture(name_value: String) -> void:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func review_route(id: String,origin: Vector2,targets: Array) -> Dictionary:
 scene.place_probe(id,origin)
 var observations := []
 var transitions: Array[String] = [id]
 for target: Vector2 in targets:
  for i in range(2000):
   var delta: Vector2 = target-scene.probe_cell
   if delta.length()<.015:break
   scene.move_probe(delta.normalized()*minf(delta.length(),.04))
   if transitions.back()!=scene.active_surface:transitions.append(scene.active_surface)
  observations.append({"target":[target.x,target.y],"position":[scene.probe_cell.x,scene.probe_cell.y],"surface":scene.active_surface,"arrived":scene.probe_cell.distance_to(target)<.02})
 return {"transitions":transitions,"observations":observations}

func start() -> void:
 root.size = Vector2i(1280,960)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/cais-v1")
 DirAccess.make_dir_recursive_absolute(output)
 scene = load("res://scenes/overworld/pier/cais-dos-elos.tscn").instantiate()
 scene.position = Vector2(600,400)
 root.add_child(scene)
 await capture("cais-1280x960")
 var complete := scene
 root.remove_child(complete)
 var geometry: Node2D = load("res://scenes/overworld/pier/cais-dos-elos.tscn").instantiate()
 geometry.geometry_only = true
 geometry.decorate = false
 geometry.position = complete.position
 root.add_child(geometry)
 scene = geometry
 await capture("geometria-1280x960")
 root.remove_child(geometry)
 geometry.free()
 root.add_child(complete)
 scene = complete
 root.size = Vector2i(1280,720)
 scene.scale = Vector2.ONE*.75
 scene.position = Vector2(640,305)
 await capture("cais-1280x720")
 scene.scale = Vector2.ONE*1.6
 scene.position = Vector2(640,550)-scene.iso(Vector2(7.8,10),96)*1.6
 await capture("escada-central-1280x720")
 scene.position = Vector2(640,520)-scene.iso(Vector2(15,10.5),36)*1.6
 await capture("escada-praia-1280x720")
 scene.position = Vector2(640,410)-scene.iso(Vector2(7,-.5),192)*1.3
 scene.scale = Vector2.ONE*1.3
 await capture("torre-1280x720")
 scene.scale = Vector2.ONE*2
 scene.position = Vector2(640,400)-scene.iso(Vector2(1,6),192)*2
 await capture("escadas-rocha-1280x720")
 scene.scale = Vector2.ONE*3
 scene.position = Vector2(640,520)-scene.iso(Vector2(2.1,4.2),112)*3
 await capture("coqueiros-apoio-1280x720")
 scene.scale = Vector2.ONE*1.2
 scene.position = Vector2(640,440)-scene.iso(Vector2(8.5,8.5),96)*1.2
 scene.place_probe("underpass",Vector2(8.5,8.5))
 await capture("passagem-inferior-1280x720")
 var full := scene
 root.remove_child(full)
 var cutaway: Node2D = load("res://scenes/overworld/pier/cais-dos-elos.tscn").instantiate()
 cutaway.cutaway_surfaces.append("upper_hub")
 cutaway.position = full.position
 cutaway.scale = full.scale
 root.add_child(cutaway)
 scene = cutaway
 scene.place_probe("underpass",Vector2(8.5,8.5))
 await capture("passagem-inferior-sem-deck-1280x720")
 root.remove_child(cutaway)
 cutaway.free()
 root.add_child(full)
 scene = full
 scene.place_probe("upper_hub",Vector2(8.5,8.5))
 await capture("passagem-superior-1280x720")
 scene.probe.visible = false
 scene.scale = Vector2.ONE*.75
 scene.position = Vector2(640,305)
 var route := review_route("terminal",Vector2(8.5,22.5),[Vector2(8.5,21.5),Vector2(8.5,18.5),Vector2(6,18.5),Vector2(6,17.5),Vector2(6,15.9),Vector2(6,14),Vector2(7.75,13.6),Vector2(7.75,11.7),Vector2(7.75,10),Vector2(7.75,8),Vector2(7.2,8),Vector2(7.2,5.9),Vector2(7.2,2.1),Vector2(7.5,2.1),Vector2(7.5,1),Vector2(7.5,-.5)])
 var beach_route := review_route("lower_hub",Vector2(10,11.5),[Vector2(10,10.5),Vector2(12.5,10.5),Vector2(15,10.5),Vector2(17,10.5)])
 var return_route := review_route("tower_floor",Vector2(7.5,-.5),[Vector2(7.5,2.1),Vector2(7.2,2.1),Vector2(7.2,5.9),Vector2(7.2,8),Vector2(7.75,8),Vector2(7.75,11.7),Vector2(7.75,13.6),Vector2(6,14),Vector2(6,17.5),Vector2(6,18.5),Vector2(8.5,18.5),Vector2(8.5,22.5)])
 var underpass_route := review_route("lower_hub",Vector2(8.5,11.5),[Vector2(8.5,10.5),Vector2(8.5,8.5),Vector2(8.5,10.5),Vector2(8.5,11.5)])
 var audit_file := FileAccess.open(output.path_join("percurso-da-sonda.json"),FileAccess.WRITE)
 audit_file.store_string(JSON.stringify({"dockToTower":route,"beach":beach_route,"towerToDock":return_route,"underpass":underpass_route,"scope":"isolated movement and support probe, not campaign/player gameplay"},"  "))
 scene.probe.visible = false
 var manifest := {"surfaces":scene.surfaces,"projection":[64,32],"reference":"user pier image","campaignIntegrated":false,"orderingReview":scene.ordering_review,"corrections":{"ladderPositions":[[-.60,5.6],[1.30,6.4]],"ladderRockMounts":[-1,1],"towerBaseRug":[8.8,-1.3,9.7,-.3],"towerNearbyPalmsRemoved":true,"postsUseHighestLowerSupport":true}}
 var file := FileAccess.open(output.path_join("layout.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(manifest,"  "))
 print("Pier: native geometry, eight surface elevations, stairs, layered decks and inspection probe captured. No campaign loaded.")
 if "--live" in OS.get_cmdline_user_args():
  scene.place_probe("terminal",Vector2(8.5,22.5))
  return
 quit()
