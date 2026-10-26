extends SceneTree
const Icons = preload("res://scripts/campaign/recorte_icons.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL ",message)

func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/recorte-v1/icons/manifest.json"))
	check(manifest.assets.size() >= 70,"complete navigation, resources, battle, classes and direction family")
	for asset in manifest.assets:
		var texture := Icons.texture(asset.id)
		var large := Icons.texture(asset.id,false,true)
		var world := Icons.texture(asset.id,true)
		check(texture != null and texture.get_size() == Vector2(48,48),"48px SVG: "+asset.id)
		check(large != null and large.get_size() == Vector2(96,96),"96px raster: "+asset.id)
		check(world != null and world.get_size() == Vector2(64,64),"padded world rim: "+asset.id)
	for alias in ["attack","energy","dodge","line","bag","team","map","settings","back","save","tail"]:
		check(Icons.texture(alias).resource_path.begins_with("res://assets/ui/recorte-v1/icons/"),"legacy name resolves only Recorte: "+alias)
	for id in ["precisa","agil","guardia","tecnica"]: check(Icons.texture(id) != null,"existing web combat type: "+id)
	check(FileAccess.file_exists("res://licenses/kenney-input-prompts-CC0.txt"),"Kenney license bundled")
	print("RECORTE ICONS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
