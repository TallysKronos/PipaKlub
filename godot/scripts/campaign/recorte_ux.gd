extends Node
## Installs the approved kit on native themed controls, without changing view flows.
const Focus = preload("res://scripts/campaign/recorte_focus.gd")
var reduced_motion := false
var surface: Control

func _ready() -> void:
	surface = get_parent() as Control
	get_tree().node_added.connect(consider)
	scan(surface)

func scan(node: Node) -> void:
	consider(node)
	for child in node.get_children(): scan(child)

func consider(node: Node) -> void:
	# CanvasLayer/Node2D/SubViewport boundaries must not fall back to Godot's skin.
	if node is Control and surface.is_ancestor_of(node): node.theme = surface.theme
	if node is Control and (node is Button or node is PanelContainer or node is LineEdit or node is ItemList or node is TabBar or node is Slider):
		if surface.is_ancestor_of(node): bind.call_deferred(weakref(node))

func bind(reference: WeakRef) -> void:
	var node: Control = reference.get_ref()
	if node == null or not is_instance_valid(node) or not surface.is_ancestor_of(node) or node.has_meta("recorte_decorated"): return
	node.set_meta("recorte_decorated",true)
	var holder := Node2D.new()
	holder.name = "RecorteArt"
	node.add_child(holder)
	var decoration := Focus.new()
	decoration.target = node
	decoration.reduced_motion = reduced_motion
	holder.add_child(decoration)

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if not is_inside_tree(): return
	for item in get_tree().get_nodes_in_group("recorte_motion"):
		if surface.is_ancestor_of(item) and item.has_method("set_reduced_motion"): item.set_reduced_motion(value)
