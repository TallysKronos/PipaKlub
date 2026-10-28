extends SceneTree
const Front=preload("res://scripts/campaign/front_end.gd")
const Fixtures=preload("res://tools/player_audit_fixtures.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
const State=preload("res://scripts/campaign/state.gd")
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(value:bool,label:String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL "+label)
func settle() -> void:
	for frame in 8:await process_frame
func labels(node:Node) -> Array:
	var found:Array=[]
	for child in node.get_children():
		if child is Label:found.append(child)
		found.append_array(labels(child))
	return found
func audit_text(card:Control,view:Control) -> void:
	var entries:Array=labels(card)
	for label:Label in entries:
		check(label.get_theme_font_size("font_size")>=14,"result text minimum 14 logical pixels")
		check(label.get_line_count()<=label.get_visible_line_count(),"wrapped text has sufficient height: "+label.text)
		var ancestor:Node=label.get_parent()
		var scrolling:=false
		while ancestor!=card and ancestor!=null:
			if ancestor is ScrollContainer:scrolling=true
			ancestor=ancestor.get_parent()
		if not scrolling:
			check(view.get_global_rect().encloses(label.get_global_rect()),"text visible within screen: "+label.text)
func run() -> void:
	var front:=Front.new()
	front.session._store=Store.new("user://reward-layout-"+State.new_id())
	front.preferences.storage_path="user://reward-layout-"+State.new_id()+".cfg"
	root.add_child(front)
	front.preferences.reduced_motion="--reduced" in OS.get_cmdline_user_args()
	var output:=ProjectSettings.globalize_path("res://../mockups/revisao/pip72")
	if front.preferences.reduced_motion:output=output.path_join("movimento-reduzido")
	var capture:bool="--capture" in OS.get_cmdline_user_args()
	if capture:DirAccess.make_dir_recursive_absolute(output)
	for viewport in [Vector2i(1280,720),Vector2i(1280,800),Vector2i(1920,1080),Vector2i(2560,1080)]:
		root.size=viewport
		for scenario in ["won","lost","fled","morro-won","boss-won"]:
			Fixtures.show(front,"boss-intro" if scenario=="boss-won" else scenario);await settle()
			var view:Control=front.battle
			if scenario=="boss-won":view.model.outcome="won";view.model.q.hp=0
			view._physics_process(0);await settle()
			view.reward_card.advance(2)
			await settle()
			for loot_card:Control in view.reward_card.loot_cards:check(is_equal_approx(loot_card.modulate.a,1),"reward entry finishes fully visible")
			check(view.finish_button.text=="Continuar" and view.finish_button.icon!=null,"shared continue label and live input glyph")
			check(view.reward_card.summary.outcome==view.model.outcome,"result keeps actual outcome")
			if scenario=="morro-won":check(view.reward_card.summary.stars>0 and view.reward_card.summary.has("unlock"),"Morro displays stars and first-clear passage")
			if scenario=="boss-won":
				check("Rabiola de Lacertubo" in view.reward_card.summary.items,"boss shows actual awarded tail")
				check(not "Rabiola do Carcará de Nina" in view.reward_card.summary.items,"quest tail is collected in world, not awarded here")
			audit_text(view.reward_card,view)
			check(view.bottom_panel.size.x<=1180,"bounded result width")
			check(view.finish_button.size.x<400,"natural continue button width")
			check(view.reward_card.size.y>=270,"reward panel has room for content")
			check(view.get_global_rect().encloses(view.finish_button.get_global_rect()),"continue remains visible")
			check(view.get_global_rect().encloses(view.reward_card.get_global_rect()),"result remains visible")
			var backing:NinePatchRect=view.reward_card.find_child("IllustratedBacking",true,false)
			check(backing!=null and backing.scale==Vector2.ONE*.32,"illustrated corners retain uniform source scale")
			check(not view.footer_contents.get_parent().clip_contents,"result ornament is not rectangularly clipped")
			check(view.get_global_rect().encloses(backing.get_global_rect()),"outer artwork stays within screen")
			check(view.result_header.z_index>view.reward_card.z_index,"subtitle stays above decorative artwork")
			if capture:
				await create_timer(.6).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output.path_join("%s-%dx%d.png"%[scenario,viewport.x,viewport.y]))
			if scenario=="won":
				# Synthetic presentation data only: no settlement or campaign XP is modified.
				var old:Control=view.reward_card
				var card=load("res://scripts/campaign/hud_reward_card.gd").new()
				card.summary=view.result_summary.duplicate(true)
				card.summary.team=[{"modelId":"rabbito","personalName":"Rabbito","xp":0,"earnedXp":30},{"modelId":"basica","personalName":"Carcará","xp":50,"earnedXp":0},{"modelId":"mata","personalName":"Mata verde","xp":20,"earnedXp":0}]
				if "--long-text" in OS.get_cmdline_user_args():
					card.summary.name="Rabbito das Correntes Douradas"
					card.summary.tamer.name="Kael dos Ventos da Cidade"
					card.summary.team[1].personalName="Carcará Guardião das Veredas"
				card.summary.additional_recipients=[{"name":"Tamer · Kael (prévia)","xp":20,"level":2,"progress":40,"threshold":100},{"name":"Carcará (prévia)","xp":15,"level":1,"progress":15,"threshold":50}]
				card.summary.items=["Rabiola de Mata verde","Rabiola de Carcará","Rabiola de Lacertubo"]
				card.portrait_texture=old.portrait_texture
				card.reduced_motion=true
				var parent:=old.get_parent()
				var index:=old.get_index()
				parent.remove_child(old);old.free()
				view.reward_card=card
				parent.add_child(card);parent.move_child(card,index)
				view._layout_actions();await settle()
				audit_text(card,view)
				check(view.get_global_rect().encloses(card.get_global_rect()),"multiple recipients and drops fit through scroll areas")
				if capture:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(output.path_join("capacidade-previa-%dx%d.png"%[viewport.x,viewport.y]))
	front.free()
	print("REWARD LAYOUT: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
