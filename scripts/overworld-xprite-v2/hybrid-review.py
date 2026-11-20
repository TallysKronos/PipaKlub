"""Validate authored hybrid atlases and publish selected models, never the video queue.

Pixel authoring/review happens in Aseprite. This utility reads pixels, records
mechanical checks and copies the exact approved files; it does not repair art.
"""
from pathlib import Path
import argparse
import csv
from collections import defaultdict
import hashlib
import html
import json
import os
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/creatures'
RUNTIME = ROOT / 'godot/assets/campaign/overworld-animations-v1'
GALLERY = ART / 'overworld-hibridos-v1'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def components(cell):
    pixels = cell.load()
    remaining = {(x, y) for y in range(112) for x in range(112) if pixels[x, y][3]}
    sizes = []
    while remaining:
        todo = [remaining.pop()]
        size = 0
        while todo:
            x, y = todo.pop()
            size += 1
            for dx, dy in ((-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)):
                neighbor = x+dx, y+dy
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    todo.append(neighbor)
        sizes.append(size)
    return sorted(sizes, reverse=True)


def validate(model):
    folder = ART / f'{model}-hibrido-v1'
    if not folder.exists():
        folder = ART / f'{model}-prancha-v1'
    manifest = read(folder / 'manifest.json')
    errors, frames = [], []
    if manifest.get('cell') != [112, 112] or manifest.get('anchor') != [56, 100]:
        errors.append('Canvas/anchor differs from 112x112 / 56,100')
    if manifest.get('views') != ['sw', 'nw']:
        errors.append('Views must be SW then NW')
    source = Image.open(ART / 'soulmonsters-overworld-v2' / model / 'duas-vistas.png').convert('RGBA')
    palette = {c for c in source.getdata() if c[3]}
    editable = list(folder.glob('*.aseprite'))
    if not editable:
        errors.append('Missing Aseprite editable')
    for action in ('idle', 'walk'):
        spec = manifest['animations'][action]
        count, durations = spec['frames'], spec['durations_ms']
        if count < 2 or len(durations) != count or any(d <= 0 for d in durations):
            errors.append(f'{action}: invalid frame timing')
        path = folder / spec['image']
        atlas = Image.open(path).convert('RGBA')
        if atlas.size != (112 * count, 224):
            errors.append(f'{action}: wrong atlas dimensions {atlas.size}')
            continue
        for row, view in enumerate(('sw', 'nw')):
            for n in range(count):
                cell = atlas.crop((112*n, 112*row, 112*(n+1), 112*(row+1)))
                colors = set(cell.getdata())
                box = cell.getbbox()
                if box is None:
                    errors.append(f'{action}/{view}/{n}: empty pose')
                elif box[0] == 0 or box[1] == 0 or box[2] == 112 or box[3] == 112:
                    errors.append(f'{action}/{view}/{n}: touches cell edge; inspect clipping')
                if any(c[3] not in (0, 255) for c in colors):
                    errors.append(f'{action}/{view}/{n}: nonbinary alpha')
                if any(c[3] and c not in palette for c in colors):
                    errors.append(f'{action}/{view}/{n}: colors outside source palette')
                groups = components(cell)
                if any(size <= 2 for size in groups):
                    errors.append(f'{action}/{view}/{n}: detached one/two pixel island')
                frames.append(dict(action=action, view=view, pose=n, bounds=box, component_sizes=groups))
    result = dict(id=model, errors=errors, frames=frames,
                  hashes={a: digest(folder / manifest['animations'][a]['image']) for a in ('idle', 'walk')},
                  limitation='Geometry/palette checks do not certify anatomy, gait or visual approval.')
    (folder / 'validacao-publicacao.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return folder, manifest, result


def publish(model):
    folder, manifest, result = validate(model)
    if result['errors']:
        raise ValueError(f'{model}: {result["errors"]}')
    if not manifest.get('approval_date'):
        if manifest.get('review_score', 0) < 7 or manifest.get('blocking_findings', ['review missing']):
            raise ValueError(f'{model}: independent art review must reach 7/10 with no blockers before publication')
    # Publication is an explicit CLI action after visual review, not inferred
    # from a high palette/connectivity score.
    runtime_path = RUNTIME / 'manifest.json'
    runtime = read(runtime_path)
    if model not in runtime:
        raise ValueError(f'{model}: not registered as an overworld companion')
    entry = dict(runtime[model])
    dest = RUNTIME / model
    dest.mkdir(exist_ok=True)
    for action in ('idle', 'walk'):
        source = folder / manifest['animations'][action]['image']
        target = dest / f'{action}.png'
        shutil.copy2(source, target)
        assert digest(source) == digest(target)
        entry[action] = f'res://assets/campaign/overworld-animations-v1/{model}/{action}.png'
    entry['frame_counts'] = {a: manifest['animations'][a]['frames'] for a in ('idle', 'walk')}
    entry['idle_durations'] = [ms / 1000 for ms in manifest['animations']['idle']['durations_ms']]
    entry['source_folder'] = folder.relative_to(ROOT).as_posix()
    version = 'sheet-v1' if folder.name.endswith('-prancha-v1') else 'hybrid-v1'
    entry['art_version'] = version
    if manifest.get('approval_date'):
        entry['art_version'] = version + '-approved'
    runtime[model] = entry
    runtime_path.write_text(json.dumps(runtime, indent=2) + '\n', encoding='utf-8')
    manifest.update(runtime_replaced=True, status='integrado localmente; conferência no jogo pendente')
    (folder / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'{model}: exact atlas copies published locally; visual playtest required')


def gallery(models=None, evidence=None):
    GALLERY.mkdir(exist_ok=True)
    cards = []
    runtime = read(RUNTIME / 'manifest.json')
    for folder in sorted([*ART.glob('*-hibrido-v1'), *ART.glob('*-prancha-v1')]):
        if not (folder / 'manifest.json').exists():
            continue
        if read(folder / 'manifest.json').get('status', '').startswith('reprovado'):
            continue
        model = folder.name.removesuffix('-hibrido-v1').removesuffix('-prancha-v1')
        if models is not None and model not in models:
            continue
        entry = runtime.get(model, {})
        if entry.get('source_folder') and entry['source_folder'] != folder.relative_to(ROOT).as_posix():
            continue
        integrated = entry.get('art_version', '').startswith(('hybrid-', 'sheet-'))
        status = 'Integrado localmente' if integrated else 'Em revisão'
        if entry.get('art_version', '').endswith('-approved'):
            status += ' · aprovado pelo usuário'
        game_gif = (evidence or ROOT / 'tmp/overworld-hybrid/playtest') / f'{model}-movimento-in-game.gif'
        game_href = os.path.relpath(game_gif,GALLERY).replace('\\','/')
        game_link = (f'<p><a href="{game_href}">GIF no Godot</a></p>'
                     if game_gif.exists() else '')
        idle_gif = game_gif.with_name(f'{model}-idle-in-game.gif')
        if idle_gif.exists():
            idle_href = os.path.relpath(idle_gif,GALLERY).replace('\\','/')
            game_link += f'<p><a href="{idle_href}">Idle no Godot</a></p>'
        if folder.name.endswith('-prancha-v1') and (folder / 'index.html').exists():
            game_link = f'<p><a href="../{folder.name}/index.html">Comparação antes/depois no jogo</a></p>'
        method = 'Prancha ImageGen finalizada' if folder.name.endswith('-prancha-v1') else 'Híbrido orientado por vídeo'
        cards.append(f'<article><h2>{html.escape(model)}</h2><p>{status} · {method}</p>'
                     + ''.join(f'<figure><img loading="lazy" src="../{folder.name}/{a}.gif"><figcaption>{a} · SW/NW</figcaption></figure>' for a in ('idle', 'walk'))
                     + f'<p><a href="../{folder.name}/revisao.md">Revisão e limites</a></p>{game_link}</article>')
    (GALLERY / 'index.html').write_text('<!doctype html><meta charset="utf-8"><title>Animações de overworld</title>'
        '<style>body{background:#112b34;color:#f6e9ce;font:16px system-ui;margin:24px}main{display:flex;flex-wrap:wrap;gap:20px}'
        'article{background:#263d48;padding:18px;max-width:700px}img{image-rendering:pixelated;width:448px;max-width:100%}'
        'figure{margin:10px 0}a{color:#7edcd3}</style><h1>Animações de overworld</h1>'
        '<p>Novas poses orientadas por vídeos ou geradas em prancha, com finalização pixel art. Cada anatomia recebe revisão própria. '
        'A galeria mostra os atlas; o teste no Godot é registrado na revisão individual.</p><main>'
        + ''.join(cards) + '</main>', encoding='utf-8')
    queue_path = ART / 'overworld-video-v2/queue.json'
    if queue_path.exists():
        queue = read(queue_path)
        by_model = defaultdict(list)
        for job in queue['jobs']:
            by_model[job['creature']].append(job)
        rows = []
        for model, jobs in sorted(by_model.items()):
            if models is not None and model not in models:
                continue
            hybrid = runtime.get(model, {}).get('art_version', '').startswith(('hybrid-', 'sheet-'))
            rows.append(dict(id=model, anatomia=jobs[0]['anatomy'],
                clipes_concluidos=sum(j['status'] == 'completed' for j in jobs),
                clipes_esperados=4,
                estado='animação finalizada integrada' if hybrid else 'aguarda reconstrução e revisão',
                revisao_visual='ver revisão individual; clipe concluído não é aprovação'))
        if rows:
            with (GALLERY / 'fila-reconstrucao.csv').open('w', encoding='utf-8-sig', newline='') as output:
                writer = csv.DictWriter(output, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--id', action='append', default=[])
    parser.add_argument('--publish', action='store_true')
    parser.add_argument('--batch', type=Path, help='Filter gallery to a batch and save it beside its JSON')
    parser.add_argument('--evidence', type=Path, help='Actual Godot capture directory for gallery links')
    args = parser.parse_args()
    for model in args.id:
        if args.publish:
            publish(model)
        else:
            _, _, result = validate(model)
            print(f'{model}: {len(result["frames"])} poses; {len(result["errors"])} errors')
            if result['errors']:
                raise ValueError(result['errors'])
    selected = None
    if args.batch:
        batch_path = ROOT / args.batch
        selected = [m['id'] for m in read(batch_path)['models']]
        GALLERY = batch_path.parent
    gallery(selected, ROOT / args.evidence if args.evidence else None)
