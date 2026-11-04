"""Normalize generated meadow art without repainting; prepare native Godot library."""
from pathlib import Path
import argparse,json,shutil
from PIL import Image
import numpy as np
from build_terrain_library import periodic

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/planicie-v1'
GAME=ROOT/'godot/assets/overworld/kits/planicie-v1'
REVIEW=ROOT/'documentation/overworld/planicie-v1'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--grass',type=Path,required=True);parser.add_argument('--tree',type=Path,required=True);args=parser.parse_args()
    for base in [ART,GAME,REVIEW]:base.mkdir(parents=True,exist_ok=True)
    (ART/'fontes').mkdir(exist_ok=True)
    shutil.copy2(args.grass,ART/'fontes/grama.png');shutil.copy2(args.tree,ART/'fontes/arvore.png')
    grass=periodic(Image.open(args.grass),512)
    tree=Image.open(args.tree).convert('RGBA')
    # Alpha normalization removes the generated faint peripheral matte, not the subject.
    tree.putalpha(tree.getchannel('A').point(lambda value:255 if value>=200 else 0))
    tree=tree.crop(tree.getbbox());height=round(tree.height*186/tree.width)
    tree=tree.resize((186,height),Image.Resampling.LANCZOS)
    sprite=Image.new('RGBA',(202,height+16));sprite.alpha_composite(tree,(8,8))
    ys,xs=np.where(np.asarray(sprite)[:,:,3]>80);bottom=int(ys.max());pivot=[float(np.median(xs[ys>=bottom-3])),bottom]
    for base in [ART,GAME]:
        (base/'surfaces').mkdir(exist_ok=True);(base/'props').mkdir(exist_ok=True)
        Image.fromarray(grass).save(base/'surfaces/grama.png');sprite.save(base/'props/arvore.png')
    manifest={'schema':'plains-showcase-1','grid':[64,32],'campaignIntegrated':False,'collision':'not-authored',
              'grass':{'file':'surfaces/grama.png','size':[512,512],'repeatCells':8},
              'props':{'arvore':{'file':'props/arvore.png','size':list(sprite.size),'pivot':pivot,'source':'fontes/arvore.png'}},
              'reusedAssets':['cavernas-v3/surfaces/terra-gruta.png','cavernas-v3/surfaces/rocha-cinza.png','cavernas-v3/props/rocha-solta.png','parque/decalques/capim-a.png','comum/pecas/flores-amarela.png'],
              'transitionImplementation':'res://shaders/overworld/terrain_transition.gdshaderinc'}
    for base in [ART,GAME]:(base/'library.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    report={'oppositeXMaxDifference':int(abs(grass[:,0].astype(int)-grass[:,-1]).max()),'oppositeYMaxDifference':int(abs(grass[0].astype(int)-grass[-1]).max()),'treePivot':pivot,'treeActualAlpha':True,'gameplayTestsRun':False}
    (REVIEW/'preparacao.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    repeated=Image.new('RGB',(1536,1536))
    for y in range(3):
        for x in range(3):repeated.paste(Image.fromarray(grass),(x*512,y*512))
    repeated.save(REVIEW/'grama-repeticao-3x3.png')
    print(json.dumps(report))

if __name__=='__main__':main()
