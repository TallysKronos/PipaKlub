extends SceneTree
const Dialogue=preload("res://scripts/campaign/hud_dialogue.gd")
const Surface=preload("res://scripts/campaign/hud_dialogue_surface.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
var checks:=0
var failures:Array[String]=[]
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
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;Controls.install()
	var word:="inconstitucionalissimamente".repeat(12)
	var lines:=Surface.wrapped_lines(word,T.text(),36,300)
	check("".join(lines)==word,"long unbroken word preserves every character")
	for line in lines:check(T.text().get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,36).x<=300,"long token is split to available width")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["long","options"]:
				var view:=Dialogue.new();view.text_scale=scale;view.reduced_motion=true
				view.dialog_text="Sr. Assis: "+("Uma explicação longa sobre cuidar da linha, da armação e do vínculo com o parceiro. ".repeat(5) if mode=="long" else "Como vamos nos preparar?")
				if mode=="options":view.options=[{"id":"a","text":"Quero conhecer melhor os caminhos do bairro."},{"id":"b","text":"Prefiro preparar o meu parceiro antes de explorar.","safe":true},{"id":"c","text":"Pode me explicar o funcionamento da Linha e da Armação?"},{"id":"d","text":"Vou descansar e volto depois."}]
				root.add_child(view);await settle()
				var viewport:=Rect2(Vector2(20,20),Vector2(dimensions)-Vector2(40,40))
				for widget in [view.box,view.nameplate,view.choice_scroll]:check(viewport.encloses(widget.get_rect()),"panel safe viewport "+str(dimensions)+str(scale)+mode)
				check(not view.box.get_rect().intersects(view.nameplate.get_rect()),"speaker separate from body")
				check(not view.nameplate.get_rect().intersects(view.choice_scroll.get_rect()),"speaker separate from choices")
				check(not view.box.get_rect().intersects(view.choice_scroll.get_rect()),"choices separate from speech")
				check(view.portrait.get_rect().end.x+12<=view.box.position.x,"portrait never crosses body text")
				var safe:=Paper.content(view.box.get_global_rect(),.45)
				check(safe.grow(.1).encloses(view.body.get_global_rect()),"body is inside ornament-free content")
				for index in view.pages.size():
					view.page_index=index;view._show_page();await settle()
					check(view.body.get_line_count()<=3,"three lines per page")
					check(view.body.get_visible_line_count()==view.body.get_line_count(),"all lines visible")
					check(view.body.get_theme_font("font").get_height(view.body.get_theme_font_size("font_size"))*view.body.get_line_count()<=view.body.size.y,"font line heights fit")
				if mode=="options":
					check(root.gui_get_focus_owner()==view.option_buttons[1],"safe option initially focused")
					for button in view.option_buttons:
						button.grab_focus();await settle()
						check(view.choice_scroll.get_global_rect().grow(.5).encloses(button.get_global_rect()),"focus scrolls whole option into view")
					var selected:Array[String]=[]
					view.choice_selected.connect(func(id:String):selected.append(id))
					await key(KEY_ENTER);await key(KEY_ENTER)
					check(selected==["d"],"native confirm emits exactly one choice")
				view.free();await settle()
	var before:=Button.new();before.text="Voltar à exploração";root.add_child(before);before.grab_focus();await settle()
	var view:=Dialogue.new();view.dialog_text="Nina: "+"Uma conversa comprida com mais de uma página para verificar a confirmação. ".repeat(10)
	var confirms:=[];view.confirmed.connect(func():confirms.append(true));root.add_child(view);await settle()
	await key(KEY_ESCAPE);check(view.page_index==1 and confirms.is_empty(),"Escape advances notice without confirming unread pages")
	while view.page_index<view.pages.size()-1:view.next_page()
	await settle();await key(KEY_ENTER);await key(KEY_ENTER);check(confirms.size()==1,"notice confirms once after final page")
	view.free();await settle();check(root.gui_get_focus_owner()==before,"closing restores previous native focus");before.free()
	for device in ["mouse","pad"]:
		var prompt:=Dialogue.new();prompt.dialog_text="Assis: Vamos preparar o parceiro?";prompt.cancel_button_text="Agora não"
		var responses:=[];prompt.confirmed.connect(func():responses.append("accept"));prompt.canceled.connect(func():responses.append("cancel"))
		root.add_child(prompt);await settle()
		check(root.gui_get_focus_owner()==prompt.decline,"destructive/optional prompt initially focuses cancel")
		if device=="mouse":
			for pressed in [true,false]:
				var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=prompt.accept.get_global_rect().get_center();event.pressed=pressed;Input.parse_input_event(event);await process_frame
			check(responses==["accept"],"native mouse click confirms")
		else:
			for code in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_A]:
				for pressed in [true,false]:
					var event:=InputEventJoypadButton.new();event.button_index=code;event.pressed=pressed;Input.parse_input_event(event);await process_frame
			check(responses==["accept"],"native pad directional navigation and confirm")
			check(Controls.gamepad,"pad event updates prompt family")
		prompt.free();await settle()
	var file:=FileAccess.open("res://../documentation/hud-v2/pip-134/testes.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"input":"Injected native keyboard, mouse and gamepad events; no physical-device test","resolutions":["1280x720","1920x1080","1024x768","1280x800"],"textScales":[1,1.5]},"\t"));file.close()
	print("MURAL DIALOGUE: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
