extends SceneTree
## PIP-87 fixed art cameras; no campaign storage or simulated input.
const View = preload("res://scripts/overworld/view.gd")
const AREAS := ["morro-praca-da-chegada","morro-escadaria-da-sombra","morro-laje-dos-ventos","morro-mirante-da-caixa-dagua","morro-parque-dos-ventos"]
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1280,720)
	var stage := "antes" if "--before" in OS.get_cmdline_user_args() else "depois"
	var output := ProjectSettings.globalize_path("res://../documentation/overworld/morro-pip87/"+stage)
	DirAccess.make_dir_recursive_absolute(output)
	var view := View.new()
	view.area_id = AREAS[0]
	view.art_preview = true
	root.add_child(view)
	view.set_physics_process(false)
	for area in AREAS:
		if view.area_id != area: view.load_area(area)
		var cameras := [{"file":"geral","point":Vector2(12,8),"zoom":.68,"offset":100},{"file":"escada","point":Vector2(13 if area==AREAS[0] else 12,8),"zoom":1.6,"offset":55}]
		if area == AREAS[4]: cameras[1] = {"file":"abrigo","point":Vector2(21,5),"zoom":1.7,"offset":85}
		if area == AREAS[4]: cameras.append({"file":"fachada-laje-direita","point":Vector2(15.5,14.5),"zoom":1.8,"offset":100})
		if area == AREAS[1]: cameras.append({"file":"sombra-copa","point":Vector2(6,7),"zoom":1.6,"offset":100})
		if area == AREAS[2]: cameras.append({"file":"varal-pipas","point":Vector2(7,4),"zoom":1.8,"offset":80})
		if area == AREAS[3]: cameras.append({"file":"fachada-telha-direita","point":Vector2(18.5,14.5),"zoom":1.8,"offset":100})
		if area in [AREAS[0],AREAS[2]]:
			cameras.append({"file":"banca","point":Vector2(1,9) if area==AREAS[0] else Vector2(20,5),"zoom":1.7,"offset":90})
		if area == AREAS[3]:
			for piece in view.model.data.pieces:
				if piece.asset == "mirante-guarda-corpo":
					cameras.append({"file":"guarda-corpo","point":Vector2(piece.u+1,piece.v+1),"zoom":2.0,"offset":70})
		if area == AREAS[0]:
			cameras.append({"file":"entrada-direita","point":Vector2(16.5,14.5),"zoom":1.6,"offset":100})
		# Isolated facade cameras also expose the base instead of hiding it
		# behind the foreground crop of the general terrain camera.
		if area == AREAS[0]:
			cameras.append({"file":"portao","point":Vector2(5,15),"zoom":1.4,"offset":100})
			for sample in [{"id":6,"name":"telha"},{"id":7,"name":"laje"},{"id":11,"name":"chapisco"}]:
				for piece in view.model.data.pieces:
					if int(piece.id) == int(sample.id):
						cameras.append({"file":"fachada-"+sample.name,"point":Vector2(piece.u+1.5,piece.v+1.5),"zoom":2.0,"offset":90})
		for frame in cameras:
			view.camera.position_smoothing_enabled = false
			view.player = frame.point
			view.follower = frame.point+Vector2.ONE
			view._refresh_positions()
			view.hide_characters()
			view.camera.zoom = Vector2.ONE*float(frame.zoom)
			view.camera.position = view.model.project(frame.point)-Vector2(0,float(frame.offset))
			view.hint.text = "PIP-87 · revisão do Morro · sem salvar campanha"
			for i in 4: await process_frame
			# The player is hidden in these art-only fixtures. Do not keep the
			# visibility fade from its temporary camera anchor on a landmark.
			for node in view.occluders:
				var art := node.get_node_or_null("Art") as Sprite2D
				if art != null: art.modulate = Color.WHITE
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(area+"-"+frame.file+"-1280x720.png"))
	view.free()
	print("Morro: cinco áreas, câmeras nativas de conjunto e detalhes; ",stage,". Sem suite de testes.")
	quit()
