extends SceneTree
## Offline catalogue: native importer and Prop renderer, no saves or gameplay.
const Prop = preload("res://scripts/overworld/prop.gd")
var stage: Node2D
func _initialize() -> void:
	call_deferred("capture")
func caption(text_value: String,point: Vector2,size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = point
	label.add_theme_color_override("font_color",Color("23394A"))
	label.add_theme_font_size_override("font_size",size)
	stage.add_child(label)
	return label
func capture() -> void:
	root.size = Vector2i(1280,720)
	var base := "res://assets/overworld/kits/mobilidade/"
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"kit.json"))
	var names: Array = kit.pieces.keys()
	var output := ProjectSettings.globalize_path("res://../documentation/overworld/mobilidade-v1/nativo")
	DirAccess.make_dir_recursive_absolute(output)
	for page in range(ceili(names.size()/3.0)):
		stage = Node2D.new()
		root.add_child(stage)
		var background := Polygon2D.new()
		background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,720),Vector2(0,720)])
		background.color = Color("ECDFC1")
		stage.add_child(background)
		caption("SOULMONSTERS · VEÍCULOS E MOBILIDADE",Vector2(22,16),25)
		caption("Prévia nativa · escala 1:1 · Kael 84 px · base/pivô propostos · sem campanha",Vector2(22,52),17)
		for slot in range(3):
			var index := page*3+slot
			if index>=names.size():break
			var id: String = names[index]
			var info: Dictionary = kit.pieces[id].variants.default.duplicate(true)
			info.texture = base+info.file
			info.shadow_texture = base+info.shadow
			var dimensions := Vector2(info.rasterSize[0],info.rasterSize[1])
			var factor := minf(1.0,minf(350.0/dimensions.x,475.0/dimensions.y))
			var holder := Node2D.new()
			holder.position = Vector2(slot*420+225,520)
			holder.scale = Vector2.ONE*factor
			stage.add_child(holder)
			var ground := Polygon2D.new()
			var a := float(info.footprint[0])*32.0
			var b := float(info.footprint[1])*32.0
			ground.polygon = PackedVector2Array([Vector2((b-a)*.5,-(a+b)*.25),Vector2((a+b)*.5,(a-b)*.25),Vector2((a-b)*.5,(a+b)*.25),Vector2(-(a+b)*.5,(b-a)*.25)])
			ground.color = Color("B4BAA6")
			holder.add_child(ground)
			var avatar := Sprite2D.new()
			avatar.texture = ImageTexture.create_from_image(Image.load_from_file(output.get_base_dir().path_join("KAEL-ESCALA.png")))
			avatar.centered = false
			avatar.position = Vector2(-200,-84)
			holder.add_child(avatar)
			var piece := Prop.new()
			piece.configure(info,Vector2i(info.footprint[0],info.footprint[1]),0,false)
			holder.add_child(piece)
			caption(info.displayName,Vector2(slot*420+20,620),19)
			caption(str(info.footprint)+" · "+str(info.kind)+" estático · zoom "+str(snappedf(factor,.01)),Vector2(slot*420+20,653),15)
		for frame in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("pagina-%02d-1280x720.png"%(page+1)))
		root.remove_child(stage)
		stage.free()
	print("Mobility library: ",names.size()," cutouts rendered across ",ceili(names.size()/3.0)," native pages. No test suite.")
	quit()


