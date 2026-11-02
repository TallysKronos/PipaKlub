extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Prefs=preload("res://scripts/campaign/preferences.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Impacts=preload("res://scripts/campaign/hud_impacts.gd")
const Option=preload("res://scripts/ui_mural/dialogue_option.gd")
var checks:=0
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);printerr("FAIL ",message)
func settle()->void:
	for frame in 8:await process_frame
func run()->void:
	root.content_scale_size=Vector2i.ZERO
	var output:=ProjectSettings.globalize_path("res://../documentation/hud-v2/pip-138");DirAccess.make_dir_recursive_absolute(output)
	var path:=ProjectSettings.globalize_path("res://../tmp/pip138-"+preload("res://scripts/campaign/state.gd").new_id())
	var prefs:=Prefs.new();prefs.storage_path=path+".cfg";prefs.text_scale=1.5;prefs.reduced_motion=true
	check(prefs.save_settings()==OK,"isolated preferences save")
	var loaded:=Prefs.new();loaded.load_settings(prefs.storage_path)
	check(loaded.text_scale==1.5 and loaded.reduced_motion,"150% and reduced motion survive reload")
	var impacts:=Impacts.new();impacts.reduced_motion=true;impacts.add({"point":Vector2(400,300),"amount":28,"critical":true});impacts.step(.4)
	check(impacts.bursts.size()==1,"reduced-motion damage readable after 400ms")
	impacts.step(.41);check(impacts.bursts.is_empty(),"damage labels still expire")
	impacts.reduced_motion=false;impacts.add({"point":Vector2.ZERO,"amount":1});impacts.step(.61);check(impacts.bursts.is_empty(),"normal motion lifetime unchanged")
	var front:=Front.new();front.session._store=Store.new(path);front.preferences.storage_path=path+"-front.cfg";root.add_child(front)
	front.preferences.crt=false;front.preferences.reduced_motion=true;front.preferences.audio_levels.master=0
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(1280,800)]:
		root.size=dimensions
		for scale in [1.0,1.5]:
			var boss=preload("res://scripts/campaign/boss_presentation.gd").new();boss.text_scale=scale;root.add_child(boss);await settle()
			check(Rect2(Vector2(20,20),Vector2(dimensions)-Vector2(40,40)).encloses(boss.skip.get_global_rect()),"boss skip button stays inside viewport")
			check(boss.skip.get_theme_font_size("font_size")==roundi(20*scale),"boss text scales once")
			boss.free()
			front.preferences.text_scale=scale;front._apply_preferences()
			for category in ["Vídeo","Áudio","Acessibilidade","Controles"]:
				front.settings_tab=category;front._show_settings();await settle()
				var scroll:ScrollContainer=front.page.get_parent()
				var context:String=str(dimensions)+str(scale)+category
				check(front.page.size.x<=scroll.size.x+1,"settings never require horizontal scroll "+context)
				for node in front.page.find_children("*","BaseButton",true,false):
					if not node.is_visible_in_tree():continue
					var rect:Rect2=node.get_global_rect()
					check(rect.position.x>=scroll.global_position.x-1 and rect.end.x<=scroll.get_global_rect().end.x+1,"button fits horizontally "+context+str(node.text))
				if category=="Acessibilidade":
					var choices:=front.page.find_children("*","OptionButton",true,false)
					var text_size:OptionButton=choices.filter(func(choice):return choice.item_count==4 and choice.get_item_text(3).contains("150%"))[0]
					check(text_size.selected==Prefs.TEXT_SCALES.find(scale),"real setting reflects applied text scale")
					text_size.item_selected.emit(3);await settle()
					var persisted:=Prefs.new();persisted.load_settings(front.preferences.storage_path)
					check(persisted.text_scale==1.5,"UI choice persists 150%")
					front.preferences.text_scale=scale;front._apply_preferences()
	front.free();await settle()
	var host:=Control.new();host.set_meta("owns_ui_theme",true);root.add_child(host)
	var option:=Option.new();option.text="Escolher caminho";host.add_child(option);option.size=Vector2(360,90);option.grab_focus();await settle()
	check(option.has_focus(),"native option focus retained")
	option.disabled=true;check(option.get_theme_color("font_disabled_color")==Option.T.MURAL_MUTED,"disabled label stays opaque and readable")
	host.free()
	var file:=FileAccess.open(output.path_join("testes.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"campaignSaveUsed":false},"\t"));file.close()
	print("MURAL ACCESSIBILITY ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
