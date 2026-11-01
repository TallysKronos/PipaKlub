extends SceneTree
## PIP-130 native component/input checks. In-memory lab, never a campaign/save.
const Lab = preload("res://scripts/ui_mural/mural_lab.gd")
const Mural = preload("res://scripts/ui_mural/mural_theme.gd")
const T = preload("res://scripts/campaign/ui_tokens.gd")
const Controls = preload("res://scripts/campaign/controls.gd")
var failures:Array[String]=[]
var checks:=0

func check(ok:bool,description:String) -> void:
	checks+=1
	if not ok:failures.append(description);printerr("FAIL ",description)

func _initialize() -> void:call_deferred("run_checks")

func key(code:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame

func pad(index:JoyButton) -> void:
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.device=99;event.button_index=index;event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame

func run_checks() -> void:
	root.content_scale_size=Vector2i.ZERO
	var theme:=Mural.shared()
	check(theme != null,"Mural Theme resource loads")
	check(theme==Mural.shared(),"shared Theme is reused")
	check(theme.get_stylebox("normal","MuralFocusButton") is StyleBoxTexture,"focus uses illustrated poster")
	for id in ["team","bag","missions","emblems","identity","workshop","save","settings","dex","evolution","varal","puxao"]:
		check(Mural.icon(id)!=null,"icon loads: "+id)
	check(Mural.icon("not-an-icon")==null,"unknown icon handled without load error")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=resolution
		var lab:=Lab.new();root.add_child(lab)
		for scale in [1.0,1.5]:
			lab.set_text_scale(scale)
			for i in 5:await process_frame
			var region:=lab.scroll.get_global_rect()
			check(region.position.x>=23 and region.end.x<=resolution.x-23,"outer margins "+str(resolution)+" text "+str(scale))
			for button in lab.menu_buttons+lab.state_buttons:
				var r:Rect2=button.get_global_rect()
				check(r.position.x>=region.position.x-1 and r.end.x<=region.end.x+1,"no horizontal clipping: "+button.text+" "+str(resolution)+" "+str(scale))
				check(button.size.x+1>=button.get_combined_minimum_size().x,"native text/icon minimum: "+button.text)
		lab.free()
	root.size=Vector2i(1280,720)
	var lab:=Lab.new();root.add_child(lab)
	for i in 5:await process_frame
	lab.menu_buttons[0].grab_focus()
	await key(KEY_RIGHT)
	check(root.gui_get_focus_owner()==lab.menu_buttons[1],"keyboard right follows spatial neighbor")
	await key(KEY_ENTER)
	check(lab.activations==1,"keyboard confirms once on native button")
	Controls.configure_device(99,"Xbox test fixture")
	await pad(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner()==lab.menu_buttons[3],"simulated D-pad follows spatial neighbor")
	await pad(JOY_BUTTON_A)
	check(lab.activations==2,"simulated gamepad confirms once")
	lab.menu_buttons[0].grab_focus()
	for i in 4:await process_frame
	var position:Vector2=lab.menu_buttons[1].get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=position;motion.global_position=position
	Input.parse_input_event(motion);await process_frame
	check(root.gui_get_focus_owner()==lab.menu_buttons[0],"pointer hover does not steal keyboard focus")
	for pressed in [true,false]:
		var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=position;click.global_position=position;click.pressed=pressed
		Input.parse_input_event(click);await process_frame
	check(lab.activations==3,"simulated mouse click confirms once")
	check(root.gui_get_focus_owner()==lab.menu_buttons[1],"click transfers focus to its target")
	lab.state_buttons[0].grab_focus()
	await key(KEY_TAB)
	check(root.gui_get_focus_owner()!=lab.state_buttons[1],"Tab navigation skips disabled button")
	lab.open_notice(lab.menu_buttons[1])
	for i in 4:await process_frame
	check(lab.dialog.visible,"native modal opens")
	lab.dialog.hide()
	for i in 4:await process_frame
	check(root.gui_get_focus_owner()==lab.menu_buttons[1],"modal restores originating focus")
	for meter in lab.meters:
		meter.value=200
		check(meter.value==100,"Range clamps overfull resource")
		meter.value=-5
		check(meter.value==0,"Range clamps empty resource")
	lab.free()
	var folder:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-130")
	DirAccess.make_dir_recursive_absolute(folder)
	var output:=FileAccess.open(folder.path_join("testes.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures,"input":"injected native Godot events, not physical devices","campaignSaveUsed":false},"\t"));output.close()
	print("MURAL CHECKS: ",checks,"; failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)
