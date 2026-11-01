extends SceneTree
const Title=preload("res://scripts/campaign/hud_title_menu.gd")
const Front=preload("res://scripts/campaign/front_end.gd")
const Mural=preload("res://scripts/ui_mural/mural_theme.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
var checks:=0
var failures:Array[String]=[]
var actions:Array[String]=[]
func check(ok:bool,note:String) -> void:
	checks+=1
	if not ok:failures.append(note);printerr("FAIL ",note)
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	for frame in 5:await process_frame
func key(code:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
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
			for saved in [false,true]:
				var view:=Title.new();view.text_scale=scale;view.has_saves=saved;root.add_child(view);await settle()
				check(view.buttons[0].disabled!=saved,"continue availability")
				check(view.first==view.buttons[0 if saved else 1],"initial focus matches save availability")
				check(root.gui_get_focus_owner()==view.first,"native initial focus")
				var previous:=view.logo_rect.end.y
				for button in view.buttons:
					var bounds:=button.get_global_rect()
					check(bounds.position.y>=previous,"logo/cards do not overlap")
					check(bounds.position.x-16>=24 and bounds.end.x<=dimensions.x-24,"icons/cards horizontal margins")
					check(bounds.end.y<=view.footer.position.y,"card/footer separated")
					var width:=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
					check(width<=bounds.size.x-116,"button text fits at "+str(scale))
					previous=bounds.end.y
				check(view.footer.position.y+view.footer.get_minimum_size().y<=dimensions.y-20,"footer bottom margin")
				view.free()
	var view:=Title.new();root.add_child(view);await settle()
	view.selected.connect(func(id:String):actions.append(id))
	await key(KEY_ENTER);check(actions==["new"],"keyboard confirms new journey")
	await pad(JOY_BUTTON_DPAD_DOWN);await pad(JOY_BUTTON_A)
	check(actions==["new","settings"],"pad navigation/confirm")
	var button:=view.buttons[3]
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=button.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		Input.parse_input_event(event);await process_frame
	check(actions.back()=="quit","mouse activates quit signal without quitting tests")
	view.free()
	# Real consumer with isolated saves: no player directory is opened by Session.
	var fixture:=ProjectSettings.globalize_path("res://../tmp/pip131-saves-"+str(Time.get_ticks_usec()))
	var app:=Front.new();app.session._store=Store.new(fixture);root.add_child(app);await settle()
	await key(KEY_ENTER);await settle()
	check(app.last_scene_key=="menu","title button opens real main menu")
	var menu:Control
	for child in app.get_children():
		if child.get_script()==Title:menu=child
	check(menu!=null and menu.theme==Mural.shared(),"Recorte respects owned Mural subtree")
	check(menu.first==menu.buttons[1],"real consumer empty store offers new journey")
	check(menu.buttons[1].theme!=app.theme,"legacy decorator does not overwrite child theme")
	check(menu.buttons[1].get_node_or_null("RecorteArt")==null,"no duplicate old decoration")
	var saved:=app.session._store.create_slot("slot-1")
	check(saved.status=="ok","isolated fixture saved")
	var original_bytes:=FileAccess.get_file_as_bytes(fixture.path_join("slot-1.json"))
	app._menu();await settle()
	for child in app.get_children():
		if child.get_script()==Title:menu=child
	check(menu.first==menu.buttons[0] and not menu.first.disabled,"real saved-slot consumer enables continue")
	app._main_menu_action("continue");await settle()
	check(app.last_scene_key=="menu:slots","continue opens existing native slots")
	check(app.session.snapshot().is_empty(),"slot picker does not start or overwrite journey")
	app._menu();await settle();app._main_menu_action("new");await settle()
	check(app.last_scene_key=="menu:slots","new uses existing native slot flow")
	check(FileAccess.get_file_as_bytes(fixture.path_join("slot-1.json"))==original_bytes,"navigation leaves fixture save bytes unchanged")
	await key(KEY_ESCAPE);await settle()
	check(app.last_scene_key=="menu","Escape returns slots to main menu")
	await key(KEY_ESCAPE);await settle()
	check(app.last_scene_key=="title","Escape returns main menu to title")
	app.free()
	await settle()
	var report:={"checks":checks,"failures":failures,"devices":"injected native keyboard, gamepad and mouse events; no physical device test","saveFixture":fixture}
	var file:=FileAccess.open("res://../documentation/hud-v2/pip-131/testes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("MURAL TITLE: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
