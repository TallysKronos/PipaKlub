extends SceneTree
const Trees=preload("res://trees.gd")
func _initialize() -> void:
	var a: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	var expected: Array=JSON.parse_string(FileAccess.get_file_as_string("res://nature-regions.json"))
	var species: Dictionary={}
	for entry: Dictionary in expected:
		var p := Vector2(float(entry.x),float(entry.y))
		var asset: String=entry.asset
		var region := Trees.region(a,p,asset)
		if Trees.mask(a,p,asset)!=int(entry.mask) or region.position!=Vector2(float(entry.region.x),float(entry.region.y)):
			print("FAIL: recorte diferente em ",asset)
			quit(1)
			return
		species[asset]=true
	for asset: String in species:
		var atlas: Texture2D=load("res://assets/tree-atlas-"+asset+".png")
		if atlas==null or atlas.get_size()!=Vector2(512,576):
			quit(1)
			return
	if species.size()!=6:
		quit(1)
		return
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://catalog.json"))
	var count := 0
	for asset: Dictionary in catalog:
		if asset.get("kit","")=="nature-v1":
			var image: Texture2D=load("res://assets/"+str(asset.id)+".png")
			if image==null or image.get_width()!=64:
				quit(1)
				return
			count+=1
	if count!=30:
		quit(1)
		return
	print("PASS Godot: 30 peças carregadas e seis atlas com máscaras iguais ao Studio.")
	quit()
