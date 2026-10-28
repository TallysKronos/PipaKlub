extends "res://tools/cave_readability_preview.gd"

func start() -> void:
 root.size = Vector2i(1280,720)
 output = ProjectSettings.globalize_path("res://../documentation/overworld/cavernas-v3/ventos")
 DirAccess.make_dir_recursive_absolute(output+"/frames")
 for variant in ["gruta-seca-ventos","gruta-ventos"]:
  page("GRUTA DOS ELOS · o vento encontra a saída")
  var scene: Node2D = load("res://scenes/overworld/caves-v3/"+variant+".tscn").instantiate()
  scene.position = Vector2(640,245)
  stage.add_child(scene)
  animated.append(scene)
  label("Flores enraizadas · rabiola presa à coluna · corrente rumo à saída",Vector2(24,650),21)
  await capture(variant+"-1280x720",2.0)
  if variant == "gruta-ventos":
   if "--still" not in OS.get_cmdline_user_args():
    for i in range(96):await capture("frames/vento-%02d"%i,float(i)/12.0)
   await capture("loop-final",8.0)
   scene.reduced_motion = true
   await capture("movimento-reduzido-1280x720",2.0)
   scene.reduced_motion = false
   if "--live" in OS.get_cmdline_user_args():
    scene.set_animation_time(-1.0)
    return
 print("Wind gallery: 2 saved scenes, 96 frames, pinned roots and reduced-motion capture. No campaign loaded.")
 quit()
