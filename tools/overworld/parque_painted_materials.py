"""Bind approved raster paintings without baking geometry into the artwork."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[2]


def apply(kit):
    kit['paintSurfaces'] = {
        'grama': 'pintura-v4/grama.png',
        'terra': 'pintura-v4/terra.png',
        'mato': 'pintura-v4/grama.png',
        'bosque': 'pintura-v4/grama.png',
        'piso': '../bairro-inicial-v2/surfaces/passeio-manga-v4.png',
    }
    kit['paintTints'] = {'mato': '#a3b49d', 'bosque': '#8c9d91'}
    kit['wallSurfaces'] = {'pedra': {'file': 'pintura-v4/barranco.png', 'repeatTexelsPerCell': [48, 96]}}
    for asset in ('arvore', 'buriti', 'capim-margem'):
        for variant in kit.get('pieces', {}).get(asset, {}).get('variants', {}).values():
            variant['foliageQuiet'] = True
    kit['surfaceTreatment']['note'] = (
        'Restrained pintura-v4 manga raster paintings and bairro sidewalk in continuous world space; '
        'native polygons own transitions, banks and elevation. SVGs are geometry fallbacks only.'
    )
    kit['mangaWater'].update(depthPx=32, surface='../cavernas-v3/surfaces/agua-linhas.png')
    kit['approval'] = 'pending_owner_review_painted_refinement_v4'
    return kit


if __name__ == '__main__':
    for prefix in ('art/overworld/kits', 'godot/assets/overworld/kits'):
        file = ROOT / prefix / 'parque/kit.json'
        kit = apply(json.loads(file.read_text(encoding='utf-8')))
        file.write_text(json.dumps(kit, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
