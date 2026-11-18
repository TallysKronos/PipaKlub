extends SceneTree
func _initialize():
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	assert(doc.append_from_file(OS.get_cmdline_user_args()[0],state)==OK)
	var model = doc.generate_scene(state)
	root.add_child(model)
	var anim = model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	var rig = model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
	for clip in ["Idle","Alerta"]:
		assert(anim.has_animation(clip))
		anim.play(clip); anim.advance(0)
		var id = rig.find_bone("orelha_E")
		var rest=rig.get_bone_pose_rotation(id)
		anim.advance(.9)
		assert(rest.angle_to(rig.get_bone_pose_rotation(id))>.012)
		print(clip," OK")
	print("RABBITO_OK ",rig.get_bone_count())
	quit()
