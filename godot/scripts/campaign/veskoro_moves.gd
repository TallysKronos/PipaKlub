extends RefCounted
## Locked target, readable warning, one impact. Conditions expire at round end.
const WARN:=1.35
const ACTIVE:=.55
const RECOVER:=1.8
const RADIUS:=70.0
const LANE:=32.0
static func fresh()->Dictionary:
	return {"version":1,"phase":"rest","elapsed":0.0,"cooldown":3.0,"cycle":0,"aimX":500.0,"aimY":290.0,"originX":828.0,"originY":290.0,"hit":false,"poisonTime":0.0,"poisonTick":0.0}
static func valid(v:Variant)->bool:
	if not v is Dictionary or v.size()!=12 or v.get("version")!=1 or v.get("phase") not in ["rest","warn","active","recover"] or not v.get("hit") is bool:return false
	if v.phase=="warn" and v.hit:return false
	if v.phase in ["active","recover"] and not v.hit:return false
	for k:String in ["elapsed","cooldown","cycle","aimX","aimY","originX","originY","poisonTime","poisonTick"]:
		if not (v.get(k) is float or v.get(k) is int) or not is_finite(float(v[k])):return false
	return v.elapsed>=0 and v.elapsed<=RECOVER+.05 and v.cooldown>=0 and v.cooldown<=3 and v.cycle>=0 and v.cycle<=1000000 and floorf(v.cycle)==v.cycle and v.aimX>=55 and v.aimX<=945 and v.aimY>=70 and v.aimY<=480 and v.originX>=55 and v.originX<=945 and v.originY>=70 and v.originY<=480 and v.poisonTime>=0 and v.poisonTime<=3 and v.poisonTick>=0 and v.poisonTick<1.05
static func hits(v:Dictionary,point:Vector2)->bool:
	var aim:=Vector2(v.aimX,v.aimY)
	if int(v.cycle)%2==0:return point.distance_to(aim)<=RADIUS
	var start:=Vector2(v.originX,v.originY)
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,start,aim))<=LANE
static func tick(model:RefCounted,v:Dictionary,dt:float)->void:
	if v.poisonTime>0:
		var poison_dt:=minf(dt,v.poisonTime)
		v.poisonTime=maxf(0,v.poisonTime-dt);v.poisonTick+=poison_dt
		if v.poisonTick>=1-.000001:
			v.poisonTick=maxf(0,v.poisonTick-1)
			model._apply_hit({"target":model.p,"body":false,"damage":2.0,"color":3})
		if v.poisonTime<=0:v.poisonTick=0.0
	if v.phase=="rest":
		v.cooldown=maxf(0,v.cooldown-dt)
		if v.cooldown<=0:
			v.phase="warn";v.elapsed=0.0;v.cycle+=1;v.hit=false
			v.aimX=clampf(model.p.x,55,945);v.aimY=clampf(model.p.y,70,480)
			v.originX=clampf(model.q.x,55,945);v.originY=clampf(model.q.y,70,480)
		return
	v.elapsed+=dt
	if v.phase=="warn" and v.elapsed>=WARN:
		v.phase="active";v.elapsed=0.0
		if hits(v,Vector2(model.p.x,model.p.y)):
			if model.p.guardTime>0 or model.p.evade>0:
				var guarding:bool=model.p.guardTime>0
				if guarding:model.p.blocks+=1
				else:model.p.counter=2.0
				model.combat_feedback.emit({"kind":"block" if guarding else "evade","amount":0,"point":Vector2(model.p.x,model.p.y),"player":true})
			else:
				model._apply_hit({"target":model.p,"body":false,"damage":8.0,"color":3})
				v.poisonTime=3.0;v.poisonTick=0.0
		v.hit=true
	elif v.phase=="active" and v.elapsed>=ACTIVE:v.phase="recover";v.elapsed=0.0
	elif v.phase=="recover" and v.elapsed>=RECOVER:v.phase="rest";v.elapsed=0.0;v.cooldown=3.0
