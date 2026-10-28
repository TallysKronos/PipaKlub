extends SceneTree
var scene: Node2D
var output: String

func _initialize() -> void:call_deferred("start")

func capture(name_value: String,time_value: float=0.0) -> void:
 scene.set_animation_time(time_value)
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/lava-v1")
 DirAccess.make_dir_recursive_absolute(output+"/frames")
 var bg := ColorRect.new()
 bg.size = Vector2(1280,720)
 bg.color = Color("191D2B")
 root.add_child(bg)
 var title := Label.new()
 title.position = Vector2(32,20)
 title.text = "RIO DE BRASA · basalto, crosta e lava"
 title.add_theme_color_override("font_color",Color("F1D3A0"))
 title.add_theme_font_size_override("font_size",28)
 root.add_child(title)
 scene = load("res://scenes/overworld/lava/rio-de-brasa.tscn").instantiate()
 scene.position = Vector2(600,170)
 root.add_child(scene)
 await capture("lava-1280x720")
 scene.props.visible = false
 await capture("sem-objetos-1280x720")
 scene.props.visible = true
 if "--still" not in OS.get_cmdline_user_args():
  for i in range(96):await capture("frames/lava-%02d"%i,float(i)/12.0)
 await capture("loop-final",8.0)
 scene.reduced_motion = true
 await capture("movimento-reduzido-1280x720",2.0)
 scene.reduced_motion = false
 if "--live" in OS.get_cmdline_user_args():
  scene.set_animation_time(-1.0)
  return
 var geometry: Node2D = load("res://scenes/overworld/lava/rio-de-brasa.tscn").instantiate()
 geometry.position = scene.position
 geometry.show_geometry = true
 root.remove_child(scene)
 scene.free()
 scene = geometry
 root.add_child(scene)
 await capture("geometria-1280x720")
 var file := FileAccess.open(output+"/geometria.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"topHeightPx":0,"lavaHeightPx":-scene.depth_px,"sharedContourPoints":scene.contour.size(),"upperGroundPieces":scene.floor_piece_count,"openOutlets":2,"campaignIntegrated":false},"  "))
 print("Lava: native 1280x720, shared measured contour, two ground banks, 96 frames. No campaign loaded.")
 quit()
