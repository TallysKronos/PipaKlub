"""PIP-87 area-specific art; approved default atlas remains untouched."""
from refine_morro_facades import ART, RUNTIME
from build_morro_floors import periodic
from build_art import studio, scale_board
from PIL import Image
import json,copy,shutil
kit=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
cement=periodic(Image.open(ART/'fontes/identidade-v5/cimento-tom-ajustado.png'))
atlas=Image.open(ART/'chao/superficies-atlas.png').convert('RGB')
atlas.paste(cement,(1024,0));atlas.save(ART/'chao/laje-superficies-v5.png')
shutil.copy2(ART/'chao/laje-superficies-v5.png',RUNTIME/'chao/laje-superficies-v5.png')
entry=copy.deepcopy(kit['pieces']['varal']['variants']['default'])
im=Image.open(ART/'fontes/identidade-v5/varal-pipas.png').convert('RGBA')
im.putalpha(im.getchannel('A').point(lambda a:0 if a<192 else a))
im=im.crop(im.getchannel('A').getbbox());factor=min(112/im.height,124/im.width)
im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
canvas=Image.new('RGBA',tuple(entry['size']))
canvas.alpha_composite(im,(entry['anchor'][0]-im.width//2,entry['anchor'][1]-im.height))
entry.update(file='pecas/varal-pipas-v5.png',rasterSize=list(im.size),source={'file':'fontes/identidade-v5/varal-pipas.png','tool':'image_gen.imagegen','normalization':'alpha halo cleanup, tight crop, uniform fit, original pivot and collision'},approval='pending_owner_review')
canvas.save(ART/entry['file']);shutil.copy2(ART/entry['file'],RUNTIME/entry['file'])
kit['pieces']['varal']['variants']['pipas']=entry
kit['areaVisuals']={
 'morro-laje-dos-ventos':{'floorSurfaceFile':'chao/laje-superficies-v5.png','identity':'sunlit cement kite-making courtyard'},
 'morro-escadaria-da-sombra':{'canopyShadow':.28},
 'morro-parque-dos-ventos':{'canopyShadow':.13}}
for file in [ART/'kit.json',RUNTIME/'kit.json']:file.write_text(json.dumps(kit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
studio(kit);scale_board(kit)
# Diagnostic repeated material, not a runtime background painting.
board=Image.new('RGB',(1024,1024))
for x in range(2):
 for y in range(2):board.paste(cement,(x*512,y*512))
board.save(ART/'fontes/identidade-v5/cimento-repeticao-2x2.png')
