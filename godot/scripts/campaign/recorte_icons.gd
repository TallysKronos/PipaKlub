extends RefCounted
## PIP-65. All UI symbol aliases resolve to one vector family.
const ROOT := "res://assets/ui/recorte-v1/icons/"
const ALIASES := {"attack":"cortar", "energy":"energia", "dodge":"esquiva", "line":"linha", "bag":"mochila", "team":"parceiros", "map":"mapa", "settings":"configuracoes", "back":"voltar", "save":"salvar", "tail":"rabiola", "menu":"configuracoes"}
static var _textures: Dictionary = {}
static func texture(id: String, world: bool = false, high_density: bool = false) -> Texture2D:
	var name: String = ALIASES.get(id,id)
	var path := ROOT + ("world/" if world else "png96/" if high_density else "") + name + (".png" if high_density and not world else ".svg")
	if not _textures.has(path): _textures[path] = load(path) if ResourceLoader.exists(path) else load(ROOT+"info.svg")
	return _textures[path]
