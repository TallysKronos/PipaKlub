extends RefCounted
## Evolução dos Soulmonsters (08/11/2026). Tabela em assets/campaign/evolutions.json, gerada por
## tools/package-evolucoes.py a partir do plano de povoamento.
##
## Regra: cada forma tem um estágio (criança, jovem, adulto) e um nível. Quando o parceiro
## alcança o nível de uma forma seguinte da sua família, a evolução fica disponível; o jogador
## confirma e, se houver mais de um ramo, escolhe. Evoluir troca a espécie (modelId) e a arte,
## mantém id, XP, nível, condição e o nome dado pelo jogador, e soma o bônus do estágio aos
## atributos de batalha. Não há volta.
const Progression = preload("res://scripts/campaign/progression.gd")
const Levels = preload("res://scripts/campaign/partner_levels.gd")

static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/campaign/evolutions.json"))
	return _data

static func form(model_id: String) -> Dictionary:
	return data().forms.get(model_id, {})

static func display_name(model_id: String, fallback: String = "") -> String:
	return str(form(model_id).get("name", fallback))

## Família de origem (o modelId da oficina): basica, mata, raio, azulao, rabbito, doberman-c.
static func root(model_id: String) -> String:
	return str(form(model_id).get("root", model_id))

## Bônus de atributos do estágio (%), somado ao bônus de criação.
static func bonus(model_id: String) -> float:
	return float(form(model_id).get("bonus", 0))

static func signature(model_id: String) -> String:
	return str(form(model_id).get("signature", {"rabbito": "Pulo do Elo", "rai": "Especial"}.get(root(model_id), "")))

## Id da arte de batalha (content.combat) de uma forma evoluída; `fallback` para as outras.
static func art(model_id: String, fallback: String = "rabbito") -> String:
	var entry := form(model_id)
	return model_id if not entry.is_empty() and entry.has("source") else fallback

## Formas seguintes da família do parceiro (sem olhar o nível).
static func next_forms(model_id: String) -> Array:
	var out: Array = []
	for id in data().forms:
		if model_id in data().forms[id].get("from", []): out.append(id)
	return out

## Formas para as quais o parceiro pode evoluir agora (nível alcançado).
static func options(partner: Dictionary) -> Array:
	var level := Levels.level_for_xp(partner.get("xp", 0))
	return next_forms(str(partner.get("modelId", ""))).filter(func(id): return level >= int(form(id).level))

static func can_evolve(partner: Dictionary) -> bool:
	return not options(partner).is_empty()

## Nível da próxima evolução (0 se não houver).
static func next_level(model_id: String) -> int:
	var best := 0
	for id in next_forms(model_id):
		var level := int(form(id).level)
		if best == 0 or level < best: best = level
	return best

## Parceiros da equipe com evolução disponível (ids).
static func requirements(player: Dictionary, partner: Dictionary, form_id: String) -> Array[Dictionary]:
	var entry := form(form_id)
	var level := Levels.level_for_xp(partner.get("xp", 0))
	var minimum := int(entry.get("level", 1))
	var rows: Array[Dictionary] = [{"text": "Nível %d / %d" % [level, minimum], "met": level >= minimum}]
	var totals: Dictionary = {}
	var labels: Dictionary = {}
	for item: Dictionary in entry.get("items", []):
		var id := str(item.id)
		totals[id] = int(totals.get(id, 0)) + maxi(1, int(item.get("quantity", 1)))
		labels[id] = str(item.get("label", id.replace("-", " ").capitalize()))
	for id: String in totals:
		var stock := int(player.get("inventory", {}).get(id, 0))
		rows.append({"text": "%s (%d/%d)" % [labels[id], stock, totals[id]], "met": stock >= totals[id]})
	for flag: String in entry.get("flags", []):
		rows.append({"text": str(entry.get("flagLabels", {}).get(flag, flag)), "met": player.get("flags", {}).get(flag, false) == true})
	return rows

static func ready_partners(player: Dictionary) -> Array:
	var ready: Array = []
	for partner: Dictionary in player.get("partners", []):
		for id: String in options(partner):
			if requirements(player, partner, id).all(func(row): return row.met):
				ready.append(partner.id)
				break
	return ready

## Evolui o parceiro `partner_id` para `form_id`. Devolve {"status", "player", "from", "to"}.
## Só altera a cópia de `player`; quem chama grava a operação.
static func evolve(player: Dictionary, partner_id: String, form_id: String) -> Dictionary:
	var target: Dictionary = {}
	for partner in player.get("partners", []):
		if partner.get("id", "") == partner_id: target = partner
	if target.is_empty(): return {"status": "wrong_step"}
	if form_id not in options(target): return {"status": "not_ready"}
	if not requirements(player, target, form_id).all(func(row): return row.met):
		return {"status": "missing_requirements"}
	for item: Dictionary in form(form_id).get("items", []):
		if not item.get("consume", false): continue
		var remaining := int(player.inventory[item.id]) - maxi(1, int(item.get("quantity", 1)))
		if remaining == 0: player.inventory.erase(item.id)
		else: player.inventory[item.id] = remaining
	var before := str(target.modelId)
	var old_name := display_name(before, str(target.get("personalName", "")))
	target.modelId = form_id
	var history: Array = target.get("evolvedFrom", [])
	history.append(before)
	target.evolvedFrom = history
	# Nome dado pelo jogador fica; o nome da espécie acompanha a forma.
	if str(target.get("personalName", "")) in ["", old_name]:
		target.personalName = display_name(form_id)
	Progression.discover(player, form_id)
	Progression.acquire(player, form_id)
	return {"status": "ok", "player": player, "from": before, "to": form_id, "partner": target}
