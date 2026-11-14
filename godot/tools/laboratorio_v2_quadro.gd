extends SceneTree
## Normalização de fonte ImageGen ANTES da edição do novo documento no Aseprite.
const BASE := "res://../art/professor-laboratorio-v2/fachada/"
const HEX := ["191e30","2d3a57","384e68","55709b","c1b6ce","efdbd1","fbe8d0","f7f3ee","066d7a","38beb3","063328","9e533a","ed6b14","f2a25c","f4b128","f3c080","974b7c","d67451","a78d6d","60372b","29533c","477444","71954b","9fb665","ced68d","698387","85b5c5","b8dbe3","9b97b0","7b7c99","ce91b5"]

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(BASE+"fontes/geracao-02-isometrica.png"))
	var opaque := Rect2i()
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a>.8:
				opaque=opaque.expand(Vector2i(x,y)) if opaque.has_area() else Rect2i(x,y,1,1)
	var cut := source.get_region(opaque)
	var height := roundi(cut.get_height()*720.0/cut.get_width())
	cut.resize(720,height,Image.INTERPOLATE_NEAREST)
	var colors:Array[Color]=[]
	for h in HEX: colors.append(Color(h))
	var mapped := Image.create(768,576,false,Image.FORMAT_RGBA8)
	var cache := {}
	for y in cut.get_height():
		for x in cut.get_width():
			var c:=cut.get_pixel(x,y)
			if c.a<.8: continue
			var key:=c.to_rgba32()
			if not cache.has(key):
				var best:=colors[0]
				var dist:=INF
				for col in colors:
					var delta:=Vector3(c.r-col.r,c.g-col.g,c.b-col.b)
					var d:=delta.length_squared()
					if d<dist:
						dist=d
						best=col
				cache[key]=best
			mapped.set_pixel(x+24,y+24,cache[key])
	mapped.save_png(BASE+"fontes/base-nativa-para-aseprite.png")
	var info:={"source_size":[source.get_width(),source.get_height()],"source_bounds":[opaque.position.x,opaque.position.y,opaque.size.x,opaque.size.y],"native_canvas":[768,576],"native_width":720,"native_height":height,"alpha_threshold":.8,"palette_count":HEX.size(),"sampling":"nearest","status":"base de conversão; requer acabamento Aseprite"}
	var f:=FileAccess.open(BASE+"fontes/normalizacao.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(info,"\t"))
	print(JSON.stringify(info))
	quit()
