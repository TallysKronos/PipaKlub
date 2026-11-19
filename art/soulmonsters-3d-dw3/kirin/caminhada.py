"""Four-beat lateral walk. Forward is -X; distance per cycle is 1.44 units."""
from math import atan2, acos, hypot

def walk_pose(t):
    cycle = t / 1.6
    phase = tau * cycle
    drop = -.18 + .037 * cos(2 * phase - .4)
    root = rig.pose.bones['root']
    root.location = arm.bones['root'].matrix_local.to_quaternion().inverted() @ Vector((0, 0, drop))

    def rest(name):
        return arm.bones[name].tail_local - arm.bones[name].head_local

    def angle(v):
        return atan2(-v.x, -v.z)

    def bend(name, relative):
        rot(name, (0, 1, 0), relative)

    for fore, side, offset in [(False,'L',0),(True,'L',.25),(False,'R',.5),(True,'R',.75)]:
        p = (cycle - offset) % 1
        stance = .64
        stride = 1.44
        dx = stride * (p - stance / 2)
        lift = 0
        if p > stance:
            u = (p - stance) / (1 - stance)
            dx -= stride * u*u*(3-2*u)
            lift = (.27 if fore else .32) * sin(pi*u)**2
        names = [n+'_'+side for n in (('front','fore') if fore else ('back','hock','heel'))]
        a,b = [rest(n) for n in names[:2]]
        target = a+b+Vector((dx,0,lift-drop))
        heel_angle = 0
        if not fore:
            heel = rest(names[2])
            heel_angle = -.22*sin(phase-tau*offset) - lift*.42
            target += heel - Quaternion((0,1,0),heel_angle) @ heel
        d = hypot(target.x,target.z)
        limit = (a.length*a.length + d*d - b.length*b.length)/(2*a.length*d)
        if abs(limit)>1.00001:
            raise ValueError(f'Unreachable step {names} at {t}')
        first = angle(target) + (-1 if fore else 1)*acos(max(-1,min(1,limit)))
        upper = first-angle(a)
        lower = angle(target - Quaternion((0,1,0),upper) @ a)-angle(b)
        bend(names[0],upper)
        bend(names[1],lower-upper)
        if not fore:
            bend(names[2],heel_angle-lower)
        bend(('toe_front_' if fore else 'toe_back_')+side, .48*lift-(lower if fore else heel_angle))
    bend('neck',.045*sin(2*phase+.6))
    bend('head',-.028*sin(2*phase+.15))
    bend('sail',.022*sin(2*phase-.4))
    for i in range(3):
        rot('tail'+str(i+1),(0,0,1),(.056+.023*i)*sin(phase-.53*i))
    for side in 'LR':
        bend('mane_'+side,.042*sin(2*phase-.7))
