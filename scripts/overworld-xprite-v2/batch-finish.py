"""Record a reviewed, integrated batch and compare actual Godot captures.

Reads art; never edits pixels, publishes assets, grants approval or runs videos.
Requires successful targeted tests and exact runtime copies before reporting.
"""
from pathlib import Path
import argparse
import hashlib
import html
import json
import os
import re

ROOT = Path(__file__).resolve().parents[2]


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def finish(batch_path, evidence):
    batch = read(batch_path)
    folder = batch_path.parent
    report = read(evidence / 'playtest/report.json')
    baseline = read(evidence / 'baseline-hashes.json')
    runtime = read(ROOT / 'godot/assets/campaign/overworld-animations-v1/manifest.json')
    ids = [m['id'] for m in batch['models']]
    assert not report['failures'], 'Visual playtest failed'
    assert set(ids) == {m['id'] for m in report['models']}, 'Test did not cover this batch'
    match = re.search(r'OVERWORLD ANIMATION (\d+) checks; (\d+) failures',
                      (evidence / 'checks.log').read_text(encoding='utf-8', errors='replace'))
    assert match and int(match[2]) == 0, 'Missing or failed animation checks'
    animation_checks = int(match[1])
    cards, proofs = [], []
    for model in batch['models']:
        name = model['id']
        art = ROOT / model['folder']
        manifest = read(art / 'manifest.json')
        assert manifest.get('review_score', 0) >= 7 and not manifest.get('blocking_findings', ['missing']), name + ': review required'
        source = ROOT / model['source']
        assert digest(source) == baseline[name]['source']['duas-vistas.png'], name + ': source changed'
        assert runtime[name]['source_folder'] == model['folder'], name + ': inactive source'
        for action in ('idle', 'walk'):
            target = ROOT / 'godot/assets/campaign/overworld-animations-v1' / name / (action + '.png')
            assert digest(art / (action + '.png')) == digest(target), name + ': runtime copy differs'
        manifest.update(status='integrado localmente; testes específicos e capturas no Godot concluídos',
                        runtime_replaced=True,
                        gameplay_validation=dict(animation_checks=animation_checks,
                            visual_checks=report['checks'], failures=0,
                            evidence=evidence.relative_to(ROOT).as_posix(),
                            scope='Targeted animation/follower tests, not full-game regression or human approval'))
        save(art / 'manifest.json', manifest)
        blocks = []
        for action in ('movimento', 'idle'):
            for state, label in [('antes', 'Antes'), ('playtest', 'Novo')]:
                gif = evidence / state / f'{name}-{action}-in-game.gif'
                assert gif.exists(), f'Missing actual game GIF: {gif}'
                href = os.path.relpath(gif, folder).replace('\\', '/')
                blocks.append(f'<figure><figcaption>{label} · {action}</figcaption>'
                              f'<img loading="lazy" src="{href}"></figure>')
        cards.append(f'<section><h2>{html.escape(name)}</h2><div>{"".join(blocks)}</div></section>')
        proofs.append(dict(id=name, source_unchanged=True, exact_runtime_copies=True))
    save(evidence / 'root-final-check.json', proofs)
    page = ('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Antes e depois no Godot</title>'
            '<style>body{background:#112b34;color:#f6e9ce;font:16px system-ui;margin:24px}'
            'section{margin:32px 0;padding:20px;background:#263d48}section div{display:grid;'
            'grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}figure{margin:0}'
            'img{width:100%;image-rendering:pixelated}figcaption{padding:10px}'
            '@media(max-width:600px){section div{grid-template-columns:1fr}}</style>'
            '<h1>Antes e depois no Godot</h1><p>Mesma cena e percurso. GIFs ampliados 2× com nearest '
            'apenas para apresentação. Revisão independente e testes específicos não substituem '
            'a avaliação do usuário. Consulte as limitações na revisão individual.</p>'
            + ''.join(cards) + '</html>')
    (folder / 'comparacao.html').write_text(page, encoding='utf-8')
    index = folder / 'index.html'
    if index.exists():
        text = index.read_text(encoding='utf-8')
        if 'href="comparacao.html"' not in text:
            index.write_text(text.replace('<h1>', '<p><a href="comparacao.html">Comparar antes/depois no Godot</a></p><h1>', 1), encoding='utf-8')
    total = sum(m.get('art_version', '').startswith(('sheet-', 'hybrid-')) for m in runtime.values())
    summary = dict(models=ids, animation_checks=animation_checks, visual_checks=report['checks'],
                   failures=0, integrated_total=total, catalog_total=len(runtime),
                   human_approval='See individual manifests; not inferred from this report')
    save(folder / 'resultado.json', summary)
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--batch', type=Path, required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    finish((ROOT / args.batch).resolve(), (ROOT / args.evidence).resolve())
