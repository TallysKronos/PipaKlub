extends RefCounted
## Public destinations only. Undeveloped biomes are display entries, never travel targets.
const REGIONS := [
	{"id":"vila","name":"Vila do Primeiro Vento","at":Vector2(.20,.23),"scenes":["quintal"],"parts":["Voltar à vila"],"description":"Lar do Kael, ateliê do professor e ruas do bairro."},
	{"id":"parque","name":"Parque dos Ventos","at":Vector2(.35,.34),"scenes":["park-trail","park-clearing","park-veredas","parque-patio-liga"],"parts":["Jardim das Pipas","Clareira do Papel","Veredas do Encanamento","Pátio da Liga · exame Azul"],"description":"Trilhas, duelos e a missão da Nina. A viagem não conclui missões nem libera recompensas."},
	{"id":"bosque","name":"Bosque dos Ventos","at":Vector2(.40,.50),"scenes":["kronasta-bosque-a","kronasta-bosque-b","kronasta-bosque-c"],"parts":["Trilha das Copas","Desvio do Riacho","Clareira do Marco"],"description":"Entre copas, riachos e mirantes. Três trilhas conectadas para explorar."},
	{"id":"pantano","name":"Pântano dos Cipós","at":Vector2(.72,.30),"scenes":["kronasta-pantano-a","kronasta-pantano-b","kronasta-pantano-c"],"parts":["Entrada alagada","Desvio dos Cipós","Lago profundo"],"description":"Passarelas e margens entre águas escuras. Prática de Remar após a orientação de Marisol; história do guardião e chefe ainda em desenvolvimento.","preview":true},
	{"id":"montanha","name":"Serra de Kronasta","at":Vector2(.72,.60),"scenes":["kronasta-montanha-a","kronasta-montanha-b","kronasta-montanha-c"],"parts":["Sopé","Encosta","Cume"],"description":"A pista de Mormaço leva ao sopé. Siga pela encosta para alcançar o cume."},
	{"id":"industrial","name":"Distrito Industrial","at":Vector2(.88,.17),"scenes":["kronasta-industrial-a","kronasta-industrial-b","kronasta-industrial-c"],"parts":["Distrito · A","Distrito · B","Distrito · C"],"description":"Galpões, passagens e pátios de carga. Exploração disponível; história em desenvolvimento.","preview":true},
	{"id":"morro","name":"Morro do Sol","at":Vector2(.32,.86),"scenes":["morro"],"parts":["Entrada do Morro"],"description":"Encontre os pipeiros do Morro. Os desafios continuam liberando os caminhos pela campanha."},
	{"id":"porto","name":"Costa de Kronasta","at":Vector2(.14,.48),"scenes":[],"parts":[],"description":"Uma costa à espera de novas jornadas. Nome e percurso provisórios."},
	{"id":"ruinas","name":"Ruínas antigas","at":Vector2(.54,.78),"scenes":[],"parts":[],"description":"Vestígios nas terras do norte. Esta região ainda não está disponível."},
	{"id":"vulcao","name":"Vulcão de Kronasta","at":Vector2(.88,.78),"scenes":[],"parts":[],"description":"Além das montanhas, uma terra de cinzas e lava. Região futura; nome provisório."},
	{"id":"cavernas","name":"Cavernas de cristal","at":Vector2(.84,.43),"scenes":[],"parts":[],"description":"Passagens sob as rochas. Região futura; nome provisório."},
	{"id":"planicies","name":"Planícies de Kronasta","at":Vector2(.52,.20),"scenes":[],"parts":[],"description":"Campos abertos ao vento. Região futura; nome provisório."},
	{"id":"mina","name":"Mina de ferro","at":Vector2(.59,.62),"scenes":["mina-ferro-a","mina-ferro-b","mina-ferro-c","mina-ferro-d"],"parts":["Pátio de carga","Entroncamento ferroviário","Frentes de extração","Grande veio"],"description":"Quatro galerias conectadas, trilhos e passagens elevadas. Exploração disponível; história e mineração em desenvolvimento.","preview":true},
	{"id":"gelo","name":"Geleira de Kronasta","at":Vector2(.67,.08),"scenes":["gelo-a","gelo-b","gelo-c","gelo-d"],"parts":["Clareira nevada","Bacia de gelo","Fenda glacial","Coroa da geleira"],"description":"Bosques nevados, gelo trincado e três pisos para explorar. História em desenvolvimento; o gelo não quebra nem escorrega.","preview":true},
	{"id":"submerso","name":"Recifes de Kronasta","at":Vector2(.10,.71),"scenes":["submerso-a","submerso-b","submerso-c"],"parts":["Recife de entrada","Jardim de algas","Fenda abissal"],"description":"Explore o leito entre corais e formações rochosas. História em desenvolvimento; sem nado livre ou sistema de oxigênio.","preview":true},
	{"id":"bambuzal","name":"Vila do Bambuzal","at":Vector2(.45,.68),"scenes":["kronasta-bambuzal-a","kronasta-bambuzal-b","kronasta-bambuzal-c"],"parts":["Praça do Bambuzal","Caminho das Varetas","Arena do Lohan"],"description":"Praças e patamares entre os bambus. Quatro pipeiros guardam o caminho até o campeão."},
{"id":"beira-canal","name":"Beira-Canal","at":Vector2(.56,.58),"scenes":["kronasta-beira-canal-a","kronasta-beira-canal-b","kronasta-beira-canal-c"],"parts":["Chegada ao canal","Oficina hidráulica","Pátio do campeão"],"description":"Pontes e patamares junto ao canal. Ajude o bairro e dispute o terceiro emblema."},
{"id":"feira","name":"Feira do Largo","at":Vector2(.64,.68),"scenes":["kronasta-feira-a","kronasta-feira-b","kronasta-feira-c"],"parts":["Praça da Feira","Mercado alto","Largo da campeã"],"description":"Bancas, pipeiros e um apito de origem duvidosa. Dispute o quarto emblema."},
{"id":"caverna","name":"Caverna do Mural","at":Vector2(.54,.74),"scenes":["caverna-mural-a","caverna-mural-b","caverna-mural-c"],"parts":["Vestíbulo do Nó","Galeria do Vento","Salão do Primeiro Laço"],"description":"Tyler encontrou marcas antigas na pedra. A Rabiola Antiga pode responder a elas."},
{"id":"cais","name":"Cais Velho","at":Vector2(.75,.72),"scenes":["kronasta-cais-a","kronasta-cais-b","kronasta-cais-c"],"parts":["Ancoradouro","Docas","Cais alto"],"description":"Barcos de pesca e pipas de sinalização. Cinco desafios pelo quinto emblema."},
	{"id":"palafitas","name":"Palafitas · resgate","at":Vector2(.84,.82),"scenes":["kronasta-palafitas-a","kronasta-palafitas-b","kronasta-palafitas-c"],"parts":["Chegada do resgate","Travessia das docas","Patamar do resgate"],"description":"Percurso do resgate de Retalho. O campeonato do bairro ainda não está disponível."}
]
const LINKS := [[0,1],[0,6],[0,7],[1,2],[2,8],[2,3],[2,4],[4,9],[4,10],[3,10],[3,11],[11,5],[4,12],[4,13],[7,14],[15,16],[16,17],[17,18],[17,19]]
static func region_for(scene:String) -> String:
	for region in REGIONS:
		if scene in region.scenes:return region.id
	if scene.begins_with("morro"):return "morro"
	return "vila"
static func can_travel(scene:String,player:Dictionary={}) -> bool:
	if scene.begins_with("kronasta-montanha-"):
		return scene=="kronasta-montanha-a" and preload("res://scripts/campaign/kronasta_story.gd").can_travel(player,"montanha")
	if scene=="parque-patio-liga":return load("res://scripts/campaign/blue_exam_preparation.gd").eligible(player)
	for region in REGIONS:
		if scene in region.scenes:return not region.get("preview",false) or preload("res://scripts/campaign/kronasta_story.gd").qa() or (region.id=="pantano" and preload("res://scripts/campaign/kronasta_story.gd").swamp_open(player))
	return false
