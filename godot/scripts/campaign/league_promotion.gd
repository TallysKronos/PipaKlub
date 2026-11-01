extends RefCounted
## First category exam; permanent story completion, never current title ownership.
const District=preload("res://scripts/campaign/district_rules.gd")
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")
const RECEIPT="league-green-v1"
static func promoted(player:Dictionary)->bool:return player.get("flags",{}).get("leagueGreen",false)
static func eligible(player:Dictionary)->bool:
	var f:Dictionary=player.get("flags",{})
	return District.completed(player,"morro") and District.completed(player,"bambuzal") and f.get("tylerClareiraMet",false) and f.get("ninaReturned",false) and f.get("guardianDefeated",false)
static func award_into(player:Dictionary)->bool:
	if promoted(player) or not eligible(player):return false
	player.flags.leagueGreen=true
	player.flags.ninaGlideLoanAvailable=true
	player.inventory["certificado-rabiola-verde"]=1
	player.inventory["emprestimo-carcara-nina"]=1
	return true
static func pending(saved:Dictionary)->bool:
	return saved.get("checkpoint",{}).get("kind","")=="world" and promoted(saved.get("player",{})) and not saved.player.flags.get("leagueGreenSeen",false)
static func acknowledge(session:Node)->Dictionary:
	var saved:Dictionary=session.snapshot()
	if not pending(saved):return {"status":"already_applied"}
	saved.player.flags.leagueGreenSeen=true
	return session.commit_operation("league-green-seen-v1",saved.checkpoint,saved.player)
static func claim(session:Node,at:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="world" or not at.is_finite() or not eligible(saved.player):return {"status":"wrong_step"}
	var cp:Dictionary=saved.checkpoint
	if cp.get("scene")!="park-trail" or cp.get("space")!=Checkpoint.SPACE or not Checkpoint.near(cp,"nina",at):return {"status":"wrong_step"}
	if not award_into(saved.player):return {"status":"already_applied"}
	return session.commit_operation(RECEIPT,saved.checkpoint,saved.player)
