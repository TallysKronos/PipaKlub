"""Prepare isolated, visually identified directions for the proven local H3 graph."""
from pathlib import Path
import importlib.util
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-video-eight-directions-v1'
spec=importlib.util.spec_from_file_location('video_sheet',ROOT/'tools/pixelgen/video-to-sheet.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
DIRECTIONS=['S','SO','O','NO','N','NE','E','SE']
# Actual visual inspection, not the order requested in the generation prompt.
CELLS={'S':0,'SO':1,'E':2,'NO':3,'N':4,'NE':5,'O':6,'SE':7}
DESCRIPTIONS={
 'S':'FRONT view facing directly toward the viewer, body facing screen DOWN. Both eyes and both cyan earcups visible; no profile or back view.',
 'SO':'FRONT-LEFT THREE-QUARTER view facing diagonally toward the viewer and screen LEFT. Preserve this exact front-left yaw.',
 'O':'strict LEFT SIDE PROFILE facing screen LEFT, the opposite view to the earlier right-facing clip. Only the nearer eye is visible.',
 'NO':'REAR-LEFT THREE-QUARTER view facing diagonally away from viewer and screen LEFT. Back of jacket and back of hair dominate; do not turn face toward camera.',
 'N':'strict BACK view facing directly away from the viewer, body facing screen UP. NO eyes or face visible at any time. Show jacket back and back of hair.',
 'NE':'REAR-RIGHT THREE-QUARTER view facing diagonally away from viewer and screen RIGHT. Back of jacket and hair dominate; do not turn toward camera.',
 'SE':'FRONT-RIGHT THREE-QUARTER view facing diagonally toward viewer and screen RIGHT. Preserve this exact front-right yaw.'}

def main():
 for folder in ['referencias','workflows','video-original','selecoes']:(OUT/folder).mkdir(parents=True,exist_ok=True)
 sheet=Image.open(OUT/'referencias/prancha-original.png').convert('RGB');w,h=sheet.size
 plan=[]
 for d in DIRECTIONS:
  if d=='E':
   plan.append({'direction':d,'status':'reused','video':'../kael-video-sprite-v1/video-original/2ee8f5c1_000.mp4','start':1.1666667,'duration':1.1666667});continue
  cell=CELLS[d];x,y=cell%4,cell//4
  crop=sheet.crop((x*w//4,y*h//2,(x+1)*w//4,(y+1)*h//2));keyed=module.key_image(crop);bbox=keyed.getchannel('A').getbbox()
  sprite=keyed.crop(bbox);scale=400/sprite.height;size=(round(sprite.width*scale),400)
  frame=Image.new('RGB',(512,512),'#ff00ff');sprite=sprite.resize(size,Image.Resampling.NEAREST);frame.paste(sprite,((512-size[0])//2,460-size[1]),sprite)
  reference=OUT/'referencias'/f'kael-angle-{d}-v1.png';frame.save(reference)
  g=json.loads((ROOT/'art/characters/kael-video-sprite-v1/minimax-local-api.json').read_text(encoding='utf-8'))
  g['5']['inputs']['image']=reference.name
  prompt=('Animate ONE original Kael game sprite, matching this directional reference exactly. '+DESCRIPTIONS[d]+' '
   'Locked orthographic camera, no zoom, no yaw, no perspective change. Same head size, hair silhouette and body height throughout. '
   'The character walks IN PLACE with four natural complete alternating gait cycles over five seconds, then ends on the starting stance. '
   'Readable foot contact, bent swing knee, passing pose and toe push-off, arms counter-swinging opposite the legs. Feet stay on the SAME ground line and inside frame. '
   'No translation toward or away from camera: WALKING ON A TREADMILL with invisible treadmill, fixed scale and fixed canvas center. '
   'Maintain exactly the clean pixel-cluster anime sprite style of reference: navy swept hair, blue jacket with thin ivory sleeve stripes and hanging ivory-trimmed straps, black shirt, cyan headphones around neck, gray trousers and dark boots with ivory soles. '
   'Rear views retain the same outfit from behind; do not invent a backpack, hood over head or extra hair spikes. '
   'Solid uniform vivid magenta #ff00ff background for every pixel outside character, no floor, no shadow, no scenery. '
   'No speech, text, gradient, glow, motion blur, smearing, duplicate figures, turning, 3D, live action, camera motion or costume transformation. Silent.')
  g['8']['inputs']['prompt']=prompt;g['11']['inputs']['noise_seed']=2910202700+DIRECTIONS.index(d)
  g['18']['inputs']['filename_prefix']=f'Pixelgen/Kael_walk_{d}_angles_v1'
  workflow=OUT/'workflows'/f'walk-{d}-local.json';workflow.write_text(json.dumps(g,ensure_ascii=False,indent=2),encoding='utf-8')
  plan.append({'direction':d,'reference':str(reference.relative_to(OUT)),'referenceCell':cell,'sourceBox':list(bbox),'referenceScale':scale,'workflow':str(workflow.relative_to(OUT)),'status':'prepared','start':1.1666667,'duration':1.1666667})
 (OUT/'jobs.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'prepared':[j['direction'] for j in plan if j['status']=='prepared'],'reuse':['E'],'size':[512,512],'length':124,'steps':16}))

if __name__=='__main__':main()
