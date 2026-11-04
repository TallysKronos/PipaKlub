"""Prepare the authored starter neighborhood materials and source record."""
from pathlib import Path
import json, shutil
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/bairro-inicial-v2'
GAME=ROOT/'godot/assets/overworld/kits/bairro-inicial-v2'

def main():
    for base in [ART,GAME]: (base/'surfaces').mkdir(parents=True,exist_ok=True)
    record=json.loads((ART/'fontes/passeio-origem.json').read_text())
    original=ART/'fontes/passeio-original.png'
    if not original.exists():shutil.copy2(record['path'],original)
    image=Image.open(original).convert('RGB').resize((512,512),Image.Resampling.LANCZOS).quantize(colors=5,dither=Image.Dither.NONE).convert('RGB')
    pixels=np.array(image).copy()
    # Keep the source's flat painted shapes but make paving quieter than foliage.
    # The generated full-contrast patches otherwise read as bare mottled earth.
    mean=pixels.reshape(-1,3).mean(axis=0)
    pixels=np.clip((pixels.astype(float)-mean)*.32+np.array([201,193,168]),0,255).astype('uint8')
    for axis in [0,1]:
        if axis==0:
            edge=((pixels[0].astype(int)+pixels[-1].astype(int))//2).astype('uint8');pixels[0]=edge;pixels[-1]=edge
        else:
            edge=((pixels[:,0].astype(int)+pixels[:,-1].astype(int))//2).astype('uint8');pixels[:,0]=edge;pixels[:,-1]=edge
    for base in [ART,GAME]:Image.fromarray(pixels).save(base/'surfaces/passeio.png')
    sources={'asfalto':'rua-japonesa-v1/surfaces/asfalto.png','telhado':'rua-japonesa-v1/surfaces/telhado-manga.png','grama':'planicie-v1/surfaces/grama.png','pedra':'cais-v1/surfaces/rocha.png'}
    for name,source in sources.items():
        for base in [ART,GAME]:shutil.copy2(ROOT/'godot/assets/overworld/kits'/source,base/'surfaces'/f'{name}.png')
    record['normalization']='512px; five colors without dithering; 32% source contrast around warm concrete; shared opposite edge texels; original retained'
    record['reusedMaterials']=sources
    (ART/'fontes/producao.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Starter neighborhood materials prepared.')
if __name__=='__main__':main()
