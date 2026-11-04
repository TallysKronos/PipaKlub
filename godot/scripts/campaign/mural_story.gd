extends RefCounted
const Rules=preload("res://scripts/campaign/district_rules.gd")
const CP=preload("res://scripts/campaign/park_checkpoint.gd")
const FLAGS=["muralChegadaLida","muralOfertaLida","muralPrimeiroLaco"]
const AT=Vector2(20.5,10.5)
const REST=Vector2(15.5,29.5)
var session:Node
func _init(active:Node)->void:session=active
static func available(player:Dictionary)->bool:
	return Rules.completed(player,"feira") and player.get("flags",{}).get("feiraApitoVerdadeiro",false) and player.get("inventory",{}).get("apito-de-vento",0)>=1
static func step(player:Dictionary)->int:
	for i in FLAGS.size():
		if not player.get("flags",{}).get(FLAGS[i],false):return i
	return FLAGS.size()
static func nodes()->Array:
	return [
		{"title":"O visitante e o ovo","text":"Tyler: Olha a primeira marca. Alguém vem do céu, trazendo um ovo de luz.\n\nKael: Parece uma história desenhada na pedra.\n\nTyler: Uma história que alguém quis guardar por muito tempo."},
		{"title":"A ponta da linha","text":"Tyler: Aqui, a criatura oferece a ponta da linha. É ela quem escolhe se aproximar.\n\nKael: Na última marca alguém tenta puxar… mas o desenho muda.\n\nTyler: Quem estica a linha à força não forma laço."},
		{"title":"A Rabiola Antiga","text":"Kael: A rabiola… está brilhando!\n\nTyler: O ovo do mural respondeu a ela. Você sentiu também, Rabbito?\n\nKael: Eu desenhei o Rabbito sem saber como ele poderia ganhar vida. E essa rabiola veio parar nas minhas mãos…\n\nTyler: Vamos guardar o que vimos. Ainda há muita coisa que essas marcas não contam."}
	]
func near(scene:String,target:Vector2,point:Vector2)->bool:
	var saved:Dictionary=session.snapshot()
	if saved.checkpoint.kind!="world" or saved.checkpoint.get("scene")!=scene or saved.checkpoint.get("space")!=CP.SPACE or not available(saved.player) or not point.is_finite():return false
	var map=CP.model_for(scene)
	return map.point_walkable(point) and point.distance_to(target)<=1.8 and absf(map.height_at(point)-map.height_at(target))<.25
func advance(index:int,point:Vector2)->Dictionary:
	if not near("caverna-mural-c",AT,point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if step(saved.player)==FLAGS.size():return {"status":"already_applied"}
	if index!=step(saved.player):return {"status":"wrong_step"}
	saved.player.flags[FLAGS[index]]=true
	return session.commit_operation("mural-leitura-"+str(index)+"-v1",CP.make("caverna-mural-c",point,CP.SPACE),saved.player)
func rest(point:Vector2)->Dictionary:
	if not near("caverna-mural-b",REST,point):return {"status":"wrong_step"}
	var saved:Dictionary=session.snapshot()
	if saved.player.partners.all(func(p):return p.get("condition",{}).get("line",100)>=100 and p.get("condition",{}).get("structure",100)>=100):return {"status":"already_applied"}
	for partner:Dictionary in saved.player.partners:partner.condition={"line":100,"structure":100}
	return session.checkpoint(saved.checkpoint,saved.player)
