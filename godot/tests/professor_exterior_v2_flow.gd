extends SceneTree
## Porta real da campanha com save isolado sob .godot; nunca abre slots do usuário.
const State=preload("res://scripts/campaign/state.gd")
const Store=preload("res://scripts/campaign/save_store.gd")
var front:Control
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures.append(label);printerr("FAIL ",label)
func settle() -> void:
	for i in 8:await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	var folder:=ProjectSettings.globalize_path("res://.godot/lab-v2-flow-"+State.new_id())
	front=load("res://scripts/campaign/front_end.gd").new()
	front.session._store=Store.new(folder)
	front.preferences.storage_path=folder+"/preferences.cfg"
	root.add_child(front)
	front.preferences.reduced_motion=true
	check(front.session.start("slot-3").status=="ok","slot isolado criado")
	var player:Dictionary=front.session.snapshot().player
	player.partners=[{"id":"flow","modelId":"rabbito","xp":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="flow"
	player.journey={"lesson":5,"phase":"complete"}
	check(front.session.checkpoint({"kind":"world","scene":"quintal","position":[7.25,-1],"space":"bairro-inicial-v2"},player).status=="ok","checkpoint de entrada novo válido")
	front._show_saved()
	for i in 1800:
		await process_frame
		if is_instance_valid(front.park) and not front.flow_busy and not is_instance_valid(front.scene_loading):break
	check(is_instance_valid(front.park),"Vila carregada pelo frontend real")
	if not is_instance_valid(front.park):finish();return
	var city:Node2D=front.park
	city.set_physics_process(false)
	city._update_hint()
	check(city.cell.distance_to(Vector2(7.25,-1))<.05,"retorno no acesso reservado")
	check(city.near_person.get("id")=="assis" or city.near_house.get("id")=="professor","entrada detectada por proximidade")
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_E
	event.pressed=true
	city._unhandled_input(event)
	for i in 1800:
		await process_frame
		if is_instance_valid(front.room) and not front.flow_busy and not is_instance_valid(front.scene_loading):break
	check(front.session.snapshot().checkpoint.get("scene")=="professor-home","E faz a transição real ao laboratório")
	check(is_instance_valid(front.room),"interior existente carregado")
	if not is_instance_valid(front.room):finish();return
	# Saída usa o fluxo existente de caminhada; nenhum desenho interno é substituído.
	front._world_interact("exit")
	for i in 2400:
		await process_frame
		if front.session.snapshot().checkpoint.get("scene")=="quintal" and is_instance_valid(front.park) and not front.flow_busy and not is_instance_valid(front.scene_loading):break
	check(front.session.snapshot().checkpoint.get("scene")=="quintal","saída do interior retorna à Vila")
	check(is_instance_valid(front.park),"Vila remontada após saída")
	if is_instance_valid(front.park):check(front.park.cell.distance_to(Vector2(7.25,-1))<.05,"posição preservada no retorno")
	check(front.session.snapshot().player.coins==0 and front.session.snapshot().player.partners[0].xp==0,"entrada e saída não concedem recompensas")
	finish()
func finish() -> void:
	var proof:={"checks":checks,"failures":failures,"isolated_save":true,"flow":"E → professor-home → caminhada de saída → quintal (7.25,-1)"}
	var f:=FileAccess.open("res://../art/professor-laboratorio-v2/fachada/integracao/fluxo.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(proof,"\t"))
	if is_instance_valid(front):front.session.close_session();front.free()
	print(JSON.stringify(proof))
	quit(0 if failures.is_empty() else 1)
