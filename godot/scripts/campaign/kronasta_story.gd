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
	{"id":"bambuzal","name":"Vila do Bambuzal","kind":"bairro","bairro":2,"act":1,"levels":"9–12","note":"Bairro 2 · Lohan."},
	{"id":"beira-canal","name":"Beira-Canal","kind":"bairro","bairro":3,"act":2,"levels":"12–15","note":"Bairro 3 · Kleie."},
	{"id":"feira","name":"Feira do Largo","kind":"bairro","bairro":4,"act":2,"levels":"15–18","note":"Bairro 4."},
	{"id":"caverna","name":"Caverna do Mural","kind":"ruinas","act":2,"levels":"15–18","note":"O primeiro laço."},
	{"id":"cais","name":"Cais Velho","kind":"bairro","bairro":5,"act":3,"levels":"18–21","note":"Bairro 5."},
	{"id":"industrial","name":"Distrito Industrial","kind":"bairro","bairro":6,"act":3,"levels":"4–6 na prévia","scene":"kronasta-industrial-a","preview":true,"note":"Pátio de Cargas, Canal das Caldeiras e Usina do Vento."},
	{"id":"pantano","name":"Pântano do Mormaço","kind":"natural","act":4,"levels":"5–7 na prévia","scene":"kronasta-pantano-a","preview":true,"note":"Entrada alagada, Desvio dos cipós e Lago profundo."},
	{"id":"palafitas","name":"Palafitas","kind":"bairro","bairro":7,"act":4,"levels":"24–27","note":"Bairro 7."},
	{"id":"montanha","name":"Serra do Minuano","kind":"natural","act":4,"levels":"6–8 na prévia","scene":"kronasta-montanha-a","preview":true,"note":"Sopé, Encosta e Cume."},
	{"id":"alto-da-serra","name":"Alto da Serra","kind":"bairro","bairro":8,"act":4,"levels":"27–30","note":"Bairro 8."},
	{"id":"aracati","name":"Ilha do Aracati","kind":"natural","act":4,"levels":"30–34","note":"A ponte está fechada."},
	{"id":"centro","name":"Centro","kind":"bairro","bairro":9,"act":5,"levels":"30–33","note":"Bairro 9 · estúdio da Pipa TV."},
	{"id":"lajes","name":"Conjunto das Lajes","kind":"bairro","bairro":10,"act":5,"levels":"33–36","note":"Bairro 10."},
	{"id":"porto","name":"Porto Novo","kind":"bairro","bairro":11,"act":6,"levels":"36–40","note":"Bairro 11."},
	{"id":"coracao","name":"Coração das Ruínas","kind":"ruinas","act":6,"levels":"40–45","note":"O Elo."},
	{"id":"mirante","name":"Alto do Mirante","kind":"bairro","bairro":12,"act":6,"levels":"40–44","note":"Bairro 12."},
	{"id":"santuario","name":"Santuário do Lendário","kind":"ruinas","act":6,"levels":"46","note":"O lendário."},
	{"id":"estadio","name":"Estádio de Kronasta","kind":"final","act":6,"levels":"48–50","note":"A final contra a Jamile."},
]

## Story beats that exist in the game today, in the order the objective follows.
## Each is complete when done(player) says so; the first open one is the objective.
const BEATS := [
	{"id":"prologo","act":0,"place":"rua-dos-ventos","text":"Termine o treino com o Sr. Assis e monte seu primeiro parceiro."},
	{"id":"nina","act":1,"place":"parque","text":"Nina perdeu a rabiola do Carcará no Parque dos Ventos. Fale com ela no Jardim das Pipas."},
	{"id":"lacertubo","act":1,"place":"parque","text":"A rabiola de Nina foi levada para os canos das Veredas. Vença o Lacertubo."},
	{"id":"nina-devolvida","act":1,"place":"parque","text":"Leve a rabiola de volta para Nina, no Jardim das Pipas."},
	{"id":"mikka","act":1,"place":"morro","text":"Suba o Morro do Sol e vença a Mikka, campeã do primeiro bairro."},
	{"id":"bosque","act":1,"place":"bosque","text":"Siga pelo Bosque dos Ventos até a Clareira do Marco. Pela pausa: Mapa → Região de Kronasta."},
]

## QA previews: built maps whose story gate does not exist yet open only in development
## builds (editor and debug exports), never for players in a release export. Set
## SOULMONSTERS_QA=0 to play a debug build as a player would. Tests pin qa_override.
static var qa_override := -1

static func qa() -> bool:
	if qa_override>=0: return qa_override==1
	return OS.is_debug_build() and OS.get_environment("SOULMONSTERS_QA")!="0"

static func flags(player: Dictionary) -> Dictionary:
	return player.get("flags",{})

static func prologue_done(player: Dictionary) -> bool:
	return not player.get("partners",[]).is_empty() and player.get("journey",{}).get("phase","")=="complete"

static func mikka_defeated(player: Dictionary) -> bool:
	return player.get("morro",{}).get("stars",{}).has("morro-5")

static func beat_done(player: Dictionary, id: String) -> bool:
	var f:=flags(player)
	match id:
		"prologo": return prologue_done(player)
		"nina": return f.get("ninaAccepted",false)
		"lacertubo": return f.get("guardianDefeated",false)
		"nina-devolvida": return f.get("ninaReturned",false)
		"mikka": return mikka_defeated(player)
		"bosque": return f.get("bosqueClareiraDescoberta",false)
	return false

static func current_beat(player: Dictionary) -> Dictionary:
	for beat in BEATS:
		if not beat_done(player,beat.id): return beat
	return {}

## Neighbourhoods won. Only the Morro do Sol is built; the rest stay 0 until their
## content exists, so nothing here invents progress.
static func neighbourhoods_won(player: Dictionary) -> int:
	return 1 if mikka_defeated(player) else 0

## Categories rise with the exam of each pair of neighbourhoods (section 6). No exam is
## built yet, so every save is in Rabiola Branca.
static func category(_player: Dictionary) -> String:
	return CATEGORIES[0]

static func act(player: Dictionary) -> int:
	var beat:=current_beat(player)
	return int(beat.act) if not beat.is_empty() else 1

static func objective(player: Dictionary) -> String:
	var beat:=current_beat(player)
	if not beat.is_empty(): return beat.text
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
	return PLACES.filter(func(entry): return state(player,entry.id) in ["aberto","vencido"] and not entry.get("preview",false))

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
static func state(player: Dictionary, id: String) -> String:
	var entry:=place(id)
	if entry.is_empty(): return "em-breve"
	match id:
		"rua-dos-ventos": return "aberto"
		"parque": return "aberto" if prologue_done(player) else "fechado"
		"morro": return "vencido" if mikka_defeated(player) else "aberto" if prologue_done(player) else "fechado"
		"bosque": return "aberto" if prologue_done(player) else "fechado"
	# Previews follow only the prologue in QA; players see them as not built yet.
	if entry.get("preview",false): return ("aberto" if prologue_done(player) else "fechado") if qa() else "em-breve"
	return "em-breve"

static func can_travel(player: Dictionary, id: String) -> bool:
	var entry:=place(id)
	return entry.has("scene") and state(player,id)=="aberto"

static func requirement(player: Dictionary, id: String) -> String:
	var entry:=place(id)
	match state(player,id):
		"aberto": return "QA · prévia sem história" if entry.get("preview",false) else "Aberto"
		"vencido": return "Bairro vencido"
		"fechado": return "Abre ao terminar o prólogo"
	return "Em breve"

static func scene_for_travel(id: String) -> String:
	return str(place(id).get("scene",""))

## Area objective for the free-roam regions. The story objective wins when a beat
## points to this place; otherwise the part's own exploration hint.
static func region_objective(player: Dictionary, scene: String) -> String:
	var region:=Checkpoint.region_of(scene)
	var beat:=current_beat(player)
	if not beat.is_empty() and beat.place==region and region!="bosque": return beat.text
	var part:=scene.right(1)
	return {
		"industrial":{"a":"Siga pelo Pátio de Cargas até o Canal das Caldeiras.","b":"Atravesse o Canal das Caldeiras até a Usina do Vento.","c":"Usina do Vento · o atalho leva de volta ao Pátio de Cargas."},
		"pantano":{"a":"Siga pela margem até o Desvio dos cipós.","b":"Passe pelos cipós até o Lago profundo.","c":"Lago profundo · a margem leva de volta à entrada."},
		"montanha":{"a":"Comece a subida pelo Sopé.","b":"Continue pela Encosta até o Cume.","c":"Cume alcançado · o vento chega livre aqui."},
	}.get(region,{}).get(part,"")
