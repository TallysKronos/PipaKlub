extends RefCounted
## Prices come from the catalogue. Coins, items and receipt share one commit.
const Care = preload("res://scripts/campaign/partner_care.gd")
const MAX_QUANTITY := 99
const CATALOGUE := [
	{"id":"kit-remendo","name":"Kit de Remendo","category":"Cuidados","price":Care.PRICE,"description":"Restaura toda a linha e a armação de um Soulmonster ao concluir os cuidados do parceiro."},
	{"id":"papel-seda","name":"Papel de seda","category":"Materiais","price":4,"description":"Folhas leves e coloridas para o acervo de materiais do pipeiro."},
	{"id":"vareta-bambu","name":"Vareta de bambu","category":"Materiais","price":5,"description":"Vareta leve e resistente. Guardada entre os materiais da sua mochila."},
	{"id":"cola-reparo","name":"Cola de reparo","category":"Materiais","price":6,"description":"Adesivo para o acervo de materiais de montagem e reparo."},
	{"id":"linha-encerada","name":"Linha encerada","category":"Materiais","price":8,"description":"Carretel de linha encerada, guardado entre os materiais da jornada."},
]
var session: Node

func _init(value: Node) -> void:
	session=value

static func item(id: String) -> Dictionary:
	for product: Dictionary in CATALOGUE:
		if product.id==id:
			return product.duplicate(true)
	return {}

func purchase(id: String, quantity: Variant, operation: String) -> Dictionary:
	var saved: Dictionary=session.snapshot()
	if saved.is_empty():
		return {"status":"no_session"}
	if not operation.begins_with("shop-purchase-") or operation.length()<=14 or operation.length()>128:
		return {"status":"invalid_operation"}
	if operation in saved.player.completedOperations:
		return {"status":"already_applied"}
	if saved.checkpoint.get("kind")!="world" or saved.checkpoint.get("scene")!="kite-shop":
		return {"status":"wrong_step"}
	var product:=item(id)
	if product.is_empty():
		return {"status":"unknown_item"}
	if not quantity is int or quantity<1 or quantity>MAX_QUANTITY:
		return {"status":"invalid_quantity"}
	var total: int=int(product.price)*int(quantity)
	if int(saved.player.coins)<total:
		return {"status":"not_enough_coins"}
	saved.player.coins-=total
	saved.player.inventory[id]=int(saved.player.inventory.get(id,0))+int(quantity)
	return session.commit_operation(operation,saved.checkpoint,saved.player)
