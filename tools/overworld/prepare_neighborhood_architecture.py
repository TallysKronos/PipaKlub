"""Prepare painted architecture; keep original art and calibrated base corners."""
from pathlib import Path
import json,shutil
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/bairro-inicial-v2'
GAME=ROOT/'godot/assets/overworld/kits/bairro-inicial-v2'
SOURCE=ART/'fontes/arquitetura-v3'

def main():
    spec=json.loads((SOURCE/'kael-origem.json').read_text(encoding='utf-8'))
    models={
        'kael':{'source':spec['path'],'edges':[[[110,959],[647,1208]],[[778,1224],[1177,1010]]],'label':'Casa do Kael · sobrado azul'},
        'professor':{'source':'art/overworld/kits/urbano/fontes/geradas/laboratorio-elos.png','corners':[[118,876],[650,1186],[1255,877]],'label':'Professor · laboratório de vínculos'},
        'shop':{'source':'art/overworld/kits/urbano/fontes/geradas/loja-pipas.png','corners':[[145,860],[702,1128],[1250,851]],'label':'Linha & Papel · vitrine de pipas'},
        'neighbor-north':{'source':'art/overworld/kits/urbano/fontes/geradas/casa-jardim.png','corners':[[150,864],[697,1128],[1245,866]],'label':'Casa térrea · jardim'},
        'neighbor-south':{'source':'art/overworld/kits/urbano/fontes/geradas/casa-ecologica.png','corners':[[150,864],[697,1128],[1245,866]],'label':'Casa ecológica · painéis solares'}
    }
    manifest={'version':3,'method':'single affine projection shared by two depth facade planes','models':{}}
    for id,entry in models.items():
        if 'edges' in entry:
            # Intersect the actual wall/floor directions. The projecting window
            # planter is a separate volume, not the main building corner.
            a,b=entry['edges'][0];c,d=entry['edges'][1]
            m0=(b[1]-a[1])/(b[0]-a[0]);m1=(d[1]-c[1])/(d[0]-c[0])
            x=(c[1]-a[1]+m0*a[0]-m1*c[0])/(m0-m1)
            entry['corners']=[a,[x,a[1]+m0*(x-a[0])],d]
        original=SOURCE/(id+'-original.png')
        if not original.exists():
            path=Path(entry['source']);path=path if path.is_absolute() else ROOT/path
            shutil.copy2(path,original)
        image=Image.open(original).convert('RGBA')
        alpha=image.getchannel('A').point(lambda a:0 if a<160 else a)
        bounds=alpha.getbbox();image.putalpha(alpha)
        image=image.crop(bounds)
        factor=min(1.0,768/max(image.size))
        image=image.resize((round(image.width*factor),round(image.height*factor)),Image.Resampling.LANCZOS)
        canvas=Image.new('RGBA',(image.width+16,image.height+16))
        canvas.alpha_composite(image,(8,8))
        for base in [ART,GAME]:
            (base/'buildings').mkdir(parents=True,exist_ok=True)
            canvas.save(base/'buildings'/f'{id}.png')
        corners=[[(p[0]-bounds[0])*factor+8,(p[1]-bounds[1])*factor+8] for p in entry['corners']]
        manifest['models'][id]={'sourceFoundationEdges':entry.get('edges'), 'file':f'buildings/{id}.png','size':list(canvas.size),'groundCorners':corners,'name':entry['label'],'source':str(original.relative_to(ROOT)),'sourceGroundCorners':entry['corners'],'opaqueCrop':list(bounds),'normalization':'tight alpha crop, maximum 768px, 8px transparent gutter; no repaint or palette flattening'}
    for base in [ART,GAME]:(base/'architecture.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Five painted building assets and ground calibration saved.')
if __name__=='__main__':main()
