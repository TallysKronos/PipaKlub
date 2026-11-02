extends SceneTree
const Album=preload("res://scripts/ui_mural/partner_album.gd")
const Case=preload("res://scripts/campaign/hud_emblem_case.gd")
const Fixtures=preload("res://tools/mural_menu_fixtures.gd")
const Controls=preload("res://scripts/campaign/controls.gd")
const Paper=preload("res://scripts/ui_mural/paper_layout.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func settle() -> void:
	for frame in 12:await process_frame
func tap(key:Key) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.physical_keycode=key;event.keycode=key;event.pressed=pressed;Input.parse_input_event(event);await process_frame
func run() -> void:
	root.content_scale_size=Vector2i.ZERO;Controls.install()
	var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/content.json"))
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			for mode in ["varal","dex","evolution","emblems"]:
				var view:Control=Case.new() if mode=="emblems" else Album.new()
				view.player=Fixtures.player();view.text_scale=scale
				var original:=JSON.stringify(view.player)
				if mode!="emblems":view.content=content;view.mode=mode;view.can_care=true
				root.add_child(view);await settle()
				var viewport:=Rect2(Vector2(20,20),Vector2(dimensions)-Vector2(40,40))
				check(viewport.encloses(view.back.get_global_rect()),"footer fits "+str(dimensions)+str(scale)+mode)
				for tab in view.tabs:check(viewport.encloses(tab.get_global_rect()),"tabs fit "+mode)
				if mode=="emblems":
					check(view.slots.size()==12 and view.count.text.ends_with("1 / 12"),"12 slots and true earned count")
					for slot in view.slots:check(viewport.encloses(slot.get_global_rect()),"emblem socket inside safe viewport")
					view.set_filter(1);check(view.slots.filter(func(slot):return slot.visible).size()==1,"earned filter")
					view.set_filter(2);check(view.slots.filter(func(slot):return slot.visible).size()==11,"pending filter")
				else:
					check(viewport.encloses(view.body.get_global_rect()),"body fits "+mode)
					check(viewport.encloses(view.detail_scroll.get_global_rect()),"details viewport fits "+mode)
					check(not view.list_scroll.get_global_rect().intersects(view.detail_scroll.get_global_rect()),"list and detail separate")
					var padding:Array=preload("res://scripts/ui_mural/menu_art.gd").padding(view.detail_surface.family)
					var surface:Rect2=view.detail_surface.get_global_rect()
					var safe:=Rect2(surface.position+Vector2(padding[0],padding[2]),surface.size-Vector2(padding[0]+padding[1],padding[2]+padding[3]))
					check(safe.grow(.1).encloses(view.detail_scroll.get_global_rect()),"scroll viewport excludes all painted corners")
					for option in view.entry_buttons:
						option.grab_focus();await settle()
						check(view.list_scroll.get_global_rect().grow(.5).encloses(option.get_global_rect()),"focused entry fully visible")
					if mode=="dex":
						check(view.entries.size()==7,"only seven Godot species")
						check(not view.known("mata") and view.known("lacertubo") and view.acquired("rabbito"),"discoveries derive from save")
						view.select_entry(1);check(view.actions.is_empty(),"Dex never grants or equips")
					if mode=="varal":
						view.select_entry(2);await settle();check(view.hero_art.has_node("MountCapability"),"mount capability icon remains beside partner art")
						var emitted:=[];view.equip_requested.connect(func(id:String):emitted.append(id));view.select_entry(1);await settle()
						view.actions[0].grab_focus();await tap(KEY_ENTER)
						check(emitted==["basica"],"native confirm emits equip request with existing partner id")
						for action in view.actions:check(viewport.encloses(action.get_global_rect()),"care/equip remain outside clipped detail scroll")
					check(not view.entry_buttons.is_empty(),"native entry focus available")
				check(JSON.stringify(view.player)==original,"menu never changes player")
				view.free();await settle()
	var empty:=Album.new();empty.content=content;root.add_child(empty);await settle();check(empty.entries.is_empty() and empty.entry_buttons.is_empty(),"empty Varal has no fictitious partner");empty.free()
	var maximum:=Album.new();maximum.content=content;maximum.player=Fixtures.player();maximum.player.partners[0].xp=preload("res://scripts/campaign/partner_levels.gd").xp_for_level(50);maximum.mode="evolution";root.add_child(maximum);await settle()
	var max_labels:=maximum.detail.find_children("*","Label",true,false)
	check(max_labels.any(func(label):return "Nível máximo" in label.text),"level cap is explicitly labelled")
	check(not max_labels.any(func(label):return "XP do nível" in label.text),"maximum level has no fictitious next-level XP target");maximum.free()
	var error:=Album.new();error.content=content;error.load_state="error";root.add_child(error);await settle();check(error.actions.size()==1,"failed Varal offers retry");var retries:=[];error.retry_requested.connect(func():retries.append(true));error.actions[0].pressed.emit();check(retries.size()==1,"retry is wired");error.free()
	var navigation:=Album.new();navigation.player=Fixtures.player();navigation.content=content;root.add_child(navigation);await settle()
	await tap(KEY_TAB);check(navigation.mode=="dex","Tab cycles native album sections")
	for pressed in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_RIGHT_SHOULDER;event.pressed=pressed;Input.parse_input_event(event);await process_frame
	check(navigation.mode=="evolution","gamepad shoulder cycles section")
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=navigation.tabs[1].get_global_rect().get_center();event.pressed=pressed;Input.parse_input_event(event);await process_frame
	check(navigation.mode=="dex","mouse clicks section without changing player")
	navigation.select_entry(0);navigation.detail_scroll.grab_focus();await settle();await tap(KEY_DOWN)
	check(navigation.detail_scroll.scroll_vertical>0,"keyboard scrolls long Dex detail")
	await tap(KEY_LEFT);check(root.gui_get_focus_owner()==navigation.entry_buttons[0],"left returns from details to list")
	var closes:=[];navigation.closed.connect(func():closes.append(true));await tap(KEY_ESCAPE);check(closes.size()==1,"Escape requests lobby return");navigation.free()
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			var lobby:=preload("res://scripts/campaign/hud_pause.gd").new();lobby.player=Fixtures.player();lobby.text_scale=scale;Paper.auditing=true;root.add_child(lobby);await settle()
			for option in lobby.buttons.values():check(Rect2(Vector2(16,16),Vector2(dimensions)-Vector2(32,32)).encloses(option.get_global_rect()),"lobby targets stay in viewport")
			lobby.free();Paper.auditing=false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-135"))
	var file:=FileAccess.open("res://../documentation/hud-v2/pip-135/testes.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"matrix":"four resolutions, 100/150% text","input":"native injected keyboard, mouse and gamepad; legacy suites cover modal return"},"\t"));file.close()
	print("MURAL MENUS: ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
