extends RefCounted
## Authored, optional first-clear duels. Wild XP and the shared level curve stay intact.
const Levels=preload("res://scripts/campaign/partner_levels.gd")
# Duel IDs remain stable because first-clear receipts in existing saves use them.
# Only this park cast changes; the original NPCs still belong to their own areas.
const DUELS := [
	{"id":"assis","name":"Sr. Assis","scene":"park-trail","area":"jardim-das-pipas","point":Vector2i(31,36),"species":"basica","level":2,"xp":70,"tip":"Procure o cruzamento dos fios antes de cortar. Não precisa atacar sem parar."},
	{"id":"bia","name":"Iara","scene":"park-trail","area":"jardim-das-pipas","point":Vector2i(43,23),"species":"mata","level":3,"xp":110,"intro":"Sou a Iara. Se uma pipa prender nos galhos, eu desembaraço o fio. Quer treinar antes de seguir?","tip":"Guarde energia para defender. Quando eu errar a puxada, você terá uma abertura."},
	{"id":"juninho","name":"Nilo","scene":"park-clearing","area":"clareira-do-papel","point":Vector2i(32,39),"species":"basica","level":4,"xp":170,"intro":"Nilo, entregador de pipas! Esta vai para... espera, depois confiro o endereço. Cabe um duelo no caminho!","tip":"Experimente alternar movimento e corte. Ficar parado facilita a minha puxada."},
	{"id":"lia","name":"Dora","scene":"park-clearing","area":"clareira-do-papel","point":Vector2i(43,24),"species":"raio","level":5,"xp":220,"intro":"Sou a Dora. Um carretel bem cuidado gira leve; um pipeiro precisa saber a hora de aliviar também. Vamos praticar?","tip":"Não gaste toda a energia de uma vez. Afaste-se um pouco para recuperar o fôlego."},
	{"id":"zeca","name":"Cauê","scene":"park-veredas","area":"veredas-do-encanamento","point":Vector2i(33,38),"species":"mata","level":6,"xp":300,"intro":"Cauê. Escute um instante... o vento mudou entre os canos. Num duelo, também dá para perceber o que vem antes do golpe.","tip":"O Lacertubo avisa antes do golpe. Treine observar o adversário, proteger e responder."},
	{"id":"tiao","name":"Celina","scene":"park-veredas","area":"veredas-do-encanamento","point":Vector2i(38,35),"species":"raio","level":7,"xp":390,"intro":"Pode me chamar de Celina. Conserto armações há muitos anos, mas ainda gosto de pôr uma boa linha à prova. Aceita um treino?","tip":"Depois deste treino, siga os canos até o pátio. Descanse no banco antes de subir; dali em diante, é território do Lacertubo."}
]
static var _events: Dictionary={}
static func duel(id: String) -> Dictionary:
	for entry in DUELS:
		if entry.id==id: return entry.duplicate(true)
	return {}
static func receipt(id: String) -> String: return "park-trainer-"+id
static func completed(player: Dictionary,id: String) -> bool: return receipt(id) in player.get("completedOperations",[])
static func active(player: Dictionary) -> Dictionary:
	for partner in player.get("partners",[]):
		if partner.id==player.get("equippedPartnerId",""): return partner
	return {}
static func level(player: Dictionary) -> int: return Levels.level_for_xp(active(player).get("xp",0))
static func needs_rest(player: Dictionary) -> bool:
	var condition: Dictionary=active(player).get("condition",{})
	return float(condition.get("line",100))<=0 or float(condition.get("structure",100))<=0
static func events(area: String, model) -> Array:
	if _events.has(area): return _events[area]
	var result: Array=[]
	for entry in DUELS:
		if entry.area!=area or entry.id=="assis": continue
		var point: Vector2i=entry.point
		var best:=INF
		# Resolve to a supported, open tile without covering an existing interaction.
		for dv in range(-3,4):
			for du in range(-3,4):
				var candidate: Vector2i=entry.point+Vector2i(du,dv)
				if not model.walkable(candidate) or model.cell_at(candidate).get("ramp")!=null: continue
				var busy:=false
				for event in model.data.events:
					if Vector2(candidate).distance_to(Vector2(event.u,event.v))<1.5: busy=true;break
				if busy: continue
				var score:=Vector2(candidate-entry.point).length_squared()
				if score<best: best=score;point=candidate
		if best==INF: continue
		result.append({"id":8100+DUELS.find(entry),"type":"npc","name":entry.name,"u":point.x,"v":point.y,"props":{"acao":"parkTraining","trainer":entry.id,"npcIdentity":entry.name}})
	_events[area]=result
	return result
static func point(id: String,model) -> Vector2:
	var entry:=duel(id)
	if entry.is_empty(): return Vector2.INF
	if id=="assis":
		for event in model.data.events:
			if event.props.get("acao","")=="wildGuide": return Vector2(event.u+.5,event.v+.5)
		return Vector2(entry.point)+Vector2.ONE*.5
	for event in events(entry.area,model):
		if event.props.trainer==id: return Vector2(event.u+.5,event.v+.5)
	return Vector2.INF
static func next_here(player: Dictionary,scene: String) -> Dictionary:
	for entry in DUELS:
		if entry.scene==scene and not completed(player,entry.id): return entry
	return {}
static func objective(player: Dictionary,scene: String) -> String:
	var flags: Dictionary=player.get("flags",{})
	if needs_rest(player) and not flags.get("guardianDefeated",false): return "Seu parceiro precisa descansar. Procure um banco do parque."
	if flags.get("ninaReturned",false): return "Resgate concluído. Explore o parque ou siga sua jornada."
	if flags.get("ninaTail",false): return "Leve a rabiola para Nina. O atalho ao Jardim fica a leste do pátio." if scene=="park-veredas" else "Volte à entrada do Jardim e entregue a rabiola para Nina."
	if not flags.get("ninaAccepted",false): return "Converse com Nina no Jardim das Pipas, perto da entrada."
	if flags.get("guardianDefeated",false): return "Lacertubo vencido! Recolha a rabiola de Nina atrás dos canos, a leste."
	var next:=next_here(player,scene)
	if not next.is_empty() and level(player)<8: return "Treino opcional: converse com %s · adversário Nv. %d."%[next.name,next.level]
	return {"park-trail":"Siga pela trilha norte até a Clareira do Papel.","park-clearing":"Atravesse a Clareira e procure os rastros nas Veredas.","park-veredas":"Procure a rabiola nos canos · parceiro Nv. 8 recomendado."}.get(scene,"")
