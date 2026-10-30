extends SceneTree
## Interactive local art review. No Session, saves, rewards or online accounts.
var view: Node2D
var area := "park-trail"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--area="):area=arg.trim_prefix("--area=")
	call_deferred("open_area",area)
func open_area(id: String="park-trail") -> void:
	area=id
	if is_instance_valid(view):view.free()
	var maps: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/park/maps.json"))
	if id=="park-veredas":view=load("res://scripts/campaign/park_view.gd").new()
	else:
		view=load("res://scripts/campaign/park_route_view.gd").new()
		view.data=maps[id]
		view.content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	view.saved_player={"name":"Kael","partners":[],"flags":{},"openedChests":[],"coins":0,"inventory":{}}
	root.add_child(view)
	view.action_requested.connect(func(_id: String):pass)
	view.menu_requested.connect(func():view.paused=not view.paused)
	var ui := CanvasLayer.new();ui.layer=120;view.add_child(ui)
	var bar := HBoxContainer.new();bar.position=Vector2(24,640);ui.add_child(bar)
	for item in [["Jardim","park-trail"],["Clareira","park-clearing"],["Veredas","park-veredas"]]:
		var button := Button.new();button.text=item[0];button.custom_minimum_size=Vector2(145,46)
		button.pressed.connect(open_area.bind(item[1]).call_deferred)
		bar.add_child(button)
	var note := Label.new();note.text="Prévia local · WASD/setas · sem salvar campanha";bar.add_child(note)
	DisplayServer.window_set_title("Soulmonsters · Parque e Veredas · revisão local")
