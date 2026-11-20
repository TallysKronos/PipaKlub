extends SceneTree
const Room=preload("res://scripts/campaign/room_view.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const OUT="res://../art/overworld/estilo/loja-piloto-v2/interior/modernizacao/integracao/"

func _initialize()->void:
	run.call_deferred()

func shot(file:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+file+".png")

func run()->void:
	root.size=Vector2i(1280,900)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	RenderingServer.set_default_clear_color(Color("101d2c"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var name:="moderno-v2"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--name="):
			name=arg.trim_prefix("--name=")
	var room:=Room.new()
	root.add_child(room)
	room.configure(D.room(),[D.ENTRY.x,D.ENTRY.y],false,"*",false,true)
	room.set_process(false)
	room.opening_pose()
	room.position=Vector2(80,35)
	await shot(name+"-geral")
	room.avatar.hide()
	room.companion.hide()
	room.get_node("ShopOwner").hide()
	await shot(name+"-sem-atores")
	if "--overview-only" in OS.get_cmdline_user_args():
		room.free()
		quit()
		return
	var views:Dictionary={
		"balcao":Vector2(625,410),"estantes":Vector2(585,270),
		"mesas":Vector2(595,585),"expositores":Vector2(215,340),
		"entrada":Vector2(245,570),"canto":Vector2(500,240),
	}
	for id in views:
		room.scale=Vector2.ONE*2
		room.position=Vector2(640,450)-views[id]*2
		await shot(name+"-detalhe-"+id)
	room.position=Vector2(640,450)-D.project(D.OWNER)*2
	room.get_node("ShopOwner").show()
	await shot(name+"-dono-balcao")
	room.get_node("ShopOwner").hide()
	room.avatar.show()
	room.scale=Vector2.ONE
	for pose in [
		["atras-balcao",D.point(6,2.2)],
		["frente-balcao",D.point(8,5.7)],
		["atras-mesa",D.point(9,6)],
		["frente-mesa",D.point(16.5,10)],
	]:
		room.actor=pose[1]
		room.opening_pose()
		room.position=Vector2(80,35)
		await shot(name+"-oclusao-"+str(pose[0]))
	room.free()
	print("SHOP capture ",name)
	quit()
