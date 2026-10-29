extends Node
## Presentation only. Gameplay and persistence remain authoritative.
const Observer = preload("res://scripts/campaign/sound_observer.gd")
const CATALOG := "res://assets/audio/sfx-v1/catalog.json"
var events: Dictionary = {}
var cache: Dictionary = {}
var last_play: Dictionary = {}
var last_variant: Dictionary = {}
var step_variants: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var music_id := ""
var music_fade: Tween
var observer: RefCounted
var previous_save: Dictionary = {}
var game_paused := false
var scene_paused := false
var focused := true
var dialogue_blips := false
var context_generation := 0
var connected_events: Dictionary = {}

static func cue(node: Node, id: String) -> void:
	if not node.is_inside_tree(): return
	var director := node.get_tree().get_first_node_in_group("soul_sound")
	if director != null: director.play_event(id)

func _ready() -> void:
	add_to_group("soul_sound")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if parsed is Dictionary:
		for entry: Dictionary in parsed.get("events", []): events[entry.id] = entry
	for bus: String in ["SFX", "UI", "Ambience", "Music"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	limiter.resource_name = "Soulmonsters peak safety"
	var has_limiter := false
	for index in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, index).resource_name == limiter.resource_name: has_limiter = true
	if not has_limiter: AudioServer.add_bus_effect(0, limiter)
	observer = Observer.new(self)
	get_tree().node_added.connect(_consider)
	_scan(get_parent())

func configure(levels: Dictionary, blips: bool) -> void:
	dialogue_blips = blips
	for key: String in ["master", "sfx", "ui", "ambience", "music"]:
		var index := AudioServer.get_bus_index({"master":"Master", "sfx":"SFX", "ui":"UI", "ambience":"Ambience", "music":"Music"}[key])
		if index < 0: continue
		var gain := clampf(float(levels.get(key, .8)), 0, 1)
		AudioServer.set_bus_mute(index, gain <= 0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(.0001, gain * gain)))

func play_event(id: String, gain_db: float = 0) -> void:
	if not events.has(id): return
	if id == "dialogue.blip" and not dialogue_blips: return
	var entry: Dictionary = events[id]
	var ui: bool = entry.bus == "UI"
	var persistent: bool = str(entry.category) in ["progress", "inventory"] or id == "workshop.birth"
	var pause_safe: bool = ui or persistent
	if not focused or ((game_paused or scene_paused) and not pause_safe): return
	var now := Time.get_ticks_msec()
	var cooldown := int(entry.get("cooldown_ms", 100))
	if id == "workshop.paper_cut": cooldown = 250
	if id == "progress.save_error": cooldown = 5000
	if now - int(last_play.get(id, -100000)) < cooldown: return
	# Prune in place: Array.filter() can return an untyped Array at runtime.
	for index in range(voices.size() - 1, -1, -1):
		if not is_instance_valid(voices[index]) or voices[index].is_queued_for_deletion():
			voices.remove_at(index)
	var same := 0
	for voice: AudioStreamPlayer in voices:
		if voice.get_meta("event", "") == id: same += 1
	if same >= int(entry.get("max_voices", 4)) or voices.size() >= 24: return
	var files: Array = entry.files
	if files.is_empty(): return
	var variant := randi_range(0, files.size() - 1)
	if files.size() > 1 and variant == int(last_variant.get(id, -1)): variant = (variant + 1) % files.size()
	if id.begins_with("world.step_"):
		var recent: Array = step_variants.get(id, [])
		var choices: Array[int] = []
		for index in files.size():
			if not recent.has(index): choices.append(index)
		if not choices.is_empty(): variant = choices[randi_range(0, choices.size() - 1)]
		recent.append(variant)
		if recent.size() > 2: recent.pop_front()
		step_variants[id] = recent
	var path: String = files[variant].path
	var stream := _stream(path)
	if stream == null: return
	var player := AudioStreamPlayer.new()
	player.bus = str(entry.bus)
	player.stream = stream
	player.volume_db = gain_db
	if id.begins_with("world.step_"): player.volume_db += randf_range(-1.5, 0.0)
	var pitch := float(entry.get("pitch_variation", 0))
	player.pitch_scale = randf_range(1 - pitch, 1 + pitch)
	player.set_meta("event", id)
	player.set_meta("ui", ui)
	player.set_meta("pause_safe", pause_safe)
	player.set_meta("persistent", persistent)
	add_child(player)
	voices.append(player)
	player.finished.connect(player.queue_free)
	last_play[id] = now
	last_variant[id] = variant
	connected_events[id] = true
	player.play()

func _stream(path: String) -> AudioStream:
	if cache.has(path): return cache[path]
	if not ResourceLoader.exists(path): return null
	var stream := load(path) as AudioStream
	if stream != null: cache[path] = stream
	return stream

func clear_context() -> void:
	context_generation += 1
	game_paused = false
	scene_paused = false
	if is_instance_valid(ambience): ambience.queue_free()
	ambience = null
	for voice: AudioStreamPlayer in voices:
		if is_instance_valid(voice) and not bool(voice.get_meta("ui", false)) and not bool(voice.get_meta("persistent", false)): voice.stop(); voice.queue_free()
	if observer != null: observer.clear()
	_update_pause()

func start_ambience(id: String) -> void:
	if not events.has(id): return
	if is_instance_valid(ambience): ambience.queue_free()
	var original := _stream(str(events[id].files[0].path)) as AudioStreamWAV
	if original == null: return
	var loop := original.duplicate() as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	ambience = AudioStreamPlayer.new()
	ambience.bus = "Ambience"
	ambience.stream = loop
	ambience.volume_db = -5
	add_child(ambience)
	ambience.play()
	_update_pause()

func set_game_paused(value: bool) -> void:
	game_paused = value
	_update_pause()

func play_music(id: String) -> void:
	if music_id == id and is_instance_valid(music): return
	var path := "res://assets/audio/music/opening-theme-v1/" + ("vento-menu.ogg" if id == "menu" else "vento-aventura.ogg")
	if not ResourceLoader.exists(path): return
	var stream := load(path) as AudioStreamOggVorbis
	if stream == null: return
	stream = stream.duplicate() as AudioStreamOggVorbis
	stream.loop = true
	stop_music()
	music_id = id
	music = AudioStreamPlayer.new()
	music.set_meta("soul_music", true)
	music.bus = "Music"
	music.stream = stream
	music.volume_db = -60
	add_child(music)
	music.play()
	music_fade = create_tween()
	music_fade.tween_property(music, "volume_db", -8.0 if id == "menu" else -13.0, 1.2)
	_update_pause()

func stop_music() -> void:
	music_id = ""
	if not is_instance_valid(music): return
	var outgoing := music
	music = null
	# Cancel an unfinished fade-in before starting the fade-out.
	if music_fade != null and music_fade.is_valid(): music_fade.kill()
	var fade := create_tween()
	fade.tween_property(outgoing, "volume_db", -60.0, .65)
	fade.tween_callback(outgoing.queue_free)

func _update_pause() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer and child.has_meta("soul_music"):
			child.stream_paused = game_paused or scene_paused or not focused
	if is_instance_valid(ambience): ambience.stream_paused = game_paused or scene_paused or not focused
	for voice: AudioStreamPlayer in voices:
		if is_instance_valid(voice): voice.stream_paused = not focused or ((game_paused or scene_paused) and not bool(voice.get_meta("pause_safe", false)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: focused = false; _update_pause()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN: focused = true; _update_pause()

func _scan(node: Node) -> void:
	_consider(node)
	for child in node.get_children(): _scan(child)

func _consider(node: Node) -> void:
	if node == self or is_ancestor_of(node): return
	_bind.call_deferred(weakref(node), context_generation)

func _bind(reference: WeakRef, generation: int) -> void:
	var node: Node = reference.get_ref()
	if node == null or not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): return
	if not get_parent().is_ancestor_of(node) or generation != context_generation: return
	if node is BaseButton and not node.has_meta("soul_audio_bound"):
		node.set_meta("soul_audio_bound", true)
		node.focus_entered.connect(func():
			if node.is_visible_in_tree() and not node.disabled: play_event("ui.focus"))
		node.pressed.connect(func():
			if not node.disabled: play_event("ui.cancel" if node is Button and (node.text.begins_with("Voltar") or node.text.begins_with("Sair")) else "ui.confirm"))
	if observer != null: observer.bind(node)

func _process(delta: float) -> void:
	if observer == null: return
	var local_pause: bool = observer.has_paused_scene()
	if local_pause != scene_paused: scene_paused = local_pause; _update_pause()
	if not game_paused and not scene_paused and focused: observer.step(delta)

func reset_session() -> void:
	previous_save.clear()

func partner_voice(model_id: String) -> void:
	var voice: String = {"basica":"carcara", "rabbito":"rabbito", "azulao":"azulao", "mata":"mata", "raio":"raio", "lacertubo":"lacertubo"}.get(model_id, "")
	if not voice.is_empty(): play_event("creature." + voice, -5)

func saved(snapshot: Dictionary) -> void:
	var old := previous_save
	previous_save = snapshot.duplicate(true)
	if old.is_empty() or snapshot.is_empty() or old.get("slotId") != snapshot.get("slotId"): return
	var a: Dictionary = old.player
	var b: Dictionary = snapshot.player
	if old.checkpoint.get("scene", "") != snapshot.checkpoint.get("scene", "") and old.checkpoint.get("kind") == "world" and snapshot.checkpoint.get("kind") == "world":
		play_event.call_deferred("world.door_open" if snapshot.checkpoint.scene in ["kael-home", "professor-home"] else "world.transition")
	if b.get("equippedPartnerId", "") != a.get("equippedPartnerId", ""):
		play_event("inventory.equip")
		for partner: Dictionary in b.get("partners", []):
			if partner.id == b.get("equippedPartnerId", ""): partner_voice.call_deferred(str(partner.modelId))
	if int(b.get("coins", 0)) > int(a.get("coins", 0)): play_event("progress.coins")
	var inventory_a: Dictionary = a.get("inventory", {})
	for key: String in b.get("inventory", {}):
		if int(b.inventory[key]) > int(inventory_a.get(key, 0)):
			var damaged: String = "damaged-" + key
			if int(inventory_a.get(damaged, 0)) > int(b.inventory.get(damaged, 0)): play_event("inventory.tail_restore")
			else: play_event("world.tail_pickup" if "rabiola" in key or "tail" in key else "progress.item")
	var chest_a: Array = a.get("openedChests", [])
	if b.get("openedChests", []).size() > chest_a.size(): play_event("world.chest_open")
	if b.get("sightings", []).size() > a.get("sightings", []).size(): play_event("progress.discovery")
	var partners_a: Dictionary = {}
	for partner: Dictionary in a.get("partners", []): partners_a[partner.id] = partner
	for partner: Dictionary in b.get("partners", []):
		if not partners_a.has(partner.id):
			play_event("workshop.birth")
			continue
		var before: Dictionary = partners_a[partner.id]
		if int(partner.get("xp", 0)) > int(before.get("xp", 0)):
			var rules = preload("res://scripts/campaign/encounter_model.gd")
			play_event("progress.level_up" if rules.level_for_xp(partner.xp) > rules.level_for_xp(before.get("xp", 0)) else "progress.xp")
		var condition: Dictionary = partner.get("condition", {})
		var prior: Dictionary = before.get("condition", {})
		if float(condition.get("line", 100)) > float(prior.get("line", 100)) or float(condition.get("structure", 100)) > float(prior.get("structure", 100)): play_event("inventory.repair_done")
	var flags: Dictionary = a.get("flags", {})
	for key: String in b.get("flags", {}):
		if b.flags[key] == true and not bool(flags.get(key, false)):
			play_event("progress.quest_complete" if key in ["ninaReturned", "guardianDefeated"] else "progress.objective")
	var phase_a: String = str(a.get("journey", {}).get("phase", ""))
	var phase_b: String = str(b.get("journey", {}).get("phase", ""))
	if phase_a != phase_b and phase_b == "choose": play_event("progress.tutorial")
