extends SceneTree
const Overlay=preload("res://scripts/campaign/hud_exploration.gd")
const AtlasView=preload("res://scripts/campaign/hud_kronasta_map.gd")
const Atlas=preload("res://scripts/campaign/kronasta_atlas.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var failures:Array[String]=[]
var checks:=0
var traveled:Array[String]=[]
var closed:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,note:String) -> void:
	checks+=1
	if not ok:failures.append(note);printerr("FAIL ",note)
func settle() -> void:
	for frame in 8:await process_frame
func key(code:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func click(button:Button) -> void:
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=button.get_global_rect().get_center()
		Input.parse_input_event(event);await process_frame
func pad(code:JoyButton) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=99;event.button_index=code;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;Controls.install()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			var hud:=Overlay.new();hud.text_scale=scale
			hud.area_name="Bosque dos Ventos · Trilha das Copas"
			var player:={"equippedPartnerId":"qa","coins":1234567,"partners":[{"id":"qa","modelId":"rabbito","personalName":"Rabbito do Primeiro Vento","xp":250,"condition":{"line":12,"structure":34}}]}
			hud.player_data=player;var before:=player.duplicate(true)
			root.add_child(hud)
			hud.objective.text="Siga a trilha e converse com Nina para descobrir o próximo passo."
			hud.prompt.text="Examinar o marco de pedra"
			hud._process(0);hud._layout();await settle()
			for widget in [hud.area_panel,hud.objective_panel,hud.partner_panel,hud.prompt_panel]:
				check(Rect2(Vector2(20,20),Vector2(dimensions)-Vector2(40,40)).encloses(widget.get_rect()),"safe overlay margins "+str(dimensions)+" scale "+str(scale))
			check(not hud.partner_panel.get_rect().intersects(hud.prompt_panel.get_rect()),"partner / prompt separated")
			check(hud.portrait!=null,"equipped portrait loaded")
			check(player==before,"rendering does not mutate player")
			hud.refresh({});check(hud.portrait==null and hud.partner.is_empty(),"empty team clears old portrait")
			hud.refresh(player)
			for i in 4:hud.push_notice("Item encontrado · %d"%i,"item")
			await settle()
			check(hud.notices.size()==3,"bounded notices")
			check(hud.notice_stack.get_rect().end.y<hud.partner_panel.position.y,"notices clear partner")
			hud.free()
			var view:=AtlasView.new();view.text_scale=scale;view.current_scene="park-trail";root.add_child(view);await settle()
			var bounds:=Rect2(Vector2(20,20),Vector2(dimensions)-Vector2(40,40))
			check(bounds.encloses(view.header.get_rect()),"map header margins")
			check(bounds.encloses(view.side.get_rect()),"map sidebar margins")
			check(bounds.encloses(view.footer.get_rect()),"flow footer margins")
			check(view.map_rect.end.x+16<=view.side.position.x,"map/sidebar separated")
			check(view.header.get_rect().end.y<view.side.position.y,"header/sidebar separated")
			view.travel_requested.connect(func(scene:String):traveled.append(scene))
			view.closed.connect(func():closed+=1)
			for index in Atlas.REGIONS.size():
				view.select(index);await settle()
				check(bounds.encloses(view.markers[index].get_rect()),"marker margins "+str(index))
				var data:Dictionary=Atlas.REGIONS[index]
				if data.scenes.is_empty():
					check(view.parts.get_child(0).disabled,"future marker cannot travel")
				else:
					check(view.parts.get_child_count()==data.scenes.size(),"all native destinations preserved")
					for button in view.parts.get_children():
						button.pressed.emit()
						check(Atlas.can_travel(traveled.back()),"destination validated by unchanged atlas")
			view.markers[0].grab_focus();await settle();await key(KEY_RIGHT)
			check(root.gui_get_focus_owner()!=view.markers[0],"arrow leaves marker")
			await key(KEY_ESCAPE);check(closed>0,"Escape closes map")
			view.back.grab_focus();await settle();var old:=closed;await pad(JOY_BUTTON_A)
			check(closed==old+1,"gamepad confirms native back button")
			await click(view.markers[9]);await settle()
			check(view.selected==9 and view.parts.get_child(0).disabled,"mouse inspects unavailable volcano without travel")
			view.free()
	var report:={"checks":checks,"failures":failures,"resolutions":["1280x720","1920x1080","1024x768","1280x800"],"textScales":[1.0,1.5],"notes":"Native keyboard events; regional signals and no-save UI fixtures. Physical devices not tested."}
	var file:=FileAccess.open("res://../documentation/hud-v2/pip-132/testes.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("MURAL EXPLORATION: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
