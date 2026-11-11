extends RefCounted
## Planícies de Kronasta e Gruta do Moinho (11/11/2026). Os dados e as regras ficam em
## side_regions.gd (região "planicies"); este arquivo mantém os nomes usados pelos testes.
const Regions = preload("res://scripts/campaign/side_regions.gd")
const SCENES := ["planicie-a", "planicie-b", "planicie-c", "caverna-a", "caverna-b", "caverna-c"]
const GUARDIAN_LEVEL := 18
const PAS := 3
const ITEM := "pa-do-moinho"
const ACTIONS := ["planicieMoinho", "grutaIara", "grutaTito"]

var regions: RefCounted
func _init(local_session: Node) -> void: regions = Regions.new(local_session)

static func is_region(scene: String) -> bool: return scene in SCENES
static func open(player: Dictionary) -> bool: return Regions.open(player, "planicies")
static func objective(player: Dictionary, scene: String) -> String: return Regions.objective(player, scene)
func talk(action: String, point: Vector2) -> Dictionary: return regions.talk(action, point)
