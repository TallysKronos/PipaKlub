extends Node
## Local authoring textures refresh without restarting the running project.
## Packaged builds continue to use their imported resources.
var _textures: Dictionary = {}

## Entry point for static code: uses the autoload when it is running and plain
## load() otherwise. Scripts run with `-s` (tests, captures) have no autoloads,
## so the global name PixelgenSprites does not even compile there.
static func load_texture(resource_path: String) -> Texture2D:
	var tree := Engine.get_main_loop() as SceneTree
	var live: Node = tree.root.get_node_or_null("PixelgenSprites") if tree != null and tree.root != null else null
	if live != null and live.has_method("texture"):
		return live.call("texture", resource_path) as Texture2D
	return load(resource_path) as Texture2D
var _hashes: Dictionary = {}
var _elapsed: float = 0.0

func texture(resource_path: String) -> Texture2D:
	if _textures.has(resource_path):
		return _textures[resource_path] as Texture2D
	var disk_path: String = ProjectSettings.globalize_path(resource_path)
	if not OS.has_feature("editor") or not FileAccess.file_exists(disk_path):
		return load(resource_path) as Texture2D
	var image: Image = Image.load_from_file(disk_path)
	if image == null or image.is_empty():
		return load(resource_path) as Texture2D
	var result: ImageTexture = ImageTexture.create_from_image(image)
	_textures[resource_path] = result
	_hashes[resource_path] = FileAccess.get_sha256(disk_path)
	return result

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 1.0:
		return
	_elapsed = 0.0
	for resource_path: String in _textures:
		var disk_path: String = ProjectSettings.globalize_path(resource_path)
		if not FileAccess.file_exists(disk_path):
			continue
		var digest: String = FileAccess.get_sha256(disk_path)
		if digest == _hashes[resource_path] or digest.is_empty():
			continue
		var image: Image = Image.load_from_file(disk_path)
		if image == null or image.is_empty():
			continue
		var target: ImageTexture = _textures[resource_path]
		if Vector2i(target.get_size()) == image.get_size():
			target.update(image)
		else:
			target.set_image(image)
		_hashes[resource_path] = digest
