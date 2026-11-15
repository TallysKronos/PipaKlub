extends SceneTree
const Session=preload("res://scripts/campaign/session.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
const Shop=preload("res://scripts/campaign/item_shop.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:
	run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("FAIL ",label)
func run()->void:
	var session:=Session.new()
	root.add_child(session)
	var model:=Shop.new(session)
	check(model.purchase("kit-remendo",1,"shop-purchase-empty").status=="no_session","missing session")
	var folder:=ProjectSettings.globalize_path("res://.godot/item-shop-"+State.new_id())
	session._store=Store.new(folder)
	check(session.start("slot-1").status=="ok","isolated session")
	check(model.purchase("kit-remendo",1,"shop-purchase-opening").status=="wrong_step","opening cannot buy")
	var player:Dictionary=session.snapshot().player
	player.coins=100
	check(session.checkpoint({"kind":"world","scene":"kite-shop","position":[D.ENTRY.x,D.ENTRY.y]},player).status=="ok","shop fixture")
	var before:Dictionary=session.snapshot()
	for quantity in [0,-1,100,1.5,"2",true]:
		check(model.purchase("kit-remendo",quantity,"shop-purchase-invalid").status=="invalid_quantity","invalid quantity "+str(quantity))
	check(model.purchase("unlisted",1,"shop-purchase-unknown").status=="unknown_item","unlisted item")
	check(model.purchase("kit-remendo",1,"care-operation").status=="invalid_operation","operation namespace")
	check(model.purchase("kit-remendo",99,"shop-purchase-expensive").status=="not_enough_coins","insufficient coins")
	check(session.snapshot().player==before.player,"rejections preserve player")
	check(Shop.item("kit-remendo").price==preload("res://scripts/campaign/partner_care.gd").PRICE,"same kit price as care")
	check(model.purchase("kit-remendo",3,"shop-purchase-three-kits").status=="ok","bulk purchase")
	var bought:Dictionary=session.snapshot().player
	check(bought.coins==64 and bought.inventory["kit-remendo"]==3,"coins and stock change together")
	check(model.purchase("kit-remendo",3,"shop-purchase-three-kits").status=="already_applied","receipt retry")
	check(session.snapshot().player==bought,"retry cannot charge twice")
	var invalid_path:=folder+"-blocked"
	var file:=FileAccess.open(invalid_path,FileAccess.WRITE)
	file.store_string("blocked")
	file.close()
	session._store.directory=invalid_path
	check(model.purchase("papel-seda",2,"shop-purchase-retry").status!="ok","disk failure")
	check(session.snapshot().player==bought,"failed save preserves coins and items")
	session._store.directory=folder
	check(model.purchase("papel-seda",2,"shop-purchase-retry").status=="ok","same operation can retry after failure")
	check(session.snapshot().player.coins==56 and session.snapshot().player.inventory["papel-seda"]==2,"retry applies once")
	for id in ["vareta-bambu","cola-reparo","linha-encerada"]:
		check(model.purchase(id,1,"shop-purchase-"+id).status=="ok","catalogue purchase "+id)
	check(not session.snapshot().player.flags.get("careWelcomeKit",false),"purchase preserves welcome care reward")
	session.close_session()
	check(session.resume_slot("slot-1").status=="ok","purchase reloads")
	check(session.snapshot().player.coins==37 and session.snapshot().player.inventory["linha-encerada"]==1,"all purchases persist")
	check(model.purchase("kit-remendo",3,"shop-purchase-three-kits").status=="already_applied","receipt survives reload")
	var saved:Dictionary=session.snapshot()
	session.checkpoint({"kind":"world","scene":"quintal","position":[10.5,20.5]},saved.player)
	check(model.purchase("kit-remendo",1,"shop-purchase-outside").status=="wrong_step","cannot buy outside store")
	session.close_session()
	session.free()
	print("ITEM SHOP ",checks," checks; ",failures.size()," failures; isolated saves")
	quit(0 if failures.is_empty() else 1)
