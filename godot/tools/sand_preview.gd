extends SceneTree
var scene: Node2D
var output: String

func _initialize() -> void:call_deferred("start")

func capture(name_value: String,time: float=0.0) -> void:
 scene.set_animation_time(time)
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/areia-v1")
 DirAccess.make_dir_recursive_absolute(output+"/frames")
 var bg := ColorRect.new()
 bg.size = Vector2(1280,720)
 bg.color = Color("B9C2BD")
 root.add_child(bg)
 var title := Label.new()
 title.position = Vector2(32,20)
 title.text = "AREIAS DO VENTO · dunas baixas e arenito"
 title.add_theme_color_override("font_color",Color("473F3F"))
 title.add_theme_font_size_override("font_size",28)
 root.add_child(title)
 scene = load("res://scenes/overworld/sand/areias-do-vento.tscn").instantiate()
 scene.position = Vector2(600,180)
 root.add_child(scene)
 await capture("areia-1280x720",2.0)
 scene.props.visible = false
 await capture("sem-objetos-1280x720",2.0)
 scene.ground_material.set_shader_parameter("show_masks",true)
 await capture("mascaras-1280x720",2.0)
 scene.ground_material.set_shader_parameter("show_masks",false)
 scene.ground_material.set_shader_parameter("show_geometry",true)
 scene.reduced_motion = true
 await capture("geometria-1280x720")
 scene.ground_material.set_shader_parameter("show_geometry",false)
 scene.props.visible = true
 await capture("movimento-reduzido-1280x720")
 scene.reduced_motion = false
 for i in range(96):await capture("frames/areia-%02d"%i,float(i)/12.0)
 await capture("loop-final",8.0)
 var record := FileAccess.open(output+"/geometria.json",FileAccess.WRITE)
 record.store_string(JSON.stringify({"heightfieldVertices":57*49,"triangles":56*48*2,"maximumHeightPx":scene.measured_max_height,"continuousSurface":true,"propAnchorsUseSameHeight":true,"campaignIntegrated":false},"  "))
 print("Sand: native 1280x720, 3 materials, continuous dunes, 96 ambient frames. No campaign loaded.")
 if "--live" in OS.get_cmdline_user_args():
  scene.set_animation_time(-1.0)
  return
 quit()
