extends SceneTree
const IDS := ["kit-remendo","papel-seda","vareta-bambu","cola-reparo","linha-encerada","moedas"]
const OUT := "res://assets/ui/loja-itens-v1/"
func _initialize() -> void:
	var sheet:=Image.load_from_file(ProjectSettings.globalize_path("res://../art/ui/loja-itens-v1/fontes/itens-imagegen.png"))
	sheet.convert(Image.FORMAT_RGBA8)
	var cell:=Vector2i(sheet.get_width()/3,sheet.get_height()/2)
	for index in IDS.size():
		var crop:=sheet.get_region(Rect2i(Vector2i(index%3,index/3)*cell,cell))
		for y in crop.get_height():
			for x in crop.get_width():
				var color:=crop.get_pixel(x,y)
				crop.set_pixel(x,y,Color(color.r,color.g,color.b,1) if color.a>=.9 else Color.TRANSPARENT)
		crop=crop.get_region(crop.get_used_rect())
		var factor:=224.0/maxi(crop.get_width(),crop.get_height())
		crop.resize(roundi(crop.get_width()*factor),roundi(crop.get_height()*factor),Image.INTERPOLATE_LANCZOS)
		var icon:=Image.create_empty(256,256,false,Image.FORMAT_RGBA8)
		icon.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),(Vector2i(256,256)-crop.get_size())/2)
		icon.save_png(OUT+IDS[index]+".png")
	print("Seis ícones da loja exportados em 256 × 256.")
	quit()
