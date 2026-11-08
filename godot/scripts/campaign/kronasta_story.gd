extends RefCounted
## Kronasta campaign spine (documentation/historia/BIBLIA-DA-HISTORIA.md, v2).
## Pure reads of the save: it never writes. Progress comes from the flags and
## records the built content already keeps; places the story has not built yet
## stay visible as "em breve" so the map shows where the journey goes (P14).
const Checkpoint=preload("res://scripts/campaign/park_checkpoint.gd")

const CATEGORIES := ["Rabiola Branca","Rabiola Verde","Rabiola Azul","Rabiola Vermelha","Rabiola Dourada","Campeão de Kronasta"]
const ACTS := ["Prólogo","Ato 1 · A rabiola cortada","Ato 2 · A porta","Ato 3 · O rival sem dono","Ato 4 · Os Quatro Ventos","Ato 5 · A noite do cerol","Ato 6 · O Elo"]

## kind: casa, bairro, natural, ruinas, final. levels: suggested range shown on the map.
## scene: where travel lands when the place can be entered from the region screen.
## preview: built map whose story gate (a later neighbourhood) is not built yet; QA only.
const PLACES := [
	{"id":"rua-dos-ventos","name":"Vila do Primeiro Vento","kind":"casa","act":0,"levels":"1–3","scene":"quintal","note":"Sua casa e o ateliê do Sr. Assis."},
	{"id":"parque","name":"Parque dos Ventos","kind":"natural","act":1,"levels":"1–8","note":"Jardim, Clareira e Veredas. Acesso pela Vila."},
	{"id":"morro","name":"Morro do Sol","kind":"bairro","bairro":1,"act":1,"levels":"4–8","note":"Bairro 1 · Mikka. Acesso pela Vila."},
	{"id":"bosque","name":"Bosque dos Ventos","kind":"natural","act":1,"levels":"1–5","scene":"kronasta-bosque-a","note":"Trilha das Copas, Desvio do Riacho e Clareira do Marco."},
	{"scene":"kronasta-bambuzal-a","id":"bambuzal","name":"Vila do Bambuzal","kind":"bairro","bairro":2,"act":1,"levels":"9–12","note":"Bairro 2 · Lohan."},
	{"scene":"kronasta-beira-canal-a","id":"beira-canal","name":"Beira-Canal","kind":"bairro","bairro":3,"act":2,"levels":"12–15","note":"Bairro 3 · Kleie."},
	{"scene":"kronasta-feira-a","id":"feira","name":"Feira do Largo","kind":"bairro","bairro":4,"act":2,"levels":"15–18","note":"Bairro 4."},
	{"scene":"caverna-mural-a","id":"caverna","name":"Caverna do Mural","kind":"ruinas","act":2,"levels":"15–18","note":"O primeiro laço."},
	{"scene":"kronasta-cais-a","id":"cais","name":"Cais Velho","kind":"bairro","bairro":5,"act":3,"levels":"18–21","note":"Bairro 5."},
	{"id":"industrial","name":"Distrito Industrial","kind":"bairro","bairro":6,"act":3,"levels":"20–24","scene":"kronasta-industrial-a","note":"Pátio de Cargas, Canal das Caldeiras e Usina do Vento."},
	{"id":"pantano","name":"Pântano do Mormaço","kind":"natural","act":4,"levels":"5–7 na prévia","scene":"kronasta-pantano-a","preview":true,"note":"Entrada alagada, Desvio dos cipós e Lago profundo."},
	{"id":"palafitas","scene":"kronasta-palafitas-a","name":"Palafitas","kind":"bairro","bairro":7,"act":4,"levels":"24–27","note":"Resgate de Retalho e campeonato de Caio Garça."},
	{"id":"montanha","name":"Serra de Kronasta","kind":"natural","act":4,"levels":"26–32","scene":"kronasta-montanha-a","note":"Sopé, Encosta e Cume."},
	{"id":"centro","name":"Centro","kind":"bairro","bairro":9,"act":4,"levels":"30–33","scene":"kronasta-centro-a","note":"Praça da Matriz e Pipa TV."},
	{"id":"alto-da-serra","name":"Alto da Serra","kind":"bairro","bairro":8,"act":4,"levels":"27–30","note":"Bairro 8."},
	{"id":"aracati","scene":"kronasta-aracati-a","name":"Ilha do Aracati","kind":"natural","act":4,"levels":"30–34","note":"Atravesse a ponte e siga a trilha até o terreiro."},
	{"id":"lajes","name":"Condomínio","scene":"kronasta-lajes-a","kind":"bairro","bairro":10,"act":5,"levels":"33–36","note":"Bairro 10."},
	{"id":"porto","scene":"kronasta-porto-a","name":"Porto Novo","kind":"bairro","bairro":11,"act":6,"levels":"36–40","note":"Bairro 11."},
	{"id":"coracao","scene":"kronasta-coracao-a","name":"Coração das Ruínas","kind":"ruinas","act":6,"levels":"40–45","note":"O Elo."},
	{"id":"mirante","scene":"kronasta-mirante-a","name":"Alto do Mirante","kind":"bairro","bairro":12,"act":6,"levels":"40–44","note":"Bairro 12."},
	{"id":"santuario","name":"Santuário do Lendário","kind":"ruinas","act":6,"levels":"46","note":"O lendário."},
	{"id":"estadio","scene":"kronasta-estadio-a","name":"Estádio de Kronasta","kind":"final","act":6,"levels":"48–50","note":"A final contra a Jamile."},
]

## Story beats that exist in the game today, in the order the objective follows.
## Each is complete when done(player) says so; the first open one is the objective.
const BEATS := [
	{"id":"prologo","act":0,"place":"rua-dos-ventos","text":"Termine o treino com o Sr. Assis e monte seu primeiro parceiro."},
	{"id":"mikka","act":1,"place":"morro","text":"Suba o Morro do Sol e vença a Mikka, campeã do primeiro bairro."},
	{"id":"nina","act":1,"place":"parque","text":"Depois da Mikka, fale com Nina no Jardim das Pipas. A rabiola do Carcará dela foi levada."},
	{"id":"bosque","act":1,"place":"bosque","text":"Siga pelo Bosque dos Ventos até a Clareira do Marco. Pela pausa: Mapa → Região de Kronasta."},
	{"id":"lohan","act":1,"place":"bambuzal","text":"Explore a Vila do Bambuzal e vença o Lohan, campeão do segundo bairro."},
	{"id":"tyler","act":1,"place":"parque","text":"Encontre Tyler e Rai na roda da Clareira do Papel."},
	{"id":"lacertubo","act":2,"place":"parque","text":"A passagem pela Clareira está aberta. Explore as Veredas e recupere a rabiola de Nina no pátio do Lacertubo."},
	{"id":"nina-devolvida","act":1,"place":"parque","text":"Leve a rabiola de volta para Nina, no Jardim das Pipas."},
	{"id":"promocao-verde","act":1,"place":"parque","text":"Volte à Nina para reconhecer o exame e receber a categoria Rabiola Verde."},
	{"id":"planar-nina","act":1,"place":"parque","text":"Experimente Planar com o Carcará da Nina nas setas azuis junto ao rio das Veredas."},
	{"id":"canal-pipeiros","act":2,"place":"beira-canal","text":"Explore Beira-Canal e vença os quatro pipeiros do percurso."},
	{"id":"canal-comporta","act":2,"place":"parque","text":"Volte às Veredas. Enfrente Grampo junto ao controle do canal e destranque a comporta."},
	{"id":"canal-kleie","act":2,"place":"beira-canal","text":"A comporta está aberta. Volte ao pátio e dispute o emblema com Kleie."},
	{"id":"feira-apito","act":2,"place":"feira","text":"Na praça da Feira, procure Seu Lalau e o apito de vento."},
	{"id":"feira-falso","act":2,"place":"parque","text":"Experimente o apito na porta das Ruínas, no antigo pátio do guardião das Veredas."},
	{"id":"feira-verdadeiro","act":2,"place":"feira","text":"Confronte Lalau e procure Grampo no beco da parte B para recuperar o apito verdadeiro."},
	{"id":"feira-zulmira","act":2,"place":"feira","text":"Vença os quatro desafios e Dona Zulmira para conquistar o quarto emblema."},
	{"id":"mural-primeiro-laco","act":2,"place":"caverna","text":"Atravesse a Caverna do Mural e encontre Tyler no salão das marcas antigas."},
	{"id":"cais-emblema","act":3,"place":"cais","text":"Explore o Cais Velho, vença os quatro pipeiros e dispute o quinto emblema com Marisol."},
	{"id":"retalho-bosque","act":3,"place":"bosque","text":"Após vencer o Cais, siga pela saída norte da Clareira do Marco e encontre Retalho no Bosque D."},
	{"id":"foto-expedicao","act":3,"place":"rua-dos-ventos","text":"Volte ao ateliê do Sr. Assis e examine o arquivo na mesa de estudos."},
	{"id":"galpao-gollia","act":3,"place":"industrial","text":"Na Vila Operária, encontre Gollia no depósito da parte B."},
	{"id":"galpao-retalho","act":3,"place":"industrial","text":"Atravesse a porta do depósito e investigue o galpão com Tyler e Retalho."},
	{"id":"bruno-emblema","act":3,"place":"industrial","text":"Depois do galpão, vença os desafios da Vila Operária e dispute o emblema com Bruno Solda."},
	{"id":"azul-preparacao","act":3,"place":"rua-dos-ventos","text":"Converse com o Sr. Assis sobre a prova de condução e cuidado da Liga."},
	{"id":"exame-azul","act":3,"place":"parque","text":"Faça a prova de condução e cuidado no Pátio da Liga, junto ao Parque."},
	{"id":"remar-orientacao","act":3,"place":"cais","text":"Volte à Marisol, no Cais Velho, para preparar a travessia pela água."},
	{"id":"remar-pratica","act":3,"place":"pantano","text":"Experimente Remar com a capivara de Marisol nas setas azuis da Entrada alagada, no Pântano."},
	{"id":"mormaco-sinais","act":4,"place":"pantano","text":"O ar parou. Observe o caminho da Entrada alagada, no Pântano."},
	{"id":"mormaco-liberto","act":4,"place":"pantano","text":"Siga até o lago da parte C e liberte Mormaço do Carretel Negro."},
	{"id":"palafitas-emblema","act":4,"place":"palafitas","text":"Vença Seyran, Oruvo, Kessai e Veldren nas Palafitas e dispute o emblema com Caio Garça."},
	# Acts 4-6 (BIBLIA §7.5-7.7, decisions of 04/11/2026). Steps marked in
	# endgame_story.gd are the new conversations and duel sequences.
	{"id":"tufanocorte","act":4,"place":"montanha","text":"Suba a Serra a pé até o Cume e solte o Tufanocorte."},
	{"id":"serra-habilidades","act":4,"place":"montanha","text":"Aprenda Cavar com o tatu e suba o paredão com a Corrente de ar."},
	{"id":"dona-neve","act":4,"place":"montanha","text":"Vença os quatro desafios do Alto da Serra e dispute o emblema com a Dona Neve."},
	{"id":"rabiolava","act":4,"place":"aracati","text":"Atravesse a ponte da Ilha do Aracati e solte a Rabiolava no terreiro."},
	{"id":"trovareta","act":4,"place":"bosque","text":"Uma tempestade caiu sobre o Bosque. Vá à Clareira do Marco: a Trovareta está presa."},
	{"id":"reuniao","act":4,"place":"centro","text":"Os campeões dos bairros esperam você na Praça da Matriz, no Centro."},
	{"id":"exame-vermelho","act":4,"place":"centro","text":"Faça o exame da categoria Vermelha com a Dona Cida, na Praça da Matriz."},
	{"id":"pipa-tv","act":5,"place":"centro","text":"Converse com o produtor da Pipa TV na Praça da Matriz."},
	{"id":"leo-antena","act":5,"place":"centro","text":"Vença os quatro desafios do Centro e dispute o emblema com o Leo Antena."},
	{"id":"homunculo","act":5,"place":"rua-dos-ventos","text":"Volte ao ateliê e desça ao laboratório sob a casa do Sr. Assis."},
	{"id":"barreira","act":5,"place":"centro","text":"A noite do cerol caiu. No Centro, tire a braçadeira de um capanga do Bando."},
	{"id":"taina","act":5,"place":"lajes","text":"Com a braçadeira, entre no Condomínio e vença a Tainá, mesmo de noite."},
	{"id":"galpao","act":5,"place":"industrial","text":"Invada o galpão do Bando, na Vila Operária: desfaça os três nós do cadeado."},
	{"id":"gollia-bando","act":5,"place":"industrial","text":"Enfrente o Gollia no fundo do galpão."},
	{"id":"gerador","act":5,"place":"montanha","text":"Suba à torre do vento, no Cume da Serra, e chame os Quatro Ventos."},
	{"id":"copa-relampago","act":5,"place":"centro","text":"Dispute a Copa Relâmpago, o exame da categoria Dourada, na Praça da Matriz."},
	{"id":"jurandir","act":6,"place":"porto","text":"Vença os quatro desafios do Porto Novo e dispute o emblema com o Capitão Jurandir."},
	{"id":"ruinas-aliados","act":6,"place":"coracao","text":"Entre no Coração das Ruínas e solte a Nina, a Mikka e a Jamile."},
	{"id":"gollia-arrependimento","act":6,"place":"coracao","text":"Siga até a porta da Câmara do Elo, na parte D das Ruínas."},
	{"id":"rato","act":6,"place":"coracao","text":"Enfrente o Rato no altar do Elo."},
	{"id":"eremor","act":6,"place":"coracao","text":"O Eremor despertou. Vença o lendário antes que ele saia das Ruínas."},
	{"id":"icaro","act":6,"place":"mirante","text":"Vença os quatro desafios do Alto do Mirante e dispute o emblema com o Ícaro."},
	{"id":"final","act":6,"place":"estadio","text":"Vá ao Estádio de Kronasta e dispute a chave final."},
]

## QA previews: built maps whose story gate does not exist yet open only in development
## builds (editor and debug exports), never for players in a release export. Set
## SOULMONSTERS_QA=0 to play a debug build as a player would. Tests pin qa_override.
static var qa_override := -1

static func qa() -> bool:
	if not OS.is_debug_build(): return false
	if qa_override>=0: return qa_override==1
	return OS.get_environment("SOULMONSTERS_QA")!="0"

static func flags(player: Dictionary) -> Dictionary:
	return player.get("flags",{})

static func prologue_done(player: Dictionary) -> bool:
	return not player.get("partners",[]).is_empty() and player.get("journey",{}).get("phase","")=="complete"

static func mikka_defeated(player: Dictionary) -> bool:
	return preload("res://scripts/campaign/district_rules.gd").completed(player,"morro")

static func beat_done(player: Dictionary, id: String) -> bool:
	var f:=flags(player)
	var endgame=load("res://scripts/campaign/endgame_story.gd")
	if endgame.STEPS.has(id):return endgame.done(player,id)
	var rules=preload("res://scripts/campaign/district_rules.gd")
	match id:
		"tufanocorte":return f.get("tufanocorteLiberto",false)
		# F18: Cavar (lesson, first dig, gallery) comes before the wind; riding the wind
		# alone does not skip the lesson.
		"serra-habilidades":return rules.completed(player,"alto-da-serra") or (f.get("canCavar",false) and "serra-galeria-cavar-v1" in player.get("completedOperations",[]) and "serra-corrente-de-ar-v1" in player.get("completedOperations",[]))
		"dona-neve":return rules.completed(player,"alto-da-serra")
		"rabiolava":return f.get("aracatiRabiolavaLivre",false)
		"leo-antena":return rules.completed(player,"centro")
		"fantasma":return f.get("pipeiroFantasmaResolvido",false)
		"homunculo":return f.get("tylerCreatedKnown",false)
		"taina":return rules.completed(player,"lajes")
		"jurandir":return rules.completed(player,"porto")
		"ruinas-aliados":return f.get("ruinasNinaLivre",false) and f.get("ruinasMikkaLivre",false) and f.get("ruinasJamileLivre",false)
		"rato":return f.get("ruinasChefeVencido",false)
		"eremor":return f.get("enamorDerrotado",false)
		"icaro":return rules.completed(player,"mirante")
		"final":return f.get("campeaoKronasta",false)
	match id:
		"heleana-confissao":return f.get("heleanaConfessouRabiola",false)
		"palafitas-emblema":return preload("res://scripts/campaign/district_rules.gd").completed(player,"palafitas")
		"galpao-gollia":return f.get("golliaCarretelVencida",false)
		"galpao-retalho":return f.get("pipaDragaoDesatadaVencida",false)
		"bruno-emblema":return preload("res://scripts/campaign/district_rules.gd").completed(player,"industrial")
		"retalho-atelie":return f.get("assisReconheceuNoRetalho",false)
		"retalho-confianca":return f.get("retalhoAcolhido",false) or f.get("retalhoParceiraHeleana",false)
		"mormaco-sinais":return f.get("mormacoVentosPararam",false)
		"mormaco-liberto":return f.get("mormacoLiberto",false)
		"remar-pratica":return f.get("marisolRemarPratica",false)
		"remar-orientacao":return f.get("marisolRemarOrientado",false)
		"exame-azul":return f.get("leagueBlue",false)
		"azul-preparacao":return preload("res://scripts/campaign/blue_exam_preparation.gd").prepared(player)
		"foto-expedicao":return f.get("fotoExpedicaoLida",false)
		"retalho-bosque":return f.get("retalhoBosqueVencido",false)
		"cais-emblema":return preload("res://scripts/campaign/district_rules.gd").completed(player,"cais")
		"canal-pipeiros":return preload("res://scripts/campaign/district_rules.gd").qualified(preload("res://scripts/campaign/district_rules.gd").entry(player,"beira-canal"),preload("res://scripts/campaign/district_rules.gd").definition("beira-canal"))
		"canal-comporta":return f.get("comportaVeredasAberta",false)
		"mural-primeiro-laco":return f.get("muralPrimeiroLaco",false)
		"feira-apito":return f.get("feiraApitoComprado",false)
		"feira-falso":return f.get("feiraApitoFalsoTestado",false)
		"feira-verdadeiro":return f.get("feiraApitoVerdadeiro",false)
		"feira-zulmira":return preload("res://scripts/campaign/district_rules.gd").completed(player,"feira")
		"canal-kleie":return preload("res://scripts/campaign/district_rules.gd").completed(player,"beira-canal")
		"prologo": return prologue_done(player)
		"nina": return f.get("ninaAccepted",false)
		"lacertubo": return f.get("guardianDefeated",false)
		"nina-devolvida": return f.get("ninaReturned",false)
		"mikka": return mikka_defeated(player)
		"planar-nina": return f.get("ninaGlideTutorialDone",false)
		"promocao-verde": return f.get("leagueGreen",false)
		"tyler": return f.get("tylerClareiraMet",false)
		"lohan": return preload("res://scripts/campaign/district_rules.gd").completed(player,"bambuzal")
		"bosque": return f.get("bosqueClareiraDescoberta",false)
	return false

## Side activities: never part of the main chain (BEATS), listed apart in the diary.
## Each entry: title, current instruction, done. Only what the player can act on.
static func optional_quests(player: Dictionary) -> Array:
	var f:=flags(player)
	var rules=preload("res://scripts/campaign/district_rules.gd")
	var result:Array=[]
	if f.get("pipaTvPedido",false) and rules.completed(player,"centro"):
		var ghost:bool=f.get("pipeiroFantasmaResolvido",false)
		result.append({"title":"O Pipeiro Fantasma","text":"Você descobriu quem soltava as pipas presas nos fios." if ghost else "Pedido da Pipa TV · procure o Pipeiro Fantasma na parte C do Centro.","done":ghost})
	if f.get("pipeiroFantasmaResolvido",false):
		var given:bool=f.get("tylerFlowerGiven",false)
		var ready:bool=load("res://scripts/campaign/tyler_arcs.gd").finale_ready(player)
		result.append({"title":"A Flor de Cerejeira","text":"Você entregou a flor ao Tyler." if given else "Leve a flor ao laboratório do Sr. Assis e converse com o Tyler." if ready else "Guarde a flor. Quando a final de Kronasta abrir, o Tyler vai querer conversar no laboratório do Sr. Assis.","done":given})
	# Retalho's personal arc (F02): a choice of Kael, never a gate of the campaign.
	if f.get("retalhoBosqueVencido",false):
		var trust=load("res://scripts/campaign/retalho_trust.gd")
		var reunion=preload("res://scripts/campaign/heleana_confession.gd")
		var welcomed:bool=f.get("retalhoAcolhido",false) or f.get("retalhoParceiraHeleana",false)
		var text:="Volte ao ateliê e aproxime-se de Retalho sem puxar a rabiola dela." if not f.get("assisReconheceuNoRetalho",false) else str(trust.objective(player))
		if f.get("retalhoAcolhido",false):text="Retalho escolheu acompanhar você."
		result.append({"title":"Retalho","text":text,"done":welcomed or reunion.refused(player)})
		if reunion.available(player) or f.get("heleanaReconheceuRetalho",false):
			var met:bool=f.get("heleanaReconheceuRetalho",false)
			result.append({"title":"Heleana e Retalho","text":"Heleana reconheceu Retalho." if met else "Volte para casa." if reunion.refused(player) else "Leve Retalho até Heleana.","done":met})
	var endgame=load("res://scripts/campaign/endgame_story.gd")
	if endgame.night_active(player) and f.get("bracadeiraBando",false):
		var calmed:=int(f.get("desalmadoCentro",false))+int(f.get("desalmadoLajes",false))
		result.append({"title":"Desalmados","text":"%d / 2 acalmados · procure-os no Centro B e no Condomínio A."%calmed,"done":calmed==2})
	return result

static func current_beat(player: Dictionary) -> Dictionary:
	for beat in BEATS:
		if not beat_done(player,beat.id): return beat
	return {}

## Permanent completion across the district catalog, independent of current title.
## Only authored encounters can produce completion in the playable campaign.
static func neighbourhoods_won(player: Dictionary) -> int:
	return preload("res://scripts/campaign/district_rules.gd").completed_count(player)

## First exam is explicit and saved; loss of a district title cannot demote it.
static func category(player: Dictionary) -> String:
	if player.get("flags",{}).get("campeaoKronasta",false):return CATEGORIES[5]
	if player.get("flags",{}).get("leagueGold",false):return CATEGORIES[4]
	if player.get("flags",{}).get("leagueRed",false):return CATEGORIES[3]
	if player.get("flags",{}).get("leagueBlue",false):return CATEGORIES[2]
	return CATEGORIES[1] if player.get("flags",{}).get("leagueGreen",false) else CATEGORIES[0]

static func act(player: Dictionary) -> int:
	var beat:=current_beat(player)
	return int(beat.act) if not beat.is_empty() else 3 if preload("res://scripts/campaign/district_rules.gd").completed(player,"industrial") else 2 if flags(player).get("leagueGreen",false) else 1

static func objective(player: Dictionary) -> String:
	var beat:=current_beat(player)
	if beat.get("id","").begins_with("mormaco-"):return load("res://scripts/campaign/mormaco_story.gd").objective(player)
	if beat.get("id")=="exame-azul":return "Pátio da Liga · "+load("res://scripts/campaign/blue_exam.gd").objective(player)
	if beat.get("id")=="retalho-confianca":return load("res://scripts/campaign/retalho_trust.gd").objective(player)
	if beat.get("id")=="canal-comporta" and flags(player).get("grampoVeredasVencido",false):
		return "Grampo recuou. Destranque a comporta no controle do canal, nas Veredas."
	# The Ruínas rescue names who is still held, in the order of the parts.
	if beat.get("id")=="ruinas-aliados":
		var held:Array=[]
		for pair in [["ruinasNinaLivre","a Nina"],["ruinasMikkaLivre","a Mikka"],["ruinasJamileLivre","a Jamile"]]:
			if not flags(player).get(pair[0],false):held.append(pair[1])
		if held.size()<3:return "Siga pelas Ruínas e solte "+(" e ".join(held) if held.size()<=2 else ", ".join(held))+"."
	# The galpão: three knots (lieutenants), then the guards to the back.
	if beat.get("id")=="galpao" and load("res://scripts/campaign/endgame_story.gd").duel_index(player,"galpao")>=3:
		return "Os três nós cederam. Vença os guardas até o fundo do galpão."
	if beat.get("id")=="serra-habilidades":
		if not flags(player).get("canCavar",false):return "Observe o tatu no cume da Serra para aprender Cavar."
		if "serra-primeira-escavacao-v1" not in player.get("completedOperations",[]):return "Experimente Cavar na terra fofa do cume."
		if "serra-galeria-cavar-v1" not in player.get("completedOperations",[]):return "Volte à terra fofa para abrir a galeria sob a Serra."
		return "Use Corrente de Ar no paredão abaixo do mirante."
	var district:String={"dona-neve":"alto-da-serra","leo-antena":"centro","taina":"lajes","jurandir":"porto","icaro":"mirante"}.get(beat.get("id",""),"")
	if not district.is_empty():
		var progress:String=preload("res://scripts/campaign/district_campaign.gd").objective(player,district)
		if not progress.is_empty():return progress
	if not beat.is_empty(): return beat.text
	if flags(player).get("tufanocorteLiberto",false):
		if not flags(player).get("canCavar",false):return "Observe o tatu no cume da Serra para aprender Cavar."
		if "serra-primeira-escavacao-v1" not in player.get("completedOperations",[]):return "Experimente Cavar na terra fofa do cume."
		if "serra-galeria-cavar-v1" not in player.get("completedOperations",[]):return "Volte à terra fofa para abrir a galeria sob a Serra."
		if "serra-corrente-de-ar-v1" not in player.get("completedOperations",[]):return "Use Corrente de Ar no paredão abaixo do mirante."
		return preload("res://scripts/campaign/district_campaign.gd").objective(player,"alto-da-serra")
	if serra_open(player):return "Siga para o sopé da Serra de Kronasta. O próximo Vento está na montanha."
	if player.get("flags",{}).get("mormacoLiberto",false):return load("res://scripts/campaign/mormaco_story.gd").objective(player)
	if preload("res://scripts/campaign/blue_exam_preparation.gd").prepared(player):return preload("res://scripts/campaign/blue_exam_preparation.gd").data().prepared
	return "Próximo destino: %s. Essa parte da história chega em breve." % next_destination(player).get("name","")

## The first place of the story still ahead (not open and not won), in map order.
## Only this one is named to the player; later places stay a surprise.
static func next_destination(player: Dictionary = {}) -> Dictionary:
	for entry in PLACES:
		if entry.get("preview",false) or entry.kind=="casa": continue
		if state(player,entry.id) in ["fechado","em-breve"]: return entry
	return {}

## Places the player can go back to freely: open or won. Story beats inside them
## are not replayed (won duels and bosses stay gone).
static func released(player: Dictionary) -> Array:
	return PLACES.filter(func(entry): return state(player,entry.id) in ["aberto","vencido"] and (not entry.get("preview",false) or entry.id=="pantano" and load("res://scripts/campaign/retalho_trust.gd").swamp_open(player) or entry.id=="industrial" and load("res://scripts/campaign/endgame_story.gd").night_active(player)))

static func previews(player: Dictionary) -> Array:
	return PLACES.filter(func(entry): return entry.get("preview",false) and qa() and state(player,entry.id)=="aberto")

static func place(id: String) -> Dictionary:
	for entry in PLACES:
		if entry.id==id: return entry
	return {}

static func place_for_scene(scene: String) -> Dictionary:
	var region:=Checkpoint.region_of(scene)
	if not region.is_empty(): return place(region)
	if scene in ["park-trail","park-clearing","park-veredas"]: return place("parque")
	if scene.begins_with("morro"): return place("morro")
	return place("rua-dos-ventos")

## aberto: can be entered now · vencido: neighbourhood won · fechado: story gate not
## reached · em-breve: not built yet.
static func swamp_open(player:Dictionary)->bool:
	return load("res://scripts/campaign/retalho_trust.gd").swamp_open(player) or load("res://scripts/campaign/marisol_row_trip.gd").allowed(player)

static func serra_open(player:Dictionary)->bool:
	return flags(player).get("mormacoLiberto",false) and preload("res://scripts/campaign/district_rules.gd").completed(player,"palafitas")

static func state(player: Dictionary, id: String) -> String:
	var entry:=place(id)
	if entry.is_empty(): return "em-breve"
	var rules=preload("res://scripts/campaign/district_rules.gd")
	# Night of the cerol, lean version: only the night places (and the story stops of
	# the act) stay open until the generator brings the Winds back.
	if load("res://scripts/campaign/endgame_story.gd").night_active(player):
		match id:
			"rua-dos-ventos":return "aberto"
			"centro":return "vencido" if rules.completed(player,"centro") else "aberto"
			"lajes":return "vencido" if rules.completed(player,"lajes") else "aberto" if rules.unlocked(player,"lajes") else "fechado"
			"industrial":return "aberto" if rules.completed(player,"lajes") else "fechado"
			"montanha":return "aberto" if flags(player).get("golliaFugiu",false) else "fechado"
		return "fechado"
	match id:
		"mirante":return "aberto" if preload("res://scripts/campaign/district_rules.gd").unlocked(player,"mirante") else "fechado"
		"estadio":return "aberto" if preload("res://scripts/campaign/district_rules.gd").city_final_unlocked(player) else "fechado"
		"coracao":return "aberto" if preload("res://scripts/campaign/district_rules.gd").completed(player,"porto") else "fechado"
		"porto":return "aberto" if preload("res://scripts/campaign/district_rules.gd").unlocked(player,"porto") else "fechado"
		"lajes":return "aberto" if preload("res://scripts/campaign/district_rules.gd").unlocked(player,"lajes") else "fechado"
		"centro":return "vencido" if rules.completed(player,"centro") else "aberto" if flags(player).get("trovaretaLivre",false) or rules.unlocked(player,"centro") else "fechado"
		# Vila Operária opens after the Cais (district order), by day as well.
		"industrial":return "vencido" if rules.completed(player,"industrial") else "aberto" if rules.unlocked(player,"industrial") else "fechado"
		"aracati":return "aberto" if preload("res://scripts/campaign/district_rules.gd").completed(player,"alto-da-serra") else "fechado"
		"montanha":return "aberto" if serra_open(player) or (qa() and prologue_done(player)) else "fechado"
		"palafitas":return "vencido" if preload("res://scripts/campaign/district_rules.gd").completed(player,id) else "aberto" if preload("res://scripts/campaign/district_rules.gd").unlocked(player,id) or load("res://scripts/campaign/retalho_trust.gd").docks_open(player) else "fechado"
		"pantano":
			if swamp_open(player):return "aberto"
		"rua-dos-ventos": return "aberto"
		"parque": return "aberto" if prologue_done(player) else "fechado"
		"morro": return "vencido" if mikka_defeated(player) else "aberto" if prologue_done(player) else "fechado"
		"caverna":return "aberto" if preload("res://scripts/campaign/mural_story.gd").available(player) else "fechado"
		"cais": return "vencido" if preload("res://scripts/campaign/district_rules.gd").completed(player,id) else "aberto" if preload("res://scripts/campaign/district_rules.gd").completed(player,"feira") else "fechado"
		"feira": return "vencido" if preload("res://scripts/campaign/district_rules.gd").completed(player,id) else "aberto" if preload("res://scripts/campaign/district_rules.gd").completed(player,"beira-canal") else "fechado"
		"beira-canal": return "vencido" if preload("res://scripts/campaign/district_rules.gd").completed(player,id) else "aberto" if flags(player).get("leagueGreen",false) else "fechado"
		"bambuzal": return "vencido" if preload("res://scripts/campaign/district_rules.gd").completed(player,"bambuzal") else "aberto" if mikka_defeated(player) else "fechado"
		"bosque": return "aberto" if prologue_done(player) else "fechado"
	# Previews follow only the prologue in QA; players see them as not built yet.
	if entry.get("preview",false): return ("aberto" if prologue_done(player) else "fechado") if qa() else "em-breve"
	return "em-breve"

static func can_travel(player: Dictionary, id: String) -> bool:
	var entry:=place(id)
	return entry.has("scene") and state(player,id) in ["aberto","vencido"]

static func requirement(player: Dictionary, id: String) -> String:
	var entry:=place(id)
	if load("res://scripts/campaign/endgame_story.gd").night_active(player) and state(player,id)=="fechado":
		if id=="lajes":return "Tire a braçadeira de um capanga do Bando no Centro."
		return "A noite do cerol fechou este caminho. Os Ventos precisam voltar."
	if id=="aracati" and state(player,id)=="fechado":return "Vença Dona Neve no Alto da Serra."
	if id=="centro" and state(player,id)=="fechado":return "Solte a Trovareta no Bosque, durante a tempestade."
	if id=="lajes" and state(player,id)=="fechado":return "Descubra o que o laboratório do Sr. Assis esconde."
	if id=="porto" and state(player,id)=="fechado":return "Conquiste a categoria Dourada na Copa Relâmpago."
	if id=="coracao" and state(player,id)=="fechado":return "Vença o Capitão Jurandir no Porto Novo."
	if id=="mirante" and state(player,id)=="fechado":return "Vença o Eremor no Coração das Ruínas."
	if id=="estadio" and state(player,id)=="fechado":return "Vença os 12 bairros, o Rato e o Eremor."
	if id=="montanha" and state(player,id)=="fechado":return "Liberte Mormaço e vença Caio Garça em Palafitas."
	if id=="palafitas" and state(player,id)=="fechado":return "O resgate abre durante o arco de Retalho; o campeonato exige o emblema de Bruno e Mormaço livre."
	if id=="beira-canal" and preload("res://scripts/campaign/district_rules.gd").completed(player,"bambuzal") and not flags(player).get("leagueGreen",false):return "Conclua o primeiro exame com Nina"
	match state(player,id):
		"aberto":
			if id=="pantano" and load("res://scripts/campaign/marisol_row_trip.gd").allowed(player):return "Prática de Remar disponível · Pântano A"
			return "Resgate de Retalho disponível" if id in ["pantano","palafitas"] and load("res://scripts/campaign/retalho_trust.gd").swamp_open(player) else "QA · prévia sem história" if entry.get("preview",false) else "Aberto"
		"vencido": return "Bairro vencido"
		"fechado": return "Vença a Mikka no Morro do Sol" if id=="bambuzal" else "Vença o Lohan na Vila do Bambuzal" if id=="beira-canal" else "Vença o Kleie em Beira-Canal" if id=="feira" else "Vença a Feira do Largo e recupere o apito verdadeiro" if id=="caverna" else "Vença Dona Zulmira na Feira do Largo" if id=="cais" else "Abre ao terminar o prólogo"
	return "Em breve"

static func scene_for_travel(id: String) -> String:
	return str(place(id).get("scene",""))

## Area objective for the free-roam regions. The story objective wins when a beat
## points to this place; otherwise the part's own exploration hint.
static func region_objective(player: Dictionary, scene: String) -> String:
	var region:=Checkpoint.region_of(scene)
	var rules=preload("res://scripts/campaign/district_rules.gd")
	if region=="mirante":
		if rules.city_final_unlocked(player):return "A Liga espera por você. Abra o mapa da cidade e viaje ao Estádio de Kronasta."
		if rules.unlocked(player,"mirante"):
			var course:String=preload("res://scripts/campaign/district_campaign.gd").objective(player,"mirante")
			# F25: on arrival, the course and Ícaro come before the first challenge.
			if rules.entry(player,"mirante").get("qualification",[]).is_empty():return "Último bairro · quatro pipeiros guardam a subida até Ícaro, o ex-campeão que largou o título. "+course
			return course
	if scene=="mina-ferro-a" and current_beat(player).get("id","")=="serra-habilidades":
		return "Galeria sob a Serra · volte à superfície pela abertura por onde você desceu."
	if region=="coracao" and flags(player).get("enamorDerrotado",false):
		return "Eremor foi contido. Recupere sua equipe e viaje pelo mapa da cidade ao Alto do Mirante, o último bairro."
	if scene=="kronasta-estadio-a":
		return "Campeão de Kronasta · seus amigos esperam por você." if flags(player).get("campeaoKronasta",false) else "Fale com o atendente no balcão para disputar a próxima rodada. Você pode salvar e cuidar da equipe no lobby."
	# An act 4-6 story step placed here wins over the area's district progress.
	var step_beat:=current_beat(player)
	if load("res://scripts/campaign/endgame_story.gd").STEPS.has(step_beat.get("id","")) and step_beat.place==str(place_for_scene(scene).get("id",region)):return objective(player)
	# The Serra's district waits for the climb and its two lessons (beats tufanocorte and
	# serra-habilidades); until then the HUD follows the story.
	if region=="montanha" and step_beat.get("id","") not in ["tufanocorte","serra-habilidades"] and preload("res://scripts/campaign/district_rules.gd").unlocked(player,"alto-da-serra"):return preload("res://scripts/campaign/district_campaign.gd").objective(player,"alto-da-serra")
	if region=="palafitas" and preload("res://scripts/campaign/district_rules.gd").unlocked(player,region):return preload("res://scripts/campaign/district_campaign.gd").objective(player,region)
	var beat:=current_beat(player)
	var here:String=str(place_for_scene(scene).get("id",region))
	# Same text as the diary: some beats (Serra lessons, Mormaço, exams) show their sub-step.
	if not beat.is_empty() and (beat.place==region or beat.place==here) and (region!="bosque" or beat.id=="trovareta"): return objective(player)
	var part:=scene.right(1)
	return {
		"industrial":{"a":"Siga pelo Pátio de Cargas até o Canal das Caldeiras.","b":"Atravesse o Canal das Caldeiras até a Usina do Vento.","c":"Usina do Vento · o atalho leva de volta ao Pátio de Cargas."},
		"pantano":{"a":"Siga pela margem até o Desvio dos cipós.","b":"Passe pelos cipós até o Lago profundo.","c":"Lago profundo · a margem leva de volta à entrada."},
		"montanha":{"a":"Comece a subida pelo Sopé.","b":"Continue pela Encosta até o Cume.","c":"Cume alcançado · o vento chega livre aqui."},
	}.get(region,{}).get(part,"")

## Pre-Bambuzal saves that already accepted Nina retain their existing route.
## A newly accepted quest records the reordered route explicitly.
static func park_access(player:Dictionary,scene:String)->bool:
	if scene=="park-trail":return prologue_done(player)
	if scene not in ["park-clearing","park-veredas"]:return false
	var f:=flags(player)
	return preload("res://scripts/campaign/district_rules.gd").completed(player,"bambuzal") or (f.get("ninaAccepted",false) and not f.get("ninaBambuzalOrder",false))
