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
 output = ProjectSettings.globalize_path("res://../documentation/overworld/submerso-v1")
 DirAccess.make_dir_recursive_absolute(output+"/frames")
 var bg := Polygon2D.new()
 bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
 bg.vertex_colors = PackedColorArray([Color("194F60"),Color("194F60"),Color("102B42"),Color("102B42")])
 root.add_child(bg)
 var title := Label.new()
 title.position = Vector2(32,20)
 title.text = "JARDIM DAS MARÉS · sob a superfície"
 title.add_theme_color_override("font_color",Color("C5E0CD"))
 title.add_theme_font_size_override("font_size",28)
 root.add_child(title)
 scene = load("res://scenes/overworld/underwater/jardim-das-mares.tscn").instantiate()
 scene.position = Vector2(600,205)
 root.add_child(scene)
 await capture("submerso-1280x720",2.0)
 scene.props.visible = false
 await capture("sem-objetos-1280x720",2.0)
 scene.ground_material.set_shader_parameter("show_masks",true)
 await capture("mascaras-1280x720",2.0)
 scene.ground_material.set_shader_parameter("show_masks",false)
 scene.effects_enabled = false
 await capture("juntas-sem-efeitos-1280x720",2.0)
 scene.props.visible = true
 scene.effects_enabled = false
 await capture("sem-efeitos-1280x720",2.0)
 scene.effects_enabled = true
 scene.reduced_motion = true
 await capture("movimento-reduzido-1280x720",2.0)
 scene.reduced_motion = false
 if "--still" not in OS.get_cmdline_user_args():
  for i in range(96):await capture("frames/submerso-%02d"%i,float(i)/12.0)
 await capture("loop-final",8.0)
 var complete := scene
 var geometry: Node2D = load("res://scenes/overworld/underwater/jardim-das-mares.tscn").instantiate()
 geometry.position = complete.position
 geometry.show_geometry = true
 geometry.effects_enabled = false
 geometry.reduced_motion = true
 root.remove_child(complete)
 root.add_child(geometry)
 scene = geometry
 scene.props.visible = false
 await capture("geometria-relevo-1280x720")
 var file := FileAccess.open(output+"/relevo/geometria.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"levelsPx":[32,0,-24],"upperRamp":{"risePx":32,"runCells":3},"lowerRamp":{"dropPx":24,"runCells":2.5},"propsUseMeasuredHeight":true,"campaignIntegrated":false},"  "))
 root.remove_child(geometry)
 geometry.free()
 root.add_child(complete)
 scene = complete
 print("Underwater: native 1280x720, pinned plants, 96 frames, masks and effects-disabled captures. No campaign loaded.")
 if "--live" in OS.get_cmdline_user_args():
  scene.set_animation_time(-1.0)
  return
 quit()
