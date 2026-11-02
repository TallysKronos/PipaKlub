extends SceneTree
## Real authored preview positions, no temporary gallery events or campaign writes.
func _initialize()->void:call_deferred("capture")
func capture()->void:
	root.size=Vector2i(1280,720)
	var mode:="geometria" if OS.get_environment("KRONASTA_GEOMETRIA")=="1" else "arte"
	var output:=ProjectSettings.globalize_path("res://../documentation/qa/vila-operaria-encontros/"+mode)
	DirAccess.make_dir_recursive_absolute(output)
	var shots:=0
	for part:String in ["a","b","c"]:
		var view:Node2D=load("res://scripts/overworld/view.gd").new()
		view.area_id="kronasta-industrial-"+part;view.art_preview=true
		root.add_child(view);await process_frame
		view.set_physics_process(false);view.interface.hide();view.player_root.hide();view.follower_root.hide()
		view.camera.position_smoothing_enabled=false
		var plan:Array[Dictionary]=[{"name":part+"-geral","point":Vector2(24,20),"zoom":.36},{"name":part+"-entrada","point":view.player,"zoom":1.0}]
		for event:Dictionary in view.interaction_events:
			if event.props.get("district","")!="industrial":continue
			plan.append({"name":part+"-"+event.name.to_lower().replace(" ","-"),"point":Vector2(event.u+.5,event.v+.5),"zoom":1.0})
			plan.append({"name":part+"-"+event.name.to_lower().replace(" ","-")+"-detalhe","point":Vector2(event.u+.5,event.v+.5),"zoom":2.0})
		for shot in plan:
			view.camera.zoom=Vector2.ONE*float(shot.zoom)
			view.camera.position=view.model.project(shot.point)-Vector2(0,45)
			for frame in 4:await process_frame
			await RenderingServer.frame_post_draw
			if root.get_texture().get_image().save_png(output.path_join(shot.name+".png"))!=OK:quit(1);return
			shots+=1
		view.free();await process_frame
	print("VILA ENCOUNTERS: ",shots," native captures ",mode,"; no save/reward writes")
	quit()
