extends RefCounted
## Seeded presentation stream. One instance per encounter/menu; never per frame.
## A shuffled bag exhausts the family before reusing a drawn source variant.
const Ink = preload("res://scripts/campaign/recorte_ink.gd")
var _rng := RandomNumberGenerator.new()
var _bags: Dictionary = {}
var _last_by_family: Dictionary = {}
var _last_global := ""

func _init(event_seed: int = 0) -> void:
	_rng.seed = event_seed

func next(family: String = "medium", outline: bool = false) -> Dictionary:
	var choices := Ink.family(family)
	if choices.is_empty(): return {}
	var bag: Array = _bags.get(family, [])
	if bag.is_empty():
		bag = choices.duplicate()
		# Fisher-Yates uses this stream, never global random state.
		for index in range(bag.size() - 1, 0, -1):
			var other := _rng.randi_range(0, index)
			var held: String = bag[index]
			bag[index] = bag[other]
			bag[other] = held
		if bag.size() > 1 and (bag.back() == _last_by_family.get(family, "") or bag.back() == _last_global):
			var held: String = bag[0]
			bag[0] = bag.back()
			bag[bag.size() - 1] = held
	var id: String = bag.pop_back()
	_bags[family] = bag
	_last_by_family[family] = id
	_last_global = id
	return {"source_id": id, "id": id + ("-outline" if outline else ""),
		"rotation": _rng.randf_range(-PI / 5, PI / 5), "flip_h": _rng.randi_range(0, 1) == 1,
		"flip_v": _rng.randi_range(0, 1) == 1}
