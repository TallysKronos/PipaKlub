extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const D=preload("res://scripts/campaign/shop_data.gd")
const Staging=preload("res://scripts/campaign/tutorial_staging.gd")
const OUT="res://../documentation/overworld/loja-tcg/fluxo/"
var front:Control
var checks:=0
func require(ok:bool,message:String)->bool:
 checks+=1
 if not ok:printerr("SHOP FLOW FAIL ",message);quit(1)
 return ok
func _initialize()->void:call_deferred("run")
func wait_for(shop:bool)->bool:
 var until:=Time.get_ticks_msec()+30000
 while Time.get_ticks_msec()<until:
  await process_frame
  if shop and is_instance_valid(front.room) and front.room.data.get("id","")=="kite-shop":return true
  if not shop and is_instance_valid(front.park) and not is_instance_valid(front.scene_loading) and not is_instance_valid(front.room):return true
 return false
func shot(name:String)->void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+name+".png")
func run()->void:
 root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 front=Front.new();front.session._store=Store.new("user://shop-flow-"+State.new_id());root.add_child(front)
 if not require(front.session.start("slot-1").status=="ok","isolated slot"):return
 var saved:Dictionary=front.session.snapshot()
 saved.player.partners=[{"id":State.new_id(),"modelId":"rabbito","personalName":"Rabbito","xp":0,"craftBonus":0,"condition":{"line":100,"structure":100}}]
 saved.player.equippedPartnerId=saved.player.partners[0].id;saved.player.journey={"lesson":5,"phase":"complete"}
 if not require(front.session.checkpoint({"kind":"world","scene":"quintal","position":[D.CITY_ENTRY.x,D.CITY_ENTRY.y],"space":"bairro-inicial-v2"},saved.player).status=="ok","city checkpoint"):return
 front._show_saved()
 if not require(await wait_for(false),"neighborhood loads"):return
 front.park._update_hint()
 if not require(front.park.near_house.get("id")=="loja","shop door wins over nearby Lia"):return
 await shot("01-porta-bairro")
 front.park.interact()
 if not require(await wait_for(true),"real doorway enters shop"):return
 await create_timer(.8).timeout
 await shot("02-interior-hud")
 if not require(await Staging.approach(front.room,D.point(8.5,9)),"walk through the widened central aisle"):return
 await shot("02b-corredor-livre")
 if not require(await Staging.approach(front.room,D.point(8,4.5)),"walk to counter without crossing furniture"):return
 front.room.can_walk=true;front.room.interacted.emit("counter")
 await process_frame
 var dialog:Control=front.get_node_or_null("ShopConversation")
 if not require(is_instance_valid(dialog) and not front.room.can_walk,"owner conversation opens and stops movement"):return
 await shot("03-dono-conversa")
 dialog.confirmed.emit();await process_frame;await process_frame
 if not require(front.room.can_walk,"conversation restores controls"):return
 if not require(front._remember_world_position(),"save walked position"):return
 var at:Vector2=front.room.actor
 front.session.close_session()
 if not require(front.session.resume_slot("slot-1").status=="ok","reload shop slot"):return
 front._show_saved()
 if not require(await wait_for(true),"shop restores"):return
 await create_timer(.8).timeout
 if not require(front.room.actor.distance_to(at)<.01,"resume preserves position"):return
 if not require(front._slot_location(front.session.snapshot()).name=="Linha & Papel","save card names shop"):return
 await shot("04-retomada")
 if not require(await Staging.approach(front.room,D.ENTRY),"walk back to exit"):return
 front.room.interacted.emit("exit")
 if not require(await wait_for(false),"exit returns to neighborhood"):return
 if not require(front.park.player.distance_to(D.CITY_ENTRY)<.05,"return preserves city location"):return
 await shot("05-retorno-bairro")
 front.park.cell=Vector2(25.05,-.2);front.park._update_hint()
 if not require(front.park.near_person.get("id")=="lia","Lia remains available outside the shop threshold"):return
 front.session.close_session();front.free();print("SHOP FLOW ",checks," checks; doorway, movement, owner dialogue, save/resume, return; isolated directory");quit()
