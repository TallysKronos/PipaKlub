extends RefCounted
## Acts 4 to 6 (documentation/historia/BIBLIA-DA-HISTORIA.md §7.5-7.7, decisions of
## 04/11/2026): the story steps that join the existing pieces (districts, Serra,
## Aracati, Tyler arcs, Ruínas, Estádio). Each step is a conversation or a short
## sequence of one-time duels. No capture, repeatable XP or invented loot.
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const Rules=preload("res://scripts/campaign/district_rules.gd")
const State=preload("res://scripts/campaign/state.gd")
const Model=preload("res://scripts/campaign/encounter_model.gd")
const KIT:="res://assets/overworld/kits/camara-do-elo-v1/"
const CAPANGA:={"path":KIT+"capanga-masculino-idle-eight.png","region":{"x":448,"y":0,"w":64,"h":96}}
const CAPANGA_F:={"path":KIT+"capanga-feminina-idle-eight.png","region":{"x":448,"y":0,"w":64,"h":96}}
const NPC_FRAME:={"x":0,"y":0,"w":64,"h":96}
## Night of the cerol (lean version): these scenes go dark; other places close.
const NIGHT_SCENES:=["kronasta-centro-a","kronasta-centro-b","kronasta-centro-c","kronasta-lajes-a","kronasta-lajes-b","kronasta-lajes-c"]
const BRACELET:="bracadeira-do-bando"

## id → step. "anchor" is resolved to the nearest walkable cell reachable from the
## area entrance. "duels" run in order; each win is kept, so a loss resumes there.
const STEPS:={
	"trovareta":{"act":4,"scene":"kronasta-bosque-c","anchor":Vector2i(24,24),"name":"Navalha","sprite":CAPANGA,"flag":"trovaretaLivre",
		"intro":"A tempestade não deixa as pipas subirem. Entre os raios, um tenente do Bando segura uma linha negra presa a uma pipa enorme.\n\nNavalha: A Trovareta é do Rato agora. Se encostar nessa linha, eu corto a sua também.",
		"duels":[["Navalha","mata",30,"Navalha: Vamos ver quanto a sua linha aguenta."],["Trovareta","raio",31,"A Trovareta desce com a tempestade. Os fios do Carretel Negro brilham nas varetas dela.\n\nKael: Rabbito, corte só os fios. Não a rabiola."]],
		"outro":"A linha negra se rompe. A Trovareta sobe e o trovão se afasta.\n\nUma figura de capuz assiste da beira da clareira.\n\nRato: Você também deu alma a uma coisa que você fez. Podia vir com a gente.\n\nKael: O Rabbito fica comigo porque quer. Não porque eu mando.\n\nRato: Então guarde essa resposta. Vai precisar dela nas Ruínas."},
	"reuniao":{"act":4,"scene":"kronasta-centro-a","anchor":Vector2i(19,33),"name":"Mikka","sprite":{"path":KIT+"mikka-0.png","region":NPC_FRAME},"flag":"reuniaoCampeoes",
		"intro":"Mikka: Os quatro Ventos voltaram por sua causa. Mas o Bando continua soltando o Carretel Negro pela cidade.\n\nLohan: Sozinho, cada um só protege o próprio bairro. Isso não basta mais.\n\nKleie: Então a gente divide as ruas. Canal e Feira ficam comigo e com a Zulmira.\n\nMarisol: O Cais e as Palafitas, eu e o Caio cobrimos pela água.\n\nBruno Solda: E a Vila Operária fica de olho no galpão do Bando.\n\nDona Neve: A subida da Serra fica comigo. O Bando não vai passar despercebido.\n\nMikka: Está decidido: a partir de hoje, os campeões patrulham Kronasta juntos.",
		"outro":"Dona Cida: Kael! Venha ao posto da Liga. Está na hora da avaliação Vermelha."},
	"exame-vermelho":{"act":4,"scene":"kronasta-centro-a","anchor":Vector2i(29,33),"name":"Dona Cida","sprite":{"path":"res://assets/npc-ds/celina.png","region":NPC_FRAME},"flag":"leagueRed","requires":"reuniaoCampeoes",
		"intro":"Dona Cida: Exame da categoria Vermelha. Dois duelos de avaliação, um atrás do outro, sem descanso no meio. Quero ver como você conduz o parceiro cansado.",
		"duels":[["Avaliação Vermelha","azulao",31,"Dona Cida: Primeiro duelo. Comece."],["Avaliação Vermelha","lacertubo",32,"Dona Cida: Segundo duelo. Sem pausa: observe o seu parceiro."]],
		"outro":"Dona Cida: Categoria Rabiola Vermelha. O Centro está aberto para você."},
	"pipa-tv":{"act":5,"scene":"kronasta-centro-a","anchor":Vector2i(19,28),"name":"Produtor da Pipa TV","sprite":{"path":"res://assets/npc-ds/tiao.png","region":NPC_FRAME},"flag":"pipaTvPedido","requires":"leagueRed",
		"intro":"Produtor: Você é o Kael da Rabiola Vermelha? Preciso de ajuda. Um tal de Pipeiro Fantasma solta pipas presas nos fios e some com as rabiolas. A audiência quer saber quem é.\n\nKael: Vou procurar. Mas primeiro, o campeão do Centro.",
		"outro":"Pedido registrado: caçar o Pipeiro Fantasma depois de vencer o Leo Antena."},
	"barreira":{"act":5,"scene":"kronasta-centro-a","anchor":Vector2i(24,34),"name":"Barreira do Bando","sprite":CAPANGA_F,"flag":"bracadeiraBando","night":true,
		"intro":"A noite do cerol caiu sobre Kronasta. O Bando cortou as rabiolas de meio bairro. Uma capanga fecha a passagem do Centro.\n\nCapanga: Sem braçadeira, ninguém passa.",
		"duels":[["Capanga da barreira","lacertubo",33,"Capanga: Então tira a braçadeira de mim, se conseguir."]],
		"outro":"Kael pega a braçadeira do Bando. Com ela, as barreiras da noite deixam passar.\n\nBraçadeira do Bando registrada."},
	"desalmado-centro":{"act":5,"scene":"kronasta-centro-b","anchor":Vector2i(27,30),"name":"Desalmado","sprite":CAPANGA,"flag":"desalmadoCentro","night":true,"optional":true,
		"intro":"Uma pipa sem rabiola vaga pela rua, sem dono e sem rumo.",
		"duels":[["Desalmado","lacertubo",33,"Kael: Calma. Vamos devolver o seu rumo."]],
		"outro":"A pipa pousa e fica quieta. Quando os Ventos voltarem, a alma dela também volta."},
	"desalmado-lajes":{"act":5,"scene":"kronasta-lajes-a","anchor":Vector2i(28,30),"name":"Desalmado","sprite":CAPANGA,"flag":"desalmadoLajes","night":true,"optional":true,
		"intro":"Um Soulmonster sem rabiola anda em círculos na portaria.",
		"duels":[["Desalmado","raio",34,"Kael: Eu sei que você não quer isso."]],
		"outro":"Ele se acalma e se encosta no muro, esperando o vento."},
	"galpao":{"act":5,"scene":"kronasta-industrial-d","anchor":Vector2i(14,26),"name":"Cadeado de três nós","sprite":CAPANGA,"flag":"galpaoInvadido","requiresDistrict":"lajes",
		"intro":"O galpão do Bando tem um cadeado de três nós. Cada tenente guarda um. Depois deles, os capangas até o fundo.",
		"duels":[["Peteca","mata",34,"Peteca: O primeiro nó é meu."],["Cola-Fina","raio",35,"Cola-Fina: O segundo nó não solta fácil."],["Navalha","mata",36,"Navalha: Na tempestade você teve sorte. Aqui dentro, não."],["Capanga do galpão","lacertubo",35,"Capanga: Ninguém chega ao fundo."],["Capanga do galpão","azulao",36,"Capanga: Último aviso."]],
		"outro":"Os três nós cedem e o cadeado cai. As almas guardadas no galpão se soltam e voam pela claraboia."},
	"gollia-bando":{"act":5,"scene":"kronasta-industrial-d","anchor":Vector2i(20,16),"name":"Gollia","sprite":{"path":"res://assets/campaign/warehouse-v1/gollia.png"},"flag":"golliaFugiu","requires":"galpaoInvadido",
		"intro":"No fundo do galpão, o Gollia espera com o Carretel Negro preso ao parceiro.\n\nGollia: O Rato me deu força. Eu fico do lado de quem tem força.",
		"duels":[["Gollia","azulao",36,"Gollia: Vem."],["Parceiro descontrolado","pipa-dragao-desatada",37,"O Carretel Negro sobrecarrega o parceiro do Gollia. Ele perde o controle e ataca tudo.\n\nGollia: Para! Eu não mandei isso!"]],
		"outro":"O Retalho se põe na frente do Gollia e segura o golpe. O parceiro dele cai, sem forças.\n\nGollia: ...Eu não queria isso.\n\nEle foge com o Bando, abalado."},
	"gerador":{"act":5,"scene":"kronasta-montanha-c","anchor":Vector2i(28,13),"name":"Torre do vento","sprite":{"path":"res://assets/campaign/tufanocorte.png","region":{"x":0,"y":0,"w":384,"h":354}},"flag":"geradorLigado","requires":"golliaFugiu",
		"intro":"Kael: Juntos, vocês conseguem devolver as almas.",
		"outro":"Kael: O vento voltou... Vamos ao Centro.\n\nPipa TV: Estão abertas as inscrições para a Copa Relâmpago!"},
	"copa-relampago":{"act":5,"scene":"kronasta-centro-a","anchor":Vector2i(29,28),"name":"Copa Relâmpago","sprite":{"path":"res://assets/npc-ds/celina.png","region":NPC_FRAME},"flag":"leagueGold","requires":"geradorLigado",
		"intro":"Dona Cida: Exame da categoria Dourada: a Copa Relâmpago. Três rodadas seguidas, ao vivo na Pipa TV.",
		"duels":[["Copa · 1ª rodada","raio",34,"Locutor: Primeira rodada da Copa Relâmpago!"],["Copa · 2ª rodada","mata",35,"Locutor: Segunda rodada, sem descanso!"],["Copa · final","azulao",36,"Locutor: A final da Copa Relâmpago!"]],
		"outro":"Dona Cida: Categoria Rabiola Dourada. O Porto Novo espera por você."},
	"gollia-arrependimento":{"act":6,"scene":"kronasta-coracao-d","anchor":Vector2i(22,30),"name":"Gollia","sprite":{"path":"res://assets/campaign/warehouse-v1/gollia.png"},"flag":"golliaArrependido","requires":"ruinasJamileLivre",
		"intro":"Gollia: No galpão, o Retalho me protegeu. Eu não esqueci.\n\nGollia: Vai, Kael. Eu seguro a porta.",
		"outro":"O Gollia larga o Bando e segura os capangas na entrada. O caminho até o Rato está livre."},
}
## Story order of the steps (the beat list in kronasta_story.gd uses the same ids).
const ORDER:=["trovareta","reuniao","exame-vermelho","pipa-tv","barreira","desalmado-centro","desalmado-lajes","galpao","gollia-bando","gerador","copa-relampago","gollia-arrependimento"]

var session:Node
func _init(active:Node)->void:session=active

static func flags(p:Dictionary)->Dictionary:return p.get("flags",{})
static func done(p:Dictionary,id:String)->bool:return bool(flags(p).get(STEPS[id].flag,false))
static func night_active(p:Dictionary)->bool:
	var f:=flags(p);return f.get("tylerCreatedKnown",false) and not f.get("geradorLigado",false)
static func storm_active(p:Dictionary)->bool:
	var f:=flags(p);return f.get("aracatiRabiolavaLivre",false) and not f.get("trovaretaLivre",false)

## Prerequisites per step, in story order.
static func ready(p:Dictionary,id:String)->bool:
	if not STEPS.has(id) or done(p,id):return false
	var f:=flags(p)
	match id:
		"trovareta":return f.get("aracatiRabiolavaLivre",false)
		"reuniao":return f.get("trovaretaLivre",false)
		"barreira","desalmado-centro","desalmado-lajes":return night_active(p) and (id=="barreira" or f.get("bracadeiraBando",false))
		"galpao":return night_active(p) and Rules.completed(p,"lajes")
	var step:Dictionary=STEPS[id]
	if step.has("requiresDistrict") and not Rules.completed(p,step.requiresDistrict):return false
	return not step.has("requires") or f.get(step.requires,false)

## Map events for one scene; ParkCheckpoint adds them when the map loads.
static func events(scene:String)->Array:
	var result:Array=[]
	for i in ORDER.size():
		var id:String=ORDER[i];var step:Dictionary=STEPS[id]
		if step.scene!=scene:continue
		var at:=point(scene,step.anchor)
		if not at.is_finite():continue
		var props:={"acao":"endgameStep","step":id,"bloqueia":false,"storySpritePath":step.sprite.path}
		if step.sprite.has("region"):props.storySpriteRegion=step.sprite.region
		result.append({"id":21000+i,"type":"npc","name":step.name,"u":int(at.x),"v":int(at.y),"props":props})
	return result

static var _points:={}
## Nearest walkable, flat, ramp-free cell to the anchor that the entrance can reach.
static func point(scene:String,anchor:Vector2i)->Vector2:
	var key:="%s:%d,%d"%[scene,anchor.x,anchor.y]
	if _points.has(key):return _points[key]
	var map=CP.model_for(scene)
	var spawn:Vector2=CP.spawn(scene)
	var best:=Vector2.INF;var best_gap:=INF
	for radius in range(0,9):
		for dv in range(-radius,radius+1):
			for du in range(-radius,radius+1):
				if maxi(absi(du),absi(dv))!=radius:continue
				var cell:=anchor+Vector2i(du,dv)
				if not map.walkable(cell) or map.cell_at(cell).get("ramp")!=null:continue
				var at:=Vector2(cell)+Vector2.ONE*.5
				var gap:=at.distance_to(Vector2(anchor))
				if gap<best_gap and not map.path_to(spawn,at).is_empty():best=at;best_gap=gap
		if best.is_finite():break
	_points[key]=best
	return best

static func duel_index(p:Dictionary,id:String)->int:
	var duels:Array=STEPS[id].get("duels",[])
	for i in duels.size():
		if not flags(p).get("endgame-%s-%d"%[id,i],false):return i
	return duels.size()

## Text for the confirmation before the next action of a step.
static func prompt(p:Dictionary,id:String)->String:
	var step:Dictionary=STEPS[id]
	var index:=duel_index(p,id)
	if index==0 or not step.has("duels"):return step.intro
	return step.duels[index][3]

static func _near(saved:Dictionary,id:String,point_value:Vector2)->bool:
	var step:Dictionary=STEPS[id];var cp:Dictionary=saved.checkpoint
	if cp.get("kind")!="world" or cp.get("scene")!=step.scene or cp.get("space")!=CP.SPACE or not point_value.is_finite():return false
	var at:=point(step.scene,step.anchor)
	return at.is_finite() and point_value.distance_to(at)<=1.8

## Conversation steps: one commit that records the step.
func talk(id:String,point_value:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot()
	if not STEPS.has(id) or STEPS[id].has("duels"):return {"status":"wrong_step"}
	if done(saved.player,id):return {"status":"already_applied"}
	if not ready(saved.player,id) or not _near(saved,id,point_value):return {"status":"wrong_step"}
	saved.player.flags[STEPS[id].flag]=true
	return session.commit_operation("endgame-"+id,saved.checkpoint,saved.player)

## Duel steps: opens the next duel of the sequence.
func begin(id:String,point_value:Vector2)->Dictionary:
	var saved:Dictionary=session.snapshot()
	if not STEPS.has(id) or not STEPS[id].has("duels"):return {"status":"wrong_step"}
	if done(saved.player,id):return {"status":"already_applied"}
	if not ready(saved.player,id) or not _near(saved,id,point_value):return {"status":"wrong_step"}
	var active:Dictionary=preload("res://scripts/campaign/park_training.gd").active(saved.player)
	if active.is_empty() or active.get("condition",{}).get("line",100)<=0 or active.get("condition",{}).get("structure",100)<=0:return {"status":"repair_needed"}
	var index:=duel_index(saved.player,id)
	var duel:Array=STEPS[id].duels[index]
	var model:=Model.new(active,{"modelId":duel[1],"level":duel[2]})
	model.q.name=duel[0];model.q.boss=true
	saved.player.encounter={"id":State.new_id(),"kind":"endgame-step","step":id,"duel":index,"scene":STEPS[id].scene,"space":CP.SPACE,"returnPoint":[point_value.x,point_value.y],"rewardXp":0,"state":model.snapshot()}
	return session.checkpoint({"kind":"encounter"},saved.player)

## Encounter validation for State.valid_encounter.
static func valid(value:Dictionary)->bool:
	var id:String=str(value.get("step",""))
	if not STEPS.has(id) or not STEPS[id].has("duels") or value.get("scene")!=STEPS[id].scene or value.get("space")!=CP.SPACE or value.get("rewardXp")!=0:return false
	var index:=int(value.get("duel",-1))
	if index<0 or index>=STEPS[id].duels.size():return false
	var duel:Array=STEPS[id].duels[index]
	return value.state.get("enemyModelId")==duel[1] and value.state.get("enemyLevel")==duel[2]

func settle()->Dictionary:
	var saved:Dictionary=session.snapshot()
	var e:Dictionary=saved.player.get("encounter",{})
	if saved.checkpoint.kind!="encounter" or e.get("kind")!="endgame-step" or not State.valid_encounter(e):return {"status":"wrong_step"}
	var s:Dictionary=e.state
	if s.outcome not in ["won","lost","fled"]:return {"status":"wrong_step"}
	for p:Dictionary in saved.player.partners:
		if p.id==s.partnerId:p.condition={"line":clampf(s.p.hp/s.p.stats.line*100,0,100),"structure":clampf(s.p.hull/s.p.stats.line*100,0,100)}
	if s.outcome=="won":
		var id:String=e.step
		saved.player.flags["endgame-%s-%d"%[id,int(e.duel)]]=true
		if int(e.duel)==STEPS[id].duels.size()-1:
			saved.player.flags[STEPS[id].flag]=true
			if id=="trovareta":saved.player.flags.trovaretaReleasePending=true
			if id=="barreira":saved.player.inventory[BRACELET]=1
	saved.player.erase("encounter")
	var back:Vector2=CP.spawn(e.scene) if s.outcome=="lost" else Vector2(e.returnPoint[0],e.returnPoint[1])
	return session.commit_operation("encounter-"+e.id,CP.make(e.scene,back,CP.SPACE),saved.player)

static func release_pending(saved: Dictionary) -> bool:
	return saved.get("checkpoint",{}).get("kind","")=="world" and saved.checkpoint.get("scene","")=="kronasta-bosque-c" and flags(saved.player).get("trovaretaLivre",false) and flags(saved.player).get("trovaretaReleasePending",false)

func finish_release() -> Dictionary:
	var saved: Dictionary=session.snapshot()
	if not release_pending(saved):return {"status":"wrong_step"}
	saved.player.flags.trovaretaReleasePending=false
	saved.player.flags.trovaretaReleaseSeen=true
	return session.commit_operation("trovareta-release-v1",saved.checkpoint,saved.player)

## Lines between chained duels, by step: one per duel already won (F33). A step
## without its own lines names who comes next.
const BETWEEN := {
	"trovareta":["Navalha recua para dentro da chuva. A linha negra fica solta no ar, ainda presa à Trovareta."],
	"exame-vermelho":["Dona Cida: Primeiro duelo aprovado. Cuide do parceiro: o segundo vem sem pausa."],
	"galpao":["O primeiro nó do cadeado cede. Peteca sai correndo pela porta lateral.","O segundo nó cede. Cola-Fina larga o carretel e foge.","O último nó estala. Navalha some entre as prateleiras, mas ainda há guardas no fundo do galpão.","Um capanga cai sentado entre as caixas. Resta um no fundo."],
	"gollia-bando":["Gollia cai de joelhos. Atrás dele, o parceiro começa a tremer, puxado pelo Carretel Negro."],
	"copa-relampago":["Locutor: Primeira rodada vencida! A arquibancada pede a segunda!","Locutor: Kael está na final da Copa Relâmpago!"],
}

## Text after a step closes, or after a single duel of a longer sequence.
static func after(p:Dictionary,id:String)->String:
	if done(p,id):return STEPS[id].outro
	var index:=duel_index(p,id)
	if index<=0:return ""
	var lines:Array=BETWEEN.get(id,[])
	if index-1<lines.size():return lines[index-1]
	return "%s ainda espera por você."%STEPS[id].duels[index][0]

## Night exits: without the bracelet, the Bando barriers hold the night scenes.
static func exit_blocked(event:Dictionary,p:Dictionary,area:String)->bool:
	if event.get("type","")!="saida" or not night_active(p) or flags(p).get("bracadeiraBando",false):return false
	return area in NIGHT_SCENES and str(event.props.get("destino",""))!="kronasta"

## Story light (night, storm) as a multiply veil under the HUD. The terrain uses
## unshaded materials, which CanvasModulate does not reach.
static func veil(hud_parent:Node,tint:Color)->void:
	if not is_instance_valid(hud_parent) or hud_parent.has_node("StoryLight"):return
	var veil_rect:=ColorRect.new()
	veil_rect.name="StoryLight"
	veil_rect.color=tint
	veil_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var blend:=CanvasItemMaterial.new()
	blend.blend_mode=CanvasItemMaterial.BLEND_MODE_MUL
	veil_rect.material=blend
	hud_parent.add_child(veil_rect)
	hud_parent.move_child(veil_rect,0)
