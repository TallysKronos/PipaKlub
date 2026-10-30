extends SceneTree
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Care=preload("res://scripts/campaign/partner_care.gd")
const State=preload("res://scripts/campaign/state.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func run() -> void:
	var session:=Session.new();session._store=Store.new(ProjectSettings.globalize_path("res://../tmp/care-test-"+State.new_id()))
	root.add_child(session);check(session.start("slot-1").status=="ok","isolated session")
	var care:=Care.new(session)
	check(care.supplies().status=="wrong_step","opening cannot grant supplies")
	var player:Dictionary=session.snapshot().player
	player.partners=[{"id":"care-partner","modelId":"rabbito","personalName":"Brisa","xp":0,"craftBonus":0,"condition":{"line":12,"structure":0}}]
	player.equippedPartnerId="care-partner";player.coins=24
	check(session.checkpoint({"kind":"world","scene":"quintal","position":[10.5,20.5]},player).status=="ok","world fixture")
	check(care.finish("care-partner","partner-care-missing",["clean","frame","line"]).status=="missing_kit","missing kit rejected")
	check(care.supplies().status=="ok","welcome supplies")
	check(session.snapshot().player.inventory[Care.ITEM]==1 and session.snapshot().player.coins==24,"welcome kit once without coins")
	check(care.finish("care-partner","partner-care-incomplete",["clean"]).status=="incomplete_care","unfinished care cannot consume")
	check(care.finish("other","partner-care-wrong",["clean","frame","line"]).status=="wrong_step","wrong partner rejected")
	var original_directory:String=session._store.directory
	var blocked_path:=ProjectSettings.globalize_path("res://../tmp/care-blocked-"+State.new_id())
	var blocked_file:=FileAccess.open(blocked_path,FileAccess.WRITE);blocked_file.store_string("not a directory");blocked_file.close()
	session._store.directory=blocked_path
	var failed:Dictionary=care.finish("care-partner","partner-care-storage-failure",["clean","frame","line"])
	check(failed.status!="ok" and session.snapshot().player.inventory[Care.ITEM]==1 and session.snapshot().player.partners[0].condition.line==12,"failed save preserves condition and kit")
	session._store.directory=original_directory
	var before:Dictionary=session.snapshot()
	var view=load("res://scripts/campaign/partner_care_view.gd").new()
	view.partner=before.player.partners[0];view.kits=1;view.coins=24;view.welcome=false
	var host:=Control.new();host.theme=load("res://scripts/campaign/hud.gd").make_theme();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();host.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,48)
	margin.add_child(view);await process_frame
	view._pet();check(session.snapshot().player==before.player,"petting has no economy mutation")
	view._care();check(view.steps==["clean"],"clean step")
	view._care();view._care();view.finish_result(false,"Tente novamente")
	check(view.steps==["clean","frame"] and not view.action.disabled,"failed UI repair can retry final step")
	check(session.snapshot().player==before.player,"partial care preserves kit and condition")
	view.queue_free();await process_frame
	view=load("res://scripts/campaign/partner_care_view.gd").new();view.partner=before.player.partners[0];view.kits=1;view.coins=24;view.welcome=false
	margin.add_child(view);await process_frame
	var operation:="partner-care-"+State.new_id()
	view.completed.connect(func(steps:Array):
		var result:Dictionary=care.finish("care-partner",operation,steps)
		view.finish_result(result.status=="ok"))
	view._care();view._care();view._care()
	check(view.saved,"care UI completes and saves")
	check(session.snapshot().player.partners[0].condition=={"line":100,"structure":100},"full repair")
	check(not session.snapshot().player.inventory.has(Care.ITEM),"exactly one kit consumed")
	check(care.finish("care-partner",operation,["clean","frame","line"]).status=="already_applied","retry receipt idempotent")
	check(care.supplies().status=="ok" and session.snapshot().player.coins==12,"second kit is purchased")
	check(care.finish("care-partner","partner-care-healthy",["clean","frame","line"]).status=="already_healthy","healthy partner preserves kit")
	check(care.supplies().status=="ok" and session.snapshot().player.coins==0,"purchase exact balance")
	check(care.supplies().status=="not_enough_coins","no free repeat grant")
	var progress:Dictionary=session.snapshot().player
	progress.partners.append({"id":"other-partner","modelId":"basica","personalName":"Outro","xp":0,"craftBonus":0,"condition":{"line":4,"structure":8}})
	session.checkpoint(session.snapshot().checkpoint,progress)
	check(care.finish("other-partner","partner-care-second",["clean","frame","line"]).status=="ok","selected secondary partner can be repaired")
	check(session.snapshot().player.partners[0].condition.line==100 and session.snapshot().player.equippedPartnerId=="care-partner","care preserves active selection and other partners")
	var resumed:=Session.new();resumed._store=session._store
	check(resumed.resume_slot("slot-1").status=="ok","reload save")
	check(resumed.snapshot().player.inventory[Care.ITEM]==1 and resumed.snapshot().player.partners[1].condition.structure==100,"repair and inventory persist")
	resumed.free()
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../documentation/qa/partner-care"))
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/partner-care/concluido.png"))
	view.saved=false;view.steps.clear();view.partner.condition={"line":12,"structure":28};view._update()
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../documentation/qa/partner-care/cuidados.png"))
	host.queue_free();session.queue_free();await process_frame
	print("PARTNER CARE ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
