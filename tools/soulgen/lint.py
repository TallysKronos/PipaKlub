# Creature linter, modelled on PMD SpriteCollab's SpriteBot: rejects what breaks the rules, before any human review.
# Usage: python3 lint.py <out>/<id>.json [<out>/<id>-<variant>.json ...]   (exit 1 when anything fails)
import json, os, sys
from PIL import Image

SOULGEN_DIR = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, SOULGEN_DIR)
from procedural import REQUIRED

MAX_COLOURS = 15
SIZE_CLASS = {'small': (24, 36), 'medium': (36, 54), 'large': (50, 62)}   # idle silhouette height, px

def frames_of(img, a):
    fw, fh = a['cell']; return [img.crop((i * fw, a['y'], (i + 1) * fw, a['y'] + fh)) for i in range(a['frames'])]

def lint(path):
    errors, warns = [], []
    d = json.load(open(path)); base = os.path.dirname(path); img = Image.open(os.path.join(base, d['image'])).convert('RGBA')
    E = errors.append
    # 1. colour budget across the whole sheet, binary alpha
    alphas = set(img.getchannel('A').getdata())
    if alphas - {0, 255}: E(f'alfa semitransparente: {sorted(alphas - {0, 255})[:6]}')
    colours = {p[:3] for p in img.getdata() if p[3]}
    if len(colours) > MAX_COLOURS: E(f'{len(colours)} cores (máximo {MAX_COLOURS}): fora da paleta {sorted("#%02x%02x%02x" % c for c in colours)[:20]}')
    slots = {tuple(int(v.lstrip('#')[i:i + 2], 16) for i in (0, 2, 4)) for v in d['palette'].values()}
    if d.get('variant'):
        pass  # variant colours are checked against the base in check_variant
    elif colours - slots: E(f'cores fora dos slots da paleta: {["#%02x%02x%02x" % c for c in colours - slots]}')
    # 2. required animations at fixed indices, data consistency
    names = {a['name']: a for a in d['anims']}
    for need in REQUIRED.get(d.get('tier', 2), []):
        if need not in names: E(f'animação obrigatória ausente: {need}')
    idx = [a['index'] for a in d['anims']]
    if len(set(idx)) != len(idx): E('índices repetidos')
    H = sum(a['cell'][1] for a in d['anims'])
    if img.height != H: E(f'altura da folha {img.height} != soma das células {H}')
    for a in d['anims']:
        n = a['frames']; fw, fh = a['cell']
        if fw % 8 or fh % 8: E(f'{a["name"]}: célula {fw}x{fh} não é múltiplo de 8')
        if len(a['durations']) != n: E(f'{a["name"]}: {n} quadros e {len(a["durations"])} durações')
        for k in ('rushFrame', 'hitFrame', 'returnFrame'):
            if k in a and not 0 <= a[k] < n: E(f'{a["name"]}: {k}={a[k]} fora de 0..{n - 1}')
        if a['name'] == 'skill' and 'hitFrame' not in a: E('skill sem hitFrame (o jogo não sabe quando o golpe acerta)')
        if any(t < 1 for t in a['durations']): E(f'{a["name"]}: duração < 1 tick')
        if len(set(a['durations'])) == 1 and n > 2: warns.append(f'{a["name"]}: durações todas iguais ({a["durations"][0]}): ritmo mecânico')
        fr = frames_of(img, a)
        for i, f in enumerate(fr):
            bb = f.getchannel('A').getbbox()
            if not bb: continue
            # 3. anchors on every non-empty frame, inside the cell
            anc = a['anchors'][i]
            for k in ('head', 'center', 'ground'):
                if k not in anc: E(f'{a["name"]}[{i}]: sem âncora {k}')
                elif not (0 <= anc[k][0] < fw and 0 <= anc[k][1] < fh): E(f'{a["name"]}[{i}]: âncora {k} fora da célula {anc[k]}')
            # 4. 1px transparent margin (outline shaders and filtering need it) and 3px visual margin
            if bb[0] < 1 or bb[1] < 1 or bb[2] > fw - 1 or bb[3] > fh - 1: E(f'{a["name"]}[{i}]: encosta na borda {bb}')
            elif bb[0] < 3 or bb[1] < 3 or bb[2] > fw - 3 or bb[3] > fh - 3: warns.append(f'{a["name"]}[{i}]: margem < 3px {bb}')
        # 5. identical frames must not have different anchors (jitter)
        for i in range(n):
            for j in range(i + 1, n):
                if fr[i].tobytes() == fr[j].tobytes() and a['anchors'][i] != a['anchors'][j]: E(f'{a["name"]}: quadros {i} e {j} iguais com âncoras diferentes')
    # 6. size class: idle silhouette height
    idle = names.get('idle')
    if idle:
        bb = frames_of(img, idle)[0].getchannel('A').getbbox(); h = bb[3] - bb[1]; lo, hi = SIZE_CLASS[d['sizeClass']]
        if not lo <= h <= hi: E(f'altura do repouso {h}px fora da classe {d["sizeClass"]} ({lo}-{hi})')
    return errors, warns, len(colours)

def check_variant(base_json, var_json):
    """Recolor rules: same files and sizes, same alpha everywhere, outline (ink) untouched."""
    errs = []
    b, v = json.load(open(base_json)), json.load(open(var_json))
    bi = Image.open(os.path.join(os.path.dirname(base_json), b['image'])).convert('RGBA'); vi = Image.open(os.path.join(os.path.dirname(var_json), v['image'])).convert('RGBA')
    if bi.size != vi.size: return [f'tamanho difere {bi.size} vs {vi.size}']
    if [(a['name'], a['cell'], a['frames']) for a in b['anims']] != [(a['name'], a['cell'], a['frames']) for a in v['anims']]: errs.append('estrutura de animações difere')
    ink = tuple(int(b['palette']['ink'].lstrip('#')[i:i + 2], 16) for i in (0, 2, 4))
    alpha_diff = ink_diff = 0
    for p, q in zip(bi.getdata(), vi.getdata()):
        if (p[3] == 0) != (q[3] == 0): alpha_diff += 1
        elif p[3] and p[:3] == ink and q[:3] != ink: ink_diff += 1
    if alpha_diff: errs.append(f'{alpha_diff} pixels mudaram de transparência')
    if ink_diff: errs.append(f'{ink_diff} pixels de contorno mudaram de cor')
    return errs

if __name__ == '__main__':
    files = sys.argv[1:]; failed = False
    for f in files:
        e, w, n = lint(f); name = os.path.basename(f)
        print(f'{"✅" if not e else "❌"} {name}: {n} cores, {len(e)} erros, {len(w)} avisos')
        for x in e: print('   ERRO ', x)
        for x in w: print('   aviso', x)
        failed |= bool(e)
    base = [f for f in files if '-' not in os.path.basename(f).replace('.json', '')]
    for f in files:
        if f not in base and base:
            e = check_variant(base[0], f); print(f'{"✅" if not e else "❌"} variante {os.path.basename(f)} vs base: {e or "contorno e alfa preservados"}'); failed |= bool(e)
    sys.exit(1 if failed else 0)
