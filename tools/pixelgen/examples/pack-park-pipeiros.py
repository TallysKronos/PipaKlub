"""Normalize generated directional drafts; final sprite export is performed in Aseprite."""
import json, shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/parque-pipeiros-runtime-v1'
SOURCE=OUT/'fontes/sources.json'
def run():
    # Reuse proven native-grid planning without writing production PNG sprites.
    old=(ROOT/'tools/pixelgen/examples/pack-npc-directions.py').read_text(encoding='utf8')
    old=old[:old.index("if __name__")]
    old=old.replace("    sheet.save(target/'candidate.png')","    # Production sheet is exported by native Aseprite.")
    ns={'__file__':str(ROOT/'tools/pixelgen/examples/pack-npc-directions.py')}
    exec(compile(old,'directional-grid-planner','exec'),ns)
    ns['OUT']=OUT
    (OUT/'fontes').mkdir(parents=True,exist_ok=True)
    for entry in json.loads(SOURCE.read_text(encoding='utf8')):
        ident=entry['id']
        shutil.copy2(entry['sprite'],OUT/'fontes'/f'{ident}.png')
        shutil.copy2(entry['portrait'],OUT/'fontes'/f'{ident}-portrait.png')
        (OUT/'fontes'/f'{ident}-prompts.json').write_text(json.dumps(entry,ensure_ascii=False,indent=2),encoding='utf8')
        print(ns['prepare']({'id':ident,'name':entry['name'],'height':82,'sourceOrder':list(range(8)),'ref':f'art/characters/parque-pipeiros-v3/{ident}-sheet.png'}))
        portrait=Image.open(entry['portrait']).convert('RGBA')
        # Remove the faint generated translucent halo without altering opaque line art.
        portrait.putalpha(portrait.getchannel('A').point(lambda a:0 if a<200 else min(255,(a-200)*255//55)))
        portrait=portrait.crop(portrait.getbbox())
        portrait.thumbnail((640,900),Image.Resampling.LANCZOS)
        portrait.save(ROOT/'godot/assets/campaign'/f'portrait-{ident}.png')
if __name__=='__main__':run()

