extends SceneTree
const Model=preload("res://scripts/campaign/encounter_model.gd")
const Trail=preload("res://scripts/campaign/morro_model.gd")
const View=preload("res://scripts/campaign/encounter_view.gd")
const TrailView=preload("res://scripts/campaign/morro_battle_view.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	Paper.auditing=true
	preload("res://scripts/campaign/controls.gd").install()
	root.content_scale_size=Vector2i.ZERO
	var revision:="pip-133-v2" if "--revision=2" in OS.get_cmdline_user_args() else "pip-133"
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/"+revision+"/capturas")
	DirAccess.make_dir_recursive_absolute(output)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		var filter:=""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--size="):filter=arg.trim_prefix("--size=")
		if not filter.is_empty() and filter!="%dx%d"%[dimensions.x,dimensions.y]:continue
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["duelo","boss","campea","enroscada","boss-intro"]:
				var partner:={"id":"qa","modelId":"rabbito","personalName":"Rabbito","xp":Model.xp_for_level(8)}
				var model=Trail.new(partner,"morro-5") if mode=="campea" else Model.new(partner,{"modelId":"basica","level":5}) if mode in ["duelo","enroscada"] else Model.new(partner)
				model.intro=2.2 if mode in ["campea","boss-intro"] else 0
				if mode=="enroscada":model.p.x=750;model.p.y=200;model.p.vx=120;model.q.x=250;model.q.y=200
				var view=TrailView.new() if mode=="campea" else View.new()
				view.text_scale=scale
				view.reward_player={"name":"Kael","tamerXp":300,"partners":[partner],"equippedPartnerId":"qa"}
				view.reduced_motion=true
				view.configure(content,model.snapshot())
				root.add_child(view);view.set_physics_process(false);view.paused=false;view.launch_age=1;view._physics_process(0)
				for frame in 6:await process_frame
				await RenderingServer.frame_post_draw
				var file:="%dx%d-%s%s.png"%[dimensions.x,dimensions.y,mode,"-150" if scale>1 else ""]
				root.get_texture().get_image().save_png(output.path_join(file))
				var canvases:Array=[view]
				for command in view.move_cards:
					if command.node.visible:canvases.append(command.tile)
				if is_instance_valid(view.duel_intro) and view.duel_intro.visible:canvases.append(view.duel_intro)
				if is_instance_valid(view.boss_intro) and view.boss_intro.visible:canvases.append(view.boss_intro)
				for canvas in canvases:
					var entries:Array=Paper.audit.get(canvas.get_instance_id(),[])
					for item in entries:
						checks+=1
						if item.safe.has_area() and not item.safe.grow(.1).encloses(item.glyphs):
							failures.append(file+" "+item.text+" glyph "+str(item.glyphs)+" safe "+str(item.safe))
							printerr("UNSAFE ",failures.back())
					for i in entries.size():
						for j in range(i+1,entries.size()):
							checks+=1
							if entries[i].glyphs.intersection(entries[j].glyphs).get_area()>.1:
								failures.append(file+" overlap: "+entries[i].text+" / "+entries[j].text)
					Paper.audit.erase(canvas.get_instance_id())
				view.free()
				if "--quick" in OS.get_cmdline_user_args() and mode=="enroscada":break
			if "--quick" in OS.get_cmdline_user_args():break
		if "--quick" in OS.get_cmdline_user_args():break
	var report:={"checks":checks,"failures":failures,"method":"Actual font ascent/descent glyph rectangles, bars and action icons inside content rect excluding fixed corner bleed + 8px clearance. OpenGL native rendering."}
	var suffix:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--size="):suffix="-"+arg.trim_prefix("--size=")
	var report_file:=FileAccess.open("res://../documentation/hud-v2/"+revision+"/padding-audit"+suffix+".json",FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report,"\t"));report_file.close()
	print("PADDING AUDIT: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

