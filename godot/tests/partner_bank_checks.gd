extends SceneTree
const Session = preload("res://scripts/campaign/session.gd")
const Store = preload("res://scripts/campaign/save_store.gd")
const State = preload("res://scripts/campaign/state.gd")
const Bank = preload("res://scripts/campaign/partner_bank.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Front = preload("res://scripts/campaign/front_end.gd")
var checks := 0
var failures := 0
class FaultStore extends "res://scripts/campaign/save_store.gd":
	var deny_campaign := false
	var deny_bank := false
	var deny_completion := false
	func _write_checked(path: String, data: Dictionary) -> Error:
		return ERR_FILE_CANT_WRITE if deny_campaign else super(path,data)
	func _bank_write_json(path: String, data: Dictionary) -> Error:
		if deny_bank or (deny_completion and data.data.pending.is_empty()): return ERR_FILE_CANT_WRITE
		return super(path,data)
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL partner bank: ", description)
func _initialize() -> void: call_deferred("run")
func mon(index: int) -> Dictionary:
	return {"id":State.new_id(),"modelId":"mata","personalName":"Parceiro %d"%index,"xp":17,"craftBonus":2,"condition":{"line":83,"structure":71},"certification":"unverified","note":"preservar"}
func fixture(store: RefCounted, slot: String, count: int) -> Node:
	var session := Session.new(); session._store=store;session.separate_autosave=true;root.add_child(session)
	check(session.start(slot).status=="ok","start fixture "+slot)
	var saved: Dictionary = session.snapshot()
	for index in count: saved.player.partners.append(mon(index))
	saved.player.equippedPartnerId = saved.player.partners[0].id
	saved.player.journey={"lesson":5,"phase":"complete"}
	check(session.checkpoint(CP.make("park-trail",CP.spawn("park-trail"),CP.SPACE),saved.player).status=="ok","world fixture")
	return session
func operation() -> String: return "bank-transfer-"+State.new_id()
func canonical(value: Variant) -> String: return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true)
func contains(partners: Array, id: String) -> bool: return partners.any(func(p):return p.id==id)
func settle() -> void:
	for frame in 8: await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless" or not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw;DirAccess.make_dir_recursive_absolute("res://tmp/partner-bank")
	root.get_texture().get_image().save_png("res://tmp/partner-bank/"+name+".png")
func run() -> void:
	var directory := "user://partner-bank-"+State.new_id()
	var store := FaultStore.new(directory)
	var a := fixture(store,"slot-1",3)
	check(a.save_manual("slot-1",1).status=="ok","save pre-transfer copy")
	var before: Dictionary = a.snapshot()
	var partner: Dictionary = before.player.partners[1].duplicate(true)
	var id: String = partner.id
	var op := operation()
	check(a.transfer_partner(before.player.equippedPartnerId,"deposit",operation()).status=="bank_active","active protected")
	a.autosave_enabled=false
	check(a.transfer_partner(id,"deposit",op).status=="ok","deposit explicitly persists with autosave off")
	check(not contains(a.snapshot().player.partners,id),"removed from campaign")
	check(canonical(a.bank_contents().partners)==canonical([partner]),"all attributes preserved in global")
	check(a.transfer_partner(id,"deposit",op).status in ["ok","already_applied"],"same receipt idempotent")
	check(a.bank_contents().partners.size()==1,"retry never duplicates")
	check(a.transfer_partner(id,"withdraw",op).status=="invalid_operation","receipt cannot be repurposed")
	var battle: Dictionary=before.duplicate(true)
	battle.checkpoint={"kind":"encounter"};battle.player.equippedPartnerId=id
	battle.player.encounter={"id":State.new_id(),"kind":"lacertubo","returnPoint":[1200,900],"state":preload("res://scripts/campaign/encounter_model.gd").new(partner).snapshot()}
	check(State.inspect(battle,str(battle.slotId))=="ok","valid historical suspended battle fixture")
	check(a.bank_reconcile(battle).status=="bank_battle_changed","historical battle cannot use globally owned fighter")
	check(a.resume_slot("slot-1").status=="ok" and not contains(a.snapshot().player.partners,id),"old manual cannot reclaim deposited creature")
	var b := fixture(store,"slot-2",2)
	check(b.transfer_partner(id,"withdraw",operation()).status=="ok","withdraw into different campaign")
	check(contains(b.snapshot().player.partners,id) and b.bank_contents().partners.is_empty(),"exactly one owner after withdraw")
	var old_cid: String = a.snapshot().campaignId
	check(a.transfer_partner(id,"deposit",op).status in ["ok","already_applied"] and a.snapshot().campaignId==old_cid,"old retry cannot load another campaign autosave")
	check(not contains(a.snapshot().player.partners,id),"old campaign cannot reclaim transferred owner")
	check(b.transfer_partner(id,"deposit",operation()).status=="ok","return to global")
	var plan: Dictionary=store.plan_campaign_archive("slot-2",int(store.load_slot("slot-2").data.revision))
	check(store.archive_campaign(plan).status=="ok","delete source campaign")
	check(canonical(Bank.new(store).global_partners(Bank.new(store).load_ledger().data))==canonical([partner]),"global survives campaign deletion")
	check(store.restore_slot(store.latest_removed()).status=="ok","undo campaign deletion")
	check(b.resume_slot("slot-0").status=="ok" and not contains(b.snapshot().player.partners,id),"undo cannot duplicate global owner")
	check(b.transfer_partner(id,"discard",operation()).status=="ok","explicit permanent release")
	check(b.bank_contents().partners.is_empty(),"release frees global slot")
	check(a.resume_slot("slot-1").status=="ok" and not contains(a.snapshot().player.partners,id),"old save cannot resurrect released creature")
	a.free();b.free()
	# Limits 19/20/21 globally and 29/30/31 in a campaign.
	store=FaultStore.new("user://partner-bank-limits-"+State.new_id())
	a=fixture(store,"slot-1",30)
	var ids: Array=[]
	for p in a.snapshot().player.partners:ids.append(p.id)
	for index in range(1,21):check(a.transfer_partner(ids[index],"deposit",operation()).status=="ok","deposit capacity "+str(index))
	check(a.bank_contents().partners.size()==20,"global reaches twenty")
	check(Array(DirAccess.get_files_at(store.bank_directory)).filter(func(name):return name.ends_with(".json")).size()<=8,"complete generation retention bounded")
	check(Bank.new(store).load_ledger().data.operations.size()==20,"generation cleanup preserves receipts")
	check(a.transfer_partner(ids[21],"deposit",operation()).status=="bank_global_full","twenty-first global rejected")
	b=fixture(store,"slot-2",29)
	check(b.transfer_partner(ids[1],"withdraw",operation()).status=="ok" and b.snapshot().player.partners.size()==30,"twenty-nine accepts thirtieth")
	check(b.transfer_partner(ids[2],"withdraw",operation()).status=="bank_campaign_full","thirty-first rejected")
	var next: Dictionary=b.snapshot();next.player.partners.append(mon(31))
	check(b.checkpoint(next.checkpoint,next.player).status=="bank_campaign_full" and b.snapshot().player.partners.size()==30,"reward growth beyond thirty not published")
	check(b.transfer_partner(ids[1],"deposit",operation()).status=="ok","withdraw frees capacity for deposit")
	check(b.transfer_partner(ids[2],"discard",operation()).status=="ok" and b.bank_contents().partners.size()==19,"discard frees twentieth slot")
	a.free();b.free()
	store=FaultStore.new("user://partner-bank-legacy-"+State.new_id());a=fixture(store,"slot-1",30)
	next=store.load_slot("slot-0").data;next.player.partners.append(mon(31))
	check(store.save_slot(next).status=="ok" and a.resume_slot("slot-0").status=="ok","legacy oversized collection loads intact")
	check(a.snapshot().player.partners.size()==31,"legacy creature is not silently dropped")
	check(a.transfer_partner(a.snapshot().player.partners[1].id,"deposit",operation()).status=="ok" and a.snapshot().player.partners.size()==30,"legacy overflow can be reduced safely")
	a.free()
	# Safe restrictions and rollback-recoverable storage boundaries.
	for fault in ["bank","campaign","completion"]:
		store=FaultStore.new("user://partner-bank-fault-"+State.new_id());a=fixture(store,"slot-1",3)
		id=a.snapshot().player.partners[1].id;op=operation()
		store.deny_bank=fault=="bank";store.deny_campaign=fault=="campaign";store.deny_completion=fault=="completion"
		var result: Dictionary=a.transfer_partner(id,"deposit",op)
		check(result.status==("io_error" if fault=="bank" else "bank_pending"),"fault reported "+fault)
		check(contains(a.snapshot().player.partners,id),"failure does not publish partial live state")
		var reopened:=Store.new(store.directory)
		var restarted:=Session.new();restarted._store=reopened;restarted.separate_autosave=true;root.add_child(restarted)
		check(restarted.resume_slot("slot-0").status=="ok","restart recovers "+fault)
		if fault=="bank":check(contains(restarted.snapshot().player.partners,id) and restarted.bank_contents().partners.is_empty(),"uncommitted transfer has no effect")
		else:
			check(not contains(restarted.snapshot().player.partners,id) and contains(restarted.bank_contents().partners,id),"committed intent completes exactly once")
			check(restarted.transfer_partner(id,"deposit",op).status in ["ok","already_applied"],"recovered receipt idempotent")
		a.free();restarted.free()
	for fault in ["corrupt","future","conflict"]:
		store=FaultStore.new("user://partner-bank-integrity-"+State.new_id());a=fixture(store,"slot-1",3)
		id=a.snapshot().player.partners[1].id
		check(a.transfer_partner(id,"deposit",operation()).status=="ok","integrity fixture")
		var files: Array[String]=[]
		for filename in DirAccess.get_files_at(store.bank_directory):
			if filename.ends_with(".json"):files.append(filename)
		files.sort();var path: String=store.bank_directory.path_join(files.back())
		var envelope: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		if fault=="conflict":store._copy_file(path,store.bank_directory.path_join(files.back().left(13)+State.new_id()+".json"))
		else:
			var file:=FileAccess.open(path,FileAccess.WRITE)
			if fault=="corrupt":file.store_string("truncated")
			else:
				envelope.data.version=Bank.VERSION+1;envelope.hash=Bank.new(store)._canonical(envelope.data).sha256_text();file.store_string(JSON.stringify(envelope))
			file.close()
		var expected: String={"corrupt":"bank_corrupt","future":"bank_future","conflict":"bank_conflict"}[fault]
		check(Bank.new(store).load_ledger().status==expected,"integrity error is explicit "+fault)
		check(Store.new(store.directory).load_slot("slot-0").status==expected,"never fall back to earlier ownership after "+fault)
		a.free()
	store=FaultStore.new("user://partner-bank-ui-"+State.new_id());a=fixture(store,"slot-1",4)
	next=a.snapshot();next.player.partners[1].borrowed=true;next.player.partners[2].modelId="retalho-original"
	next.player.partners[0].personalName = "Sentinela do Vento do Norte"
	check(a.checkpoint(next.checkpoint,next.player).status=="ok","story fixtures")
	var policy:=Bank.new(store)
	check(policy.restriction(a.snapshot(),next.player.partners[1].id)=="bank_story","loan protected")
	check(policy.restriction(a.snapshot(),next.player.partners[2].id)=="bank_story","Retalho protected")
	var front:=Front.new();front.session._store=store;front.preferences.storage_path=directory.path_join("settings.cfg")
	root.add_child(front);front.preferences.reduced_motion=true;front.session.separate_autosave=true
	front.session.resume_slot("slot-0")
	front.team_load_state = "error"
	front._show_collection()
	await settle()
	var retry := root.gui_get_focus_owner() as Button
	if retry != null and retry.text == "Tentar de novo":
		await capture("team-error")
		retry.pressed.emit()
		await settle()
		check(front.team_load_state == "ready" and front.last_scene_key == "page:EQUIPE","retry reopens team")
	else:
		check(false,"team error focuses retry")
		front.team_load_state = "ready"
	if "--capture" in OS.get_cmdline_user_args():
		front._show_collection();await settle();await capture("team")
		var window_size := root.size
		var original_scale: float = front.preferences.text_scale
		front.preferences.text_scale = 1.3
		front._apply_preferences()
		for resolution in [Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(2560,1080)]:
			root.size = resolution
			await settle()
			front._show_collection()
			await settle()
			await capture("team-%dx%d-text130" % [root.size.x,root.size.y])
		root.size = window_size
		front.preferences.text_scale = original_scale
		front._apply_preferences()
		await settle()
	front._show_partner_bank();await settle()
	check(front.last_scene_key=="page:BANCO DE PIPAMONS","bank integrated into frontend")
	await capture("bank")
	check(root.gui_get_focus_owner() is Button and not root.gui_get_focus_owner().disabled,"bank focuses usable action and scrolls to it")
	var press:=InputEventJoypadButton.new();press.button_index=JOY_BUTTON_A;press.pressed=true;root.push_input(press,true)
	await settle();press=press.duplicate();press.pressed=false;root.push_input(press,true);await settle()
	var dialogs:=get_nodes_in_group("manga_dialogue")
	check(dialogs.size()==1 and root.gui_get_focus_owner()==dialogs[0].decline,"transfer starts at Cancel")
	dialogs[0].canceled.emit();await settle()
	check(front.session.bank_contents().partners.is_empty(),"cancel changes nothing")
	front._confirm_bank_transfer(next.player.partners[3].id,"deposit","Parceiro 3");await settle()
	dialogs=get_nodes_in_group("manga_dialogue");dialogs[0].confirmed.emit();await settle()
	check(front.session.bank_contents().partners.size()==1 and front.session.snapshot().player.partners.size()==3,"UI confirmation moves one creature")
	await capture("populated")
	front._confirm_bank_transfer(next.player.partners[3].id,"discard","Parceiro 3");await settle()
	dialogs=get_nodes_in_group("manga_dialogue")
	check(dialogs[0].dialog_text.contains("permanentemente") and root.gui_get_focus_owner()==dialogs[0].decline,"release warns and starts at Cancel")
	dialogs[0].canceled.emit();await settle()
	check(front.session.bank_contents().partners.size()==1,"cancel release preserves creature")
	var streams:Array[WeakRef]=[]
	for child in front.sound.get_children():
		if child is AudioStreamPlayer and child.stream!=null:streams.append(weakref(child.stream))
	front.free();a.free();await settle()
	var deadline:=Time.get_ticks_msec()+2000
	var pending:=true
	while pending and Time.get_ticks_msec()<deadline:
		pending=false
		for ref:WeakRef in streams:
			if ref.get_ref()!=null:pending=true
		if pending:await create_timer(.02).timeout
	check(not pending,"audio teardown")
	print("PARTNER BANK ",checks," checks; ",failures," failures; local profile and injected interruptions")
	quit(0 if failures==0 else 1)
