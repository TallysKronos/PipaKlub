extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SKIP Pixelgen GPU readback: run with the graphical backend; dummy renderer retains its initial CPU image")
		quit(0)
		return
	var file: String = "res://tmp/pixelgen-reload-test.png"
	DirAccess.make_dir_recursive_absolute("res://tmp")
	var image: Image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	assert(image.save_png(file) == OK)
	var loader: Node = load("res://scripts/pixelgen_sprites.gd").new()
	root.add_child(loader)
	var texture: Texture2D = loader.texture(file)
	assert(texture is ImageTexture, "Local project must use a reloadable texture")
	assert(texture.get_image().get_pixel(0, 0).is_equal_approx(Color.RED))
	image.fill(Color.BLUE)
	assert(image.save_png(file) == OK)
	loader._process(1.1)
	if not texture.get_image().get_pixel(0, 0).is_equal_approx(Color.BLUE):
		push_error("Texture refresh failed")
		quit(1)
		return
	assert(texture == loader.texture(file), "Nodes retain the same texture object")
	DirAccess.remove_absolute(file)
	loader.queue_free()
	print("PASS Pixelgen: existing local ImageTexture reloads new pixels without restarting")
	quit(0)
