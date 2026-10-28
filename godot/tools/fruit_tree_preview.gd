extends SceneTree
## Isolated art/interaction gallery. No campaign saves or inventory access.
const TreeRig = preload("res://scripts/overworld/fruit_tree.gd")
var stage: Node2D
var trees: Array[Node2D] = []
var page := 0
var names: Array = []
var kit: Dictionary
var status: Label
var output: String
var capture_mode := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	root.size = Vector2i(1280,720)
	kit = JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/kits/frutiferas/kit.json"))
	names = kit.pieces.keys()
	output = ProjectSettings.globalize_path("res://../documentation/overworld/frutiferas-v1/nativo")
	capture_mode = "--capture-fruit-trees" in OS.get_cmdline_user_args()
	if capture_mode:
		await capture_all()
		quit()
	else:show_page()

func label(text_value: String,at: Vector2,size: int) -> Label:
	var item := Label.new()
	item.text = text_value
	item.position = at
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",Color("23394A"))
	stage.add_child(item)
	return item

func show_page() -> void:
	if is_instance_valid(stage):
		root.remove_child(stage)
		stage.free()
	trees.clear()
	stage = Node2D.new()
	root.add_child(stage)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
	background.color = Color("ECDFC1")
	stage.add_child(background)
	label("SOULMONSTERS · ÁRVORES ARTICULADAS",Vector2(22,18),28)
	label("Espaço / Bater: sacudir e soltar 1 fruto por árvore · ← →: espécies · R: repor nesta prévia",Vector2(22,62),18)
	label("Galeria local · sem inventário/salvamento · base fixa, copa e frutos separados",Vector2(22,94),17)
	status = label("Página %s/4 · pronto"%(page+1),Vector2(22,674),18)
	for slot in range(3):
		var index := page*3+slot
		if index>=names.size():break
		var id: String = names[index]
		var info: Dictionary = kit.pieces[id].variants.default
		var packed := load(info.articulatedScene) as PackedScene
		var tree := packed.instantiate() as Node2D
		tree.position = Vector2(slot*420+250,535)
		stage.add_child(tree)
		tree.fruit_landed.connect(func(species: String,_at: Vector2) -> void:status.text = species+" · fruto pousou · prévia sem coleta")
		trees.append(tree)
		if capture_mode:tree.set_process(false)
		var avatar := Sprite2D.new()
		avatar.texture = ImageTexture.create_from_image(Image.load_from_file(output.get_base_dir().path_join("KAEL-ESCALA.png")))
		avatar.centered = false
		avatar.position = Vector2(slot*420+60,535-84)
		stage.add_child(avatar)
		label(info.displayName,Vector2(slot*420+22,580),23)
		label("Escala 1:1 · tronco 1×1 · pivô na raiz",Vector2(slot*420+22,619),16)
	if not capture_mode:
		var button := Button.new()
		button.text = "Bater nas árvores [Espaço]"
		button.position = Vector2(850,665)
		button.size = Vector2(360,40)
		button.pressed.connect(hit_all)
		stage.add_child(button)

func hit_all() -> void:
	for tree in trees:tree.hit()
	status.text = "Golpe · frutos restantes: "+str(trees[0].fruit_count())+" na primeira árvore"

func _unhandled_input(event: InputEvent) -> void:
	if capture_mode or not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_SPACE:hit_all()
		KEY_RIGHT:
			page = (page+1)%4
			show_page()
		KEY_LEFT:
			page = (page+3)%4
			show_page()
		KEY_R:show_page()
		KEY_ESCAPE:quit()

func snapshot(name_value: String) -> void:
	for frame in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name_value+"-1280x720.png"))

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	for p in range(4):
		page = p
		show_page()
		for pose: Dictionary in [{"id":"repouso","clip":"idle","time":0.0},{"id":"impacto","clip":"drop","time":.18},{"id":"queda","clip":"drop","time":.62}]:
			for tree in trees:tree.show_pose(pose.clip,pose.time)
			status.text = "Página %s/4 · %s · juntas e raiz em escala 1:1"%[page+1,pose.id]
			await snapshot("pagina-%02d-%s"%[page+1,pose.id])
	# Also capture a REAL runtime hit/detachment; no inventory/network or test suite.
	page = 0
	show_page()
	for tree in trees:
		tree.set_process(true)
		tree.hit()
	await create_timer(.85).timeout
	status.text = "Interação real · copa retornando · 1 fruto destacado por árvore"
	await snapshot("interacao-real")
	print("Fruit gallery: 12 species, rest/impact/drop captured; one real hit/detachment page. No test suite.")
