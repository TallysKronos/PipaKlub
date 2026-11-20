extends SceneTree
func _initialize() -> void:
	var model=load("res://campaign_map_model.gd").new()
	var area: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://studio-generated/verification-1793991837046/integration/area.overworld.json"))
	model.setup(area)
	assert(model.graph.get_point_count()>0)
	assert(area.events.size()==1)
	assert(area.pieces[-1].props.collision.shape=="rect")
	print("PASS: campaign map_model accepts adapter, events and collision metadata.")
	quit()
