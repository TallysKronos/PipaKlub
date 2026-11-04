extends SceneTree
func _initialize() -> void:
	var map_id: String=OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "clareira-do-papel"
	var model=load("res://scripts/overworld/map_model.gd").new()
	model.setup(JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/"+map_id+".json")))
	var kit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/kits/parque/kit.json"))
	kit.root="res://assets/overworld/kits/parque/"
	var terrain=load("res://scripts/overworld/clareira_terrain.gd").new()
	var start:=Time.get_ticks_msec()
	terrain.setup(model,kit,true,map_id)
	var manifest_path: String=terrain.BASE+("manifest.json" if map_id=="clareira-do-papel" else map_id+"-manifest.json")
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest_path)) if FileAccess.file_exists(manifest_path) else {"map":map_id,"density":16}
	contract.mapSha256=FileAccess.get_sha256("res://assets/overworld/maps/"+map_id+".json")
	contract.size=[int(model.data.w),int(model.data.h)]
	var manifest:=FileAccess.open(manifest_path,FileAccess.WRITE)
	manifest.store_string(JSON.stringify(contract,"  "))
	print(map_id," mask baked in ",Time.get_ticks_msec()-start,"ms")
	quit(0 if terrain.mask!=null else 1)
