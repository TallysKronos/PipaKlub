extends RefCounted
const Identity=preload("res://scripts/campaign/pipeiro_identity.gd")
const Rules=preload("res://scripts/campaign/morro_rules.gd")
const FIRST_BOSS := "mikka"
const FIRST_ITEM := "insignia-morro-do-sol"
const FIRST_NAME := "Insígnia do Morro do Sol"

static func first_completed(player:Dictionary) -> bool:
	var stars:Dictionary=player.get("morro",{}).get("stars",{})
	for id in Rules.IDS:
		if int(stars.get(id,0))<1:return false
	return true

static func has_first(player:Dictionary) -> bool:
	return player.get("districtEmblems",{}).get(Identity.slot_id(0),{}).get("bossId","")==FIRST_BOSS

static func award_first_into(player:Dictionary) -> bool:
	if not first_completed(player) or has_first(player):return false
	if not Identity.issued(player):
		if not Identity.eligible(player):return false
		Identity.issue_into(player)
		player.flags.pipeiroDocumentsSeen=true
	if not Identity.award_district(player,0,FIRST_BOSS,FIRST_NAME,{"districtName":"Morro do Sol","bossName":"Mikka","description":"Conquistada ao vencer Mikka, campeã do Morro do Sol, depois de atravessar os cinco desafios do primeiro bairro."}):return false
	player.inventory[FIRST_ITEM]=1
	return true

static func ensure_legacy(session:Node) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.is_empty() or saved.checkpoint.get("kind","")!="world" or not first_completed(saved.player) or has_first(saved.player):return {"status":"already_applied"}
	if not award_first_into(saved.player):return {"status":"wrong_step"}
	return session.commit_operation("district-morro-first-v1",saved.checkpoint,saved.player)

static func pending(saved:Dictionary) -> bool:
	return not saved.is_empty() and saved.checkpoint.get("kind","")=="world" and has_first(saved.player) and not saved.player.flags.get("firstInsigniaSeen",false)

static func acknowledge(session:Node) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	if saved.is_empty() or not has_first(saved.player):return {"status":"wrong_step"}
	saved.player.flags.firstInsigniaSeen=true
	return session.commit_operation("district-morro-first-seen-v1",saved.checkpoint,saved.player)
