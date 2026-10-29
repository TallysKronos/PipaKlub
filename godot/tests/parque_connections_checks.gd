extends SceneTree
const View = preload("res://scripts/overworld/view.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var view := View.new()
	root.add_child(view)
	await process_frame
	for test in [["clareira-do-papel","mirante-alto",Vector2(61.5,18.5)], ["veredas-do-encanamento","canal-alto",Vector2(61.5,25.5)]]:
		view.load_area(test[0],test[1])
		if view.player != test[2]: failures.append("Entrada alta incorreta: "+test[0])
		var origin: Vector2 = view.player
		var exit: Dictionary = {}
		for event in view.model.data.events:
			if event.id == 1201: exit = event
		if exit.is_empty():
			failures.append("Saída alta ausente")
			continue
		view.nearby = exit
		view.interact()
		var expected := Vector2(61.5,25.5) if test[0]=="clareira-do-papel" else Vector2(61.5,18.5)
		if view.player != expected: failures.append("Transição perdeu entrada de destino")
		for event in view.model.data.events:
			if event.id == 1201: view.nearby = event
		view.interact()
		if view.player != origin: failures.append("Retorno não preservou rota alta")
	print("PARQUE CONNECTIONS: ",failures.size()," falhas; chegada e ida/volta B/C verificadas")
	for failure in failures: printerr(failure)
	quit(0 if failures.is_empty() else 1)
