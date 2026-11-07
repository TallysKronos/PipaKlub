extends RefCounted

static func free_view(tree: SceneTree, view: Control) -> bool:
	var streams: Array[WeakRef] = []
	for child in view.sound.get_children():
		if child is AudioStreamPlayer and child.stream != null:
			streams.append(weakref(child.stream))
	view.free()
	await tree.process_frame
	await tree.process_frame
	var deadline := Time.get_ticks_msec() + 2000
	while streams.any(func(ref: WeakRef): return ref.get_ref() != null):
		if Time.get_ticks_msec() >= deadline: return false
		await tree.create_timer(0.02).timeout
	return true
