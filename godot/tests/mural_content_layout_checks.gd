extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Fixtures=preload("res://tools/mural_menu_fixtures.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func settle()->void:
	for frame in 12:await process_frame
func tap(code:Key)->void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;root.push_input(event,true);await process_frame
func run()->void:
	root.content_scale_size=Vector2i.ZERO
	var front:=Front.new();var path:=ProjectSettings.globalize_path("res://../tmp/pip139-layout-"+State.new_id());front.session._store=Store.new(path);front.preferences.storage_path=path+".cfg";front.preferences.audio_levels.master=0;root.add_child(front)
	front.preferences.reduced_motion=true
	front.session._snapshot=State.fresh("slot-1");front.session._snapshot.player=Fixtures.player();front.session._snapshot.checkpoint={"kind":"world","scene":"professor-home","position":[1056,1232]}
	var original:=JSON.stringify(front.session.snapshot())
	for extent in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=extent
		for scale in [1.0,1.5]:
			front.preferences.text_scale=scale;front._apply_preferences();front._show_identity();await settle()
			var card:Control=front.get_children().filter(func(child):return child.get_script()==preload("res://scripts/campaign/hud_pipeiro_identity.gd"))[0]
			check(card.text_scale==scale,"identity receives scale once")
			check(Rect2(Vector2(16,16),Vector2(extent)-Vector2(32,32)).encloses(card.back.get_global_rect()),"identity return target inside screen")
			var scroll:ScrollContainer=card.pages[0];scroll.grab_focus();await tap(KEY_DOWN);await settle()
			check(scroll.get_v_scroll_bar().max_value<=scroll.size.y+1 or scroll.scroll_vertical>0,"profile can be scrolled with actual keyboard input")
			card.tabs[1].pressed.emit();await settle();check(card.pages[1].visible and not card.pages[0].visible,"history still selects its own page")
			front._show_controls();await settle();var binding:Button=front.binding_rows.dodge.button
			binding.grab_focus();await settle();check(binding.autowrap_mode!=TextServer.AUTOWRAP_OFF and binding.size.y>=binding.get_minimum_size().y,"long remapping action wraps inside its button")
			front._show_bag();await settle()
			var outer:ScrollContainer=front.page.get_parent();check(outer.follow_focus,"bag outer scroll follows footer focus")
			var care:=front.page.find_children("*","Button",true,false).filter(func(button):return button.text=="Cuidar do parceiro" and not button.disabled)
			check(not care.is_empty(),"care remains available in world fixture")
			for button in care:
				button.grab_focus();await settle();check(Rect2(Vector2(16,16),Vector2(extent)-Vector2(32,32)).encloses(button.get_global_rect()),"care target scrolls fully into view")
			check(JSON.stringify(front.session.snapshot())==original,"layout changes do not mutate campaign state")
	front.free();await settle()
	var output:=FileAccess.open("res://../documentation/hud-v2/pip-139/layout-tests.json",FileAccess.WRITE);output.store_string(JSON.stringify({"checks":checks,"failures":failures,"input":"injected keyboard and programmatic focus; isolated in-memory campaign"},"\t"));output.close()
	print("MURAL CONTENT LAYOUT ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
