extends Node2D
const Layer=preload("res://scripts/soulgen_rider_layer.gd")
var front:Node2D
var back:Node2D
var source_path:="res://assets/mounts/kael-mounted-rig-v1/project.json"
var revision:=""
var elapsed:=0.0

func _ready() -> void:
	use_parent_material=true
	back=Layer.new();back.name="FarParts";back.behind=true;back.z_index=-1;back.use_parent_material=true;add_child(back)
	front=Layer.new();front.name="NearParts";front.z_index=1;front.use_parent_material=true;add_child(front)
	reload_project()

func reload_project() -> bool:
	var text:=FileAccess.get_file_as_string(source_path)
	if text.sha256_text()==revision:return false
	var data=JSON.parse_string(text)
	if not data is Dictionary or data.get("creatureId")!="kael-mounted":return false
	var images:Dictionary={}
	for key in data.assets:
		var asset:Dictionary=data.assets[key]
		var image:=Image.new()
		if image.load_png_from_buffer(Marshalls.base64_to_raw(asset.src.get_slice(",",1)))!=OK:return false
		images[key]=ImageTexture.create_from_image(image)
	for layer in [front,back]:
		layer.project=data;layer.textures=images;layer.queue_redraw()
	revision=text.sha256_text()
	return true

func _process(delta:float) -> void:
	if not OS.has_feature("editor") or not is_visible_in_tree():return
	elapsed+=delta
	if elapsed>=1.0:elapsed=0;reload_project()
