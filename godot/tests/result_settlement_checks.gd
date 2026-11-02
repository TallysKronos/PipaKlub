extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL ",message)
func settle() -> void:
	for frame in 12:await process_frame
func run() -> void:
	var front:=Front.new();var path:=ProjectSettings.globalize_path("res://../tmp/result-settlement-"+State.new_id());front.session._store=Store.new(path);front.preferences.storage_path=path+".cfg";root.add_child(front);front.preferences.reduced_motion=true
	var started:Dictionary=front.session.start("slot-1");check(started.status=="ok","isolated slot created")
	if started.status!="ok":front.free();quit(1);return
	var saved:Dictionary=front.session.snapshot()
	saved.player.partners=[{"id":"result-integration","modelId":"rabbito","personalName":"Rabbito","xp":39,"condition":{"line":100,"structure":100}}];saved.player.equippedPartnerId="result-integration";saved.player.journey={"lesson":5,"phase":"complete"}
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(saved.player);saved.player.flags.pipeiroDocumentsSeen=true
	var model:=Model.new(saved.player.partners[0],{"modelId":"mata","level":3});model.intro=0;model.outcome="won";model.q.hp=0
	saved.player.encounter={"id":"pip136-integration","kind":"wild","scene":"professor-home","returnPoint":[1152,864],"dropRoll":0,"state":model.snapshot()}
	var committed:Dictionary=front.session.checkpoint({"kind":"encounter"},saved.player);check(committed.status=="ok","terminal battle stored without granting rewards")
	if committed.status!="ok":front.free();quit(1);return
	front._show_saved();await settle()
	var battle:Control=front.battle;var expected:int=battle.result_summary.xp
	check(front.session.snapshot().player.partners[0].xp==39,"preview never grants XP")
	battle.finish_button.pressed.emit();await settle()
	var after:Dictionary=front.session.snapshot();var xp:int=after.player.partners[0].xp
	check(after.checkpoint.kind=="world" and xp==39+expected,"settlement commits before milestone")
	var banners:=front.get_children().filter(func(child):return child.has_meta("key_item_banner") and child.moment=="level")
	check(banners.size()==1 and front.flow_busy,"one confirmed level-up presentation locks repeated confirmation")
	var revision:int=after.revision;battle.finish_requested.emit();await settle()
	check(front.session.snapshot().revision==revision and front.session.snapshot().player.partners[0].xp==xp,"double confirm cannot grant or settle twice")
	if not banners.is_empty():banners[0]._process(10)
	await settle();check(not front.flow_busy and front.last_scene_key=="world:professor-home","milestone returns to actual saved world")
	check(front.session.resume_slot("slot-1").status=="ok" and front.session.snapshot().player.partners[0].xp==xp,"earned level survives reload")
	front.free();await settle();print("RESULT SETTLEMENT: ",checks," checks; ",failures," failures");quit(0 if failures==0 else 1)
