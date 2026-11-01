extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func run() -> void:
	root.size=Vector2i(1280,720)
	var avatar=load("res://scripts/avatar.gd").new();root.add_child(avatar)
	avatar.position=Vector2(640,590);avatar.scale=Vector2.ONE*3.2;avatar.facing="se";avatar.set_mounted(true)
	for i in 8:await process_frame
	var rig:Node2D=avatar.mount_rig
	check(rig.rider.visible and not rig.has_node("RiderSocket/ArticulatedKael"),"game uses complete rider sprite")
	var articulated=load("res://scripts/soulgen_mounted_rider.gd").new();rig.seat.add_child(articulated)
	articulated.scale=Vector2.ONE*rig.definition.riderScale
	rig.rider.hide();rig.far_leg.hide()
	var layer=articulated.front
	check(layer.project.parts.size()==15,"15 independent parts")
	check(layer.textures.atlas.get_size()==Vector2(1262,1246),"actual atlas dimensions")
	check(articulated.back.z_index<rig.body.z_index and layer.z_index>rig.body.z_index,"separate mount depth passes")
	var parts:Dictionary={}
	for p in layer.project.parts:parts[p.id]=p
	layer.clock=0
	var rest:Transform2D=layer.part_matrix(parts["hand-near"],{},parts)
	layer.pose_override={"upper-near":{"rotation":12}}
	var posed:Transform2D=layer.part_matrix(parts["hand-near"],{},parts)
	check(not rest.is_equal_approx(posed),"hand inherits shoulder pose")
	check(layer.part_matrix(parts.head,{},parts).is_equal_approx(Transform2D.IDENTITY),"arm pose never rotates head")
	layer.pose_override={};layer.set_process(false);articulated.back.set_process(false)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var folder:=ProjectSettings.globalize_path("res://../documentation/qa/kael-mounted-rig-v1")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder.path_join("mounted-se.png"))
	for dir in ["s","sw","w","nw","n","ne","e"]:
		rig.set_facing(dir)
		check(rig.rider.texture!=null,"static fallback "+dir)
	rig.set_facing("se")
	check(rig.rider.texture!=null,"SE retains complete sprite")
	print("Mounted rider: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
