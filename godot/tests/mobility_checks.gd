extends SceneTree
const Model=preload("res://scripts/overworld/map_model.gd")
const Traversal=preload("res://scripts/overworld/mobility_traversal.gd")
const View=preload("res://scripts/overworld/mobility_preview.gd")
var checks:=0
var failures:Array[String]=[]
func check(ok:bool,reason:String) -> void:
	checks+=1
	if not ok:failures.append(reason);printerr("MOBILITY FAIL: "+reason)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m:=Model.new()
	m.setup(JSON.parse_string(FileAccess.get_file_as_string("res://assets/overworld/maps/encosta-dos-ventos-piloto.json")))
	var spawn:=Vector2(m.data.spawn.u+.5,m.data.spawn.v+.5)
	for link:Dictionary in m.data.mobility.links:
		var a:=Traversal.point(link.from);var b:=Traversal.point(link.to)
		check(Traversal.valid(m,link),link.id+" valid")
		if not Traversal.valid(m,link):quit(1);return
		check(not m.clear_segment(a,b),link.id+" cannot walk through cliff")
		check(not m.path_to(spawn,a).is_empty(),link.id+" takeoff reachable on foot")
		check(not m.path_to(b,spawn).is_empty(),link.id+" walking return exists")
		var t:=Traversal.new()
		check(not t.begin(m,link,spawn),"remote activation rejected")
		check(t.begin(m,link,a),"authorized start")
		check(not t.begin(m,link,a),"double activation rejected")
		t.advance(.4)
		check(t.checkpoint()==a,"air checkpoint is grounded takeoff")
		check(float(t.sample().lift)>0,"visible flight arc")
		check(t.sample(true).t<t.sample().t,"partner follows with delay")
		check(t.cancel()==a and not t.active,"interrupted trip returns to takeoff")
		check(t.begin(m,link,a),"retry after cancel")
		t.advance(9)
		check(not t.active and t.checkpoint()==b,"bounded completion at exact destination")
		check(t.sample(true).point==b,"partner completes same link")
		var bad:=link.duplicate(true);bad.to=bad.from.duplicate()
		check(not Traversal.valid(m,bad),"zero distance rejected")
		bad=link.duplicate(true);bad.to=[99,99]
		check(not Traversal.valid(m,bad),"unsupported landing rejected")
		bad=link.duplicate(true);bad.from=[NAN,1]
		check(not Traversal.valid(m,bad),"non finite rejected")
		var obstacle:=a.lerp(b,.5)
		var key:=m.key(Vector2i(floori(obstacle.x),floori(obstacle.y)))
		m.solid[key]=true
		check(not Traversal.valid(m,link),"blocking prop in flight rejected")
		m.solid.erase(key)
		if link.kind=="drop":
			bad=link.duplicate(true);bad.from=link.to;bad.to=link.from
			check(not Traversal.valid(m,bad),"drop is one way")
	var view:=View.new();root.add_child(view);view.set_physics_process(false)
	var original_scale:Vector2=view.avatar.scale
	# Actual movement, not just graph reachability: walk every ramp in both directions.
	for target in [Vector2(7.5,6.5),Vector2(24.5,12.5),spawn,Vector2(5.5,13.5),spawn]:
		check(view.walk_to(target),"actual click route "+str(target))
		for frame in 3000:
			view._physics_process(1.0/60)
			if view.path.is_empty():break
		check(view.player.distance_to(target)<.02,"actual route completes "+str(target))
	for link:Dictionary in m.data.mobility.links:
		var a:=Traversal.point(link.from)
		view.player=a;view.follower=a;view.follower_trail.clear();view._refresh_positions()
		check(view.request_link(link),"actual contextual link")
		check(not view.request_link(link),"actual duplicate blocked")
		view._physics_process(1.0/60)
		check(not view.walk_to(spawn),"click blocked during flight")
		view._physics_process(.35)
		check(view.avatar.jump_time>=0,"current Kael jump sprite active")
		view.recover()
		check(view.player==a and view.follower==a,"actual recover both actors")
		check(view.request_link(link),"actual retry")
		for frame in 120:view._physics_process(1.0/60)
		check(view.completed.has(link.id),"actual trip complete")
		check(view.player==Traversal.point(link.to) and view.follower==view.player,"both exact arrival")
		check(view.avatar.jump_time<0,"locomotion restored")
		check(view.avatar.scale==original_scale,"current Kael scale preserved")
	# A lagging companion must follow its accepted ground trail before jumping.
	var link:Dictionary=m.data.mobility.links[0]
	var a:=Traversal.point(link.from)
	view.player=a;view.follower=a-Vector2(1,0);view.follower_trail.assign([a])
	check(view.request_link(link),"lagging companion start")
	for frame in 180:view._physics_process(1.0/60)
	check(view.player==Traversal.point(link.to) and view.follower==view.player,"lagging companion safely catches up")
	for pad in [false,true]:
		view.player=a;view.follower=a;view.follower_trail.clear();view.pending.clear()
		view._physics_process(0)
		var input:InputEvent
		if pad:
			var joy:=InputEventJoypadButton.new();joy.button_index=JOY_BUTTON_A;joy.pressed=true;input=joy
		else:
			var key:=InputEventKey.new();key.physical_keycode=KEY_E;key.pressed=true;input=key
		view._unhandled_input(input)
		check(not view.pending.is_empty(),"controller A" if pad else "keyboard E")
		view.recover()
	# Keyboard/analogue use the same named movement map, and ordinary movement never jumps.
	view.player=a;view.follower=a;view.path.clear()
	Input.action_press("campaign_right")
	for frame in 30:view._physics_process(1.0/60)
	Input.action_release("campaign_right")
	check(not view.traversal.active and m.height_at(view.player)==1,"directional input respects cliff")
	var grounded:Vector2=view.player
	view.art_toggle.button_pressed=true
	check(view.player==grounded and view.follower==grounded,"geometry toggle preserves grounded location")
	check(view.art_preview,"geometry uses the same forest renderer")
	view.art_toggle.button_pressed=false
	check(view.player==grounded and view.avatar.scale==original_scale,"return to art preserves location and scale")
	view.free()
	print("MOBILITY CHECKS: "+str(checks)+" checks; "+str(failures.size())+" failures; ramp walking, jump/drop, partner, recovery, no campaign writes")
	quit(0 if failures.is_empty() else 1)
