extends RefCounted
## Quadro-chave modular na régua 2:1, em cima das coordenadas persistidas da campanha.
const BASE := "res://assets/campaign/professor-laboratorio-v2/interior/"
const FLOOR := Rect2(384, 288, 1344, 1056)
const CELLS := Vector2(13.0, 7.6)
const OFFSET := Vector2(120, 37)
const ORIGIN := Vector2(32, 270)
const WORKBENCH := Vector2(1416, 1118)
const WORKBENCH_FACE := Vector2(1576, 1118)
const NPC_POINT := Vector2(960, 818)
const PROPS := {
	"estante-livros": [[1.25,6.42,2.90,7.15], ["estante-livros"]],
	"planta-recepcao": [[.33,6.15,.90,6.69], ["planta-recepcao"]],
	"recepcao": [[.98,4.19,3.23,5.48], ["recepcao"]],
	"carrinho": [[.56,1.82,1.75,2.65], ["carrinho"]],
	"bancada-pesquisa": [[4.25,4.43,8.92,5.74], ["bancada-pesquisa","aparelho-losango","monitores"]],
	"banqueta": [[7.30,2.60,7.88,3.17], ["banqueta"]],
	"estante-caixas": [[9.30,6.73,10.90,7.60], ["estante-caixas"]],
	"mesa-maleta": [[10.52,.80,12.46,2.22], ["mesa-maleta","maleta-sensor"]],
	"entrada": [[5.02,-.75,7.57,.12], ["entrada"]],
}
const ARCHITECTURE := ["piso","parede-lateral","parede-fundo","abobada-esquerda","abobada-direita","torre-vidro","janela-esquerda","quadro-losango","painel-teal","estoque-fundos"]
const STOCK_BLOCKS := [
	[10.88,5.41,11.16,5.97],
	[12.52,5.38,12.86,6.34],
	[12.06,6.71,13,7.6],
	[12.89,5.40,13,7.6],
]
static var atlas: Texture2D
static var pieces: Dictionary = {}

static func applies(room: Dictionary) -> bool:
	return room.get("id") == "professor"

static func visible_point(point: Vector2) -> Vector2:
	var cells := Vector2((point.x - FLOOR.position.x) * CELLS.x / FLOOR.size.x, (FLOOR.end.y - point.y) * CELLS.y / FLOOR.size.y)
	return (OFFSET + ORIGIN + Vector2((cells.x + cells.y) * 32, (cells.x - cells.y) * 16)).round()

static func point_at(u: float, d: float) -> Vector2:
	return Vector2(FLOOR.position.x + FLOOR.size.x * u / CELLS.x, FLOOR.end.y - FLOOR.size.y * d / CELLS.y)

static func solid_bounds(bounds: Array) -> Rect2:
	var a := point_at(bounds[0], bounds[3])
	var b := point_at(bounds[2], bounds[1])
	return Rect2(a, b - a)

static func _walkable_rect(point: Vector2, floor_rect: Rect2, blocks: Array) -> bool:
	const RADIUS := 14.0
	var walkable := floor_rect.grow(-RADIUS)
	if not walkable.has_point(point):
		return false
	for bounds in blocks:
		if Rect2(bounds[0], bounds[1], bounds[2], bounds[3]).grow(RADIUS).has_point(point):
			return false
	return true

static func blocked() -> Array:
	var rooms: Array = []
	for id in PROPS:
		if id != "entrada":
			rooms.append(PROPS[id][0])
	rooms.append_array(STOCK_BLOCKS)
	var result: Array = []
	for bounds in rooms:
		var collider := solid_bounds(bounds)
		result.append([collider.position.x,collider.position.y,collider.size.x,collider.size.y])
	return result

static func walkable(point: Vector2) -> bool:
	return _walkable_rect(point, FLOOR, blocked())

static func resume_point(point: Vector2, blocks: Array) -> Vector2:
	if _walkable_rect(point, FLOOR, blocks):
		return point
	var entry := Vector2(1056, 1232)
	if not point.is_finite() or not FLOOR.grow(100).has_point(point):
		return entry
	# A área pode agora conter um móvel. Procura piso livre perto da posição salva.
	var best := entry
	var distance := point.distance_squared_to(best)
	for y in range(int(FLOOR.position.y) + 16, int(FLOOR.end.y) - 14, 16):
		for x in range(int(FLOOR.position.x) + 16, int(FLOOR.end.x) - 14, 16):
			var candidate := Vector2(x, y)
			var cost := point.distance_squared_to(candidate)
			if cost < distance and _walkable_rect(candidate, FLOOR, blocks):
				best = candidate
				distance = cost
	return best

static func room_data(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data.camera.scale = 1.0
	data.walkable = [[FLOOR.position.x,FLOOR.position.y,FLOOR.size.x,FLOOR.size.y]]
	data.blocked = blocked()
	data.layout.blocking.mother = [NPC_POINT.x,NPC_POINT.y]
	for spot: Dictionary in data.hotspots:
		if spot.id == "workbench":
			spot.x = WORKBENCH.x
			spot.y = WORKBENCH.y
	data.props = []
	for id in PROPS:
		data.props.append({"id":id,"kind":"solid","footprint":depth_rect(PROPS[id][0])})
	# Jambas da porta do estoque podem encobrir o sprite enquanto ele cruza o vão.
	for frame in [
		["estoque-batente-esquerdo", Rect2i(556,254,12,104), [10.83,5.43,11.14,5.61]],
		["estoque-batente-direito", Rect2i(607,281,20,111), [12.48,5.30,12.82,5.62]],
	]:
		data.props.append({"id":frame[0],"kind":"solid","footprint":depth_rect(frame[2]),"crop":frame[1]})
	return data

static func depth_rect(bounds: Array) -> Dictionary:
	var rect := solid_bounds(bounds)
	return {
		"u0":(rect.position.x - FLOOR.position.x) / 96,
		"v0":(rect.position.y - FLOOR.position.y) / 96,
		"u1":(rect.end.x - FLOOR.position.x) / 96,
		"v1":(rect.end.y - FLOOR.position.y) / 96,
	}

static func load_kit() -> void:
	if atlas != null:
		return
	atlas = preload("res://scripts/pixelgen_sprites.gd").load_texture(BASE + "atlas.png")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE + "manifesto.json"))
	for item: Dictionary in manifest.parts:
		pieces[item.id] = item

static func build_floor(room: Node2D) -> void:
	load_kit()
	var root := Node2D.new()
	root.name = "LaboratorioInteriorV2"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.add_child(root)
	for id in ARCHITECTURE:
		root.add_child(sprite_for(id))
	room.set_meta("professor_art", "interior-v2")

static func create_prop(_room: Node2D, prop: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = prop.id
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if prop.has("crop"):
		root.add_child(sprite_for("estoque-fundos", prop.crop))
	else:
		for id in PROPS[prop.id][1]:
			root.add_child(sprite_for(id))
	return root

static func sprite_for(id: String, crop: Rect2i = Rect2i()) -> Sprite2D:
	var data: Dictionary = pieces[id]
	var at: Array = data.position_px
	var pivot: Array = data.pivot_px
	var p := Vector2i(int(at[0]) - int(pivot[0]), int(at[1]) - int(pivot[1]))
	var bounds: Array = data.atlas_rect
	var rect := Rect2i(bounds[0], bounds[1], bounds[2], bounds[3])
	if crop.has_area():
		var visible := Rect2i(p, rect.size).intersection(crop)
		rect = Rect2i(rect.position + visible.position - p, visible.size)
		p = visible.position
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = Rect2(rect)
	region.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = region
	sprite.centered = false
	sprite.position = OFFSET + Vector2(p)
	return sprite
