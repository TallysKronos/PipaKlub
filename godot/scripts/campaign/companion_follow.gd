extends RefCounted

const Avatar = preload("res://scripts/avatar.gd")

const SHEETS_PATH := "res://assets/campaign/overworld-companions"
const CELL_SIZE := Vector2(80, 80)
## Folhas v1 (80×80): desenhadas pequenas; crescem SIZE para o tamanho aprovado (12/11/2026).
## As folhas revisadas v2 (112×112, overworld-v2/manifest.json) já vêm no tamanho final, na
## densidade de pixel do Kael: bebê 41 px, criança 55, jovem 70, adulto 84 (Kael: 70).
const SIZE := 1.25
const OUTLINE = preload("res://shaders/overworld/companion_outline.gdshader")
const PILOT_SHEET := "res://assets/campaign/overworld-v2/azulfazo/duas-vistas.png"
const PILOT_CELL := Vector2(112, 112)
const REVIEWED_PATH := "res://assets/campaign/overworld-v2/manifest.json"
const ANIMATIONS_PATH := "res://assets/campaign/overworld-animations-v1/manifest.json"
static var animation_manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ANIMATIONS_PATH))
static var animation_cache: Dictionary = {}
static var reviewed_sheets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REVIEWED_PATH))
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

static func equipped_model(player: Dictionary) -> String:
	var equipped_id: String = player.get("equippedPartnerId", "")
	if equipped_id.is_empty(): return ""
	for partner: Dictionary in player.get("partners", []):
		if partner.get("id") == equipped_id: return partner.get("modelId", "")
	return ""

static func combat_art_id(model_id: String) -> String:
	return COMBAT_ALIASES.get(model_id, model_id)

static func overworld_texture(model_id: String) -> Texture2D:
	var sheet_id: String = OVERWORLD_ALIASES.get(model_id, model_id)
	if reviewed_sheets.has(sheet_id): return load(reviewed_sheets[sheet_id].image) as Texture2D
	if not ground_pivots.has(sheet_id): return null
	return load(SHEETS_PATH.path_join(sheet_id + ".png")) as Texture2D

static func overworld_portrait(model_id: String) -> Texture2D:
	var sheet := overworld_texture(model_id)
	if sheet == null: return null
	var portrait := AtlasTexture.new()
	portrait.atlas = sheet
	portrait.region = Rect2(Vector2.ZERO, cell_size(model_id))
	portrait.filter_clip = true
	return portrait

static func cell_size(model_id: String) -> Vector2:
	var sheet_id: String = OVERWORLD_ALIASES.get(model_id, model_id)
	return PILOT_CELL if reviewed_sheets.has(sheet_id) else CELL_SIZE

## A v2 usa a escala do próprio Kael (mesmo tamanho de pixel); a v1 cresce SIZE.
static func sprite_scale(model_id: String, kael_scale: float) -> float:
	var sheet_id: String = OVERWORLD_ALIASES.get(model_id, model_id)
	return kael_scale if reviewed_sheets.has(sheet_id) else kael_scale / Avatar.OVERWORLD_SCALE * SIZE

static func setup_overworld_art(sprite: Sprite2D, model_id: String, kael_scale: float) -> bool:
	var sheet := overworld_texture(model_id)
	if sheet == null: return false
	sprite.texture = sheet
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.region_enabled = true
	sprite.region_filter_clip_enabled = true
	sprite.centered = true
	var sheet_id: String = OVERWORLD_ALIASES.get(model_id, model_id)
	var pose_pivots := Vector2(100, 100)
	if not reviewed_sheets.has(sheet_id):
		var pivot: Variant = ground_pivots[sheet_id]
		pose_pivots = Vector2(float(pivot[0]), float(pivot[1])) if pivot is Array else Vector2.ONE * float(pivot)
	sprite.scale = Vector2.ONE * sprite_scale(model_id, kael_scale)
	# Legibilidade: contorno de 1 texel em volta da silhueta (KRONASTA_CONTORNO=0 desliga, para comparar).
	if OS.get_environment("KRONASTA_CONTORNO") != "0":
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE
		sprite.material = outline
	else:
		sprite.material = null
	sprite.set_meta("overworld_pivots", pose_pivots)
	var cell := cell_size(model_id)
	sprite.set_meta("overworld_cell", cell)
	var image := sheet.get_image()
	var bounds: Array[Rect2] = []
	for index in 2:
		bounds.append(Rect2(image.get_region(Rect2i(index * int(cell.x), 0, int(cell.x), int(cell.y))).get_used_rect()))
	sprite.set_meta("overworld_bounds", bounds)
	# Keep portraits and setup's rest pose static; playback starts on a physics tick.
	sprite.set_meta("animation_model", sheet_id)
	sprite.set_meta("animation_clock", 0.0)
	sprite.set_meta("animation_phase", 0.0)
	sprite.set_meta("animation_state", "")
	if sprite.has_meta("animated_bounds"): sprite.remove_meta("animated_bounds")
	sprite.flip_h = true
	orient(sprite, "se")
	return true

static func visible_bounds(sprite: Sprite2D) -> Rect2:
	var cell: Vector2 = sprite.get_meta("overworld_cell")
	var views: Array[Rect2] = sprite.get_meta("overworld_bounds")
	var index := 1 if sprite.region_rect.position.x >= cell.x else 0
	var bounds: Rect2 = sprite.get_meta("animated_bounds", views[index])
	if sprite.flip_h: bounds.position.x = cell.x - bounds.end.x
	bounds.position += sprite.offset - cell * .5
	return Rect2(bounds.position * sprite.scale, bounds.size * sprite.scale)

## Distance drives the walk; elapsed time drives breathing only while stationary.
static func animate(sprite: Sprite2D, delta: float, distance: float, cycle_distance: float = 2.0) -> void:
	var id: String = sprite.get_meta("animation_model", "")
	if not animation_manifest.has(id): return
	if not animation_cache.has(id):
		var loaded := {}
		for state: String in ["idle", "walk"]:
			var texture: Texture2D = load(animation_manifest[id][state])
			var image := texture.get_image()
			var count := maxi(1,texture.get_width()/112)
			var bounds: Array[Rect2] = []
			for row in 2:
				for col in count:
					bounds.append(Rect2(image.get_region(Rect2i(col*112,row*112,112,112)).get_used_rect()))
			var durations: Array = animation_manifest[id].get("idle_durations",[.32,.14,.22,.32,.14,.22,.20,.24])
			var duration := 0.0
			for value: float in durations: duration += value
			loaded[state] = {"texture":texture,"bounds":bounds,"frames":count,"durations":durations,"duration":duration}
		animation_cache[id] = loaded
	var state := "walk" if distance > .00001 else "idle"
	if sprite.get_meta("animation_state") != state:
		sprite.set_meta("animation_clock", 0.0)
		sprite.set_meta("animation_phase", 0.0)
	sprite.set_meta("animation_state", state)
	sprite.set_meta("animation_clock", float(sprite.get_meta("animation_clock")) + maxf(delta,0))
	sprite.set_meta("animation_phase", fmod(float(sprite.get_meta("animation_phase")) + maxf(distance,0)/maxf(cycle_distance,.001), 1.0))
	orient(sprite, sprite.get_meta("facing", "se"))

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
		var state: String = sprite.get_meta("animation_state", "")
		if not state.is_empty():
			var id: String = sprite.get_meta("animation_model")
			var data: Dictionary = animation_cache[id][state]
			var count: int = data.frames
			var frame := 0
			if state == "walk":
				frame = mini(count-1, int(float(sprite.get_meta("animation_phase"))*count))
			else:
				var remaining := fmod(float(sprite.get_meta("animation_clock")),float(data.duration))
				for duration: float in data.durations:
					if remaining < duration: break
					remaining -= duration
					frame += 1
				frame = mini(frame,count-1)
			sprite.texture = data.texture
			sprite.region_rect = Rect2(frame*cell.x,cell.y if rear else 0.0,cell.x,cell.y)
			sprite.set_meta("animated_bounds", data.bounds[(count if rear else 0)+frame])
		sprite.offset = Vector2(0, cell.y * .5 - (pivots.y if rear else pivots.x))
		sprite.set_meta("facing", facing)
		return
	# Current creature sheets have a right-facing view. Keep vertical movement's
	# last horizontal heading rather than rotate the entire creature or its pivot.
	if facing in ["sw","w","nw"]:sprite.flip_h=true
	elif facing in ["se","e","ne"]:sprite.flip_h=false
	sprite.set_meta("facing",facing)
