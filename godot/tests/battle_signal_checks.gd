extends SceneTree
const Model=preload("res://scripts/campaign/encounter_model.gd")
const Flight=preload("res://scripts/campaign/first_flight_model.gd")
const Signals=preload("res://scripts/campaign/battle_signals.gd")
const Effects=preload("res://scripts/campaign/hud_impacts.gd")
const T=preload("res://scripts/campaign/ui_tokens.gd")
const Ink=preload("res://scripts/campaign/battle_ink.gd")
var count:=0
var failures:Array=[]
func check(condition:bool,label:String) -> void:
	count+=1
	if not condition:failures.append(label);printerr("FAIL "+label)
func _initialize() -> void:
	var model:=Model.new()
	for width in [.1,.3,.5,1.0,2.0,5.0,12.0,100.0]:
		var polygon:=Ink.shape(Rect2(0,0,width,13),3)
		check(Geometry2D.triangulate_polygon(polygon).size()==6,"near-empty meter has a valid convex polygon")
	var rng:=RandomNumberGenerator.new();rng.seed=69
	for i in 1200:
		for actor:Dictionary in [model.p,model.q]:
			actor.x=rng.randf_range(55,945);actor.y=rng.randf_range(70,480)
		var actual:=model.contact(model.p,model.q)
		var hint:=model.contact_hint(model.p,model.q)
		check(actual.is_empty() or actual==hint,"hint preserves authoritative contact")
		if actual.is_empty() and not hint.is_empty():check(not hint.valid and hint.angle<.2,"closed-angle hint cannot authorize damage")
		check(Signals.state(model,model.q).contact==actual,"presentation retains contact contract")
	check(model.signature_profile(model.q)=={"radius":95.0,"windup":1.5},"boss profile")
	check(model.signature_profile(model.p)=={"radius":85.0,"windup":1.4},"player profile")
	check(Flight.new().signature_profile({})=={"radius":78.0,"windup":1.65},"lesson profile")
	for scale in [Vector2(1.18,.67),Vector2(2.46,1.2),Vector2(.9,.42)]:
		var center:=Vector2(500,250)
		var ring:=Signals.projected_ring(func(point:Vector2)->Vector2:return Vector2(50,210)+point*scale,center,95)
		for vertex in ring:
			var restored:Vector2=(vertex-Vector2(50,210))/scale
			check(absf(restored.distance_to(center)-95)<.002,"every projected vertex has exact model radius")
	var effects:=Effects.new()
	effects.protected_points.assign([Vector2(450,350),Vector2(600,350),Vector2(525,290)])
	var occupied:Array[Rect2]=[]
	var visible:=Rect2(10,210,1260,400)
	var placed:=0
	for point in [Vector2(525,350),Vector2(750,400),Vector2(200,450)]:
		for word in ["TCHAC!","CONTRA!","−42"]:
			var placement:=effects.place_label(point,word,T.lettering(),38,visible,occupied)
			if placement.is_empty():continue
			placed+=1
			check(Signals.safe_rect(placement.rect,effects.protected_points),"full text bounds clear foreign kites by 40 pixels")
			check(visible.encloses(placement.rect),"lettering stays in flight area")
			for other in occupied:check(not placement.rect.intersects(other),"lettering avoids existing higher priority text")
			occupied.append(placement.rect)
	check(placed>=3,"layout can place actual lettering, not only suppress everything")
	var before:=model.snapshot()
	effects.add({"amount":42,"point":Vector2(500,300),"critical":true})
	effects.step(1)
	check(effects.bursts.is_empty() and before==model.snapshot(),"expired visuals cannot mutate combat")
	print("BATTLE SIGNALS: ",count," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
