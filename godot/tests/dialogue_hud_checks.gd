extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Surface=preload("res://scripts/campaign/hud_dialogue_surface.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,text:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+text)
func settle() -> void:
	for frame in 8:await process_frame
func run() -> void:
	var parsed:=Surface.parse_tags("[emo=suor][voz=grito][reacao=HÃ?!] Olá!")
	check(parsed.text=="Olá!" and parsed.emotion=="sweat" and parsed.shout and parsed.reaction=="HÃ?!","emotion, reaction and shout tags parse cleanly")
	for tag in Surface.EMOTIONS:check(not Surface.parse_tags("[emo=%s] Texto"%tag).emotion.is_empty(),"supported emotion "+tag)
	check(Surface.parse_tags("[emo=desconhecida] Texto").text=="Texto","unknown emotion is stripped safely")
	var probe=load("res://scripts/campaign/hud_dialogue.gd").new()
	root.add_child(probe)
	var confirms:=[]
	probe.confirmed.connect(func():confirms.append(true))
	probe._finish(true);probe._finish(true)
	check(confirms.size()==1,"confirmation emits once")
	probe.free()
	var four=load("res://scripts/campaign/hud_dialogue.gd").new()
	four.dialog_text="Escolha uma resposta."
	four.options=[{"id":"a","text":"Primeira"},{"id":"b","text":"Depois","safe":true},{"id":"c","text":"Terceira"},{"id":"d","text":"Quarta"}]
	root.add_child(four);await settle()
	check(four.option_buttons.size()==4,"supports four native response strips")
	check(root.gui_get_focus_owner()==four.option_buttons[1],"explicit safe response gets focus")
	four.free()
	var owner:=Node2D.new()
	root.add_child(owner)
	var bubble_a=load("res://scripts/campaign/hud_world_speech.gd").spawn(owner,Vector2.ZERO,"Olá!")
	var bubble_b=load("res://scripts/campaign/hud_world_speech.gd").spawn(owner,Vector2.ZERO,"Ei!")
	await settle()
	check(get_nodes_in_group("world_manga_speech").size()==1,"at most one ambient balloon")
	bubble_b._process(2.1);await settle()
	check(get_nodes_in_group("world_manga_speech").is_empty(),"ambient balloon expires after two seconds")
	owner.free()
	var front:=Front.new()
	front.session._store=Store.new("user://dialogue-hud-"+State.new_id())
	front.preferences.storage_path="user://dialogue-hud-"+State.new_id()+".cfg"
	root.add_child(front)
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip74")
	if capture:DirAccess.make_dir_recursive_absolute(output)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		if "--quick" in OS.get_cmdline_user_args() and viewport!=Vector2i(1280,720):continue
		root.size=viewport
		for reduced in [false,true]:
			if "--quick" in OS.get_cmdline_user_args() and reduced:continue
			front.preferences.reduced_motion=reduced
			for scenario in ["morro-dialog","long-notice","starter-confirm","workshop-cancel","binding-dialog","nina","assis"]:
				Fixtures.show(front,"park" if scenario=="nina" else "professor" if scenario=="assis" else scenario)
				if scenario=="nina":front._notice("Nina: [emo=suor]Ele cortou minha linha perto dos canos. Meu Carcará ficou lá… Eu só consegui voltar até aqui.")
				if scenario=="assis":front._notice("Sr. Assis: [emo=brilho]Pronto! Reforcei a linha e a armação dos seus parceiros. Estão novos em folha.")
				await settle()
				var dialogs:=get_nodes_in_group("manga_dialogue")
				check(dialogs.size()==1,"one shared manga dialogue: "+scenario)
				if dialogs.is_empty():continue
				var dialog:Control=dialogs[0]
				var page_count:int=dialog.pages.size()
				check(page_count>0,"dialogue has pages")
				var original_text:String=dialog.dialog_text
				dialog.dialog_text=original_text+" "+"Uma explicação um pouco mais longa para verificar a leitura e o espaço sem esconder palavras. ".repeat(maxi(1,original_text.length()/200))
				await settle()
				for index in dialog.pages.size():
					dialog.page_index=index;dialog._show_page();await settle()
					check(dialog.body.get_line_count()<=3,"at most three lines per page")
					check(dialog.body.get_visible_line_count()>=dialog.body.get_line_count(),"long text has enough height")
					for widget in [dialog.box,dialog.nameplate,dialog.choices]:check(Rect2(Vector2.ZERO,dialog.size).encloses(widget.get_rect()),"panel and choices stay in viewport")
					check(dialog.body.get_global_rect().end.y<dialog.size.y-20,"body leaves bottom breathing room")
				check(root.gui_get_focus_owner()==(dialog.decline if dialog.decline.visible else dialog.accept),"safe final choice gets focus")
				if scenario=="morro-dialog":
					var speakers:Array=[]
					for page in dialog.pages:
						if page.speaker not in speakers:speakers.append(page.speaker)
					check("Juninho" in speakers and "Lia" in speakers,"duo changes speaker by line")
				if capture:
					dialog.dialog_text=original_text
					dialog.page_index=mini(1,dialog.pages.size()-1) if scenario=="morro-dialog" else 0
					dialog._show_page();await settle()
					await create_timer(.3).timeout
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("%s-%s-%dx%d.png"%[scenario,"reduzido" if reduced else "normal",viewport.x,viewport.y]))
		for step in [0,5,6,10]:
			Fixtures.show(front,"opening-%d"%step);await settle()
			check(front.speech.get_line_count()<=3,"opening stays at most three lines")
			check(front.speech.get_global_rect().end.y<front.size.y,"opening text visible")
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("opening-%d-%dx%d.png"%[step,viewport.x,viewport.y]))
	front.free()
	print("DIALOGUE HUD: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
