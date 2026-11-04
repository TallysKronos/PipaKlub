extends SceneTree
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Badges=preload("res://scripts/campaign/district_badges.gd")
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
const Morro=preload("res://scripts/campaign/morro.gd")
const Model=preload("res://scripts/campaign/morro_model.gd")
var app:Control
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL ",message)
func settle() -> void:
	for i in 10:await process_frame
func terminal(outcome:String) -> void:
	var saved:Dictionary=app.session.snapshot()
	var model:=Model.new();model.restore(saved.player.encounter.state)
	model.outcome=outcome
	if outcome=="won":model.p.rounds=model.rounds_to_win
	if outcome=="lost":model.q.rounds=model.rounds_to_win
	saved.player.encounter.state=model.snapshot()
	check(app.session.checkpoint(saved.checkpoint,saved.player).status=="ok","persist terminal fixture "+outcome)
func capture(name:String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():return
	var folder:=ProjectSettings.globalize_path("res://../documentation/qa/first-district-insignia-v1")
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name+".png"))
func run() -> void:
	app=load("res://scripts/campaign/front_end.gd").new()
	var folder:="user://first-insignia-"+State.new_id()
	app.session._store=Store.new(folder);app.preferences.storage_path=folder+".cfg"
	root.add_child(app);app.preferences.reduced_motion=true
	var icon:Image=load("res://assets/ui/key-items/insignia-morro-do-sol.png").get_image()
	check(icon.get_size()==Vector2i(128,128),"native 128-pixel insignia")
	var colors:Dictionary={};var opaque:=true
	for y in 128:
		for x in 128:
			var color:=icon.get_pixel(x,y)
			if color.a!=0 and color.a!=1:opaque=false
			if color.a>0:colors[color.to_html()]=true
	check(opaque,"binary alpha, no antialiasing")
	check(colors.size()<=9,"limited nine-color palette")
	check(app.session.start("slot-1").status=="ok","isolated journey")
	var player:Dictionary=app.session.snapshot().player
	player.journey={"lesson":5,"phase":"complete"}
	player.partners=[{"id":"insignia-partner","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="insignia-partner"
	Identity.issue_into(player);player.flags.pipeiroDocumentsSeen=true
	check(not Badges.award_first_into(player),"training alone gives no insignia")
	player.flags.guardianDefeated=true;player.flags.ninaReturned=true
	check(not Badges.award_first_into(player),"Nina and Lacertubo are not the first district championship")
	player.flags.erase("guardianDefeated");player.flags.erase("ninaReturned")
	check(app.session.checkpoint({"kind":"world","scene":"professor-home","position":[1152,864]},player).status=="ok","prepared fixture")
	var final_point:=Vector2.ZERO
	for i in 5:
		var scene:String="morro" if i==0 else "morro-area-%d"%(i+1)
		var map:Dictionary=Morro.maps()[scene]
		var place:Dictionary=map.places.filter(func(p):return p.has("stage"))[0]
		var point:=Vector2(place.point[0],place.point[1])
		player=app.session.snapshot().player
		player.partners[0].condition={"line":100,"structure":100}
		check(app.session.checkpoint({"kind":"world","scene":scene,"position":place.point},player).status=="ok","enter challenge "+scene)
		if i==4:
			final_point=point
			for outcome in ["lost","fled"]:
				check(app.morro.start(point).status=="ok","Mikka challenge "+outcome)
				terminal(outcome)
				check(app.morro.settle().status=="ok","settle "+outcome)
				check(not Badges.has_first(app.session.snapshot().player),"no insignia after "+outcome)
		check(app.morro.start(point).status=="ok","earned route unlocks challenge "+scene)
		terminal("won")
		if i==4:
			var newer:Dictionary=app.session._store.load_slot("slot-1").data
			check(app.session._store.save_slot(newer).status=="ok","concurrent revision before reward")
			var old_coins:int=app.session.snapshot().player.coins
			check(app.morro.settle().status=="stale","failed reward reports conflict")
			check(not Badges.has_first(app.session.snapshot().player) and app.session.snapshot().player.coins==old_coins,"failed commit grants neither insignia nor money")
			check(app.session.resume_slot("slot-1").status=="ok","resume terminal battle after conflict")
		check(app.morro.settle().status=="ok","settle actual challenge "+scene)
		check(Badges.has_first(app.session.snapshot().player)==(i==4),"first insignia only after Mikka")
	check(app.session.snapshot().player.inventory[Badges.FIRST_ITEM]==1,"one permanent insignia item")
	check(app.session.snapshot().player.districtEmblems.size()==1,"first of twelve positions filled")
	check(app.session.snapshot().player.districtEmblems["bairro-01"].bossName=="Mikka","champion metadata is canonical")
	check(Badges.pending(app.session.snapshot()),"award awaits presentation")
	check(app.session.snapshot().player.lastMorro.insignia,"final result marks first insignia")
	check(app.morro.settle().status=="wrong_step","result cannot settle twice")
	var badge_date:int=app.session.snapshot().player.districtEmblems["bairro-01"].earnedAt
	app._return_morro_result();await settle()
	var dialogs:=get_nodes_in_group("manga_dialogue")
	check(dialogs.size()==1 and "Mikka:" in dialogs[0].dialog_text,"Mikka announces first district victory")
	if not dialogs.is_empty():dialogs[0].confirmed.emit()
	await settle()
	var banner:Control
	for child in app.get_children():
		if child.has_meta("key_item_banner"):banner=child
	check(is_instance_valid(banner) and banner.item_name==Badges.FIRST_NAME,"acquisition banner uses actual insignia")
	if not is_instance_valid(banner):quit(1);return
	check(not app.session.snapshot().player.flags.get("firstInsigniaSeen",false),"presentation not acknowledged prematurely")
	banner.set_process(false);banner.elapsed=.8;banner.queue_redraw()
	await settle();await capture("banner-1280x720")
	banner._process(2.5);await settle()
	check(not Badges.pending(app.session.snapshot()),"banner completion saved")
	dialogs=get_nodes_in_group("manga_dialogue")
	check(dialogs.size()==1 and dialogs[0].ok_button_text=="Ver porta-emblemas","explicit route to the new insignia")
	if not dialogs.is_empty():dialogs[0].confirmed.emit()
	await settle()
	var case:Control
	for child in app.get_children():
		if child.has_meta("emblem_case"):case=child
	check(is_instance_valid(case) and case.count.text.ends_with("1 / 12"),"actual case shows first victory")
	if is_instance_valid(case):
		check(case.selected==0 and case.art.seal_texture!=null,"first slot uses official insignia artwork")
		check(app.park.paused,"world remains stopped while admiring insignia")
		for viewport in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size=viewport
			if DisplayServer.get_name()!="headless":DisplayServer.window_set_size(viewport)
			await settle();await capture("primeira-insignia-%dx%d"%[viewport.x,viewport.y])
		case.back.pressed.emit();await settle()
	check(not app.park.paused,"closing case resumes exploration")
	check(app.session.resume_slot("slot-1").status=="ok" and Badges.has_first(app.session.snapshot().player) and not Badges.pending(app.session.snapshot()),"earned insignia survives restart without replay")
	player=app.session.snapshot().player;player.partners[0].condition={"line":100,"structure":100}
	check(app.session.checkpoint(app.session.snapshot().checkpoint,player).status=="ok","rematch recovery")
	# District rules: a won title is not replayed; only a pending defense reopens Mikka.
	check(app.morro.start(final_point).status=="already_applied","won Mikka duel is not replayed")
	player=app.session.snapshot().player
	check(player.inventory[Badges.FIRST_ITEM]==1 and player.districtEmblems.size()==1 and player.districtEmblems["bairro-01"].earnedAt==badge_date,"revisit never duplicates or re-dates insignia")
	check(not Badges.pending(app.session.snapshot()),"revisit does not replay ceremony")
	check(player.inventory["rabiola-raio"]==1,"unique tail remains unique")
	# Legacy completion receives only the missing insignia, never old combat rewards.
	check(app.session.start("slot-2").status=="ok","legacy fixture")
	var legacy:Dictionary=app.session.snapshot().player
	legacy.journey=player.journey;legacy.partners=player.partners;legacy.equippedPartnerId=player.equippedPartnerId
	legacy.morro=player.morro;legacy.coins=321;legacy.tamerXp=789;legacy.inventory={"rabiola-raio":1}
	check(app.session.checkpoint({"kind":"world","scene":"professor-home","position":[1152,864]},legacy).status=="ok","legacy championship saved")
	check(Badges.ensure_legacy(app.session).status=="ok","old completed save receives first insignia")
	legacy=app.session.snapshot().player
	check(legacy.coins==321 and legacy.tamerXp==789 and legacy.inventory["rabiola-raio"]==1,"legacy upgrade grants no extra XP, money or tail")
	check(not Identity.pending(app.session.snapshot()) and Badges.pending(app.session.snapshot()),"legacy presentation skips old training documents")
	check(Badges.ensure_legacy(app.session).status=="already_applied","legacy migration idempotent")
	app._show_saved();await settle()
	for child in app.get_children():
		if child.has_meta("key_item_banner"):child._process(2.5)
	await settle()
	check(not Badges.pending(app.session.snapshot()),"legacy acquisition presentation completes")
	app.queue_free();await settle()
	print("FIRST DISTRICT INSIGNIA: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)
