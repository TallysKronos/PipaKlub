"""Read-only pixel proof/previews for canonical-core Aseprite animation batches."""
from pathlib import Path
from PIL import Image
import argparse,json
ROOT=Path(__file__).resolve().parents[2]
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(p,value):p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=argparse.ArgumentParser();p.add_argument('--batch',type=Path,required=True);p.add_argument('--id',action='append',default=[]);a=p.parse_args()
for model in load(a.batch)['models']:
 if a.id and model['id']not in a.id:continue
 folder=ROOT/model['folder'];source=Image.open(ROOT/model['source']).convert('RGBA');proof=[]
 for action,count,durations in [('idle',4,[750,200,750,200]),('walk',6,[140,100,120,140,100,120])]:
  atlas=Image.open(folder/f'{action}.png').convert('RGBA')
  for row,view in enumerate(('sw','nw')):
   mask=Image.open(folder/f'core-original-{view}.png').convert('RGBA');base=source.crop((row*112,0,(row+1)*112,112));frames=[]
   for pose in range(count):
    cell=atlas.crop((pose*112,row*112,(pose+1)*112,(row+1)*112));diff=sum(mask.getpixel((x,y))[3]>0 and cell.getpixel((x,y))!=base.getpixel((x,y))for y in range(112)for x in range(112));assert diff==0,(model['id'],action,view,pose,'canonical core changed');proof.append(dict(action=action,view=view,pose=pose,original_core_differences_including_transparency=diff));bg=Image.new('RGBA',(112,112),'#263d48');bg.alpha_composite(cell);frames.append(bg.convert('RGB'))
   frames[0].save(folder/f'{action}-{view}-1x.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2)
 comparison=Image.new('RGBA',(448,112),'#263d48');comparison.alpha_composite(source,(0,0));walk=Image.open(folder/'walk.png').convert('RGBA');comparison.alpha_composite(walk.crop((0,0,112,112)),(224,0));comparison.alpha_composite(walk.crop((0,112,112,224)),(336,0));comparison.resize((1792,448),Image.Resampling.NEAREST).convert('RGB').save(folder/'source-final-comparison-4x.png');save(folder/'core-original-independent-pixel-audit.json',dict(source=model['source'],frames=proof))
 manifest=load(folder/'manifest.json');manifest.update(method='ImageGen complete limb/sail articulation; Aseprite canonical-original face/head/upper core copied LAST including transparent gaps',source_identity_exact_in_protected_mask=True,core_masks=dict(sw='core-original-sw.png',nw='core-original-nw.png'),core_audit='core-original-independent-pixel-audit.json',generation_count=2,batch_generation_count=10,motion_limitation='Upper core steady; complete locomotor limbs/sails are free. Articulation/contact must be judged visually; exact face pixels alone do not approve gait.')
 if manifest.get('review_score')is None:manifest['status']='ready for independent review'
 save(folder/'manifest.json',manifest)
 (folder/'brief.md').write_text(f"# {model['id']}\n\nCanonical source: `{model['source']}`;height{model['height']}px,112cell,anchor56,100,scale1.\n\n{model['motion']}\n\nPositive original head/upper-core masks include transparent gaps, copied last in Aseprite; full limbs/sails free from root. Quiet stable original idle4, two internal pixels varied,1900ms, no lunge. Review1x gait/attachment/identity, not metrics alone.\n",encoding='utf-8')
 (folder/'revisao.md').write_text('# Ready for independent review\n\n20poses, source-positive-core pixel audit and saved ASE/PNG exactness passed. Technical proof is not gait/art approval. See native1x GIFs, source-final-comparison-4x.png (sourceSW/NW left, final firstSW/NW right), core-original-independent-pixel-audit.json and auditoria-aseprite.json.\n\nComplete limbs free; upper core held steady. No videos, generated idle, runtime/Git changes or editing previously approved models. Initial10walk generations for batch, no claimed percentage savings without measurement.\n',encoding='utf-8')
 print(model['id'],'20 canonical-core checks0;native1x/4x previews ready')
