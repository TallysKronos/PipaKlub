"""PIP-87: generated landmark cutouts, existing anchors, authored composition."""
from pathlib import Path
import json,shutil
from PIL import Image
from build_art import studio,scale_board
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/overworld/kits/morro'
RUNTIME=ROOT/'godot/assets/overworld/kits/morro'
def write(path,data):path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def main():
    k=json.loads((ART/'kit.json').read_text(encoding='utf-8'))
    for asset,name,height in [('banca-pipas','banca',112),('toldo-bandeirolas','toldo',128)]:
        entry=k['pieces'][asset]['variants']['default']
        im=Image.open(ART/f'fontes/marcos-v2/{name}.png').convert('RGBA')
        im.putalpha(im.getchannel('A').point(lambda a:0 if a<160 else a))
        box=im.getchannel('A').getbbox();im=im.crop(box)
        factor=min(height/im.height,(entry['size'][0]-4)/im.width)
        im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.LANCZOS)
        out=Image.new('RGBA',tuple(entry['size']))
        out.alpha_composite(im,(entry['anchor'][0]-im.width//2,entry['anchor'][1]-im.height))
        entry['file']=f'pecas/{asset}-v2.png';out.save(ART/entry['file'])
        entry.update({'rasterSize':list(im.size),'source':{'file':f'fontes/marcos-v2/{name}.png','tool':'image_gen.imagegen','normalization':'alpha halo cleanup, tight crop, uniform fit; existing anchor and footprint preserved'},'approval':'pending_native_visual_review'})
        shutil.copy2(ART/entry['file'],RUNTIME/entry['file'])
    k['context'].update({'automaticTrees':False,'houses':False,'radius':6,'role':'quiet background; all visible houses from authored source lots'})
    k['automaticLotTrees']=False
    k['automaticYardFurniture']=False
    k['automaticLotSmall']=False
    k['composition']={
        'morro-praca-da-chegada':{'houses':[6,7,8,9,10,11,14,23]},
        'morro-escadaria-da-sombra':{'houses':[3,4,5,6,8,9,16,17]},
        'morro-laje-dos-ventos':{'houses':[3,4,5,7,9,19,16,24]},
        'morro-mirante-da-caixa-dagua':{'houses':[3,4,6,7,9,15,16,17]},
        'morro-parque-dos-ventos':{'houses':[3,5,6,7,9,10,16]}}
    k['compositionRevision']='PIP-87 authored houses; no random tree or rooftop furniture fill; original footprints and navigation unchanged'
    write(ART/'kit.json',k);write(RUNTIME/'kit.json',k)
    studio(k);scale_board(k)
    print('Morro: two new landmark cutouts, five authored house selections, no automatic forest backdrop.')
if __name__=='__main__':main()
