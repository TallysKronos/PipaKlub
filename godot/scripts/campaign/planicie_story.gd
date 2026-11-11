extends RefCounted
## Planícies de Kronasta e Gruta do Moinho (11/11/2026): região lateral do Ato 2.
## Abre depois do Lacertubo (Veredas). Duas missões de moradores e o guardião do lago:
##   · Seu Bento (Campos do Vento): três pás do moinho espalhadas pelas planícies e pela gruta.
##   · Iara (Colinas do Moinho): o filho Tito entrou na gruta atrás de um Vertim.
##   · Estratonte (Lago Subterrâneo): guardião opcional, rabiola garantida na primeira vitória.
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")
const Pacing = preload("res://scripts/campaign/park_pacing.gd")

const SCENES := ["planicie-a", "planicie-b", "planicie-c", "caverna-a", "caverna-b", "caverna-c"]
const GUARDIAN_LEVEL := 18
const PAS := 3
const ITEM := "pa-do-moinho"
const ACTIONS := ["planicieMoinho", "grutaIara", "grutaTito"]

var session: Node
func _init(local_session: Node) -> void: session = local_session

static func is_region(scene: String) -> bool:
	return scene in SCENES

static func open(player: Dictionary) -> bool:
	return bool(player.get("flags", {}).get("guardianDefeated", false))

static func flags(player: Dictionary) -> Dictionary:
	return player.get("flags", {})

## Texto do HUD nas seis áreas, pela primeira coisa em aberto.
static func objective(player: Dictionary, scene: String) -> String:
	var f := flags(player)
	var pas := int(player.get("inventory", {}).get(ITEM, 0))
	if f.get("planicieMoinhoPedido", false) and not f.get("planicieMoinhoConsertado", false):
		if pas >= PAS: return "Você tem as três pás. Leve-as ao Seu Bento, no alto da colina dos Campos do Vento."
		return "Procure as pás do moinho do Seu Bento: %d de %d. Uma ficou nas Colinas, outra no Vale das Pedras e outra na gruta." % [pas, PAS]
	if f.get("grutaTitoPedido", false) and not f.get("grutaTitoAchado", false):
		return "Encontre o Tito na Gruta do Moinho. A Iara acha que ele seguiu um Vertim até as Galerias de Cristal."
	if f.get("grutaTitoAchado", false) and not f.get("grutaTitoRecompensa", false):
		return "O Tito voltou para casa. Fale com a Iara nas Colinas do Moinho."
	if not f.get("planicieMoinhoPedido", false):
		return "Converse com os moradores das planícies. No alto da colina, o Seu Bento cuida do moinho parado."
	if not f.get("grutaTitoPedido", false):
		return "Nas Colinas do Moinho, a Iara procura alguém perto da boca da gruta."
	if not f.get("grutaEstratonteVencido", false):
		return "No fundo da gruta, o Estratonte guarda a ilha do Lago Subterrâneo. Nv.%d." % GUARDIAN_LEVEL
	return "As planícies estão em paz. Explore à vontade · M para viajar por Kronasta."

func _near(action: String, point: Vector2) -> bool:
	var scene: String = session.snapshot().checkpoint.get("scene", "")
	for event in Checkpoint.data(scene).events:
		if event.props.get("acao", "") == action and point.distance_to(Vector2(event.u + .5, event.v + .5)) <= 2.0: return true
	return false

func _ready(action: String, point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	if saved.checkpoint.get("space", "") != Checkpoint.SPACE or not is_region(saved.checkpoint.get("scene", "")): return {}
	if not point.is_finite() or not _near(action, point): return {}
	return saved

## Uma conversa. Retorna {status, text}; status "ok" quando algo foi gravado.
func talk(action: String, point: Vector2) -> Dictionary:
	var saved := _ready(action, point)
	if saved.is_empty(): return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var f: Dictionary = player.get("flags", {})
	player.flags = f
	if action == "planicieMoinho":
		if f.get("planicieMoinhoConsertado", false):
			return {"status": "already_applied", "text": "Seu Bento: Ouve só o moinho girando! Volte quando quiser, a farinha da semana é sua."}
		if not f.get("planicieMoinhoPedido", false):
			f.planicieMoinhoPedido = true
			return _commit("planicie-moinho-pedido-v1", saved, "Seu Bento: O vento da última tempestade arrancou as pás do meu moinho. Uma voou para as Colinas, outra caiu no Vale das Pedras e a terceira rolou para dentro da gruta.\n\nSeu Bento: Se achar as três, eu monto tudo de novo.")
		var pas := int(player.inventory.get(ITEM, 0))
		if pas < PAS:
			return {"status": "already_applied", "text": "Seu Bento: Já são %d de %d. Elas brilham um pouco no sol, é madeira envernizada." % [pas, PAS]}
		player.inventory[ITEM] = pas - PAS
		if player.inventory[ITEM] == 0: player.inventory.erase(ITEM)
		f.planicieMoinhoConsertado = true
		player.coins = int(player.get("coins", 0)) + 60
		player.inventory["linha-encerada"] = int(player.inventory.get("linha-encerada", 0)) + 2
		player.inventory["kit-remendo"] = int(player.inventory.get("kit-remendo", 0)) + 1
		return _commit("planicie-moinho-v1", saved, "Seu Bento encaixa as três pás e solta o freio. O moinho range, hesita e gira.\n\nSeu Bento: Aí está! Leve 60 moedas, duas linhas enceradas e um Kit de Remendo.")
	if action == "grutaIara":
		if f.get("grutaTitoRecompensa", false):
			return {"status": "already_applied", "text": "Iara: O Tito agora só entra na gruta comigo. Obrigada de novo."}
		if f.get("grutaTitoAchado", false):
			f.grutaTitoRecompensa = true
			player.coins = int(player.get("coins", 0)) + 50
			player.inventory["kit-remendo"] = int(player.inventory.get("kit-remendo", 0)) + 2
			return _commit("gruta-tito-v1", saved, "Iara: Você achou o meu menino! Ele chegou falando de cristais azuis e de um bicho de pedra que dorme no lago.\n\nIara: Fique com estes dois Kits de Remendo e 50 moedas.")
		if f.get("grutaTitoPedido", false):
			return {"status": "already_applied", "text": "Iara: O Tito seguiu um Vertim para dentro da gruta. Ele gosta dos cristais azuis das galerias do fundo."}
		f.grutaTitoPedido = true
		return _commit("gruta-tito-pedido-v1", saved, "Iara: Meu filho, o Tito, entrou na gruta atrás de um Vertim e não voltou. Eu não consigo passar dos bichos da galeria.\n\nIara: Ele adora os cristais azuis. Por favor, procure por ele.")
	if action == "grutaTito":
		if not f.get("grutaTitoPedido", false) or f.get("grutaTitoAchado", false): return {"status": "wrong_step"}
		f.grutaTitoAchado = true
		return _commit("gruta-tito-achado-v1", saved, "Tito: Eu só queria ver os cristais de perto... e me perdi nas galerias.\n\nKael: Sua mãe está preocupada. O caminho de volta é por ali, siga o rio.\n\nTito sai correndo para as Colinas do Moinho.")
	return {"status": "wrong_step"}

func _commit(receipt: String, saved: Dictionary, text: String) -> Dictionary:
	var result: Dictionary = session.commit_operation(receipt, saved.checkpoint, saved.player)
	result.text = text
	return result
