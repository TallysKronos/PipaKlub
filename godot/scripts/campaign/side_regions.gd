extends RefCounted
## Regiões laterais jogáveis (11/11/2026): Planícies e Gruta do Moinho, Vulcão, Serra Gelada e
## Abismo. Cada uma abre num ponto da campanha, tem criaturas selvagens próprias
## (assets/campaign/encounters.json), duas missões de moradores e um guardião.
##
## Missões:
##   fetch · o morador pede N itens; eles só aparecem no mapa depois do pedido (props requer).
##   find  · o morador pede para achar alguém; a pessoa aparece no mapa, volta para casa ao ser
##           achada (ocultar_apos / requer) e o morador entrega a recompensa.
## O texto do HUD segue a primeira coisa em aberto: missão em andamento, missão ainda não
## pedida, guardião e, por fim, a região em paz.
const Checkpoint = preload("res://scripts/campaign/park_checkpoint.gd")

const REGIONS := {
	"planicies": {
		"scenes": ["planicie-a", "planicie-b", "planicie-c", "planicie-d", "caverna-a", "caverna-b", "caverna-c"],
		"opens": "lacertubo",
		"guardian": {"flag": "grutaEstratonteVencido", "text": "No fundo da gruta, o Estratonte guarda a ilha do Lago Subterrâneo. Nv.18."},
		"peace": "As planícies estão em paz. Explore à vontade · M para viajar por Kronasta.",
		"quests": [
			{"kind": "fetch", "action": "planicieMoinho", "item": "pa-do-moinho", "count": 3,
			 "ask_flag": "planicieMoinhoPedido", "done_flag": "planicieMoinhoConsertado",
			 "ask_receipt": "planicie-moinho-pedido-v1", "done_receipt": "planicie-moinho-v1",
			 "reward": {"coins": 60, "items": {"linha-encerada": 2, "kit-remendo": 1}},
			 "hint": "Converse com os moradores das planícies. No alto da colina, o Seu Bento cuida do moinho parado.",
			 "seek": "Procure as pás do moinho do Seu Bento: %d de %d. Uma ficou nas Colinas, outra no Vale das Pedras e outra na gruta.",
			 "ready": "Você tem as três pás. Leve-as ao Seu Bento, no alto da colina dos Campos do Vento.",
			 "ask": "Seu Bento: O vento da última tempestade arrancou as pás do meu moinho. Uma voou para as Colinas, outra caiu no Vale das Pedras e a terceira rolou para dentro da gruta.\n\nSeu Bento: Se achar as três, eu monto tudo de novo.",
			 "progress": "Seu Bento: Já são %d de %d. Elas brilham um pouco no sol, é madeira envernizada.",
			 "done": "Seu Bento encaixa as três pás e solta o freio. O moinho range, hesita e gira.\n\nSeu Bento: Aí está! Leve 60 moedas, duas linhas enceradas e um Kit de Remendo.",
			 "after": "Seu Bento: Ouve só o moinho girando! Volte quando quiser, a farinha da semana é sua."},
			{"kind": "find", "action": "grutaIara", "target": "grutaTito",
			 "ask_flag": "grutaTitoPedido", "found_flag": "grutaTitoAchado", "reward_flag": "grutaTitoRecompensa",
			 "ask_receipt": "gruta-tito-pedido-v1", "found_receipt": "gruta-tito-achado-v1", "done_receipt": "gruta-tito-v1",
			 "reward": {"coins": 50, "items": {"kit-remendo": 2}},
			 "hint": "Nas Colinas do Moinho, a Iara procura alguém perto da boca da gruta.",
			 "seek": "Encontre o Tito na Gruta do Moinho. A Iara acha que ele seguiu um Vertim até as Galerias de Cristal.",
			 "back": "O Tito voltou para casa. Fale com a Iara nas Colinas do Moinho.",
			 "ask": "Iara: Meu filho, o Tito, entrou na gruta atrás de um Vertim e não voltou. Eu não consigo passar dos bichos da galeria.\n\nIara: Ele adora os cristais azuis. Por favor, procure por ele.",
			 "waiting": "Iara: O Tito seguiu um Vertim para dentro da gruta. Ele gosta dos cristais azuis das galerias do fundo.",
			 "found": "Tito: Eu só queria ver os cristais de perto... e me perdi nas galerias.\n\nKael: Sua mãe está preocupada. O caminho de volta é por ali, siga o rio.\n\nTito sai correndo para as Colinas do Moinho.",
			 "done": "Iara: Você achou o meu menino! Ele chegou falando de cristais azuis e de um bicho de pedra que dorme no lago.\n\nIara: Fique com estes dois Kits de Remendo e 50 moedas.",
			 "after": "Iara: O Tito agora só entra na gruta comigo. Obrigada de novo."},
		],
	},
	"vulcao": {
		"scenes": ["vulcao-a"],
		"opens": "rabiolava",
		"guardian": {"flag": "vulcaoTricordioVencido", "text": "Na boca do vulcão, o Tricórdio guarda a cratera. Nv.40."},
		"peace": "A Caldeira está calma. Explore à vontade · M para viajar por Kronasta.",
		"quests": [
			{"kind": "fetch", "action": "vulcaoBrasa", "item": "pedra-de-brasa", "count": 3,
			 "ask_flag": "vulcaoBrasaPedido", "done_flag": "vulcaoBrasaEntregue",
			 "ask_receipt": "vulcao-brasa-pedido-v1", "done_receipt": "vulcao-brasa-v1",
			 "reward": {"coins": 120, "items": {"linha-encerada": 3, "kit-remendo": 2}},
			 "hint": "No pé da Caldeira, o Mestre Brasa trabalha numa forja de pipas.",
			 "seek": "Procure as pedras de brasa do Mestre Brasa: %d de %d. Elas ficam nas ilhas de basalto, perto da lava.",
			 "ready": "Você tem as três pedras de brasa. Leve-as ao Mestre Brasa, na forja do pé da Caldeira.",
			 "ask": "Mestre Brasa: Pipa que voa perto da lava precisa de vareta temperada em pedra de brasa. Sobraram três no vulcão, longe do meu alcance.\n\nMestre Brasa: Traga as três e eu tempero uma linha que aguenta qualquer calor.",
			 "progress": "Mestre Brasa: Já são %d de %d. A pedra de brasa fica morna na mão, mesmo de noite.",
			 "done": "Mestre Brasa mergulha as pedras na forja. A brasa sobe vermelha e estala.\n\nMestre Brasa: Pronto! Leve 120 moedas, três linhas enceradas e dois Kits de Remendo.",
			 "after": "Mestre Brasa: Essas linhas vão voar por cima da lava sem chamuscar."},
			{"kind": "find", "action": "vulcaoCinza", "target": "vulcaoCaco",
			 "ask_flag": "vulcaoCacoPedido", "found_flag": "vulcaoCacoAchado", "reward_flag": "vulcaoCacoRecompensa",
			 "ask_receipt": "vulcao-caco-pedido-v1", "found_receipt": "vulcao-caco-achado-v1", "done_receipt": "vulcao-caco-v1",
			 "reward": {"coins": 90, "items": {"kit-remendo": 2}},
			 "hint": "Na entrada da Caldeira, a Dona Cinza estuda as rochas e parece preocupada.",
			 "seek": "Encontre o Caco, ajudante da Dona Cinza. Ele subiu para medir as quedas de lava.",
			 "back": "O Caco voltou. Fale com a Dona Cinza na entrada da Caldeira.",
			 "ask": "Dona Cinza: Meu ajudante, o Caco, subiu para medir as quedas de lava e não desceu. Daqui eu só vejo fumaça.\n\nDona Cinza: Ele sempre fica perto das cachoeiras de lava, no alto.",
			 "waiting": "Dona Cinza: O Caco foi para o alto, onde a lava cai. Tome cuidado com os bichos de brasa.",
			 "found": "Caco: Os Trincaguardas cercaram a passagem e eu fiquei preso aqui em cima.\n\nKael: Agora dá para passar. Desça com cuidado.\n\nCaco desce para a entrada da Caldeira.",
			 "done": "Dona Cinza: Ele voltou inteiro, e ainda trouxe as medidas! Obrigada.\n\nDona Cinza: Fique com 90 moedas e dois Kits de Remendo.",
			 "after": "Dona Cinza: O Caco agora mede as quedas de longe."},
		],
	},
	"serra-gelada": {
		"scenes": ["serra-gelada-a", "serra-gelada-b", "serra-gelada-c"],
		"opens": "dona-neve",
		"guardian": {"flag": "geleiraBorealvoVencido", "text": "No topo da Coroa Glacial, o Borealvo guarda o santuário. Nv.38."},
		"peace": "A Serra Gelada está em paz. Explore à vontade · M para viajar por Kronasta.",
		"quests": [
			{"kind": "fetch", "action": "geleiraFlores", "item": "flor-de-gelo", "count": 3,
			 "ask_flag": "geleiraFloresPedido", "done_flag": "geleiraFloresEntregues",
			 "ask_receipt": "geleira-flores-pedido-v1", "done_receipt": "geleira-flores-v1",
			 "reward": {"coins": 110, "items": {"papel-seda": 3, "kit-remendo": 2}},
			 "hint": "No Vale Congelado, o Seu Tomé cuida do abrigo dos viajantes.",
			 "seek": "Procure as flores de gelo do Seu Tomé: %d de %d. Uma em cada trecho da serra.",
			 "ready": "Você tem as três flores de gelo. Leve-as ao Seu Tomé, no Vale Congelado.",
			 "ask": "Seu Tomé: A flor de gelo só nasce onde o vento bate forte. Com três delas eu faço o chá que aquece quem sobe a serra.\n\nSeu Tomé: Tem uma no vale, uma no desfiladeiro e uma lá na Coroa.",
			 "progress": "Seu Tomé: Já são %d de %d. Ela brilha azul no meio da neve.",
			 "done": "Seu Tomé põe as flores na chaleira. O abrigo inteiro fica cheirando a hortelã.\n\nSeu Tomé: Obrigado! Leve 110 moedas, três folhas de papel de seda e dois Kits de Remendo.",
			 "after": "Seu Tomé: Ninguém mais sobe a serra com frio. Volte para um chá."},
			{"kind": "find", "action": "geleiraBia", "target": "geleiraCaio",
			 "ask_flag": "geleiraCaioPedido", "found_flag": "geleiraCaioAchado", "reward_flag": "geleiraCaioRecompensa",
			 "ask_receipt": "geleira-caio-pedido-v1", "found_receipt": "geleira-caio-achado-v1", "done_receipt": "geleira-caio-v1",
			 "reward": {"coins": 90, "items": {"linha-encerada": 2}},
			 "hint": "No Vale Congelado, a Bia olha para o desfiladeiro sem tirar os olhos.",
			 "seek": "Encontre o Caio, irmão da Bia. Ele foi escalar o Desfiladeiro de Gelo.",
			 "back": "O Caio desceu. Fale com a Bia no Vale Congelado.",
			 "ask": "Bia: Meu irmão, o Caio, foi escalar o Desfiladeiro de Gelo e a corda dele ficou presa. Ele não responde quando eu chamo.\n\nBia: Por favor, procure por ele lá no desfiladeiro.",
			 "waiting": "Bia: O Caio está em algum lugar do Desfiladeiro de Gelo, depois do vale.",
			 "found": "Caio: Minha corda congelou numa fenda e eu não consegui descer.\n\nKael: Já soltei. O caminho de volta é por baixo.\n\nCaio desce para o Vale Congelado.",
			 "done": "Bia: Ele chegou! Cheio de gelo no cabelo, mas inteiro.\n\nBia: Fique com 90 moedas e duas linhas enceradas.",
			 "after": "Bia: O Caio agora só escala de dia."},
		],
	},
	"abismo": {
		"scenes": ["abismo-a", "abismo-b", "abismo-c", "abismo-d"],
		"opens": "porto",
		"guardian": {"flag": "abismoCoromarVencido", "text": "No Trono das Marés, o Coromar guarda o fundo do Abismo. Nv.42."},
		"peace": "O Abismo está em paz. Explore à vontade · M para viajar por Kronasta.",
		"quests": [
			{"kind": "fetch", "action": "abismoPerolas", "item": "perola-das-mares", "count": 3,
			 "ask_flag": "abismoPerolasPedido", "done_flag": "abismoPerolasEntregues",
			 "ask_receipt": "abismo-perolas-pedido-v1", "done_receipt": "abismo-perolas-v1",
			 "reward": {"coins": 150, "items": {"linha-encerada": 3, "kit-remendo": 2}},
			 "hint": "No Recife da Entrada, o Seu Jacinto, mergulhador antigo, conserta a rede.",
			 "seek": "Procure as pérolas das marés do Seu Jacinto: %d de %d. Uma no labirinto, uma na cidade e uma perto do trono.",
			 "ready": "Você tem as três pérolas. Leve-as ao Seu Jacinto, no Recife da Entrada.",
			 "ask": "Seu Jacinto: A corrente levou as três pérolas do meu colar para o fundo. Uma ficou no Labirinto de Algas, outra na Cidade Afundada e a última perto do Trono das Marés.\n\nSeu Jacinto: Eu já não desço tão fundo. Você me ajuda?",
			 "progress": "Seu Jacinto: Já são %d de %d. Elas brilham como lua no escuro.",
			 "done": "Seu Jacinto passa as pérolas no fio e fecha o colar.\n\nSeu Jacinto: Era da minha mãe. Leve 150 moedas, três linhas enceradas e dois Kits de Remendo.",
			 "after": "Seu Jacinto: O mar sempre devolve o que é nosso, com um pouco de ajuda."},
			{"kind": "find", "action": "abismoCelina", "target": "abismoLia",
			 "ask_flag": "abismoLiaPedido", "found_flag": "abismoLiaAchada", "reward_flag": "abismoLiaRecompensa",
			 "ask_receipt": "abismo-lia-pedido-v1", "found_receipt": "abismo-lia-achada-v1", "done_receipt": "abismo-lia-v1",
			 "reward": {"coins": 120, "items": {"kit-remendo": 2}},
			 "hint": "No Recife da Entrada, a Celina espera alguém que não voltou do mergulho.",
			 "seek": "Encontre a Lia, a mergulhadora que se perdeu na Cidade Afundada.",
			 "back": "A Lia voltou à superfície. Fale com a Celina no Recife da Entrada.",
			 "ask": "Celina: A Lia mergulhou até a Cidade Afundada atrás dos mosaicos antigos e a boia dela não subiu.\n\nCelina: Ela conhece o mar, mas aquelas ruas viram um labirinto. Procure por ela, por favor.",
			 "waiting": "Celina: A Lia foi até a Cidade Afundada. Siga as ruas cheias de coral.",
			 "found": "Lia: Os Vortespiras me cercaram numa casa afundada e eu perdi a saída.\n\nKael: A Capiboia conhece o caminho. Suba com a gente.\n\nLia nada de volta para o Recife.",
			 "done": "Celina: Ela voltou! E trouxe um desenho dos mosaicos.\n\nCelina: Fique com 120 moedas e dois Kits de Remendo.",
			 "after": "Celina: A Lia agora mergulha sempre com uma corda guia."},
		],
	},
}

var session: Node
func _init(local_session: Node) -> void: session = local_session

static func region_of(scene: String) -> String:
	for id in REGIONS:
		if scene in REGIONS[id].scenes: return id
	return ""

static func is_region(scene: String) -> bool:
	return not region_of(scene).is_empty()

static func actions() -> Array:
	var out: Array = []
	for id in REGIONS:
		for quest in REGIONS[id].quests:
			out.append(quest.action)
			if quest.has("target"): out.append(quest.target)
	return out

## Ponto da campanha que abre cada região (fora do modo QA).
static func open(player: Dictionary, id: String) -> bool:
	var f: Dictionary = player.get("flags", {})
	var rules = preload("res://scripts/campaign/district_rules.gd")
	match str(REGIONS.get(id, {}).get("opens", "")):
		"lacertubo": return bool(f.get("guardianDefeated", false))
		"rabiolava": return bool(f.get("aracatiRabiolavaLivre", false))
		"dona-neve": return rules.completed(player, "alto-da-serra")
		"porto": return rules.completed(player, "porto")
	return false

static func objective(player: Dictionary, scene: String) -> String:
	var id := region_of(scene)
	if id.is_empty(): return ""
	var region: Dictionary = REGIONS[id]
	var f: Dictionary = player.get("flags", {})
	for quest in region.quests:
		if not f.get(quest.ask_flag, false): continue
		if quest.kind == "fetch" and not f.get(quest.done_flag, false):
			var have := int(player.get("inventory", {}).get(quest.item, 0))
			return quest.ready if have >= int(quest.count) else quest.seek % [have, int(quest.count)]
		if quest.kind == "find" and not f.get(quest.found_flag, false): return quest.seek
		if quest.kind == "find" and not f.get(quest.reward_flag, false): return quest.back
	for quest in region.quests:
		if not f.get(quest.ask_flag, false): return quest.hint
	if not f.get(region.guardian.flag, false): return region.guardian.text
	return region.peace

static func quest_for(action: String) -> Dictionary:
	for id in REGIONS:
		for quest in REGIONS[id].quests:
			if quest.action == action or quest.get("target", "") == action: return quest
	return {}

func _ready(action: String, point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var scene: String = saved.checkpoint.get("scene", "")
	if saved.checkpoint.get("space", "") != Checkpoint.SPACE or not is_region(scene) or not point.is_finite(): return {}
	for event in Checkpoint.data(scene).events:
		if event.props.get("acao", "") == action and point.distance_to(Vector2(event.u + .5, event.v + .5)) <= 2.0: return saved
	return {}

## Uma conversa. Retorna {status, text}; status "ok" quando algo foi gravado.
func talk(action: String, point: Vector2) -> Dictionary:
	var quest := quest_for(action)
	var saved := _ready(action, point)
	if quest.is_empty() or saved.is_empty(): return {"status": "wrong_step"}
	var player: Dictionary = saved.player
	var f: Dictionary = player.get("flags", {})
	player.flags = f
	if quest.kind == "fetch":
		if f.get(quest.done_flag, false): return {"status": "already_applied", "text": quest.after}
		if not f.get(quest.ask_flag, false):
			f[quest.ask_flag] = true
			return _commit(quest.ask_receipt, saved, quest.ask)
		var have := int(player.inventory.get(quest.item, 0))
		if have < int(quest.count): return {"status": "already_applied", "text": quest.progress % [have, int(quest.count)]}
		player.inventory[quest.item] = have - int(quest.count)
		if player.inventory[quest.item] == 0: player.inventory.erase(quest.item)
		f[quest.done_flag] = true
		_reward(player, quest.reward)
		return _commit(quest.done_receipt, saved, quest.done)
	if action == quest.target:
		if not f.get(quest.ask_flag, false) or f.get(quest.found_flag, false): return {"status": "wrong_step"}
		f[quest.found_flag] = true
		return _commit(quest.found_receipt, saved, quest.found)
	if f.get(quest.reward_flag, false): return {"status": "already_applied", "text": quest.after}
	if f.get(quest.found_flag, false):
		f[quest.reward_flag] = true
		_reward(player, quest.reward)
		return _commit(quest.done_receipt, saved, quest.done)
	if f.get(quest.ask_flag, false): return {"status": "already_applied", "text": quest.waiting}
	f[quest.ask_flag] = true
	return _commit(quest.ask_receipt, saved, quest.ask)

static func _reward(player: Dictionary, reward: Dictionary) -> void:
	player.coins = int(player.get("coins", 0)) + int(reward.get("coins", 0))
	for item in reward.get("items", {}):
		player.inventory[item] = int(player.inventory.get(item, 0)) + int(reward.items[item])

func _commit(receipt: String, saved: Dictionary, text: String) -> Dictionary:
	var result: Dictionary = session.commit_operation(receipt, saved.checkpoint, saved.player)
	result.text = text
	return result
