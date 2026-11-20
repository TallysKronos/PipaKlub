extends RefCounted
const KIT="res://assets/overworld/kits/mormaco-cel-pixel-pilot/"
const Pixel=preload("res://scripts/pixelgen_sprites.gd")

static func build(parent:Node2D, data:Dictionary, origin:Vector2)->void:
	var actors:=Node2D.new()
	actors.name="MargemDoMormaco"
	actors.position=origin
	actors.y_sort_enabled=true
	actors.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(actors)
	var terrain:=Sprite2D.new()
	terrain.texture=Pixel.load_texture(KIT+data.terrain)
	terrain.centered=false
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/overworld/mormaco_cel_water.gdshader")
	material.set_shader_parameter("water_mask",Pixel.load_texture(KIT+"water-mask.png"))
	terrain.material=material
	terrain.z_index=-2
	actors.add_child(terrain)
	for i in data.trees.size():
		var tree:Dictionary=data.trees[i]
		var root:=Node2D.new()
		root.name="Tree%02d"%i
		root.position=Vector2(tree.foot[0],tree.foot[1]).round()
		actors.add_child(root)
		var image:=Sprite2D.new()
		image.texture=Pixel.load_texture(KIT+tree.file)
		image.centered=false
		image.position=Vector2(tree.origin[0],tree.origin[1])-root.position
		var wind:=ShaderMaterial.new()
		wind.shader=preload("res://shaders/overworld/mormaco_cel_canopy.gdshader")
		wind.set_shader_parameter("phase",float(i)*1.79)
		image.material=wind
		root.add_child(image)
	for prop:Dictionary in data.get("props",[]):
		var root:=Node2D.new()
		root.position=Vector2(prop.foot[0],prop.foot[1]).round()
		actors.add_child(root)
		var image:=Sprite2D.new()
		image.texture=Pixel.load_texture(KIT+prop.file)
		image.centered=false
		image.position=Vector2(prop.origin[0],prop.origin[1])-root.position
		root.add_child(image)
	var waterfall:Dictionary=data.waterfall
	var fall:=Sprite2D.new()
	fall.texture=Pixel.load_texture(KIT+waterfall.file)
	fall.centered=false
	# Register the lip with the notch and the plunge pool with the lower water plane.
	fall.position=Vector2(waterfall.origin[0]+38,waterfall.origin[1]-19)
	fall.scale.y=1.13
	var flow:=ShaderMaterial.new()
	flow.shader=preload("res://shaders/overworld/mormaco_cel_fall.gdshader")
	flow.set_shader_parameter("terrain",terrain.texture)
	flow.set_shader_parameter("map_origin",origin)
	fall.material=flow
	actors.add_child(fall)
	fall.z_index=-1
