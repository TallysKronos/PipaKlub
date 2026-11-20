extends SceneTree
const Store=preload("res://scripts/campaign/save_store.gd")
const Session=preload("res://scripts/campaign/session.gd")
const State=preload("res://scripts/campaign/state.gd")
const Bank=preload("res://scripts/campaign/partner_bank.gd")
const Opening=preload("res://scripts/campaign/opening.gd")
const Journey=preload("res://scripts/campaign/journey.gd")
const Workshop=preload("res://scripts/campaign/workshop_model.gd")
const Trust=preload("res://scripts/campaign/retalho_trust.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Front=preload("res://scripts/campaign/front_end.gd")
var checks:=0
var failures:=0
class FaultStore extends "res://scripts/campaign/save_store.gd":
	var deny_campaign:=false
	var deny_bank:=false
	var deny_completion:=false
	func _write_checked(path:String,data:Dictionary)->Error:return ERR_FILE_CANT_WRITE if deny_campaign else super(path,data)
	func _bank_write_json(path:String,data:Dictionary)->Error:
		return ERR_FILE_CANT_WRITE if deny_bank or (deny_completion and data.data.pending.is_empty()) else super(path,data)
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL pending rewards: ",label)
func op()->String:return "bank-transfer-"+State.new_id()
func mon()->Dictionary:return {"id":State.new_id(),"modelId":"basica","personalName":"Parceiro","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}
func fixture(count:int,opening:bool=false)->Node:
	var s:=Session.new();s._store=FaultStore.new("user://pending-rewards-"+State.new_id());s.separate_autosave=true;root.add_child(s)
	check(s.start("slot-1").status=="ok","start fixture")
	var saved:Dictionary=s.snapshot()
	for index in count:saved.player.partners.append(mon())
	if count>0:saved.player.equippedPartnerId=saved.player.partners[0].id
	saved.player.journey={"phase":"complete","lesson":5}
	saved.player.flags.ancientTailAttached=true
	check(s.checkpoint({"kind":"opening","step":10} if opening else {"kind":"world","scene":"professor-home","position":[1440,672]},saved.player).status=="ok","seed safe point")
	return s
func reward(s:Node,source:String)->Dictionary:
	var saved:Dictionary=s.snapshot();var p:=mon();p.personalName="Recompensa";p.origin=source;saved.player.partners.append(p)
	return s.commit_operation(source,saved.checkpoint,saved.player)
func queue(s:Node)->Array:return s.snapshot().player.get("pendingPartners",[])
func settle()->void:
	for frame in 8:await process_frame
func capture(name:String)->void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw;DirAccess.make_dir_recursive_absolute("res://tmp/pending-rewards")
	root.get_texture().get_image().save_png("res://tmp/pending-rewards/"+name+".png")
func run()->void:
	var s:=fixture(30,true);s.autosave_enabled=false
	check(s.save_manual("slot-1",1).status=="ok","save before birthday")
	check(Opening.new(s).name_partner("").status=="ok","full bank reserves Rabbito")
	check(s.snapshot().player.partners.size()==30 and queue(s).size()==1,"thirtieth slot not overwritten")
	var id:String=queue(s)[0].id
	check(queue(s)[0].mandatory and queue(s)[0].partner.modelId=="rabbito","Rabbito is essential")
	check(Opening.BIRTH in s.snapshot().player.completedOperations,"reward receipt committed with pending creature")
	var reopened:=Session.new();reopened._store=Store.new(s._store.directory);reopened.separate_autosave=true;root.add_child(reopened)
	check(reopened.resume_slot("slot-0").status=="ok" and queue(reopened)[0].id==id,"reservation survives restart even with autosave off")
	check(reopened.resolve_reward(id,"global","",op()).status=="reward_essential","essential reward cannot leave story")
	check(reopened.resolve_reward(id,"decline","",op()).status=="reward_essential","essential reward cannot be discarded")
	check(reopened.resolve_reward(id,"replace",reopened.snapshot().player.equippedPartnerId,op()).status=="bank_active","active victim protected")
	var victim:String=reopened.snapshot().player.partners[1].id
	check(reopened.resolve_reward(id,"replace",victim,op()).status=="ok","atomic release and receive Rabbito")
	check(queue(reopened).is_empty() and reopened.snapshot().player.partners.size()==30,"no overflow after replacement")
	check(reopened.snapshot().player.partners.any(func(p):return p.id==id) and not reopened.snapshot().player.partners.any(func(p):return p.id==victim),"correct identities replaced")
	check(reopened.resume_slot("slot-1").status=="ok" and queue(reopened).is_empty(),"old save cannot recreate a resolved reservation")
	check(Opening.new(reopened).name_partner("Duplicado").status=="ok","old naming step reuses earned identity")
	check(reopened.snapshot().player.partners.filter(func(p):return p.modelId=="rabbito").size()==1 and reopened.snapshot().player.partners.any(func(p):return p.id==id),"replaying birthday creates no second Rabbito")
	check(reopened.resolve_reward(id,"campaign","",op()).status=="reward_missing","stale reward action grants nothing")
	s.free();reopened.free()
	# A v1 profile remains readable; the first acquisition upgrades its generation.
	s=fixture(30)
	var legacy:Dictionary=Bank.new(s._store).fresh();legacy.version=1;legacy.revision=1
	var preserved:=mon();legacy.entries[preserved.id]={"owner":"global","partner":preserved}
	DirAccess.make_dir_recursive_absolute(s._store.bank_directory)
	var path:String=s._store.bank_directory.path_join("000000000001-"+State.new_id()+".json")
	check(s._store._bank_write_json(path,{"data":legacy,"hash":Bank.new(s._store)._canonical(legacy).sha256_text()})==OK,"seed legacy profile generation")
	check(Bank.new(s._store).load_ledger().data.version==1,"v1 ledger readable")
	check(reward(s,"migrated-award").status=="ok","v1 acquisition migrates recoverably")
	check(Bank.new(s._store).load_ledger().data.version==Bank.VERSION and s.bank_contents().partners[0].id==preserved.id,"migration preserves stored creature")
	var detached:Dictionary=s.snapshot()
	var blank:=Store.new("user://missing-profile-"+State.new_id());var original:RefCounted=s._store;s._store=blank
	check(s.bank_reconcile(detached).status=="bank_corrupt","missing profile never silently drops reservation ownership")
	s._store=original;s.free()
	s=fixture(30)
	check(reward(s,"space-open").status=="ok","reserve before vacancy")
	id=queue(s)[0].id
	check(s.transfer_partner(s.snapshot().player.partners[1].id,"deposit",op()).status=="ok","vacancy opens after reservation")
	check(s.resolve_reward(id,"replace",s.snapshot().player.partners[1].id,op()).status=="reward_space_available" and queue(s).size()==1,"stale replacement cannot release a creature unnecessarily")
	check(s.resolve_reward(id,"campaign","",op()).status=="ok" and s.snapshot().player.partners.size()==30,"free vacancy used without sacrifice")
	s.free()
	# Real inventory invocation, with the actual workshop-model event fixture.
	s=fixture(30);var saved:Dictionary=s.snapshot();saved.player.inventory["rabiola-lacertubo"]=1
	check(s.checkpoint(saved.checkpoint,saved.player).status=="ok","seed tail")
	var journey:=Journey.new(s)
	check(journey.start_summon("lacertubo").status=="ok","ritual consumes tail once")
	var completed:Dictionary={}
	for f in JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/workshop.json")):
		if f.kind!="raro":continue
		var model:=Workshop.new(f.kind,int(f.seed))
		for e in f.events:
			match e[0]:
				"rod":model.place_rod(Vector2(e[1],e[2]))
				"knot":model.hold_knot(int(e[1]))
				"knot-up":model.release_knot()
				"cut":model.cut_at(Vector2(e[1],e[2]),e[3])
				"t":model.tick(e[1],e[2])
				"soul":model.hold_soul()
				"soul-up":model.release_soul()
		completed=model.run.duplicate(true)
	saved=s.snapshot();saved.player.workshop.seed=int(completed.seed);saved.player.workshop.state=completed
	check(s.checkpoint(saved.checkpoint,saved.player).status=="ok","persist completed ritual fixture")
	check(journey.finish_workshop().status=="ok" and queue(s).size()==1,"invocation becomes reserved reward")
	id=queue(s)[0].id
	check(not queue(s)[0].mandatory and queue(s)[0].partner.has("craftDetails"),"craft attributes preserved")
	check(s.snapshot().player.inventory.get("rabiola-lacertubo",0)==0,"no second tail charge")
	check(journey.finish_workshop().status=="wrong_step","ritual cannot finish twice")
	check(s.resume_slot("slot-0").status=="ok" and queue(s)[0].id==id,"invocation pending after reload")
	check(s.resolve_reward(id,"global","",op()).status=="ok","optional reward can go directly to global")
	check(s.bank_contents().partners[0].id==id and queue(s).is_empty(),"single global instance")
	s.free()
	# Both banks full: preserve reward, then allow an explicit decline.
	s=fixture(30)
	for index in range(20):check(s.transfer_partner(s.snapshot().player.partners[1].id,"deposit",op()).status=="ok","fill global "+str(index))
	saved=s.snapshot()
	while saved.player.partners.size()<30:saved.player.partners.append(mon())
	check(s.checkpoint(saved.checkpoint,saved.player).status=="ok","refill campaign")
	check(reward(s,"capture-fixture").status=="ok","generic creature award is queued when both full")
	id=queue(s)[0].id
	check(s.resolve_reward(id,"global","",op()).status=="bank_global_full" and queue(s).size()==1,"full destination leaves reward intact")
	check(s.resolve_reward(id,"campaign","",op()).status=="bank_campaign_full" and queue(s).size()==1,"full campaign leaves reward intact")
	var decline_op:=op()
	check(s.resolve_reward(id,"decline","",decline_op).status=="ok","optional reward declined explicitly")
	check(s.resolve_reward(id,"decline","",decline_op).status in ["ok","already_applied"] and queue(s).is_empty(),"decline receipt idempotent")
	s.free()
	# Real Retalho claim, including the legacy accepted-but-full flag.
	s=fixture(30);saved=s.snapshot()
	for flag in Trust.FLAGS.slice(0,7):saved.player.flags[flag]=true
	saved.player.flags.retalhoAceitoKael=true
	saved.player.flags.pipaDragaoDesatadaVencida=true;saved.player.flags.assisReconheceuNoRetalho=true
	var rules=preload("res://scripts/campaign/district_rules.gd")
	var district:Dictionary=rules.fresh("industrial");district.completed=true;district.rewardClaimed=true;rules.store(saved.player,"industrial",district)
	check(s.checkpoint(CP.make(Trust.C,Trust.RESCUE,CP.SPACE),saved.player).status=="ok","Retalho acceptance fixture")
	check(Trust.new(s).claim(Trust.RESCUE).status=="ok","Retalho full bank reserves identity")
	check(queue(s).size()==1 and queue(s)[0].mandatory and queue(s)[0].partner.modelId=="retalho-original","Retalho essential reservation")
	id=queue(s)[0].id
	check(s.resolve_reward(id,"replace",s.snapshot().player.partners[1].id,op()).status=="ok","Retalho can enter without losing another instance accidentally")
	check(Trust.new(s).claim(Trust.RESCUE).status=="already_applied","Retalho cannot be claimed twice")
	s.free()
	for fault in ["bank","campaign","completion"]:
		s=fixture(30);s._store.deny_bank=fault=="bank";s._store.deny_campaign=fault=="campaign";s._store.deny_completion=fault=="completion"
		var before:Dictionary=s.snapshot()
		check(reward(s,"fault-reward").status==("io_error" if fault=="bank" else "bank_pending"),"reward fault "+fault)
		check(s.snapshot()==before,"failed reward does not publish half-state")
		reopened=Session.new();reopened._store=Store.new(s._store.directory);reopened.separate_autosave=true;root.add_child(reopened)
		check(reopened.resume_slot("slot-0").status=="ok","reopen reward fault "+fault)
		check(queue(reopened).size()==(0 if fault=="bank" else 1),"committed reservation recovered exactly once")
		s.free();reopened.free()
	s=fixture(30);check(reward(s,"claim-fault").status=="ok","claim fault seed")
	id=queue(s)[0].id;victim=s.snapshot().player.partners[1].id;s._store.deny_campaign=true
	check(s.resolve_reward(id,"replace",victim,op()).status=="bank_pending","failure between release and receipt is recoverable")
	reopened=Session.new();reopened._store=Store.new(s._store.directory);reopened.separate_autosave=true;root.add_child(reopened)
	check(reopened.resume_slot("slot-0").status=="ok" and queue(reopened).is_empty(),"reopen completes replacement")
	check(reopened.snapshot().player.partners.any(func(p):return p.id==id) and not reopened.snapshot().player.partners.any(func(p):return p.id==victim),"replacement never leaves both or neither")
	s.free();reopened.free()
	# Actual frontend: dismissing and cancelling leave the durable reservation intact.
	s=fixture(30);reward(s,"ui-optional");id=queue(s)[0].id
	var front:=Front.new();front.session._store=s._store;front.preferences.storage_path=s._store.directory.path_join("settings.cfg")
	root.add_child(front);front.preferences.reduced_motion=true;front.session.separate_autosave=true
	front.session.resume_slot("slot-0");front._show_saved();await settle()
	check(front.last_scene_key=="page:RECOMPENSAS RESERVADAS","saved game opens pending screen")
	await capture("pending")
	front._show_reward_replacement(id,"Recompensa");await settle();await capture("replacement")
	var back:=InputEventKey.new();back.physical_keycode=KEY_ESCAPE;back.keycode=KEY_ESCAPE;back.pressed=true;root.push_input(back,true);await settle()
	back=back.duplicate();back.pressed=false;root.push_input(back,true);await settle()
	check(front.last_scene_key=="page:RECOMPENSAS RESERVADAS" and queue(front.session).size()==1,"Escape returns from replacement without releasing anyone")
	front._show_reward_replacement(id,"Recompensa");await settle()
	front._confirm_reward(id,"replace",front.session.snapshot().player.partners[1].id,"Recompensa","Parceiro");await settle()
	var dialogs:=get_nodes_in_group("manga_dialogue")
	check(dialogs.size()==1 and root.gui_get_focus_owner()==dialogs[0].decline,"replacement focuses cancel")
	dialogs[0].canceled.emit();await settle()
	check(queue(front.session).size()==1 and front.session.snapshot().player.partners.size()==30,"cancel preserves everyone")
	front._confirm_reward(id,"global","","Recompensa");await settle()
	dialogs=get_nodes_in_group("manga_dialogue");dialogs[0].confirmed.emit();await settle()
	check(queue(front.session).is_empty() and front.session.bank_contents().partners[0].id==id,"UI confirms one reward into global")
	var streams:Array[WeakRef]=[]
	for child in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream!=null:streams.append(weakref(child.stream))
	front.free();s.free();await settle()
	var deadline:=Time.get_ticks_msec()+2000;var pending:=true
	while pending and Time.get_ticks_msec()<deadline:
		pending=false
		for ref:WeakRef in streams:
			if ref.get_ref()!=null:pending=true
		if pending:await create_timer(.02).timeout
	check(not pending,"audio teardown")
	print("PENDING REWARDS ",checks," checks; ",failures," failures; isolated profile, real reward services")
	quit(0 if failures==0 else 1)
