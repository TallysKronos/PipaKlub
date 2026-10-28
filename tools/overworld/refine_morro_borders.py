"""PIP-87 alternate entrance facades and a properly scaled overlook railing."""
from refine_morro_facades import ART, RUNTIME
from build_art import studio, scale_board
from PIL import Image
import json, copy, shutil
kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
def normalize(entry,source,destination,width):
    im=Image.open(ART/source).convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a:0 if a<192 else a))
    im=im.crop(im.getchannel('A').getbbox())
    factor=width/im.width
    im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',tuple(entry['size']))
    canvas.alpha_composite(im,(entry['anchor'][0]-im.width//2,entry['anchor'][1]-im.height))
    canvas.save(ART/destination);shutil.copy2(ART/destination,RUNTIME/destination)
    entry.update(file=destination,rasterSize=list(im.size),source={'file':source,'tool':'image_gen.imagegen','normalization':'threshold alpha halo; tight crop; uniform scale; existing canvas, anchor and collision'},approval='pending_owner_review')
for base in ['telha','laje','muro-chapisco']:
    name=base+'-direita'
    entry=copy.deepcopy(kit['pieces']['casa-morro']['variants'][base])
    entry['doorFace']='u+'
    normalize(entry,f'fontes/bordas-v4/{name}.png',f'pecas/casa-morro-{name}-v4.png',188)
    kit['pieces']['casa-morro']['variants'][name]=entry
    kit['pieces']['casa-morro']['variants'][base]['doorFace']='v+'
rail=kit['pieces']['mirante-guarda-corpo']['variants']['default']
rail['groundAnchor']='front'
normalize(rail,'fontes/bordas-v4/guarda-corpo-frontal.png','pecas/mirante-guarda-corpo-v4.png',122)
for file in [ART/'kit.json',RUNTIME/'kit.json']:file.write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
studio(kit);scale_board(kit)
