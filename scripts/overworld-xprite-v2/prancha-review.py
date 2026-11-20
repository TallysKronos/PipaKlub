"""Inspect and preview any direct-prancha model without touching runtime."""
from pathlib import Path
from PIL import Image
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def components(im):
    remaining = {(x, y) for y in range(112) for x in range(112) if im.getpixel((x, y))[3]}
    groups = []
    while remaining:
        first = remaining.pop()
        todo, group = [first], [first]
        while todo:
            x, y = todo.pop()
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if not dx and not dy:
                        continue
                    pixel = x + dx, y + dy
                    if pixel in remaining:
                        remaining.remove(pixel)
                        todo.append(pixel)
                        group.append(pixel)
        groups.append(group)
    return groups


def review(model, phase):
    folder = ROOT / model['folder']
    source = Image.open(ROOT / model['source']).convert('RGBA')
    palette = {c for c in source.getdata() if c[3]}
    actions = ('walk',) if phase == 'walk' else ('idle', 'walk')
    previous = load(folder / 'manifest.json') if (folder / 'manifest.json').exists() else {}
    manifest = dict(previous, id=model['id'], cell=[112, 112], anchor=[56, 100],
                    views=['sw', 'nw'], source=model['source'],
                    runtime_replaced=previous.get('runtime_replaced', False),
                    method=('ImageGen walk poses; Aseprite grid/palette/alpha finalization; source-authored stationary idle'
                            if model.get('authored_idle') else 'ImageGen poses; Aseprite grid/palette/alpha finalization'),
                    status='walk masters ready; idle pending' if phase == 'walk' else 'review pending',
                    animations={})
    report, errors = {}, []
    for action in actions:
        count = 6 if action == 'walk' else 4
        durations = ([140, 100, 120, 140, 100, 120] if action == 'walk' else
                     ([750, 200, 750, 200] if model.get('authored_idle') else [400, 150, 400, 150]))
        path = folder / f'{action}.png'
        if not path.exists():
            print(model['id'], 'waiting for', action)
            return
        sheet = Image.open(path).convert('RGBA')
        if sheet.size != (count * 112, 224):
            raise ValueError(f'{model["id"]}/{action}: bad atlas dimensions {sheet.size}')
        frames, stats = [], []
        poses = Image.new('RGB', (count * 224, 448), '#263d48')
        for n in range(count):
            pair = Image.new('RGBA', (224, 112))
            for row, view in enumerate(('sw', 'nw')):
                im = sheet.crop((n*112, row*112, (n+1)*112, (row+1)*112))
                box, colors = im.getbbox(), set(im.getdata())
                if box is None or box[0] == 0 or box[1] == 0 or box[2] == 112 or box[3] == 112:
                    errors.append(f'{action}/{view}/{n}: empty or touching cell edge')
                if any(c[3] not in (0, 255) for c in colors):
                    errors.append(f'{action}/{view}/{n}: nonbinary alpha')
                if any(c[3] and c not in palette for c in colors):
                    errors.append(f'{action}/{view}/{n}: tone outside source palette')
                groups = components(im)
                small = [g for g in groups if len(g) <= 2]
                if small:
                    errors.append(f'{action}/{view}/{n}: tiny opaque groups {small}')
                stats.append(dict(action=action, view=view, pose=n, bounds=box,
                                  colors=len({c for c in colors if c[3]}),
                                  opaque=sum(c[3] > 0 for c in im.getdata()),
                                  components=sorted(map(len, groups), reverse=True),
                                  tiny=small, sha256=hashlib.sha256(im.tobytes()).hexdigest()))
                pair.paste(im, (row*112, 0))
                big = im.resize((224, 224), Image.Resampling.NEAREST)
                poses.paste(big, (n*224, row*224), big)
            bg = Image.new('RGBA', (224, 112), '#263d48')
            bg.alpha_composite(pair)
            frames.append(bg.convert('RGB').resize((672, 336), Image.Resampling.NEAREST))
        frames[0].save(folder / f'{action}.gif', save_all=True, append_images=frames[1:],
                       duration=durations, loop=0, disposal=2)
        poses.save(folder / f'{action}-poses.png')
        report[action] = stats
        manifest['animations'][action] = dict(image=f'{action}.png', frames=count,
                                               durations_ms=durations, loop=True)
    save(folder / 'validacao.json', dict(errors=errors, actions=report,
                                         limitation='Palette/geometry checks are not art approval.'))
    save(folder / 'manifest.json', manifest)
    print(model['id'], sum(map(len, report.values())), 'poses,', len(errors), 'mechanical errors')
    for error in errors:
        print('  ', error)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--batch', type=Path, required=True)
    parser.add_argument('--id', action='append', default=[])
    parser.add_argument('--phase', choices=('walk', 'complete'), default='walk')
    args = parser.parse_args()
    for model in load(args.batch)['models']:
        if args.id and model['id'] not in args.id:
            continue
        if not (ROOT / model['folder'] / 'walk.png').exists():
            continue
        review(model, args.phase)
