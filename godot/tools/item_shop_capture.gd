extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const OUT:="res://../art/ui/loja-itens-v1/revisao/"
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:
	run.call_deferred()
func check(ok:bool,label:String)->bool:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("FAIL ",label)
	return ok
func shot(name:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run()->void:
	root.size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var folder:=ProjectSettings.globalize_path("res://.godot/item-shop-view-"+State.new_id())
	var front:=Front.new()
	front.session._store=Store.new(folder)
	front.preferences.storage_path=folder+"/preferences.cfg"
	root.add_child(front)
	if not check(front.session.start("slot-1").status=="ok","isolated slot"):quit(1);return
	var player:Dictionary=front.session.snapshot().player
	player.coins=80
	player.inventory={"kit-remendo":2,"papel-seda":5}
	player.partners=[{"id":"shop-partner","modelId":"rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="shop-partner"
	player.journey={"lesson":5,"phase":"complete"}
	player.starter={"completed":true}
	var at:=D.point(8,5.7)
	if not check(front.session.checkpoint({"kind":"world","scene":"kite-shop","position":[at.x,at.y]},player).status=="ok","store fixture"):quit(1);return
	front._show_saved()
	for i in range(600):
		if is_instance_valid(front.room) and not is_instance_valid(front.scene_loading):
			break
		await process_frame
	if not check(is_instance_valid(front.room),"store loads"):quit(1);return
	front._world_interact("counter")
	await process_frame
	await process_frame
	await process_frame
	var view:Control=front.get_node_or_null("ItemShop")
	if not check(view!=null,"shopkeeper opens item shop"):quit(1);return
	check(not front.room.can_walk and front.room.story_paused,"store blocks world movement")
	check(front.get_node_or_null("ShopConversation")==null,"direct shop menu")
	check(view.rows.size()==5 and root.gui_get_focus_owner()==view.rows["kit-remendo"],"catalogue and initial focus")
	check(view.size==Vector2(root.size) and view.canvas.scale==Vector2.ONE,"native 1280 layout")
	await shot("01-loja")
	front._shop_interact("counter")
	check(front.get_node("ItemShop")==view,"opening again reuses existing store")
	var down:=InputEventAction.new()
	down.action="ui_down"
	down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	down=InputEventAction.new()
	down.action="ui_down"
	down.pressed=false
	Input.parse_input_event(down)
	await process_frame
	check(root.gui_get_focus_owner()==view.rows["papel-seda"],"keyboard moves selection")
	view.rows["kit-remendo"].pressed.emit()
	view._change_amount(2)
	view._purchase()
	await process_frame
	check(front.session.snapshot().player.coins==44,"purchase charges total")
	check(front.session.snapshot().player.inventory["kit-remendo"]==5,"purchase adds quantity")
	check(view.balance.text=="44 moedas" and view.message.text.contains("3 ×"),"feedback uses committed state")
	await shot("02-compra")
	view._change_amount(96)
	check(view.amount==99 and view.buy_button.disabled,"unaffordable bulk purchase disabled")
	var before:Dictionary=front.session.snapshot().player
	view._purchase()
	check(front.session.snapshot().player==before,"disabled purchase preserves funds")
	await shot("03-saldo-insuficiente")
	view._filter("Materiais")
	check(view.selected_id=="papel-seda" and view.amount==1 and not view.rows["kit-remendo"].visible,"filter resets hidden selection")
	check(view.rows["papel-seda"].focus_neighbor_bottom==view.rows["vareta-bambu"].get_path(),"filtered focus links")
	root.size=Vector2i(960,540)
	await process_frame
	await process_frame
	check(is_equal_approx(view.canvas.scale.x,.75),"960 viewport fits layout")
	await shot("04-960x540")
	root.size=Vector2i(1920,1080)
	await process_frame
	await process_frame
	check(is_equal_approx(view.canvas.scale.x,1.5),"1920 viewport fits layout")
	await shot("05-1920x1080")
	root.size=Vector2i(1280,720)
	await process_frame
	var cancel:=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	Input.parse_input_event(cancel)
	await process_frame
	var released:=InputEventAction.new()
	released.action="ui_cancel"
	released.pressed=false
	Input.parse_input_event(released)
	await process_frame
	await process_frame
	check(front.get_node_or_null("ItemShop")==null and front.room.can_walk and not front.room.story_paused,"cancel restores store exploration")
	check(not is_instance_valid(front.pause_overlay) and not front.flow_busy,"cancel does not open pause menu")
	check(front.room.actor.distance_to(at)<.01,"closing preserves player position")
	front.session.close_session()
	check(front.session.resume_slot("slot-1").status=="ok","reload purchase")
	check(front.session.snapshot().player.coins==44 and front.session.snapshot().player.inventory["kit-remendo"]==5,"purchase persists after closing and reload")
	front.session.close_session()
	front.free()
	var report:={"checks":checks,"failures":failures,"viewports":[[1280,720],[960,540],[1920,1080]],"input":"keyboard actions simulated; mouse button callbacks exercised","saves":"isolated"}
	var file:=FileAccess.open(OUT+"verificacao.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("ITEM SHOP VIEW ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
