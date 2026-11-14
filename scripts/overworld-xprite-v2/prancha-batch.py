"""One configurable Aseprite importer for direct ImageGen animation sheets.

Python inspects geometry and prepares explicit crop/scale metadata. Pixel
normalization, palette alignment and exporting masters happen in Aseprite.
"""
from pathlib import Path
from PIL import Image
import argparse
import hashlib
import json
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[2]
ASEPRITE = Path(r'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe')
LUA = ROOT / 'scripts/overworld-xprite-v2/prancha-import.lua'


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def inspect_sheet(model, action, view, previous):
    folder = ROOT / model['folder']
    override = model.get('sheet_overrides', {}).get(f'{action}-{view}')
    path = ROOT / override if override else folder / f'gerado-{action}-{view}.png'
    if not path.exists():
        return None
    old = next((s for s in previous.get('sheets', []) if s['action'] == action and s['view'] == view), None)
    if old and old.get('source_sha256') == digest(path):
        return old
    raw = Image.open(path).convert('RGBA')
    columns, rows = (3, 2) if action == 'walk' else (2, 2)
    if raw.width % columns or raw.height % rows:
        raise ValueError(f'{model["id"]}/{action}/{view}: nonuniform grid {raw.size}')
    width, height = raw.width // columns, raw.height // rows
    boxes = []
    for n in range(columns * rows):
        cell = raw.crop(((n % columns) * width, (n // columns) * height,
                         (n % columns + 1) * width, (n // columns + 1) * height))
        alpha = cell.getchannel('A').point(lambda a: 255 if a >= 200 else 0)
        box = alpha.getbbox()
        if not box:
            raise ValueError(f'{model["id"]}/{action}/{view}/{n}: empty alpha>=200')
        boxes.append(box)
    scale = model['height'] / max(box[3] - box[1] for box in boxes)
    reference = Image.open(ROOT / model['source']).convert('RGBA')
    src = reference.crop((0 if view == 'sw' else 112, 0, 112 if view == 'sw' else 224, 112))
    source_box = src.getbbox()
    target_center = (source_box[0] + source_box[2]) / 2
    raw_center = statistics.median((box[0] + box[2]) / 2 for box in boxes)
    offset_x = round(target_center - raw_center * scale)
    offset_y = round(100 - max(box[3] for box in boxes) * scale)
    cells = [dict(x=(n % columns) * width, y=(n // columns) * height,
                  w=width, h=height, offset_x=offset_x, offset_y=offset_y, edits=[])
             for n in range(columns * rows)]
    return dict(path=path.relative_to(ROOT).as_posix(), source_sha256=digest(path),
                action=action, view=view, scale=scale, alpha_threshold=200, master_pose=1,
                inspected_bounds=boxes, cells=cells)


def prepare(model, phase, views):
    folder = ROOT / model['folder']
    folder.mkdir(exist_ok=True, parents=True)
    layout_file = folder / 'normalizacao.json'
    previous = load(layout_file) if layout_file.exists() else {}
    actions = ('walk',) if phase == 'walk' else ('idle', 'walk')
    sheets = [s for s in previous.get('sheets', []) if s['action'] in actions and s['view'] not in views]
    for action in actions:
        if action == 'idle' and model.get('authored_idle'):
            continue
        for view in views:
            sheet = inspect_sheet(model, action, view, previous)
            if not sheet:
                return None
            sheets.append(sheet)
    layout = dict(id=model['id'], folder=model['folder'], source=model['source'],
                  height=model['height'], motion=model['motion'], sheets=sheets,
                  source_sha256=digest(ROOT / model['source']),
                  idle_durations=[750, 200, 750, 200] if model.get('authored_idle') else [400, 150, 400, 150],
                  walk_durations=[140, 100, 120, 140, 100, 120],
                  manual_color_merges=previous.get('manual_color_merges', model.get('manual_color_merges', {})))
    if model.get('authored_idle'):
        layout['authored_idle'] = model['authored_idle']
    if model.get('source_core_lock'):
        layout['source_core_lock'] = model['source_core_lock']
    save(layout_file, layout)
    return layout_file


def run(model, layout, phase):
    command = [str(ASEPRITE), '-b', '--script-param', f'root={ROOT.as_posix()}',
               '--script-param', f'layout={layout.as_posix()}', '--script', LUA.as_posix()]
    process = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                             creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    scratch = ROOT / 'tmp/overworld-pranchas-lote-02'
    scratch.mkdir(exist_ok=True, parents=True)
    (scratch / f'{model["id"]}-{phase}.log').write_text(process.stdout + process.stderr, encoding='utf-8')
    if process.returncode:
        raise RuntimeError(f'{model["id"]}: Aseprite failed. See {scratch}')
    folder = ROOT / model['folder']
    available_views = [s['view'] for s in load(layout)['sheets'] if s['action'] == 'walk']
    print(model['id'], phase, 'imported;', *(f'mestre-walk-{v}.png' for v in available_views))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--batch', type=Path, required=True)
    parser.add_argument('--id', action='append', default=[])
    parser.add_argument('--phase', choices=('walk', 'complete'), default='walk')
    parser.add_argument('--view', choices=('sw', 'nw', 'both'), default='both')
    parser.add_argument('--prepare-only', action='store_true')
    args = parser.parse_args()
    batch = load(args.batch)
    for model in batch['models']:
        if args.id and model['id'] not in args.id:
            continue
        views = ('sw', 'nw') if args.view == 'both' else (args.view,)
        layout = prepare(model, args.phase, views)
        if layout is None:
            print(model['id'], 'waiting for generated sheets')
        elif args.prepare_only:
            print(model['id'], 'layout ready')
        else:
            run(model, layout, args.phase)
