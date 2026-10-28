@tool
extends Node2D
## Reusable visual water. Deliberately has no collision, swimming or save logic.
const BASE := "res://assets/overworld/kits/aguas-v1/"
@export_enum("lago-claro","lago-profundo","rio-claro","rio-escuro","corredeira","agua-pantano") var water_id := "lago-claro"
@export_enum("lake","river","bend","branch","rectangle") var layout := "lake"
@export var patch_size := Vector2i(8,8)
@export var flow_direction := Vector2(0,1)
@export var preview_time := -1.0
@export_tool_button("Atualizar água") var refresh_action: Callable = rebuild
var water_material: ShaderMaterial
var water_layer: TileMapLayer

func _ready() -> void:rebuild()

func cells_for_layout() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(patch_size.y):
		for x in range(patch_size.x):
			var center := Vector2(patch_size-Vector2i.ONE)/2.0
			var lake: bool = (Vector2(x,y)-center).length() < mini(patch_size.x,patch_size.y)*0.48
			var vertical := x>=2 and x<=4
			var horizontal := y>=2 and y<=4
			var keep: bool = layout=="rectangle" or (layout=="lake" and lake) or (layout=="river" and vertical)
			keep = keep or (layout=="bend" and ((vertical and y<=4) or (horizontal and x>=2)))
			keep = keep or (layout=="branch" and (horizontal or (vertical and y<=4)))
			if keep:cells.append(Vector2i(x,y))
	return cells

func rebuild() -> void:
	if is_instance_valid(water_layer):
		remove_child(water_layer)
		water_layer.queue_free()
	var path := BASE+"tilesets/"+water_id+".tres"
	if not ResourceLoader.exists(path):return
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/overworld/water_surface.gdshader")
	water_material.set_shader_parameter("surface_texture",load(BASE+"surfaces/"+water_id+".png"))
	water_material.set_shader_parameter("shore_texture",load(BASE+"masks/shore-atlas.png"))
	water_material.set_shader_parameter("flow_direction",flow_direction)
	water_material.set_shader_parameter("preview_time",preview_time)
	water_layer = TileMapLayer.new()
	water_layer.tile_set = load(path)
	water_layer.material = water_material
	water_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	water_layer.collision_enabled = false
	water_layer.navigation_enabled = false
	add_child(water_layer)
	# DIAMOND_DOWN adds a half-cell offset. Public node origin is cell (0,0)'s centre.
	water_layer.position = -water_layer.map_to_local(Vector2i.ZERO)
	if layout=="rectangle":
		# An open channel lip must reach its exact geometric edge, without bank inset.
		for cell in cells_for_layout():water_layer.set_cell(cell,0,Vector2i(6,5))
	else:water_layer.set_cells_terrain_connect(cells_for_layout(),0,0,false)
	water_layer.update_internals()

func set_animation_time(value: float) -> void:
	preview_time = value
	if water_material:water_material.set_shader_parameter("preview_time",value)
