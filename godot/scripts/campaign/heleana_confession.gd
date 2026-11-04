extends RefCounted
const City=preload("res://scripts/campaign/neighborhood_checkpoint.gd")
const AT=Vector2(1040,912)
const ENTRY=Vector2(432,1008)
var session:Node
func _init(active:Node)->void:session=active
static func available(p:Dictionary)->bool:
	return refused(p) or p.get("partners",[]).any(func(partner):return partner.get("modelId","")=="retalho-original" and partner.get("id","")==p.get("equippedPartnerId",""))
static func refused(p:Dictionary)->bool:
	return p.get("flags",{}).get("retalhoRecusadoKael",false) and not p.get("flags",{}).get("retalhoAcolhido",false) and not p.get("flags",{}).get("retalhoAceitoKael",false)
static func done(p:Dictionary)->bool:return p.get("flags",{}).get("heleanaConfessouRabiola",false)
static func recognition(p:Dictionary)->bool:return done(p) and not p.get("flags",{}).get("heleanaReconheceuRetalho",false)
static func nodes(p:Dictionary)->Array:
	if done(p):
		if p.get("flags",{}).get("heleanaLacoKael",false):
			return [["Heleana","Esse nó... Eu o reconheceria em qualquer lugar."],["Heleana","Heleana começa a chorar. — Ela era minha parceira. Soltei sua linha nas Ruínas para que ninguém a usasse para chegar ao Elo."],["Kael","Retalho escolheu ficar comigo. Eu aceitei, e demos um nome ao nosso novo laço."],["Heleana","Retalho olha para Heleana sem reconhecê-la. — O laço de vocês transcreveu o anterior. As lembranças dela comigo não vão voltar."],["Heleana","Eu me lembro por nós duas. Cuide bem dela, Kael. Ela escolheu você."]]
		return [["Heleana","Esse nó... É você? Heleana se emociona e se ajoelha diante de Retalho."],["Kael","Ela estende a mão devagar e toca a rabiola. Retalho fica imóvel por um instante."],["Heleana","Sou eu. Eu soltei sua linha nas Ruínas para que ninguém a usasse para chegar ao Elo."],["Kael","As lembranças da expedição e de Heleana voltam. Retalho se aproxima e encosta a rabiola na mão da antiga parceira."],["Heleana","Heleana chora ao acolhê-la. — Estamos juntas outra vez. Desta vez, não vou deixar você sozinha."]]
	if refused(p):
		return [["Kael","Um grunhido vem do lado de fora da casa. — Mãe, você ouviu?"],["Heleana","Ouvi. Vamos ver o que foi."],["Kael","Kael e Heleana saem. Retalho está junto à entrada, escondida até aquele instante."],["Kael","Você seguiu o Tyler até aqui? Mesmo depois de eu não ter aceitado seu convite..."],["Heleana","Retalho não responde. Alguma coisa a trouxe até aquela casa. Ao vê-la, Heleana leva a mão à boca."],["Heleana","Eu conheço esse nó. Era a minha parceira, quando eu pesquisava as Ruínas com o Assis."],["Heleana","No seu aniversário, eu disse que aquela rabiola era minha desde criança. Não era verdade. Eu a encontrei nas Ruínas do Primeiro Vento."],["Heleana","Eu a levei embora porque não queria que alguém fosse criado só para cumprir uma ordem. E deixei minha parceira lá para protegê-la..."]]
	return [["Heleana","Kael... esse Soulmonster que veio com você. Eu conheço esse nó. Preciso contar uma coisa."],["Heleana","No seu aniversário, eu disse que aquela rabiola era minha desde criança. Não era verdade."],["Kael","Então de onde ela veio?"],["Heleana","Das Ruínas do Primeiro Vento. Eu era pesquisadora. O Assis e eu estivemos lá."],["Kael","Então aquela foto era de vocês na expedição?" if p.get("flags",{}).get("fotoExpedicaoLida",false) else "Você nunca me contou que pesquisava as Ruínas."],["Heleana","Eu levei a rabiola embora porque não queria que alguém fosse criado só para cumprir uma ordem."],["Kael","O Rabbito está aqui. E escolhe ficar comigo."],["Heleana","Eu sei. O que eu não podia era continuar escondendo isso de você."]]
static func index(p:Dictionary)->int:
	var prefix:="heleanaReconhecimento" if done(p) else "heleanaConfissao"
	for i in nodes(p).size():
		if not p.get("flags",{}).get(prefix+str(i),false):return i
	return nodes(p).size()
static func outside(p:Dictionary)->bool:
	return refused(p) and p.get("flags",{}).get("heleanaConfissao1",false)
func near(point:Vector2)->bool:
	var s:Dictionary=session.snapshot()
	if not available(s.player) or not point.is_finite() or s.checkpoint.get("kind")!="world":return false
	if outside(s.player):return s.checkpoint.get("scene")=="quintal" and point.distance_to(City.HOME)<=2.0
	if s.checkpoint.get("scene")!="kael-home":return false
	return refused(s.player) or point.distance_to(AT)<=110
func advance(expected:int,point:Vector2)->Dictionary:
	if not near(point):return {"status":"wrong_step"}
	var s:Dictionary=session.snapshot()
	if done(s.player) and not recognition(s.player):return {"status":"already_applied"}
	var step:=index(s.player)
	if expected!=step:return {"status":"wrong_step"}
	var branch:=done(s.player)
	var key:="heleanaReconhecimento" if branch else "heleanaConfissao"
	s.player.flags[key+str(step)]=true
	if not branch and step==0:s.player.flags.heleanaLacoKael=not refused(s.player)
	if step+1==nodes(s.player).size():s.player.flags["heleanaReconheceuRetalho" if branch else "heleanaConfessouRabiola"]=true
	if branch and step+1==nodes(s.player).size() and not s.player.flags.get("heleanaLacoKael",false):s.player.flags.retalhoParceiraHeleana=true
	if not branch and step==1 and refused(s.player):s.checkpoint=City.make(City.HOME,s.player)
	return session.commit_operation("heleana-"+("recognition-" if branch else "confession-")+str(step),s.checkpoint,s.player)

# Temporary creature voice, routed through the player's SFX volume setting.
static func play_grunt(parent:Node)->void:
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var data:=PackedByteArray();data.resize(19845*2)
	for i in 19845:
		var t:=float(i)/22050.0
		var envelope:=sin(PI*t/.9)*minf(1.0,t/.05)
		var phase:=TAU*(100.0*t-24.0*t*t)
		var sample:=int((sin(phase)+.3*sin(phase*2.03)+.12*sin(phase*5.1))*envelope*6500.0)
		data.encode_s16(i*2,sample)
	stream.data=data
	var voice:=AudioStreamPlayer.new();voice.stream=stream;voice.bus="SFX"
	parent.add_child(voice);voice.finished.connect(voice.queue_free);voice.play()
