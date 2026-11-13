"""Prepare identity-preserving H3 experiments; no videos or runtime assets replaced."""
from pathlib import Path
from PIL import Image
import json, hashlib, copy, csv
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/creatures/overworld-video-v2'
for name in ['references','workflows','video-original','review']:(OUT/name).mkdir(parents=True,exist_ok=True)
manifest=OUT/'queue.json'
previous=json.loads(manifest.read_text(encoding='utf-8')) if manifest.exists() else {'jobs':[],'uploads':{}}
old={j['id']:j for j in previous['jobs']}
anatomies={e['id']:e['anatomy'] for e in json.loads((ROOT/'art/creatures/overworld-animacoes-v1/anatomias.json').read_text(encoding='utf-8'))}
anatomies['azulfazo']='voador'
# Papisco's approved child pose is upright; Velcao is its quadruped young form.
anatomies['papisco']='bipede'
assets=json.loads((ROOT/'art/creatures/soulmonsters-overworld-v2/manifest.json').read_text(encoding='utf-8'))['assets']
template=json.loads((ROOT/'art/concepts/montaria-doberman/animation-v1/workflows/walk-sw.json').read_text(encoding='utf-8'))
template['8']['inputs'].update(width=384,height=384,length=56,ref_image_size='match')
template['13']['inputs']['steps']=12
(OUT/'template-api.json').write_text(json.dumps(template,indent=2),encoding='utf-8')
motions={
 'bipede':'one complete alternating biped walk cycle IN PLACE: left foot contact, knee bends, passing pose, right foot contact, toe push-off. Arms counter-swing. Real changing joint poses, stable torso volume.',
 'quadrupede':'one complete natural four-legged walking cycle IN PLACE. Four attached legs alternate footfalls, bend at shoulders, hips and knees, swing through and plant. Clear passing poses, subtle shoulder weight shift, tail follows.',
 'voador':'one complete wingbeat cycle while travelling IN PLACE. Articulated wing roots, folded recovery and spread downstroke, feather or paper tips lag. Preserve both wings, body and tail; no spinning.',
 'serpentino':'one complete serpentine slithering cycle IN PLACE. A travelling curve passes through the flexible body, head held steady, base and tail follow. Preserve body thickness and original silhouette identity.',
 'nadador':'one complete swimming cycle IN PLACE. Fins and tail articulate and propel, head stays stable, preserve all fins and volume. No water or scenery in background.',
 'multipatas':'one complete crawling cycle IN PLACE, alternating support groups of attached legs with real bent joints and lifted feet. Preserve original leg count and body volume.',
 'pequeno':'one complete small-creature locomotion cycle IN PLACE. Articulate the existing tiny feet, fins or appendages, with a passing pose and gentle weight transfer; never invent limbs absent in reference.'}
jobs=[]
priority={'alvacordo':0,'papisco':1,'azulfazo':2,'anaconda-young':3,'viuva-young':4}
for asset in sorted(assets,key=lambda a:(priority.get(a['id'],10),a['id'])):
    id=asset['id'];anatomy=anatomies[id]
    source=ROOT/'art/creatures/soulmonsters-overworld-v2'/id/'duas-vistas.png'
    image=Image.open(source).convert('RGBA');sha=hashlib.sha256(source.read_bytes()).hexdigest()
    colors=[c[:3] for c in set(image.getdata()) if c[3]]
    bg=max([(255,0,255),(0,255,0),(0,255,255)],key=lambda candidate:min(sum((a-b)**2 for a,b in zip(candidate,c)) for c in colors))
    hexbg='#'+''.join(f'{v:02x}' for v in bg)
    for view,row in [('sw',0),('nw',1)]:
        cell=image.crop((row*112,0,(row+1)*112,112));box=cell.getbbox();cut=cell.crop(box)
        scale=max(1,min(268//cut.height,336//cut.width));size=(cut.width*scale,cut.height*scale)
        x=(384-size[0])//2;y=324-size[1]
        reference=Image.new('RGB',(384,384),bg);enlarged=cut.resize(size,Image.Resampling.NEAREST);reference.paste(enlarged,(x,y),enlarged)
        ref=f'references/{id}-{view}.png';reference.save(OUT/ref)
        for action in ['walk','idle']:
            key=f'{id}/{action}/{view}'
            if key in old and old[key].get('source_sha256')==sha and old[key].get('prompt_id'):
                jobs.append(old[key]);continue
            movement=motions[anatomy] if action=='walk' else 'One calm idle cycle: breathe through the chest with subtle living posture changes, blink once only if visible eyes exist, appendages settle with delayed follow-through. Ground contacts remain planted, do not walk or bounce the entire figure.'
            facing='FRONT LEFT THREE QUARTER facing southwest toward the viewer and screen LEFT' if view=='sw' else 'REAR LEFT THREE QUARTER facing northwest away from the viewer and screen LEFT; keep the back visible, never turn toward the camera'
            prompt=f'Animate exactly ONE Soulmonsters creature from this single reference. {facing}. {movement} Clean 2D manga pixel-sprite appearance, same colors and distinctive anatomy as reference. Preserve head shape, face, ears, limbs, ornaments, tail attachment and proportions throughout. Fixed slightly elevated isometric camera, constant scale and position, no rotation, no camera movement. Full body and appendages visible with margins. Complete the cycle within this short clip and return to the reference pose. Background remains one perfectly flat chroma color {hexbg}; no floor, shadow or scenery. Silent. No text, speech, glow, motion blur, duplicates, new limbs, melting, costume change, gradients, 3D or photorealism. Movement must come from new articulated poses, not warping a still cutout.'
            jobs.append(dict(id=key,creature=id,action=action,view=view,anatomy=anatomy,status='prepared',profile='fast-pilot',reference=ref,source_sha256=sha,source_box=list(box),reference_scale=scale,reference_origin=[x,y],reference_background=hexbg,native_cell=[112,112],native_anchor=[56,100],native_height=asset['height'],width=384,height=384,frames=56,fps=24,steps=12,seed=int(hashlib.sha256(key.encode()).hexdigest()[:8],16),prompt=prompt))
data=dict(version=2,local_only=True,profile_status='experimental: benchmark before bulk submission',model=template['1']['inputs']['unet_name'],duration_seconds=56/24,trained_range_note='live node reports trained range ~124–362 frames;56 is supported but below it',total_creatures=194,total_jobs=len(jobs),mirror={'se':'sw','ne':'nw'},uploads=previous.get('uploads',{}),jobs=jobs)
manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
with (OUT/'lista.csv').open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=['id','creature','anatomy','action','view','status','width','height','frames','steps','elapsed_seconds','review_status']);writer.writeheader();writer.writerows({k:j.get(k,'') for k in writer.fieldnames} for j in jobs)
print(json.dumps({'creatures':194,'jobs':len(jobs),'profile':'384x384 / 56frames /12steps','runtime_replaced':False}))
