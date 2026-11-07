extends SceneTree
## Test-only barriers. The parent kills this process; recovery uses an unmodified Store.
const Store = preload("res://scripts/campaign/save_store.gd")
const Session = preload("res://scripts/campaign/session.gd")
const State = preload("res://scripts/campaign/state.gd")
const CP = preload("res://scripts/campaign/park_checkpoint.gd")
var failures := 0
var checks := 0

class PausingStore extends "res://scripts/campaign/save_store.gd":
	var phase := ""
	var marker := ""
	func barrier(at: String) -> void:
		if phase != at: return
		var file := FileAccess.open(marker + ".tmp", FileAccess.WRITE)
		file.store_string(at); file.flush(); file.close()
		if DirAccess.rename_absolute(marker + ".tmp", marker) != OK: return
		OS.delay_msec(30000)
	func _write_checked(path: String, data: Dictionary) -> Error:
		if path.ends_with(".json.tmp"): barrier("before-temp")
		var error := super(path, data)
		if error == OK and path.ends_with(".json.tmp"): barrier("after-temp")
		return error
	func _replace_file(source: String, destination: String) -> Error:
		var bank_phase := ""
		if destination.get_base_dir() == bank_directory:
			var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
			bank_phase = "bank-complete" if envelope.data.pending.is_empty() else "bank-intent"
		if destination == _path("slot-1"):
			barrier("before-primary")
			if phase == "windows-gap":
				# Explicitly emulate the platform's remove/move gap on this fixture only.
				if _remove_file(destination) == OK: barrier("windows-gap")
		var error := super(source, destination)
		if error == OK:
			if destination.ends_with(".bak"): barrier("after-backup")
			if destination == _path("slot-1"): barrier("after-primary")
			if destination.ends_with("/campaign.json"): barrier("delete-intent")
			if source.ends_with(".restore-tmp"): barrier("restore-published")
			if not bank_phase.is_empty(): barrier(bank_phase)
		return error
	func _remove_file(path: String) -> Error:
		var error := super(path)
		if error == OK and path.get_base_dir() == directory: barrier("delete-first")
		return error
	func _copy_file(source: String, destination: String) -> Error:
		var error := super(source, destination)
		if error == OK and destination.ends_with(".restore-tmp"): barrier("restore-copy")
		return error

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL process recovery: ", label)

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		quit(2); return
	var mode: String = args[0]
	var scenario: String = args[1]
	var phase: String = args[2]
	var folder: String = args[3].replace("\\", "/")
	# Never accept the production user:// directory. Parent creates a fresh case root.
	if not folder.is_absolute_path() or not FileAccess.file_exists(folder.path_join("fixture-only")):
		quit(2); return
	var store := PausingStore.new(folder.path_join("campaign"))
	if scenario == "profile":
		var lock := preload("res://scripts/campaign/profile_lock.gd").new()
		check(lock.acquire(), "profile available")
		if mode == "write" and failures == 0:
			store.phase = phase
			store.marker = folder.path_join("ready")
			store.barrier(phase)
			check(false, "owner returned without being killed")
		quit(0 if failures == 0 else 1)
		return
	if mode == "prepare":
		var created: Dictionary = store.create_slot("slot-1")
		check(created.status == "ok", "create")
		if created.status != "ok": quit(1); return
		var data: Dictionary = created.data
		data.player.coins = 11
		for index in (30 if scenario == "reward" else 3):
			data.player.partners.append({"id":"fixture-%d" % index,"modelId":"mata","xp":17,"craftBonus":2,"condition":{"line":83,"structure":71}})
		data.player.equippedPartnerId = "fixture-0"
		data.player.journey = {"lesson":5,"phase":"complete"}
		data.checkpoint = CP.make("park-trail", CP.spawn("park-trail"), CP.SPACE)
		check(store.save_slot(data).status == "ok", "seed")
		if scenario in ["delete", "restore"]:
			data = store.load_slot("slot-1").data
			check(store.copy_to_slot(data,"slot-0",-1).status == "ok", "autosave sibling")
			check(store.copy_to_slot(data,"slot-2",-1).status == "ok", "manual sibling")
			check(store.create_slot("slot-3").status == "ok", "unrelated campaign")
			if scenario == "restore":
				check(store.archive_campaign(store.plan_campaign_archive("slot-1",int(data.revision))).status == "ok", "prepare archive")
	elif mode == "write":
		store.marker = folder.path_join("ready")
		store.phase = phase
		if scenario == "save":
			var data: Dictionary = store.load_slot("slot-1").data
			data.player.coins = 23
			store.save_slot(data)
		elif scenario == "delete":
			var data: Dictionary = store.load_slot("slot-1").data
			store.archive_campaign(store.plan_campaign_archive("slot-1",int(data.revision)))
		elif scenario == "restore": store.restore_slot(store.latest_removed())
		else:
			var session := Session.new(); session._store = store
			check(session.resume_slot("slot-1").status == "ok", "writer resume")
			if scenario == "bank": session.transfer_partner("fixture-1","deposit","bank-transfer-fixture")
			else:
				var data: Dictionary = session.snapshot()
				data.player.partners.append({"id":"reward-fixed","modelId":"mata","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}})
				session.commit_operation("fixture-reward",data.checkpoint,data.player)
			session.free()
		check(false,"writer returned without being killed at barrier")
	elif mode == "verify":
		if scenario in ["delete", "restore"]:
			for slot in ["slot-0", "slot-1", "slot-2"]:
				var loaded: Dictionary = store.load_slot(slot)
				check(loaded.status == ("missing" if scenario == "delete" else "ok"), "recover group "+slot)
				if loaded.status == "ok": check(int(loaded.data.player.coins) == 11,"restored contents")
			check(store.load_slot("slot-3").status == "ok","unrelated campaign preserved")
		elif scenario == "save":
			var loaded: Dictionary = store.load_slot("slot-1")
			check(loaded.status == "ok", "readable save")
			if loaded.status == "ok":
				check(int(loaded.data.player.coins) == (23 if phase == "after-primary" else 11), "exact committed revision")
				check(loaded.data.player.partners.size() == 3,"all partners preserved")
				check(store.save_slot(loaded.data).status == "ok","can save again")
		else:
			var session := Session.new(); session._store = store
			check(session.resume_slot("slot-1").status == "ok","recover transaction")
			var data: Dictionary = session.snapshot()
			if scenario == "bank":
				check(data.player.partners.size() == 2,"deposit removed exactly once")
				var contents: Dictionary = session.bank_contents()
				check(contents.status == "ok" and contents.partners.size() == 1,"one global partner")
				if contents.status == "ok" and contents.partners.size() == 1:
					check(contents.partners[0].id == "fixture-1" and int(contents.partners[0].xp) == 17 and int(contents.partners[0].condition.line) == 83,"identity and attributes preserved")
				check(session.transfer_partner("fixture-1","deposit","bank-transfer-fixture").status in ["ok","already_applied"],"retry idempotent")
				check(session.bank_contents().partners.size() == 1,"no duplication on retry")
			else:
				check(data.player.partners.size() == 30,"party limit preserved")
				check(data.player.get("pendingPartners",[]).size() == 1,"one pending award")
				if data.player.get("pendingPartners",[]).size() == 1: check(data.player.pendingPartners[0].partner.id == "reward-fixed","original identity")
				check(data.player.completedOperations.count("fixture-reward") == 1,"source receipt exactly once")
			session.free()
	else: check(false,"unknown mode")
	print("PROCESS RECOVERY ",mode," ",scenario,"/",phase," ",checks," checks; ",failures," failures")
	quit(0 if failures == 0 else 1)
