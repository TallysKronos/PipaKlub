"""Open the eight trailer scenes without recording video or touching player saves."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SHOTS = [('park-trail', 'farpim'), ('kronasta-bosque-a', 'gambalhote-baby'),
    ('planicie-d', 'papisco'), ('caverna-c', 'vertim'), ('vulcao-a', 'trincaguarda'),
    ('serra-gelada-a', 'urso-polar-young'), ('abismo-b', 'capivara-boia'),
    ('kronasta-palafitas-b', 'alvacordo')]


def run(godot):
    folder = ROOT / 'tmp/trailer-v2/planos'
    folder.mkdir(parents=True, exist_ok=True)

    def one(pair):
        scene, partner = pair
        cmd = [godot, '--headless', '--fixed-fps', '30', '--path', str(ROOT / 'godot'),
            '--log-file', str(folder / (partner + '-engine.log')), '--script',
            'res://tools/trailer_capture.gd', '--', '--shot=motivo', '--scene=' + scene,
            '--partner=' + partner, '--secs=4', '--storage=' + str(folder / ('save-' + partner))]
        result = subprocess.run(cmd, cwd=ROOT, capture_output=True, timeout=90)
        log = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        (folder / (partner + '.log')).write_text(log, encoding='utf-8')
        ready = result.returncode == 0 and 'READY frame=' in log and 'MOTIVO ' + scene in log
        return dict(scene=scene, partner=partner, returncode=result.returncode, ready=ready,
                    log=(folder / (partner + '.log')).relative_to(ROOT).as_posix())

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(one, SHOTS))
    report = dict(shots=results, failures=sum(not r['ready'] for r in results),
                  scope='Headless scene/setup smoke test only; no footage recorded, no visual route review')
    (ROOT / 'documentation/trailer/VALIDACAO-PLANOS-V2.json').write_text(
        json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))
    return 1 if report['failures'] else 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot'))
    args = parser.parse_args()
    if not args.godot:
        parser.error('Pass --godot PATH or set GODOT_BIN')
    raise SystemExit(run(args.godot))
