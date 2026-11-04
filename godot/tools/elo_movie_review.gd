extends SceneTree
const View = preload("res://scripts/overworld/view.gd")
const Elo = preload("res://scripts/overworld/elo_chamber.gd")
var view
var caption: Label

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size=Vector2i(960,540)
	var hud := CanvasLayer.new()
	root.add_child(hud)
	caption=Label.new()
	caption.position=Vector2(28,450)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(caption)
	for part in ["a","b","c","d"]:
		view=View.new()
		view.area_id="kronasta-coracao-"+part
		view.art_preview=true
		root.add_child(view)
		view.set_physics_process(false)
		view.interface.hide()
		view.camera.position_smoothing_enabled=false
		view.camera.zoom=Vector2.ONE*.85
		var spawn: Dictionary=view.model.data.spawn
		var target: Dictionary=view.model.data.events.filter(func(e):return int(e.id)==31002)[0]
		view.player=Vector2(spawn.u+.5,spawn.v+.5)
		_pose()
		caption.text="Coração das Ruínas · "+str(view.model.data.name)+"\nSimulação do percurso"
		await create_timer(1.6).timeout
		await _walk(Vector2(target.u+.5,target.v+.5))
		if part=="d":
			caption.text="Eremor · O selo do altar se rompe."
			caption.text="Após perder, Rato corre até o selo e o rompe."
			var gag := Elo.prepare_rock_gag(view)
			await Elo.move_culprit(view,gag,false)
			var fissure := Elo.rupture(view)
			await create_timer(.65).timeout
			var creature := Elo.awakening_sprite(view)
			if creature != null:
				var roar := AudioStreamPlayer.new()
				roar.stream=load("res://assets/overworld/kits/camara-do-elo-v1/enamor-rugido.wav")
				view.add_child(roar)
				creature.frame_changed.connect(func():
					if creature.frame==6:
						roar.play()
						Elo.drop_rock(gag,false))
				creature.play()
				await creature.animation_finished
			fissure.queue_free()
			Elo.collapse(view)
			var awakened := Elo.eremor_advance(view)
			awakened.play()
			var step: Tween = view.create_tween()
			step.tween_property(awakened,"position",view.model.project(Vector2(24,16.5)),.48)
			await step.finished
			awakened.stop()
			caption.text="Kael encara Eremor.\nFim da simulação · duelo final não jogado."
			await create_timer(3).timeout
		else:
			caption.text="%s foi libertada.\nResultado do duelo simulado." % {"a":"Nina","b":"Mikka","c":"Jamile"}[part]
			await create_timer(2.4).timeout
			var passage: Dictionary=view.model.data.events.filter(func(e):return int(e.id)==31001)[0]
			await _walk(Vector2(passage.u+.5,passage.v+.5))
		view.queue_free()
		await process_frame
	quit()

func _walk(destination: Vector2) -> void:
	var path: PackedVector2Array=view.model.path_to(view.player,destination)
	for point in path:
		if view.player.distance_to(point)<.01:continue
		var tween := create_tween()
		tween.tween_method(func(p: Vector2):
			view.player=p
			_pose(),view.player,point,view.player.distance_to(point)*.21)
		await tween.finished

func _pose() -> void:
	view.follower=view.player
	view._refresh_positions()
	view.camera.position=view.model.project(view.player)-Vector2(0,36)

