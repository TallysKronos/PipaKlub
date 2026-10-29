"""Add local Stable Audio textures, verify WAV assets and package the listening library."""
from pathlib import Path
import importlib.util
import json
import math
import subprocess
import wave
import zipfile
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'art/sfx-study-v1'
OUT=ROOT/'godot/assets/audio/sfx-v1'
FF=ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'

def main():
    spec=importlib.util.spec_from_file_location('sfx_builder',ROOT/'tools/build-soulmonsters-sfx.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    catalog=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
    catalog['events']=[e for e in catalog['events'] if e['category']!='texture']
    prompts=json.loads((ART/'texture-prompts.json').read_text(encoding='utf-8'))
    jobs={j['id']:j['prompt_id'] for j in json.loads((ART/'texture-jobs.json').read_text(encoding='utf-8'))}
    clips=[]
    for t in prompts['textures']:
        source=next((ART/'ai-originals'/t['id']).glob('*.flac'))
        result=subprocess.run([str(FF),'-nostdin','-hide_banner','-loglevel','error','-i',str(source),'-f','f32le','-ac','1','-ar','48000','pipe:1'],capture_output=True,check=True)
        x=np.frombuffer(result.stdout,dtype='<f4').astype(np.float64)
        if not len(x) or not np.isfinite(x).all() or np.max(np.abs(x))<1e-6:raise RuntimeError('Silent/invalid '+t['id'])
        peak=float(np.max(np.abs(x)))
        x=x/peak*10**(-12/20)
        fade=min(960,len(x)//4);x[:fade]*=np.linspace(0,1,fade);x[-fade:]*=np.linspace(1,0,fade)
        target=OUT/'texture'/(t['id']+'_01.wav');builder.write_wav(target,x)
        clips.extend([x[:4*48000],np.zeros(24000)])
        catalog['events'].append({'id':'texture.'+t['id'],'title':t['title'],'category':'texture',
            'notes':'Textura gerada para escuta e recorte; não é um one-shot isolado nem loop final aprovado.',
            'method':'Stable Audio Open 1.0 via ComfyUI local','prompt':t['prompt'],'seed':t['seed'],'prompt_id':jobs[t['id']],
            'original':str(source.relative_to(ROOT)),'workflow':f'art/sfx-study-v1/workflows/texture-{t["id"]}.json',
            'action_status':'layer_candidate','source':'Workshop and overworld materials; audition before layering',
            'files':[{'path':'res://'+target.relative_to(ROOT/'godot').as_posix(),'seconds':round(len(x)/48000,4),'sample_peak_dbfs':-12}],
            'bus':'Ambience' if t['id'] not in ['paper','bamboo'] else 'SFX','loop':False,
            'cooldown_ms':500,'max_voices':1,'pitch_variation':0,
            'integration_status':'mapped_asset_not_wired','review_status':'technical_pass_listening_pending'})
    catalog['event_count']=len(catalog['events']);catalog['file_count']=sum(len(e['files']) for e in catalog['events'])
    catalog['sources']='209 original procedural DSP files plus six locally generated Stable Audio Open textures. No commercial game samples.'
    catalog['model_source']='https://huggingface.co/Comfy-Org/stable-audio-open-1.0'
    for file in [OUT/'catalog.json',ART/'catalog.json']:file.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
    builder.build_board(catalog['events'])
    reel=ART/'previews/textures.wav';builder.write_wav(reel,np.concatenate(clips))
    subprocess.run([str(FF),'-nostdin','-hide_banner','-loglevel','error','-y','-i',str(reel),'-c:a','libmp3lame','-b:a','160k',str(reel.with_suffix('.mp3'))],check=True)
    report=[]
    for e in catalog['events']:
        for f in e['files']:
            path=ROOT/'godot'/f['path'].removeprefix('res://')
            with wave.open(str(path),'rb') as w:
                if w.getframerate()!=48000 or w.getnchannels()!=1 or w.getsampwidth()!=2:raise RuntimeError(str(path))
                values=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(np.float64)/32768
            if np.max(np.abs(values))<=0:raise RuntimeError('Silent '+str(path))
            report.append({'event':e['id'],'path':f['path'],'seconds':round(len(values)/48000,4),
                'sample_peak_dbfs':round(20*math.log10(np.max(np.abs(values))),2),
                'rms_dbfs':round(20*math.log10(max(1e-12,np.sqrt(np.mean(values**2)))) ,2)})
    (ART/'technical-review.json').write_text(json.dumps({'files_checked':len(report),'failures':0,
        'checks':['All catalog files exist','PCM16 mono 48 kHz','Full PCM read','Non-silence','Sample-peak and RMS measurements'],
        'not_checked':['Perceptual listening','True peak after mixing','Runtime event connections','Seamless AI ambience loops'],
        'files':report},ensure_ascii=False,indent=2),encoding='utf-8')
    mapping=ART/'mapa-de-acoes.md'
    text=mapping.read_text(encoding='utf-8').split('\n## Texturas locais')[0]
    text+='\n## Texturas locais\n\nTexturas complementares, pendentes de seleção e recorte por escuta.\n\n'
    for t in prompts['textures']:text+=f'- `texture.{t["id"]}`: {t["title"]}.\n'
    mapping.write_text(text,encoding='utf-8')
    package=ART/'soulmonsters-sfx-v1.zip'
    with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p.suffix!='.import':z.write(p,p.relative_to(ROOT).as_posix())
        for name in ['catalog.json','mapa-de-acoes.md','technical-review.json','texture-prompts.json','texture-jobs.json','README.md','ouvir.html']:
            p=ART/name
            if p.exists():z.write(p,p.relative_to(ROOT).as_posix())
        for folder in ['workflows','previews','ai-originals']:
            for p in (ART/folder).rglob('*'):
                if p.is_file():z.write(p,p.relative_to(ROOT).as_posix())
    print(json.dumps({'events':catalog['event_count'],'files':catalog['file_count'],'technical_failures':0,'zip':str(package)},indent=2))

if __name__=='__main__':main()
