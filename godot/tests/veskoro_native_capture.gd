extends SceneTree
## Capture naturally occurring phases from the real battle controller, no result injection.
var captured:Dictionary={}
func _initialize()->void:call_deferred("run")
func run()->void:
	preload("res://scripts/campaign/controls.gd").install()
	root.size=Vector2i(1280,720)
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	var partner:Dictionary={"id":"r","modelId":"rabbito","xp":load("res://scripts/campaign/partner_levels.gd").xp_for_level(27)}
	var model=load("res://scripts/campaign/morro_model.gd").new(partner,"palafitas-5")
	var view=load("res://scripts/campaign/morro_battle_view.gd").new()
	view.configure(content,model.snapshot());view.reduced_motion=true
	view.reward_player={"partners":[partner],"equippedPartnerId":"r","tamerXp":0}
	root.add_child(view)
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/veskoro-battle-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	for i in 12000:
		await process_frame
		var v:Dictionary=view.model.veskoro
		var key:=""
		if v.phase=="warn" and v.elapsed>.6:key="jato-aviso" if int(v.cycle)==1 else "nuvem-aviso"
		elif v.phase=="active" and v.elapsed>.1:key="jato-impacto" if int(v.cycle)==1 else "nuvem-impacto"
		elif v.phase=="recover" and v.elapsed>.4:key="recuperacao"
		if key.is_empty() or captured.has(key):continue
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(folder+"/"+key+".png")==OK)
		captured[key]=true
		if captured.size()==5:break
	print("VESKORO NATIVE: ",captured.keys()," art=",view.art_ids," facing=",view.model.enemy_model_id," position=",Vector2(view.model.q.x,view.model.q.y))
	assert(captured.size()==5,"Five natural phases required")
	view.queue_free();await process_frame
	quit()
