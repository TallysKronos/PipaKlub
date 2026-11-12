extends RefCounted

const Avatar = preload("res://scripts/avatar.gd")

const SHEETS_PATH := "res://assets/campaign/overworld-companions"
const CELL_SIZE := Vector2(80, 80)
## Tamanho dos companheiros em relação ao Kael (12/11/2026): as folhas foram desenhadas com
## bebê 31 px, criança 42, jovem 54 e adulto 63 (Kael: 67 px na tela). Com 1,25 o jovem fica
## do tamanho do Kael, o adulto um pouco maior, a criança menor e o bebê não tão pequeno.
const SIZE := 1.25
const OUTLINE = preload("res://shaders/overworld/companion_outline.gdshader")
const OVERWORLD_ALIASES := {
	"basica": "carcara",
	"basic-carcara": "carcara",
	"mata": "mata-verde",
	"basic-mata-verde": "mata-verde",
	"basic-azulao": "azulao",
	"mormaco-normal": "mormaco",
	"platyx-draft": "platyx",
}
const COMBAT_ALIASES := {
	"basica": "basic-carcara",
	"mata": "basic-mata-verde",
	"azulao": "basic-azulao",
	"raio": "basic-raio-de-sol",
}
static var ground_pivots: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_PATH + ".json"))
## Folhas v2 (tools/sprites/converter-overworld.mjs): convertidas da geração original com o
## xprite-pixelate, já no tamanho final e na densidade de pixel do Kael (célula 112, sem o SIZE).
## Quando uma criatura tem v2, ela vence a v1.
const SHEETS_V2_PATH := "res://assets/campaign/overworld-companions-v2"
static var sheets_v2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHEETS_V2_PATH + ".json")) if FileAccess.file_exists(SHEETS_V2_PATH + ".json") else {}

static func sheet_id(model_id: String) -> String:
	return OVERWORLD_ALIASES.get(model_id, model_id)

static func is_v2(model_id: String) -> bool:
	return sheets_v2.has(sheet_id(model_id)) and OS.get_environment("KRONASTA_SPRITES_V1") != "1"

static func cell_size(model_id: String) -> Vector2:
	return Vector2.ONE * float(sheets_v2[sheet_id(model_id)].cell) if is_v2(model_id) else CELL_SIZE

static func pivots(model_id: String) -> Vector2:
	var pivot: Variant = sheets_v2[sheet_id(model_id)].pivots if is_v2(model_id) else ground_pivots[sheet_id(model_id)]
	return Vector2(float(pivot[0]), float(pivot[1])) if pivot is Array else Vector2.ONE * float(pivot)

## Escala do sprite: a v1 cresce SIZE em relação ao Kael; a v2 já vem no tamanho e usa a escala dele.
static func sprite_scale(model_id: String, kael_scale: float) -> float:
	return kael_scale if is_v2(model_id) else kael_scale / Avatar.OVERWORLD_SCALE * SIZE

static func equipped_model(player: Dictionary) -> String:
	var equipped_id: String = player.get("equippedPartnerId", "")
	if equipped_id.is_empty(): return ""
	for partner: Dictionary in player.get("partners", []):
		if partner.get("id") == equipped_id: return partner.get("modelId", "")
	return ""

static func combat_art_id(model_id: String) -> String:
	return COMBAT_ALIASES.get(model_id, model_id)

static func overworld_texture(model_id: String) -> Texture2D:
	if is_v2(model_id): return load(SHEETS_V2_PATH.path_join(sheet_id(model_id) + ".png")) as Texture2D
	if not ground_pivots.has(sheet_id(model_id)): return null
	return load(SHEETS_PATH.path_join(sheet_id(model_id) + ".png")) as Texture2D

static func overworld_portrait(model_id: String) -> Texture2D:
	var sheet := overworld_texture(model_id)
	if sheet == null: return null
	var portrait := AtlasTexture.new()
	portrait.atlas = sheet
	portrait.region = Rect2(Vector2.ZERO, cell_size(model_id))
	portrait.filter_clip = true
	return portrait

static func setup_overworld_art(sprite: Sprite2D, model_id: String, kael_scale: float) -> bool:
	var sheet := overworld_texture(model_id)
	if sheet == null: return false
	sprite.texture = sheet
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	sprite.centered = true
	var pose_pivots := pivots(model_id)
	sprite.set_meta("overworld_cell", cell_size(model_id))
	sprite.scale = Vector2.ONE * sprite_scale(model_id, kael_scale)
	# Legibilidade: contorno de 1 texel em volta da silhueta (KRONASTA_CONTORNO=0 desliga, para comparar).
	if OS.get_environment("KRONASTA_CONTORNO") != "0":
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE
		sprite.material = outline
	else:
		sprite.material = null
	sprite.set_meta("overworld_pivots", pose_pivots)
	sprite.flip_h = true
	orient(sprite, "se")
	return true

## Consume accepted footsteps, including multiple short steps in one tick.
static func advance(point:Vector2,trail:Array[Vector2],delta:float,speed:float,gap:float,safe:Callable) -> Vector2:
	var remaining:=0.0
	var previous:=point
	for step in trail:
		remaining+=previous.distance_to(step)
		previous=step
	var budget:=minf(maxf(0,delta)*speed,maxf(0,remaining-gap))
	while budget>.00001 and not trail.is_empty():
		var next:=point.move_toward(trail[0],budget)
		if not safe.call(point,next):break
		budget-=point.distance_to(next)
		point=next
		if point.distance_to(trail[0])<.00001:trail.remove_at(0)
		else:break
	return point

static func orient(sprite:Sprite2D,facing:String) -> void:
	if sprite.has_meta("overworld_pivots"):
		var rear := facing in ["nw", "n", "ne"]
		var pivots: Vector2 = sprite.get_meta("overworld_pivots")
		var cell: Vector2 = sprite.get_meta("overworld_cell", CELL_SIZE)
		if facing in ["sw", "w", "nw"]: sprite.flip_h = false
		elif facing in ["se", "e", "ne"]: sprite.flip_h = true
		sprite.region_rect = Rect2(Vector2(cell.x if rear else 0.0, 0), cell)
		sprite.offset = Vector2(0, cell.y * .5 - (pivots.y if rear else pivots.x))
		sprite.set_meta("facing", facing)
		return
	# Current creature sheets have a right-facing view. Keep vertical movement's
	# last horizontal heading rather than rotate the entire creature or its pivot.
	if facing in ["sw","w","nw"]:sprite.flip_h=true
	elif facing in ["se","e","ne"]:sprite.flip_h=false
	sprite.set_meta("facing",facing)
