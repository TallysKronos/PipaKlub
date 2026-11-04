extends SceneTree
const Controls = preload("res://scripts/campaign/controls.gd")
## Deterministic SVG -> PNG export, no gameplay or player files.
func _initialize() -> void:
	var root := "res://assets/ui/recorte-v1/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root+"icons/manifest.json"))
	DirAccess.make_dir_recursive_absolute(root+"icons/png96")
	for asset in manifest.assets:
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(root+"icons/"+asset.file),2.0)
		if error == OK: error = image.save_png(root+"icons/"+asset.png96)
		if error != OK:
			push_error("Icon export failed: "+asset.id)
			quit(error)
			return
	var glyphs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root+"glyphs/manifest.json"))
	for asset in glyphs.assets:
		DirAccess.make_dir_recursive_absolute(root+"glyphs/png64/"+asset.family)
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(root+"glyphs/"+asset.file))
		if error == OK: error = image.save_png(root+"glyphs/png64/"+asset.file.replace(".svg",".png"))
		if error != OK:
			push_error("Glyph export failed: "+asset.file)
			quit(error)
			return
	var routes := {}
	Controls.install()
	for family in ["kbd","xbox","ps","switch"]:
		Controls.gamepad = family != "kbd"
		Controls.family_override = family if family != "kbd" else "auto"
		routes[family] = {}
		for action in ["interact","cut","skill","dodge","guard","signature","pause"]:
			routes[family][action] = {"glyph":Controls.glyph_id(action),"label":Controls.prompt(action)}
	var file := FileAccess.open(root+"mockups/input-routes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(routes,"\t"))
	print("Recorte exports: ",manifest.assets.size()," icons at 96px; ",glyphs.assets.size()," glyphs at 64px")
	quit()
