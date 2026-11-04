extends SceneTree
var scene: Node2D
var output: String

func _initialize() -> void:call_deferred("start")

func capture(name_value: String) -> void:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/rua-japonesa-v1")
 DirAccess.make_dir_recursive_absolute(output)
 var bg := ColorRect.new()
 bg.size = Vector2(1280,720)
 bg.color = Color("C5CCC4")
 root.add_child(bg)
 var title := Label.new()
 title.position = Vector2(32,20)
 title.text = "RUA DAS RABIOLAS · passeio, guias e drenagem"
 title.add_theme_color_override("font_color",Color("34434B"))
 title.add_theme_font_size_override("font_size",28)
 root.add_child(title)
 scene = load("res://scenes/overworld/street/rua-das-rabiolas.tscn").instantiate()
 scene.position = Vector2(640,185)
 root.add_child(scene)
 var fabrics: Array[Node] = []
 for support in scene.props.get_children():
  for child in support.get_children():
   if child.has_method("update_cloth"):
    child.set_process(false)
    fabrics.append(child)
 await capture("rua-1280x720")
 scene.props.visible = false
 await capture("passeio-sem-fachadas-1280x720")
 var complete := scene
 var geometry: Node2D = load("res://scenes/overworld/street/rua-das-rabiolas.tscn").instantiate()
 geometry.position = scene.position
 geometry.show_geometry = true
 root.remove_child(complete)
 root.add_child(geometry)
 scene = geometry
 await capture("geometria-1280x720")
 root.remove_child(geometry)
 geometry.free()
 root.add_child(complete)
 scene = complete
 scene.props.visible = true
 scene.scale = Vector2.ONE*2.0
 scene.position = Vector2(640,610)-scene.iso(Vector2(13,5.4),10)*2.0
 await capture("casa-apoio-1280x720")
 scene.position = Vector2(640,610)-scene.iso(Vector2(3.5,5.2),10)*2.0
 await capture("loja-apoio-1280x720")
 DirAccess.make_dir_recursive_absolute(output.path_join("toldo-frames"))
 for frame in range(32):
  for fabric in fabrics:
   fabric.cloth_phase = TAU*float(frame)/32.0
   fabric.update_cloth()
  await capture("toldo-frames/toldo-%02d"%frame)
 for fabric in fabrics:
  fabric.cloth_phase = 0
  fabric.update_cloth()
  fabric.set_process(true)
 scene.scale = Vector2.ONE
 scene.position = Vector2(640,185)
 print("Street: saved scene, 5 native 1280x720 views including both native building foundations. No campaign loaded.")
 if "--live" in OS.get_cmdline_user_args():return
 quit()
