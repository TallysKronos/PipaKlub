extends RefCounted

const CP = preload("res://scripts/campaign/park_checkpoint.gd")
const Model = preload("res://scripts/campaign/encounter_model.gd")
const State = preload("res://scripts/campaign/state.gd")
const Rules = preload("res://scripts/campaign/district_rules.gd")
const BRACKET := [
	["Grampo","platyx-draft",47,"kronastaQuartas"],
	["Tyler","rai",48,"kronastaSemifinal"],
	["Faye","lacertubo",49,"kronastaChaveVencida"],
	["Jamile","azulao",50,"campeaoKronasta"],
]
static func round_index(flags: Dictionary) -> int:
	if flags.get("campeaoKronasta",false):return 4
	for i in BRACKET.size():
		if not flags.get(BRACKET[i][3],false):return i
	return 4

static func battle_stage(battle: Dictionary) -> Array:
	if battle.scene=="kronasta-estadio-a":
		var index := int(battle.get("stadiumRound",3))
		return BRACKET[index] if index in range(4) else []
	if battle.scene=="kronasta-coracao-d" and battle.get("cerolChief",false):return CHIEF
	return STAGES.get(battle.scene,[])

static func bracket_text(flags: Dictionary) -> String:
	var rows := PackedStringArray(["Quartas: Kael × Grampo · Tyler × Mikka · Faye × Kleie · Lohan × Tainá"])
	var current := round_index(flags)
	if current>=1:rows.append("Semifinais: Kael × Tyler · Faye × Tainá")
	if current>=2:rows.append("Final da chave: Kael × Faye")
	if current>=3:rows.append("Duelo pelo título: Kael × Jamile")
	return "\n\n".join(rows)

## F27: the lobby between rounds. "lobby" is who waits by the attendant before each
## round; earlier opponents watch from the side. Faye has no overworld art yet.
const GRAMPO := ["res://assets/campaign/beira-canal-v1/grampo-idle-eight.png", true, 80.0]
const PLATYX := ["res://assets/campaign/beira-canal-v1/platyx-overworld-eight.png", true, 52.0]
const TYLER := ["res://assets/campaign/tyler-clareira-v1/tyler-overworld-idle-eight.png", true, 80.0]
const JAMILE := ["res://assets/overworld/kits/camara-do-elo-v1/jamile-0.png", false, 76.0]
const LOBBY := [[["Grampo",GRAMPO],["Platyx",PLATYX]], [["Tyler",TYLER]], [], [["Jamile",JAMILE]]]
const LOBBY_SPOT := Vector2i(27, 7)
const STANDS_SPOT := Vector2i(20, 9)
## Reactions after each round, and what the attendant says about the next one.
const AFTER := [
	{"won":"Grampo: Perdemos, mas o Platyx puxou porque quis. Ele nunca voou assim comigo.\n\nPlatyx encosta a cabeça na mão de Grampo.\n\nGrampo: A gente assiste ao resto da chave daqui de baixo.",
	"lost":"Grampo: Viu? O Platyx escolheu lutar, e lutou bem. Recupere a equipe; a gente espera."},
	{"won":"Tyler: A gente aguentou até o fim, Rai. Kael, desde a Clareira eu sabia que essa luta ia acontecer.\n\nTyler: Vou torcer com a Heleana e o Assis.",
	"lost":"Tyler: Foi por pouco. Respire, cuide da equipe e volte. Na revanche eu também puxo com tudo."},
	{"won":"Faye: Então essa é a linha que chegou à final. Guarde esta luta, Kael. Um dia eu volto para a revanche.",
	"lost":"Faye: Agora você sabe como eu puxo. Volte quando tiver uma resposta."},
	{"won":"","lost":"Jamile: A final continua aqui, Kael. Cuide da equipe e volte quando estiver pronto."},
]
const NEXT := [
	"Atendente: Próxima rodada: semifinal contra Tyler. Dá tempo de cuidar da equipe e salvar; fale comigo quando estiver pronto.",
	"Atendente: Você está na final da chave. Faye espera no lobby. Fale comigo quando estiver pronto.",
	"Atendente: A chave é sua. Só falta o duelo pelo título: Jamile já está no lobby.",
]

static func stadium_return_text(flags: Dictionary, outcome: String) -> String:
	var current := round_index(flags)
	if current >= 4: return ""
	if outcome == "won" and current >= 1:
		return AFTER[current - 1].won + "\n\n" + NEXT[current - 1]
	return AFTER[current].lost + "\n\nAtendente: Sua vaga continua na chave. Fale comigo quando quiser tentar de novo."

const CHIEF := ["Rato", "azulao", 44, "ruinasChefeVencido"]

const STAGES := {
	"kronasta-aracati-c": ["Rabiolava", "rabiolava", 33, "aracatiRabiolavaLivre"],
	"kronasta-estadio-a": ["Jamile", "azulao", 50, "campeaoKronasta"],
	"kronasta-coracao-a": ["Capanga do Cerol", "lacertubo", 40, "ruinasNinaLivre"],
	"kronasta-coracao-b": ["Capanga do Cerol", "mata", 41, "ruinasMikkaLivre"],
	"kronasta-coracao-c": ["Platyx · Grampo", "platyx-draft", 43, "ruinasJamileLivre"],
	"kronasta-coracao-d": ["Eremor", "eremor", 45, "enamorDerrotado"],
}
const INTRO := {
	"kronasta-estadio-a": "Na arquibancada, Heleana, Assis e Tyler torcem. Ao lado deles, o Gollia, o Grampo e os campeões dos doze bairros.\n\nJamile: Você viu minha última final pela televisão. Desta vez, é a sua linha que eu vou enfrentar. Pronto, Kael?",
	"kronasta-coracao-a": "Capanga: Se quiser soltar a Nina, vai ter que passar por mim.",
	"kronasta-coracao-b": "Capanga: A Mikka fica onde está. Mostre sua linha, Kael.",
	"kronasta-coracao-c": "Capanga: Rato já entrou na câmara. Você não vai tirar a Jamile daqui.",
	"kronasta-coracao-d": "O Bando desperta Eremor. Os pilares cedem, e o piso se abre. Tyler leva Nina, Mikka e Jamile para a saída; Grampo e Platyx seguram a retaguarda.\n\nKael: Se ele passar daqui, a região inteira corre perigo. Segurem a passagem. Eu vou enfrentá-lo.",
}

static func begin(session: Node, point: Vector2) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var cp: Dictionary = saved.checkpoint
	var scene: String = cp.get("scene", "")
	if cp.kind != "world" or cp.get("space") != CP.SPACE or not STAGES.has(scene) or not (Rules.city_final_unlocked(saved.player) if scene == "kronasta-estadio-a" else Rules.completed(saved.player, "alto-da-serra" if scene == "kronasta-aracati-c" else "porto")):
		return {"status":"wrong_step"}
	var current := round_index(saved.player.flags) if scene=="kronasta-estadio-a" else -1
	if current==4:return {"status":"wrong_step"}
	var stage: Array = BRACKET[current] if current>=0 else STAGES[scene]
	if saved.player.flags.get(stage[3], false):
		return {"status":"wrong_step"}
	var map = CP.model_for(scene)
	var nearby: bool = map.data.events.any(func(e: Dictionary) -> bool:
		return e.props.get("acao") == ("aracatiTerreiro" if scene == "kronasta-aracati-c" else "ruinasDuel") and point.distance_to(Vector2(e.u + .5, e.v + .5)) <= 1.8)
	if not point.is_finite() or not map.point_walkable(point) or not nearby:
		return {"status":"wrong_step"}
	var active: Dictionary = preload("res://scripts/campaign/park_training.gd").active(saved.player)
	if active.is_empty() or active.get("condition", {}).get("line", 100) <= 0 or active.get("condition", {}).get("structure", 100) <= 0:
		return {"status":"repair_needed"}
	var chief: bool = scene=="kronasta-coracao-d" and not saved.player.flags.get("ruinasChefeVencido",false) and not saved.player.flags.get("enamorDesperto",false)
	# Gollia holds the chamber door first (BIBLIA §7.7, act 6 step 3).
	if chief and not saved.player.flags.get("golliaArrependido",false):return {"status":"wrong_step"}
	if chief:stage=CHIEF
	elif scene=="kronasta-coracao-d" and not saved.player.flags.get("enamorDesperto",false):return {"status":"wrong_step"}
	var model := Model.new(active, {"modelId":stage[1], "level":stage[2]})
	model.q.name = stage[0]
	model.q.boss = true
	if scene=="kronasta-coracao-c":model.q.platyxRefusal = "pending"
	saved.player.encounter = {"id":State.new_id(), "kind":"ruinas-elo", "scene":scene, "space":CP.SPACE, "returnPoint":[point.x, point.y], "rewardXp":0, "state":model.snapshot()}
	if current>=0:saved.player.encounter.stadiumRound=current
	if chief:saved.player.encounter.cerolChief=true
	return session.checkpoint({"kind":"encounter"}, saved.player)

static func settle(session: Node) -> Dictionary:
	var saved: Dictionary = session.snapshot()
	var battle: Dictionary = saved.player.get("encounter", {})
	if saved.checkpoint.kind != "encounter" or battle.get("kind") != "ruinas-elo" or not State.valid_encounter(battle):
		return {"status":"wrong_step"}
	var result: Dictionary = battle.state
	if result.outcome not in ["won", "lost", "fled"]:
		return {"status":"wrong_step"}
	if battle.scene=="kronasta-coracao-c" and result.outcome=="won" and result.q.get("platyxRefusal","")!="stopped":
		return {"status":"wrong_step"}
	if result.outcome=="won":preload("res://scripts/campaign/progression.gd").story_win(saved.player,result)
	if result.outcome == "won":
		saved.player.flags[battle_stage(battle)[3]] = true
		if battle.scene=="kronasta-aracati-c":saved.player.flags.canCorrenteDeAr=true
	saved.player.erase("encounter")
	return session.commit_operation("encounter-"+battle.id, CP.make(battle.scene, Vector2(battle.returnPoint[0], battle.returnPoint[1]), CP.SPACE), saved.player)
