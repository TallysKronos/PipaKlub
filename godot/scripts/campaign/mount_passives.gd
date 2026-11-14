extends RefCounted
## Passivas de montaria por família (raiz da evolução, evolution.gd → root).
## terrestre: o Dóber leva o Kael pelas ruas (mount_quest.gd).
## aquatica: a Capiboia nada com o Kael no fundo do mar; sem ela não dá para mergulhar no
## Abismo de Kronasta (cenas "abismo-*").
const Evolution = preload("res://scripts/campaign/evolution.gd")
const PASSIVES := {"doberman-c": ["terrestre"], "capivara-boia": ["aquatica"]}
const BOIA_ORIGIN := "marisol-boia-v1"

static func passives(model_id: String) -> Array:
	return PASSIVES.get(Evolution.root(model_id), [])

static func healthy(partner: Dictionary) -> bool:
	var condition: Dictionary = partner.get("condition", {})
	return float(condition.get("line", 100)) > 0 and float(condition.get("structure", 100)) > 0

## Primeiro parceiro com montaria aquática em condição de nadar (vazio se não houver).
static func aquatic_partner(player: Dictionary) -> Dictionary:
	for partner in player.get("partners", []):
		if "aquatica" in passives(str(partner.get("modelId", ""))) and healthy(partner): return partner
	return {}

static func has_aquatic(player: Dictionary) -> bool:
	for partner in player.get("partners", []):
		if "aquatica" in passives(str(partner.get("modelId", ""))): return true
	return false

static func can_dive(player: Dictionary) -> bool:
	return not aquatic_partner(player).is_empty()

## Quem já fez a aula de remo com a Marisol (flag canRemar) recebe a Boia na primeira tentativa
## de mergulho (front_end.gd, _travel_kronasta). A entrega passa pelo fluxo de recompensas
## de parceiro da sessão, por isso fica fora da viagem de remo. Devolve true se entregou.
static func grant_boia(player: Dictionary) -> bool:
	if has_aquatic(player) or not player.get("flags", {}).get("canRemar", false): return false
	if player.get("partners", []).size() >= 30: return false
	# A Boia chega dois níveis abaixo do parceiro ativo (nunca abaixo do Nv.10).
	var Levels = preload("res://scripts/campaign/partner_levels.gd")
	var level := 10
	for partner in player.get("partners", []):
		if partner.get("id", "") == player.get("equippedPartnerId", ""): level = maxi(10, Levels.level_for_xp(partner.get("xp", 0)) - 2)
	player.partners.append({"id": preload("res://scripts/campaign/state.gd").new_id(), "modelId": "capivara-boia", "personalName": "Boia", "xp": Levels.xp_for_level(level), "craftBonus": 0, "condition": {"line": 100, "structure": 100}, "origin": BOIA_ORIGIN})
	preload("res://scripts/campaign/progression.gd").acquire(player, "capivara-boia")
	return true
