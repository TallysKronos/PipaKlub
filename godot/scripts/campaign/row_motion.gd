extends RefCounted
const DURATION:=5.0
var token:String
var link_id:String
var progress:=0.0
var energy:=100.0
var complete:=false
var paddled:=0.0
func _init(id:String,link:String)->void:token=id;link_id=link
func tick(delta:float,paddle:bool)->void:
 if complete or not is_finite(delta) or delta<=0:return
 var dt:=minf(delta,.05)
 if paddle and energy>0:
  paddled+=dt;progress=minf(1,progress+dt/DURATION);energy=maxf(0,energy-dt*12)
 else:energy=minf(100,energy+dt*35)
 complete=progress>=1 and paddled>=DURATION-.01
