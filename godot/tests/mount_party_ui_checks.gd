extends SceneTree
const Quest=preload("res://scripts/campaign/mount_quest.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	for i in 12:await process_frame
func capture(label:String) -> void:
	await RenderingServer.frame_post_draw
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/mount-party-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func run() -> void:
	root.size=Vector2i(1280,720);root.gui_disable_input=true
	var app=load("res://scripts/campaign/front_end.gd").new()
	var dir:="user://mount-party-ui-"+preload("res://scripts/campaign/state.gd").new_id()
	app.session._store=load("res://scripts/campaign/save_store.gd").new(dir);app.preferences.storage_path=dir+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	app.session.start("slot-1")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"};player.inventory[Quest.ITEM]=1
	Quest.grant_partner(player);player.equippedPartnerId=player.partners[0].id
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(player);player.flags.pipeiroDocumentsSeen=true
	check(app.session.checkpoint({"kind":"world","scene":"quintal","space":"bairro-inicial-v2","position":[22,18.5]},player).status=="ok","valid real partner save")
	app._show_saved()
	for i in 600:
		await process_frame
		if not is_instance_valid(app.scene_loading):break
	await settle()
	app.park.toggle_mount();check(app.park.avatar.mounted,"live city mounts party creature")
	app.park.saved_player.partners[0].condition.line=0
	app.park.avatar._process(0);check(not app.park.avatar.mounted,"live HP loss dismounts")
	app.park.saved_player=player.duplicate(true)
	app.park.toggle_mount();check(app.park.avatar.mounted,"repaired creature mounts")
	app.park.saved_player.partners=[]
	app.park.avatar._process(0);check(not app.park.avatar.mounted,"party removal dismounts")
	app._show_collection();await settle()
	check(app.page.find_child("MountCapability",true,false)!=null,"mount icon beside party portrait")
	await capture("01-team")
	var combat=Model.new(player.partners[0],{"modelId":"mata","level":1})
	var view=load("res://scripts/campaign/encounter_view.gd").new()
	view.configure(app.content,combat.snapshot());view.reward_player=player;view.reduced_motion=true
	app._clear();app.add_child(view);view.paused=true;view.model.intro=0
	await settle()
	check(view.art_ids[0]==Quest.MODEL,"battle uses Doberman artwork")
	check(view.model.partner_id==player.equippedPartnerId and view.model.p.hp==100,"battle uses same selected party member and HP")
	var hp:float=view.model.p.hp
	view.model._apply_hit({"target":view.model.p,"body":false,"damage":10})
	check(view.model.p.hp<hp,"mount receives combat damage")
	await capture("02-battle")
	app.free();print("Mount party UI: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
