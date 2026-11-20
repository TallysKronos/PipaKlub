extends RefCounted
## Explicit release-pack probe: --main-pack <game.pck> --script res://scripts/diagnostics/export_resources.gd
## Does not enter the campaign or open/write player saves.
const Room = preload("res://scripts/campaign/room_view.gd")
const Shop = preload("res://scripts/campaign/shop_data.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
const Title = preload("res://scripts/campaign/hud_title_menu.gd")
const Park = preload("res://scripts/campaign/park_checkpoint.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL export resources: ", label)

func run(tree: SceneTree) -> int:
	if not OS.is_debug_build():
		var story := preload("res://scripts/campaign/kronasta_story.gd")
		story.qa_override = 1
		check(not story.qa(), "release refuses a QA override")
		var menu := Title.new()
		tree.root.add_child(menu)
		check(menu.column.get_child_count() == 4, "release menu has only player actions")
		menu.free()
		story.qa_override = -1
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	check(not content.is_empty(), "campaign data is in the package")
	for file: String in content.get("portraits", {}).values():
		var portrait_path := "res://assets/campaign/" + file
		check(ResourceLoader.exists(portrait_path, "Texture2D"), "dialogue portrait: " + portrait_path)
	var theme: Theme = load("res://assets/ui/recorte-v1/theme/recorte_theme.tres")
	check(theme != null and theme.default_font != null, "theme and imported font load")
	for base in ["casa-moderna-v1", "loja-tcg-v1", "professor-moderno-v1"]:
		var directory: String = "res://assets/campaign/" + base + "/"
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory + "kit.json"))
		check(not manifest.is_empty(), base + " manifest is packaged")
		for asset: String in manifest.get("pieces", {}):
			var texture: Texture2D = load(directory + asset + ".png")
			check(texture is CompressedTexture2D and texture.get_width() > 0, base + "/" + asset + " uses imported texture")
	for key in ["bedroom", "home"]:
		var room := Room.new()
		tree.root.add_child(room)
		room.configure(content.rooms[key], content.rooms[key].entry, false, "", true, true)
		check(room.get_node_or_null("Modern_cama" if key == "bedroom" else "Modern_porta-mae") != null, key + " builds actual furniture")
		check_room(room, key)
		room.free()
	var shop := Room.new()
	tree.root.add_child(shop)
	shop.configure(Shop.room(), [Shop.ENTRY.x, Shop.ENTRY.y], false, "", false, true)
	check(shop.get_node_or_null("ShopOwner/Art") != null, "shop owner is present")
	check_room(shop, "shop")
	shop.free()
	var front := Front.new()
	front.content = content
	for scene in ["kite-shop", "professor-home"]:
		var preview: Dictionary = front._slot_location({"checkpoint":{"kind":"world", "scene":scene}})
		check(preview.texture is CompressedTexture2D, "save preview uses imported art: " + scene)
	front.sound.free()
	front.session.free()
	front.free()
	for file in ["logo.png", "neighborhood-starters-soulgen-v4.png"]:
		check(Title.artwork("res://assets/campaign/title-v1/" + file) is CompressedTexture2D, "title uses imported art: " + file)
	for actor: Dictionary in content.get("combat", {}).values():
		var path := "res://assets/campaign/" + str(actor.get("image", ""))
		check(ResourceLoader.exists(path, "Texture2D"), "combat atlas: " + path)
	for file: String in Park.MAPS.values():
		var path := "res://assets/overworld/maps/" + file + ".json"
		check(JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary, "map data: " + path)
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/sfx-v1/catalog.json"))
	check(catalog is Dictionary and not catalog.get("events", []).is_empty(), "sound catalog is packaged")
	if catalog is Dictionary:
		for event: Dictionary in catalog.get("events", []):
			for entry: Dictionary in event.files:
				check(ResourceLoader.exists(entry.path, "AudioStream"), "sound effect: " + str(entry.path))
	print("EXPORT RESOURCES ", checks, " checks; ", failures, " failures")
	return 0 if failures == 0 else 1

func check_room(room: Node2D, label: String) -> void:
	var count := 0
	for item: Dictionary in room.props:
		var sprite: Sprite2D = item.node.get_node_or_null("Art")
		if sprite == null:
			continue
		count += 1
		check(sprite.texture is CompressedTexture2D, label + "/" + str(item.node.name) + " imported prop")
	check(count > 0, label + " has textured props")
