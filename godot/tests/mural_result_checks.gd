extends SceneTree
const Fixtures=preload("res://tools/mural_result_fixtures.gd")
const Art=preload("res://scripts/ui_mural/result_art.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Banner=preload("res://scripts/campaign/hud_key_item_banner.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func settle() -> void:
	for frame in 12:await process_frame
func run() -> void:
	Controls.install();root.content_scale_size=Vector2i.ZERO
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["won","lost","fled","morro","boss","blocked"]:
				var view:=Fixtures.create(mode,scale)
				if mode=="blocked":view.result_wipe_started=false
				root.add_child(view);view.set_physics_process(false);view.blocked=mode=="blocked";view._physics_process(0);await settle();view._layout_actions();await settle()
				var card:Control=view.reward_card;var before:=JSON.stringify(view.reward_player)
				var viewport:=Rect2(Vector2(16,16),Vector2(dimensions)-Vector2(32,32))
				if mode!="blocked":check(viewport.encloses(card.get_global_rect()),"receipt inside safe viewport "+str(dimensions)+str(scale)+mode)
				check(viewport.encloses(view.finish_button.get_global_rect()),"continue always visible")
				if mode!="blocked":
					check(card.get_global_rect().grow(-31.9).encloses(card.scroll.get_global_rect()),"receipt content excludes ornament bleed")
					check(view.bottom_panel.position.y>=Art.layout(Vector2(dimensions),scale,view.model.outcome).bottom-1,"header/subtitle never cross receipt")
				else:
					check(not card.is_visible_in_tree() and not view.finish_button.visible and view.resume_button.visible and not view.result_wipe_started,"failed save hides rewards and offers retry without celebration")
					check(viewport.encloses(view.resume_button.get_global_rect()),"retry remains in safe viewport")
				check(not card.summary.committed and card.shown==card.summary.get("xp",0),"preview is static and explicit")
				card.advance(.1);card.advance(5);check(JSON.stringify(view.reward_player)==before,"presentation never grants XP money or items")
				check("prévia" in card.earned.text,"projected XP marked preview")
				check(view.finish_button.disabled==(mode=="blocked"),"save failure blocks continue")
				for label in card.find_children("*","Label",true,false) if mode!="blocked" else []:
					check(label.get_visible_line_count()==label.get_line_count(),"native wrapped label height fits")
					check(label.get_theme_font_size("font_size")>=16,"text never shrinks below baseline")
				if mode!="blocked":check(root.gui_get_focus_owner()==view.finish_button,"initial focus stays on continue")
				if mode=="morro":check(card.summary.stars>0 and card.summary.has("unlock"),"district stars and passage preserved")
				if mode=="blocked":
					view.blocked=false;view._physics_process(0);await settle()
					check(card.visible and view.finish_button.visible and view.result_wipe_started and root.gui_get_focus_owner()==view.finish_button,"successful retry restores receipt and continue focus")
				view.free();await settle()
	for moment in ["item","emblem","level"]:
		var banner:=Banner.new();banner.moment=moment;banner.item_name="Insígnia do Morro do Sol";banner.item_texture=load("res://assets/ui/key-items/insignia-morro-do-sol.png");root.add_child(banner);banner.set_process(false);await settle()
		check(banner.duration==(3.0 if moment=="emblem" else 1.7 if moment=="level" else 2.5),"distinct milestone pacing")
		check(banner.opacity_at(0)==0 and banner.opacity_at(.8)==1 and banner.opacity_at(banner.duration)==0,"milestone fades")
		var signals:=[];banner.finished.connect(func():signals.append(true));banner._process(10);banner._process(10);check(signals.size()==1,"milestone completes exactly once");banner.free()
	for device in ["keyboard","mouse","pad"]:
		var view:=Fixtures.create("won",1.5);root.add_child(view);view.set_physics_process(false);view._physics_process(0);await settle()
		var requests:=[];view.finish_requested.connect(func():requests.append(true))
		for pressed in [true,false]:
			var event:InputEvent
			if device=="keyboard":event=InputEventKey.new();event.keycode=KEY_ENTER;event.physical_keycode=KEY_ENTER
			elif device=="pad":event=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A
			else:event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=view.finish_button.get_global_rect().get_center()
			event.pressed=pressed;Input.parse_input_event(event);await process_frame
		check(requests.size()==1,"native continue request by "+device);view.free();await settle()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-136"))
	var file:=FileAccess.open("res://../documentation/hud-v2/pip-136/testes.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"matrix":"4 resolutions, 100/150% text"},"\t"));file.close()
	print("MURAL RESULTS: ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
