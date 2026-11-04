extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
var app:Control
var checks:=0
var failures:=0
var output:="res://../documentation/qa/pipeiro-identity-v2"
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func settle() -> void:
	for i in 10:await process_frame
func card() -> Control:
	for child in app.get_children():
		if child.get_script()==load("res://scripts/campaign/hud_pipeiro_identity.gd"):return child
	return null
func capture(name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.gui_disable_input=true
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://identity-layout-"+State.new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.tamerXp=350;player.coins=3560
	player.partners=[{"id":"layout-partner","modelId":"rabbito","xp":1380,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="layout-partner"
	Identity.issue_into(player);player.flags.pipeiroDocumentsSeen=true
	Identity.award_district(player,0,"mikka","Insígnia do Morro do Sol",{"districtName":"Morro do Sol","bossName":"Mikka"})
	player.inventory["insignia-morro-do-sol"]=1
	player.morro=load("res://scripts/campaign/morro_rules.gd").defaults()
	for stage in ["morro-1","morro-2","morro-3","morro-4","morro-5"]:player.morro.stars[stage]=2
	check(app.session.checkpoint({"kind":"world","scene":"morro-area-5","position":[300,300]},player).status=="ok","issued identity fixture saves")
	for viewport in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768)]:
		root.size=viewport
		if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
		app._show_identity();await settle()
		var screen:=card()
		check(screen.tabs.size()==2,"identity has no emblem or settings tab")
		check(screen.name_label.text=="Kael","real player name")
		for index in 2:
			screen.tabs[index].pressed.emit();await settle()
			check(screen.pages[index].visible and screen.pages.filter(func(page):return page.visible).size()==1,"tab switches to one page")
			check(root.get_visible_rect().encloses(screen.back.get_global_rect()),"return within viewport")
			for label in screen.pages[index].find_children("*","Label",true,false):
				if label.is_visible_in_tree():check(root.get_visible_rect().encloses(label.get_global_rect()),"visible copy within viewport")
			if viewport!=Vector2i(1024,768):await capture("%s-%dx%d"%[["perfil","historico"][index],viewport.x,viewport.y])
	player=app.session.snapshot().player;player.name="Um nome de pipeiro muito comprido para conferir as margens";player.tamerXp=31383
	for id in ["basica","mata","azulao","raio"]:player.partners.append({"id":id,"modelId":id,"xp":400,"condition":{"line":100,"structure":100}})
	app.session.checkpoint(app.session.snapshot().checkpoint,player)
	root.size=Vector2i(1280,720);app._show_identity();await settle()
	check(card().name_label.tooltip_text==player.name,"full long name available")
	check(root.get_visible_rect().encloses(card().back.get_global_rect()),"full team and maximum level fit")
	check(card().find_children("*","Label",true,false).any(func(label):return label.text=="Nível máximo de tamer"),"maximum level does not imply another level")
	await capture("perfil-nome-longo-equipe-cheia")
	app.free();await settle()
	print("IDENTITY LAYOUT: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
