extends RefCounted
## QA only (KronastaStory.qa()): start a throwaway journey at a story point of acts
## 4-6, with everything before it already done. Uses its own save folder, so the
## player's real slots are never touched.
const State=preload("res://scripts/campaign/state.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const Levels=preload("res://scripts/campaign/partner_levels.gd")
const Endgame=preload("res://scripts/campaign/endgame_story.gd")
const STORE_PATH:="user://qa-jump"

## Acts 1-3 and the start of act 4, as the beats in kronasta_story.gd record them.
const BASE_FLAGS:=["ninaAccepted","guardianDefeated","ninaReturned","ninaGlideTutorialDone","leagueGreen","leagueGreenSeen","tylerClareiraMet","bosqueClareiraDescoberta","comportaVeredasAberta","muralPrimeiroLaco","feiraApitoComprado","feiraApitoFalsoTestado","feiraApitoVerdadeiro","retalhoBosqueVencido","fotoExpedicaoLida","golliaCarretelVencida","pipaDragaoDesatadaVencida","exameAzulOrientadoV2","leagueBlue","marisolRemarOrientado","marisolRemarPratica","canRemar","assisReconheceuNoRetalho","retalhoAcolhido","mormacoVentosPararam","mormacoLiberto"]
const BASE_DISTRICTS:=["morro","bambuzal","beira-canal","feira","cais","industrial","palafitas"]

## Each jump adds districts and flags on top of the previous ones, in story order.
## "at" is an endgame step (stand next to it) or a scene (stand at its entrance).
const JUMPS:=[
	{"id":"serra","label":"Ato 4 · Subir a Serra (Tufanocorte)","level":28,"districts":[],"flags":[],"at":"kronasta-montanha-a"},
	{"id":"dona-neve","label":"Ato 4 · Alto da Serra (Dona Neve)","level":29,"districts":[],"flags":["tufanocorteLiberto","canCavar","canCorrenteDeAr"],"ops":["serra-primeira-escavacao-v1","serra-galeria-cavar-v1","serra-corrente-de-ar-v1"],"at":"kronasta-montanha-a"},
	{"id":"aracati","label":"Ato 4 · Ilha do Aracati (Rabiolava)","level":31,"districts":["alto-da-serra"],"flags":[],"at":"kronasta-aracati-a"},
	{"id":"trovareta","label":"Ato 4 · Tempestade no Bosque (Navalha e Trovareta)","level":31,"districts":[],"flags":["aracatiRabiolavaLivre"],"at":"trovareta"},
	{"id":"reuniao","label":"Ato 4 · Reunião dos campeões e exame Vermelho","level":32,"districts":[],"flags":["trovaretaLivre"],"at":"reuniao"},
	{"id":"centro","label":"Ato 5 · Pipa TV e Leo Antena","level":33,"districts":[],"flags":["reuniaoCampeoes","leagueRed"],"at":"pipa-tv"},
	{"id":"noite","label":"Ato 5 · Noite do cerol (barreira do Bando)","level":34,"districts":["centro"],"flags":["pipaTvPedido","pipeiroFantasmaResolvido","tylerCreatedKnown"],"at":"barreira"},
	{"id":"taina","label":"Ato 5 · Condomínio à noite (Tainá)","level":35,"districts":[],"flags":["bracadeiraBando"],"at":"kronasta-lajes-a"},
	{"id":"galpao","label":"Ato 5 · Invasão do galpão e Gollia","level":36,"districts":["lajes"],"flags":[],"at":"galpao"},
	{"id":"gerador","label":"Ato 5 · Gerador e Copa Relâmpago","level":37,"districts":[],"flags":["galpaoInvadido","golliaFugiu"],"at":"gerador"},
	{"id":"porto","label":"Ato 6 · Porto Novo (Capitão Jurandir)","level":39,"districts":[],"flags":["geradorLigado","leagueGold"],"at":"kronasta-porto-a"},
	{"id":"ruinas","label":"Ato 6 · Coração das Ruínas","level":42,"districts":["porto"],"flags":[],"at":"kronasta-coracao-a"},
	{"id":"rato","label":"Ato 6 · Câmara do Elo (Gollia, Rato e Eremor)","level":44,"districts":[],"flags":["ruinasNinaLivre","ruinasMikkaLivre","ruinasJamileLivre"],"at":"gollia-arrependimento"},
	{"id":"mirante","label":"Ato 6 · Alto do Mirante (Ícaro)","level":45,"districts":[],"flags":["golliaArrependido","ruinasChefeVencido","enamorDesperto","enamorDerrotado"],"at":"kronasta-mirante-a"},
	{"id":"final","label":"Ato 6 · Estádio de Kronasta (chave final)","level":48,"districts":["mirante"],"flags":[],"at":"kronasta-estadio-a"},
]

static func jump(id:String)->Dictionary:
	for entry:Dictionary in JUMPS:
		if entry.id==id:return entry
	return {}

## Builds the player and checkpoint for a jump. Empty when the id is unknown.
static func build(id:String)->Dictionary:
	var target:=jump(id)
	if target.is_empty():return {}
	var player:Dictionary=State.fresh("slot-1").player
	player.name="QA"
	player.partners=[{"id":"qa-partner","modelId":"rabbito","personalName":"Rabbito","xp":Levels.xp_for_level(int(target.level)),"craftBonus":0,"condition":{"line":100,"structure":100}}]
	player.equippedPartnerId="qa-partner"
	player.journey={"lesson":5,"phase":"complete"}
	preload("res://scripts/campaign/pipeiro_identity.gd").issue_into(player)
	player.flags.pipeiroDocumentsSeen=true
	# Ceremonies of earlier acts were already watched in this journey.
	player.flags.firstInsigniaSeen=true
	player.morro=load("res://scripts/campaign/morro.gd").Rules.defaults()
	player.morro.stars={"morro-1":3,"morro-2":3,"morro-3":3,"morro-4":3,"morro-5":3}
	var districts:Array=BASE_DISTRICTS.duplicate()
	for flag in BASE_FLAGS:player.flags[flag]=true
	for entry:Dictionary in JUMPS:
		districts.append_array(entry.districts)
		for flag in entry.flags:player.flags[flag]=true
		for op in entry.get("ops",[]):player.completedOperations.append(op)
		if entry.id==id:break
	for district in districts:_win(player,district)
	var at:String=target.at
	var scene:String=Endgame.STEPS[at].scene if Endgame.STEPS.has(at) else at
	var point:Vector2=CP.spawn(scene)
	if Endgame.STEPS.has(at):
		var near:Vector2=Endgame.point(scene,Endgame.STEPS[at].anchor)+Vector2(0,1)
		if CP.model_for(scene).point_walkable(near):point=near
	return {"player":player,"checkpoint":CP.make(scene,point,CP.SPACE)}

## Writes a jump into an open session. Completed operations can only enter a save
## through commit_operation, so each one is committed on top of the checkpoint.
static func install(session:Node,id:String)->Dictionary:
	var built:=build(id)
	if built.is_empty():return {"status":"wrong_step"}
	var ops:Array=built.player.completedOperations.duplicate()
	built.player.completedOperations=[]
	var result:Dictionary=session.checkpoint(built.checkpoint,built.player)
	for op in ops:
		if result.status!="ok":break
		result=session.commit_operation(op,built.checkpoint,session.snapshot().player)
	return result

static func _win(player:Dictionary,id:String)->void:
	var entry:Dictionary=Rules.entry(player,id)
	entry.completed=true;entry.rewardClaimed=true;entry.champion="player"
	for stage:Dictionary in Rules.definition(id).stages.slice(0,4):
		if stage.id not in entry.qualification:entry.qualification.append(stage.id)
	Rules.store(player,id,entry)
	Rules.award_emblem(player,id)
