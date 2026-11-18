def ease_at(t, points):
 for (a,x),(b,y) in zip(points,points[1:]):
  if t<=b:
   k=min(1,max(0,(t-a)/(b-a)));return x+(y-x)*k*k*(3-2*k)
 return points[-1][1]
def pose_kirin(clip,t):
 # Torso breathes independently of the four supporting leg chains.
 for p in rig.pose.bones:p.rotation_quaternion=Quaternion()
 idle=clip=='Idle'
 phase=t*tau/5
 def sway(offset):
  return sin(phase-offset)-sin(-offset)
 breath=.68*sin(phase)+.21*sin(2*phase)
 lift=0 if idle else ease_at(t,[(0,0),(.68,-.26),(1.06,-.34),(1.82,1),(2.16,.89),(3.85,.91),(4.35,.99),(5.38,.08),(6,0)])
 tension=0 if idle else ease_at(t,[(0,0),(.85,.52),(1.8,1),(3.8,.8),(5.2,.32),(6,0)])
 breathe=breath if idle else tension
 rig.pose.bones['breath'].scale=(1+.029*breathe,1+.012*breathe,1+.036*breathe)
 def orient(b,pitch=0,yaw=0,roll=0):
  local=arm.bones[b].matrix_local.to_quaternion()
  q=Quaternion((0,0,1),yaw)@Quaternion((0,1,0),pitch)@Quaternion((1,0,0),roll)
  rig.pose.bones[b].rotation_quaternion=local.inverted()@q@local
 glance=.052*(1-cos(phase)) if idle else ease_at(t,[(0,0),(1,0),(2.35,-.18),(3,-.23),(4.4,.15),(5.4,.025),(6,0)])
 orient('neck',.042*breath if idle else .39*lift,.33*glance)
 orient('head',.021*sway(.45) if idle else .15*lift,glance,.016*sin(phase*2) if idle else .039*lift)
 orient('jaw',-.012*max(breath,0) if idle else -.086*tension)
 orient('sail',.018*sway(.38) if idle else .085*lift,0,.045*sin(phase) if idle else .077*tension*sin(t*3.4))
 for i,tag in enumerate(('L','R')):
  lag=.18+i*.12
  orient('mane_'+tag,.065*sway(lag) if idle else -.14*lift+.085*tension*sin(5*t-lag),(.025*sway(lag) if idle else .11*tension)*(-1 if i else 1))
 for j in range(3):
  lag=j*.53+.12
  sweep=.11*sway(lag) if idle else tension*((.17+.05*j)*sin(2.55*t-lag)-.11)
  orient('tail'+str(j+1),.045*sway(lag+.5) if idle else -.18*lift+.046*tension*sin(3.6*t-lag),sweep)
