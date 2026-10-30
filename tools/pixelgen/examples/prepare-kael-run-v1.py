"""Reproducible local-only H3 run cycles. Never calls a paid API node."""
from pathlib import Path
import argparse, json, shutil, urllib.request, uuid

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'art/characters/kael-locomotion-v1'
DIRS=['s','sw','w','nw','n','ne','e','se']
ALIASES=dict(zip(DIRS,['S','SO','O','NO','N','NE','E','SE']))
VIEWS={
 's':'FRONT view, facing directly DOWN towards viewer. Both eyes remain visible.',
 'sw':'FRONT LEFT three-quarter view, facing DOWN LEFT. Keep this exact yaw.',
 'w':'strict LEFT SIDE profile, facing LEFT. Never turn around.',
 'nw':'BACK LEFT three-quarter view, facing UP LEFT. Back of head and jacket dominate.',
 'n':'strict BACK view facing UP, away from viewer. Never show the eyes or face.',
 'ne':'BACK RIGHT three-quarter view, facing UP RIGHT. Back of head and jacket dominate.',
 'e':'strict RIGHT SIDE profile, facing RIGHT. Never turn around.',
 'se':'FRONT RIGHT three-quarter view, facing DOWN RIGHT. Keep this exact yaw.'}
BASE='http://127.0.0.1:8188'

def request(path, data=None, content_type='application/json'):
    req=urllib.request.Request(BASE+path, data=data, headers={'Content-Type':content_type})
    with urllib.request.urlopen(req,timeout=30) as r:return json.load(r)

def prepare():
    for name in ['references','workflows','video-original','selections','aseprite','review']:(OUT/name).mkdir(parents=True,exist_ok=True)
    plan=[]
    for index,d in enumerate(DIRS):
        source=ROOT/'art/characters/kael-video-eight-directions-v1/referencias'/f'kael-angle-{ALIASES[d]}-v1.png'
        if d=='e':source=ROOT/'art/characters/kael-video-sprite-v1/referencia.png'
        ref=OUT/'references'/f'kael-rest-{d}.png';shutil.copyfile(source,ref)
        graph=json.loads((ROOT/'art/characters/kael-video-sprite-v1/minimax-local-api.json').read_text(encoding='utf-8'))
        prompt=('Animate ONE original Kael pixel-art game sprite matching the supplied character EXACTLY. '+VIEWS[d]+' '
          'RUN IN PLACE continuously for six complete repeating run cycles, like an athletic teenager jogging on an invisible treadmill. '
          'This is a RUN, not a faster walk: torso leans 10 degrees forward in the facing direction, elbows bent, compact arm pump, '
          'opposite arm and leg, visible knee lift and heel recovery, contact-compression-push-flight alternating between legs. '
          'Include a short flight with both feet off the ground in every step. The head stays stable and the feet contact one fixed ground line. '
          'Same head, face, hairstyle, anatomy and body scale throughout, centered in the same canvas. No character translation or rotation. '
          'Keep swept navy blue hair, blue jacket with ivory sleeve stripes and narrow long jacket straps, black shirt, cyan headphones, '
          'GRAY trousers with the black thigh band, dark boots and ivory soles. The trousers stay exactly the same gray in every frame. '
          'Readable flat 2D manga pixel clusters, crisp outlines, no anti-aliased paint or 3D. Restrained jacket tail follow-through. '
          'Uniform vivid MAGENTA #ff00ff everywhere outside the sprite. No floor, no shadow, no scenery, no text, no glow, no blur, '
          'no smearing, no camera movement, no extra characters, no added equipment. Silent. End on the same cycle phase as the start.')
        graph['5']['inputs']['image']=ref.name
        graph['8']['inputs']['prompt']=prompt
        graph['11']['inputs']['noise_seed']=3010202600+index
        graph['18']['inputs']['filename_prefix']='Pixelgen/Kael_run_'+d+'_v1'
        path=OUT/'workflows'/f'run-{d}-local.json';path.write_text(json.dumps(graph,ensure_ascii=False,indent=2),encoding='utf-8')
        (OUT/'workflows'/f'run-{d}-prompt.txt').write_text(prompt,encoding='utf-8')
        plan.append({'direction':d,'reference':str(ref.relative_to(OUT)),'workflow':str(path.relative_to(OUT)),'status':'prepared'})
    (OUT/'jobs.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
    return plan

def submit(directions):
    plan=json.loads((OUT/'jobs.json').read_text(encoding='utf-8'))
    schema=request('/object_info');queue=request('/queue')
    if queue.get('queue_running') or queue.get('queue_pending'):raise RuntimeError('Existing ComfyUI queue: do not overlap other work.')
    for job in plan:
        if job['direction'] not in directions or job.get('prompt_id'):continue
        graph=json.loads((OUT/job['workflow']).read_text(encoding='utf-8'))
        if any(n['class_type'] not in schema or 'API' in n['class_type'] for n in graph.values()):raise RuntimeError('Invalid or external API node')
        ref=OUT/job['reference'];boundary=uuid.uuid4().hex
        body=(f'--{boundary}\r\nContent-Disposition: form-data; name="image"; filename="{ref.name}"\r\nContent-Type: image/png\r\n\r\n'.encode()+ref.read_bytes()+f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="overwrite"\r\n\r\ntrue\r\n--{boundary}--\r\n'.encode())
        upload=request('/upload/image',body,'multipart/form-data; boundary='+boundary)
        graph['5']['inputs']['image']=(upload.get('subfolder','')+'/' if upload.get('subfolder') else '')+upload['name']
        response=request('/prompt',json.dumps({'prompt':graph,'client_id':'pixelgen-kael-locomotion-v1'}).encode())
        if response.get('node_errors'):raise RuntimeError(response['node_errors'])
        job.update(prompt_id=response['prompt_id'],status='queued')
        (OUT/'jobs.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
        print(json.dumps({'direction':job['direction'],'prompt_id':job['prompt_id']}),flush=True)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--submit',nargs='*');p.add_argument('--prepare',action='store_true');a=p.parse_args()
    if a.prepare:prepare();print('Prepared 8 directional run graphs, local model only.')
    if a.submit is not None:submit(a.submit or DIRS)
