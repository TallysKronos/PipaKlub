"""Package native wind review captures; no gameplay or account access."""
from pathlib import Path
import json
import zipfile
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'documentation/overworld/cavernas-v3/ventos'

def main():
    paths = sorted((OUT / 'frames').glob('vento-*.png'))
    if len(paths) != 96:
        raise ValueError('Expected 96 native frames')
    frames = [Image.open(p).convert('RGB') for p in paths]
    first = np.asarray(frames[0]).astype(int)
    last = np.asarray(Image.open(OUT / 'loop-final.png').convert('RGB')).astype(int)
    difference = np.abs(first - last)
    duration = [80, 80, 90] * 32
    small = [f.resize((960, 540), Image.Resampling.LANCZOS) for f in frames]
    small[0].save(OUT / 'GRUTA-VENTOS.webp', save_all=True, append_images=small[1:], duration=duration, loop=0, quality=88)
    palette = small[0].quantize(colors=256)
    gif = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in small]
    gif[0].save(OUT / 'GRUTA-VENTOS.gif', save_all=True, append_images=gif[1:], duration=duration, loop=0, disposal=2)
    # Magnify the fixed attachment and the rooted flower next to it.
    details = [f.crop((378,245,567,433)).resize((567,564),Image.Resampling.NEAREST) for f in frames]
    details[0].save(OUT / 'DETALHE-ANIMADO.webp', save_all=True, append_images=details[1:], duration=duration, loop=0, lossless=True)
    details[24].save(OUT / 'DETALHE-AMARRACAO.png')
    report = {'resolution':[1280,720], 'savedScenesInstantiated':2, 'frames':96, 'loopSeconds':8,
              'loopMaximumChannelDifference':int(difference.max()),
              'loopMeanChannelDifference':float(difference.mean()),
              'reducedMotionCapture':True,'rootWeight':0,'attachmentWeight':0,
              'gameplayTestsRun':False,'campaignIntegrated':False}
    (OUT / 'auditoria.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    paths_to_pack = []
    for folder in ['godot/assets/overworld/kits/cavernas-v3','godot/assets/overworld/kits/aguas-v1','godot/scenes/overworld/caves-v3']:
        paths_to_pack += [p for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix != '.import']
    names = ['water_patch.gd','waterfall.gd','water_effect.gd','cave_water.gd','cave_waterfall.gd','cave_basin.gd','cave_wind.gd','cave_ground.gd']
    shaders = ['water_surface.gdshader','water_fall.gdshader','water_foam.gdshader','cave_floor.gdshader','cave_prop_outline.gdshader','cave_basin_water.gdshader','cave_wind_paper.gdshader','cave_ground_blend.gdshader','terrain_transition.gdshaderinc']
    paths_to_pack += [ROOT/'godot/scripts/overworld'/p for p in names]
    paths_to_pack += [ROOT/'godot/shaders/overworld'/p for p in shaders]
    paths_to_pack += [p.with_suffix(p.suffix+'.uid') for p in paths_to_pack.copy() if p.with_suffix(p.suffix+'.uid').exists()]
    with zipfile.ZipFile(OUT/'gruta-com-ventos-godot.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(set(paths_to_pack)):
            archive.write(path,path.relative_to(ROOT))
        archive.write(OUT/'README.md','README.md')
    print(json.dumps(report,indent=2))

if __name__ == '__main__':
    main()
