extends RefCounted
## Care is applied atomically after the three interactions; cancelling costs nothing.
const ITEM := "kit-remendo"
const PRICE := 12
const State=preload("res://scripts/campaign/state.gd")
var session:Node
func _init(value:Node) -> void:session=value
func available(saved:Dictionary) -> bool:
	return not saved.is_empty() and saved.get("checkpoint",{}).get("kind","")=="world" and not saved.player.partners.is_empty()
func supplies() -> Dictionary:
	var saved:Dictionary=session.snapshot()
	if not available(saved):return {"status":"wrong_step"}
	if not saved.player.flags.get("careWelcomeKit",false):
		saved.player.flags.careWelcomeKit=true
		saved.player.inventory[ITEM]=int(saved.player.inventory.get(ITEM,0))+1
		return session.commit_operation("care-welcome-kit-v1",saved.checkpoint,saved.player)
	if saved.player.coins<PRICE:return {"status":"not_enough_coins"}
	saved.player.coins-=PRICE
	saved.player.inventory[ITEM]=int(saved.player.inventory.get(ITEM,0))+1
	return session.checkpoint(saved.checkpoint,saved.player)
func finish(partner_id:String,operation_id:String,steps:Array) -> Dictionary:
	var saved:Dictionary=session.snapshot()
	if not available(saved) or operation_id.is_empty() or not operation_id.begins_with("partner-care-"):return {"status":"wrong_step"}
	if operation_id in saved.player.completedOperations:return {"status":"already_applied"}
	if steps!=["clean","frame","line"]:return {"status":"incomplete_care"}
	var target:Dictionary={}
	for partner in saved.player.partners:
		if partner.id==partner_id:target=partner;break
	if target.is_empty():return {"status":"wrong_step"}
	if int(saved.player.inventory.get(ITEM,0))<=0:return {"status":"missing_kit"}
	var condition:Dictionary=target.get("condition",{"line":100,"structure":100})
	if float(condition.line)>=100 and float(condition.structure)>=100:return {"status":"already_healthy"}
	saved.player.inventory[ITEM]-=1
	if saved.player.inventory[ITEM]==0:saved.player.inventory.erase(ITEM)
	target.condition={"line":100,"structure":100}
	return session.commit_operation(operation_id,saved.checkpoint,saved.player)
