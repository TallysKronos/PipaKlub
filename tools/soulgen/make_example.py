# Builds a test key pose in the exact format expected from the artist (art/soulgen/keys/<id>/), by splitting
# the procedural v8 Carcará into layers. It is a placeholder to exercise keyanim.py and the linter before
# the hand-drawn key arrives; it is not final art.
# Usage: python3 tools/soulgen/make_example.py tools/soulgen/species/carcara8.json art/soulgen/keys/_exemplo-carcara
import json, math, os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import procedural3d as p3

def main(species, out):
    sp = json.load(open(species)); os.makedirs(out, exist_ok=True)
    g = 96; sp['grid'] = g; sp['ground_y'] = (g - sp['cell']) // 2 + sp['cell'] - 2
    P, slots = p3.make_palette(sp)
    C = (g / 2, (g - sp['cell']) / 2 + sp['cell'] * sp.get('center_y', .42))
    pose = dict(center=C, tilt=0, wing=(0, 0), tail_phase=0, expr='normal')
    cam = p3.Cam(C, 0, sp['yaw'], sp['pitch'])
    near = 'right' if cam.rot((1, 0, 0))[2] > 0 else 'left'; far = 'left' if near == 'right' else 'right'
    body, anchors = p3.body_layer(sp, cam, P, pose)
    body.save(f'{out}/body.png')
    p3.wing_layer(sp, cam, P, pose, near).save(f'{out}/wing-near.png')
    p3.wing_layer(sp, cam, P, pose, far).save(f'{out}/wing-far.png')
    p3.tail_layer(sp, cam, P, pose, anchors).save(f'{out}/tail.png')
    # faces: only the pixels that change from the neutral body (an overlay the animator swaps)
    faces = {}
    for expr in ('normal', 'blink', 'fierce', 'hurt', 'happy'):
        b2, _ = p3.body_layer(sp, cam, P, {**pose, 'expr': expr}); ov = Image.new('RGBA', b2.size, (0, 0, 0, 0)); a, b, o = body.load(), b2.load(), ov.load()
        for y in range(g):
            for x in range(g):
                if b[x, y] != a[x, y] or (expr == 'normal' and False): o[x, y] = b[x, y]
        name = f'face-{expr}.png'; ov.save(f'{out}/{name}'); faces[expr] = name
    b = sp['body']; sh = lambda s: cam.proj((s * (b['half'] - 2.5), -b['up'] * .12, 0))
    pivot = lambda s: [round(sh(s)[0]), round(sh(s)[1])]
    s_near, s_far = (1, -1) if near == 'right' else (-1, 1)
    vslots = p3.make_palette({**sp, 'colors': {**sp['colors'], **sp['variants']['noturno']}})[1]
    key = {
        'id': 'carcara', 'name': 'Carcará', 'placeholder': True, 'cell': sp['cell'], 'sizeClass': sp['sizeClass'], 'tier': 2, 'shadowSize': 1,
        'palette': list(slots.values()),
        'variants': {'noturno': list(vslots.values())},
        'parts': {'body': {'file': 'body.png'},
                  'wing_near': {'file': 'wing-near.png', 'pivot': pivot(s_near), 'side': near},
                  'wing_far': {'file': 'wing-far.png', 'pivot': pivot(s_far), 'side': far},
                  'tail': {'file': 'tail.png', 'pivot': [round(anchors['bottom'][0]), round(anchors['bottom'][1])]}},
        'faces': faces,
        'anchors': {'head': [round(v) for v in anchors['face']], 'center': [round(C[0]), round(C[1])], 'effect': [round(v) for v in anchors['face']],
                    'tail': [round(v) for v in anchors['bottom']]},
        'fx': {'hot': slots['s6'], 'mid': slots['s13'], 'dim': slots['s11'], 'edge': slots['s2']},
    }
    json.dump(key, open(f'{out}/key.json', 'w'), ensure_ascii=False, indent=1); print('ok', out)

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
