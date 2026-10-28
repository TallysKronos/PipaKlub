extends SceneTree
var scene: Node2D
var output: String

func _initialize() -> void: call_deferred("start")

func capture(name_value: String) -> void:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(name_value+".png"))

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/planicie-v1")
 DirAccess.make_dir_recursive_absolute(output)
 var bg := ColorRect.new()
 bg.size = Vector2(1280,720)
 bg.color = Color("D0D4B2")
 root.add_child(bg)
 var title := Label.new()
 title.position = Vector2(32,20)
 title.text = "PLANÍCIE DOS VENTOS · grama, terra e pedra"
 title.add_theme_color_override("font_color",Color("283E39"))
 title.add_theme_font_size_override("font_size",28)
 root.add_child(title)
 scene = load("res://scenes/overworld/plains/planicie-dos-ventos.tscn").instantiate()
 scene.position = Vector2(600,180)
 root.add_child(scene)
 await capture("planicie-1280x720")
 scene.props.visible = false
 await capture("solo-sem-objetos-1280x720")
 scene.ground_material.set_shader_parameter("show_masks",true)
 await capture("mascaras-1280x720")
 scene.ground_material.set_shader_parameter("show_masks",false)
 scene.props.visible = true
 if "--live" in OS.get_cmdline_user_args():return
 print("Plains: saved scene, 3 native 1280x720 views, shared transition shader include. No campaign loaded.")
 quit()
