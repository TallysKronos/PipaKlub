"""Validate delivered files; does not record footage or grant artistic approval."""
from pathlib import Path
import hashlib
import json
import wave
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def validate():
    package = json.loads((ROOT / 'documentation/trailer/PACOTE-V2.json').read_text(encoding='utf-8'))
    results = []
    for asset in package['assets']:
        path = ROOT / asset['path']
        assert path.is_file(), asset['path']
        if asset['type'] == 'png':
            with Image.open(path) as image:
                assert list(image.size) == asset['size'], asset['path'] + ': size'
                if asset.get('alpha_required'):
                    assert 'A' in image.getbands() and image.getchannel('A').getextrema()[0] == 0, asset['path'] + ': alpha'
        data = path.read_bytes()
        hashes = {hashlib.sha256(data).hexdigest()}
        if path.suffix in ('.json', '.md', '.txt', '.csv'):
            # O pacote foi medido no Windows (CRLF); o git guarda os textos com LF.
            lf = data.replace(b'\r\n', b'\n')
            hashes |= {hashlib.sha256(lf).hexdigest(), hashlib.sha256(lf.replace(b'\n', b'\r\n')).hexdigest()}
        assert asset['sha256'] in hashes, asset['path'] + ': source changed since delivery'
        results.append(dict(path=asset['path'], ok=True))
    for atlas in package['atlases']:
        data = json.loads((ROOT / atlas['json']).read_text(encoding='utf-8'))
        frames = data['frames']
        assert len(frames) == atlas['frames']
        with Image.open(ROOT / atlas['image']) as image:
            for frame in frames:
                rect = frame['frame']
                assert rect['w'] > 0 and rect['h'] > 0 and min(rect['x'], rect['y']) >= 0
                assert rect['x'] + rect['w'] <= image.width and rect['y'] + rect['h'] <= image.height
        assert atlas['animation'] in data['animations']
        assert sum(data['durations_ms']) == atlas['duration_ms']
    for source in package['overworld_sources']:
        norm = json.loads((ROOT / source['json']).read_text(encoding='utf-8'))
        with Image.open(ROOT / source['image']) as image:
            assert len(norm['regions']) == 2
            for r in norm['regions']:
                assert r['x'] >= 0 and r['y'] >= 0 and r['width'] > 0 and r['height'] > 0
                assert r['x'] + r['width'] <= image.width and r['y'] + r['height'] <= image.height
    with wave.open(str(ROOT / package['roar_audio']), 'rb') as audio:
        assert audio.getnchannels() == 2 and audio.getframerate() == 48000
        assert 2 <= audio.getnframes() / audio.getframerate() <= 3
    smoke = json.loads((ROOT / 'documentation/trailer/VALIDACAO-PLANOS-V2.json').read_text())
    assert len(smoke['shots']) == 8 and smoke['failures'] == 0 and all(s['ready'] for s in smoke['shots'])
    result = dict(ok=True, checked_files=len(results), checked_atlases=len(package['atlases']),
        checked_overworld_sources=len(package['overworld_sources']), scene_smokes=8,
        limitations='Technical file/setup validation; not a filmed or human-approved trailer, no listening review implied',
        files=results)
    (ROOT / 'documentation/trailer/VALIDACAO-PACOTE-V2.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k != 'files'}))


if __name__ == '__main__':
    validate()
