"""Measure actual texture-core luminance and the text colors used by Mural UI.

Internal readability check, not a claim of WCAG certification. Sampling excludes
the illustrated caps; layout audits separately keep text out of those caps.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'documentation/hud-v2/pip-138'
ART = ROOT / 'godot/assets/ui/mural-v1'

def luminance(rgb):
    c = [v / 255 for v in rgb[:3]]
    c = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in c]
    return sum(a*b for a, b in zip(c, [.2126, .7152, .0722]))

def contrast(a, b):
    return (max(a, b) + .05) / (min(a, b) + .05)

def rgb(value):
    return tuple(int(value[n:n+2],16) for n in [0,2,4])

entries = []
for name, foreground in [
    ('pieces/paper.png','123442'), ('pieces/selected.png','123442'),
    ('pieces/ink.png','fff1d2'), ('pieces/board-paper.png','123442'),
    ('pieces/board-sun.png','123442'), ('pieces/board-ink.png','fff1d2'),
    ('menus-v2/cloth.png','fff1d2'), ('menus-v2/dex.png','123442'),
    ('menus-v2/evolution.png','123442'), ('menus-v2/case.png','fff1d2'),
    ('menus-v2/tag.png','123442'), ('events-v1/crossing.png','123442'),
    ('events-v1/boss-status.png','fff1d2')
]:
    im = Image.open(ART / name).convert('RGBA')
    w,h = im.size
    box = (int(w*.42), int(h*.42), int(w*.58), int(h*.58))
    pixels = [p for p in im.crop(box).getdata() if p[3] >= 250]
    assert pixels, name
    ratios = sorted(contrast(luminance(rgb(foreground)), luminance(p)) for p in pixels)
    p05, median = ratios[int(len(ratios)*.05)], ratios[len(ratios)//2]
    entries.append({'texture':name, 'foreground':'#'+foreground, 'sampleBox':box, 'samplePixels':len(pixels), 'contrastP05':round(p05,2), 'contrastMedian':round(median,2), 'target':4.5, 'pass':p05>=4.5})
for fg,bg in [('496261','fff1d2'), ('ad382c','fff1d2'), ('126c76','fff1d2'), ('77d0bc','0c2530'), ('f4e9d2','22303f'), ('d8c9ac','22303f'), ('fff1d2','0b1017')]:
    ratio = contrast(luminance(rgb(fg)),luminance(rgb(bg)))
    entries.append({'foreground':'#'+fg,'background':'#'+bg,'contrast':round(ratio,2),'target':4.5,'pass':ratio>=4.5})
OUT.mkdir(parents=True,exist_ok=True)
(OUT / 'contraste.json').write_text(json.dumps({'method':'sRGB luminance; opaque central 16% texture crop, 5th percentile; solid semantic pairs; not a screen-wide conformance claim','correctedFinding':{'component':'boss_presentation.gd','oldBackground':'events-v1/boss-warning.png','oldContrastP05':3.5,'fix':'Native cut-ink backing (#0b1017) behind title/name/subtitle; warning red remains decoration. Backing measured as a solid semantic pair.'},'checks':len(entries),'failures':[e for e in entries if not e['pass']],'entries':entries},ensure_ascii=False,indent=2),encoding='utf-8')
for entry in entries:
    print(entry.get('texture', entry['foreground']), entry.get('contrastP05',entry.get('contrast')), 'PASS' if entry['pass'] else 'FAIL')
raise SystemExit(any(not e['pass'] for e in entries))
