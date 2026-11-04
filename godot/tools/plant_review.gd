extends SceneTree
const View = preload("res://scripts/overworld/view.gd")
var records: Array = []
var failures: Array = []

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	root.size=Vector2i(1280,720)
	var out:=ProjectSettings.globalize_path("res://../documentation/overworld/pip81/captures")
	DirAccess.make_dir_recursive_absolute(out)
	var index: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/index.json"))
	var view:=View.new()
	root.add_child(view)
	view.set_physics_process(false)
	for area in index.areas:
		if area.id=="veredas-piloto":continue
		view.art_preview=false
		view.load_area(area.id)
		view.set_physics_process(false)
		view.camera.position_smoothing_enabled=false
		var labels:=Node2D.new()
		view.add_child(labels)
		for event in view.model.data.events:
			var marker:=Label.new()
			marker.text=event.name+" (%d,%d)"%[event.u,event.v]
			marker.add_theme_font_size_override("font_size",11)
			marker.add_theme_color_override("font_outline_color",Color("15202B"))
			marker.add_theme_constant_override("outline_size",4)
			marker.position=view.model.project(Vector2(event.u+.5,event.v+.5))-Vector2(20,36)
			labels.add_child(marker)
		var w:float=view.model.data.w
		var h:float=view.model.data.h
		view.camera.zoom=Vector2.ONE*minf(1160/((w+h)*32+80),530/((w+h)*16+180))
		view.camera.position=Vector2((w-h)*16,(w+h)*8-50)
		view.hint.text="Planta PIP-81 · entradas, saídas, NPCs e desníveis"
		await settle()
		root.get_texture().get_image().save_png(out.path_join(area.id+"-planta-1280x720.png"))
		labels.free()
		var targets: Array=view.interaction_events.duplicate(true)
		var visits: Array=[]
		for event in targets:
			if event.type=="entrada":continue
			var best:=PackedVector2Array()
			for delta: Vector2 in [Vector2.ZERO,Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]:
				var route: PackedVector2Array=view.model.path_to(view.player,Vector2(event.u+.5,event.v+.5)+delta)
				if not route.is_empty() and (best.is_empty() or route.size()<best.size()):best=route
			var arrived:=false
			if not best.is_empty():
				var target:Vector2=best[-1]
				view.walk_to(target)
				for tick in (best.size()+4)*30:
					view._physics_process(1.0/30)
					if view.player.distance_to(target)<.03:arrived=true;break
				# Let the real follower finish each approach, without teleporting.
				for tick in 120:view._physics_process(1.0/30)
			if not arrived:failures.append(area.id+": "+event.name)
			visits.append({"name":event.name,"type":event.type,"arrived":arrived,"followerDistance":view.follower.distance_to(view.player)})
			if event.name.begins_with("Casa") or event.name=="Loja de pipas" or event.name=="Nina" or event.name.begins_with("Lacertubo"):
				await settle()
				root.get_texture().get_image().save_png(out.path_join(area.id+"-evento-"+str(event.id)+".png"))
		view.art_preview=true
		view.load_area(area.id)
		view.set_physics_process(false)
		view.camera.position_smoothing_enabled=false
		view.hint.text="Prévia PIP-88 · arte dos biomas ainda em revisão"
		await settle()
		root.get_texture().get_image().save_png(out.path_join(area.id+"-previa-1280x720.png"))
		records.append({"area":area.id,"visits":visits,"size":[1280,720]})
	var file:=FileAccess.open(out.path_join("movement.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"areas":records,"failures":failures,"scope":"isolated preview; no rewards or saves; real movement with simulated 1/30s ticks"},"\t"))
	print("PLANT REVIEW: ",records.size()," areas; movement failures: ",failures.size())
	view.free()
	quit(0 if failures.is_empty() else 1)
