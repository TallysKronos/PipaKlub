extends RefCounted
## PIP-63 art registry. No save, input or gameplay dependencies.
const ROOT := "res://assets/ui/recorte-v1/"
static var _manifest: Dictionary = {}
static var _assets: Dictionary = {}
static var _textures: Dictionary = {}

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
		for asset: Dictionary in _manifest.assets: _assets[asset.id] = asset
	return _manifest

static func definition(id: String) -> Dictionary:
	manifest()
	return _assets.get(id, {})

static func texture(id: String, high_density: bool = false) -> Texture2D:
	var key := id + ("@2x" if high_density else "")
	if not _textures.has(key):
		var asset := definition(id)
		if asset.is_empty():
			push_error("Unknown Recorte ink asset: " + id)
			return null
		_textures[key] = load(ROOT + str(asset.file_2x if high_density else asset.file))
	return _textures[key]

static func family(name: String, form: String = "filled") -> Array[String]:
	var result: Array[String] = []
	for asset: Dictionary in manifest().assets:
		if asset.get("family") == name and asset.get("form") == form: result.append(asset.id)
	return result
