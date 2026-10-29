"""Local reference-conditioned ACE-Step arrangement; no paid nodes or model downloads."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import requests
import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/opening-theme-v1'
BASE = 'http://127.0.0.1:8188'
FF = ROOT / 'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
SOURCE = Path('C:/Users/user/Downloads/o-vento-nos-chamou-v1.mp3')

def prepare():
    ART.mkdir(exist_ok=True)
    (ART / 'workflows').mkdir(exist_ok=True)
    raw = subprocess.run([str(FF), '-v', 'error', '-i', str(SOURCE), '-f', 'f32le', '-ac', '1', '-ar', '12000', '-'], capture_output=True, check=True).stdout
    y = np.frombuffer(raw, dtype='<f4')
    f, t, z = signal.stft(y, fs=12000, nperseg=2048, noverlap=1536)
    mag = np.abs(z)
    flux = np.maximum(np.diff(mag, axis=1), 0).sum(axis=0)
    corr = signal.correlate(flux-flux.mean(), flux-flux.mean(), mode='full')[len(flux)-1:]
    rate = 12000/512
    candidates = [(float(corr[lag]), 60*rate/lag) for lag in range(round(rate*60/170), round(rate*60/80)+1)]
    bpm = round(max(candidates)[1])
    valid = (f > 65) & (f < 2000)
    pitches = np.mod(np.round(69+12*np.log2(f[valid]/440)).astype(int), 12)
    chroma = np.bincount(pitches, weights=np.mean(mag[valid]**2, axis=1), minlength=12)
    major = np.array([6.35,2.23,3.48,2.33,4.38,4.09,2.52,5.19,2.39,3.66,2.29,2.88])
    minor = np.array([6.33,2.68,3.52,5.38,2.6,3.53,2.54,4.75,3.98,2.69,3.34,3.17])
    names = ['C','C#','D','Eb','E','F','F#','G','Ab','A','Bb','B']
    keys = [(float(np.corrcoef(chroma, np.roll(profile, i))[0,1]), names[i]+' '+quality) for profile,quality in [(major,'major'),(minor,'minor')] for i in range(12)]
    key = max(keys)[1]
    # Use a whole 32-bar reference excerpt at the estimated pulse.
    seconds = min(128*60/bpm, len(y)/12000)
    clip = ART / 'reference-32-bars.wav'
    subprocess.run([str(FF), '-nostdin', '-v', 'error', '-y', '-i', str(SOURCE), '-t', str(seconds), '-ar', '48000', '-ac', '2', str(clip)], check=True)
    analysis = dict(source=SOURCE.name, sha256=hashlib.sha256(SOURCE.read_bytes()).hexdigest(), duration_seconds=len(y)/12000,
                    estimated_bpm=bpm, estimated_key=key, estimate_warning='Spectral/autocorrelation estimates, not a transcription or listening judgment.',
                    key_candidates=sorted(keys, reverse=True)[:4], excerpt_start_seconds=0, excerpt_seconds=seconds,
                    reference_use='Audio-to-audio latent conditioning; melody retention and absence of voice require listening.')
    (ART/'reference-analysis.json').write_text(json.dumps(analysis, indent=2), encoding='utf-8')
    print(json.dumps(analysis, indent=2))

def submit():
    analysis = json.loads((ART/'reference-analysis.json').read_text())
    with (ART/'reference-32-bars.wav').open('rb') as file:
        upload = requests.post(BASE+'/upload/image', files={'image': ('soulmonsters-vento-reference.wav', file, 'audio/wav')}, data={'type':'input','overwrite':'false'}, timeout=90)
    upload.raise_for_status()
    uploaded = upload.json()
    filename = '/'.join(p for p in [uploaded.get('subfolder',''),uploaded['name']] if p)
    tracks = [
        ('01-vento-menu', .76, 28102841, 'Instrumental Japanese adventure role-playing game title screen arrangement of the provided theme. Replace the sung melody with a clear warm solo flute and rounded celesta answering its phrases. Preserve the reference melodic contour, chord motion and rhythmic identity as much as possible. Light pizzicato bass, soft piano chords, restrained brushed snare, small bell accents like sunlight on kite paper. Nostalgic hopeful friendship and a new journey, melodic and memorable, transparent four-part handheld game arrangement. Gentle playable menu music, moderate dynamics, no cinematic crescendo, no pop rock wall, no electric guitar solo. Absolutely instrumental: no singing, speech, humming, choir or vocal chops. Short introduction, recognizable main theme early, contrasting answer, return to theme and a short turnaround. Clean dry samples, soft high frequencies, no fadeout.'),
        ('02-vento-aventura', .84, 28102842, 'Instrumental monster-adventure RPG opening theme arranged from the supplied song. Transfer the vocal melody into bright clear sampled clarinet and a small warm trumpet, keeping the reference phrase contours, chord movement and sense of adventure. Tuneful sampled-game style, light marimba arpeggios, independently moving plucked bass, crisp but quiet snare and acoustic kick, occasional short strings answering only in melody gaps. Youthful soaring paper-kite journey, hopeful and heartfelt with a wistful middle section. Sparse readable voices, singable hook in the foreground, no ambient wash, no EDM drop or rock distortion. No singer, words, humming, choir, breaths or vocal chops: melody performed entirely by instruments. Brief pickup, main theme, contrasting bridge, return and a concise turnaround, no fadeout.'),
    ]
    jobs=[]
    for track, denoise, seed, prompt in tracks:
        graph={
            '1': {'class_type':'UNETLoader','inputs':{'unet_name':'acestep_v1.5_turbo.safetensors','weight_dtype':'default'}},
            '2': {'class_type':'DualCLIPLoader','inputs':{'clip_name1':'qwen_0.6b_ace15.safetensors','clip_name2':'qwen_1.7b_ace15.safetensors','type':'ace','device':'default'}},
            '3': {'class_type':'VAELoader','inputs':{'vae_name':'ace_1.5_vae.safetensors'}},
            '4': {'class_type':'LoadAudio','inputs':{'audio':filename}},
            '5': {'class_type':'VAEEncodeAudio','inputs':{'audio':['4',0],'vae':['3',0]}},
            '6': {'class_type':'TextEncodeAceStepAudio1.5','inputs':{'clip':['2',0],'tags':prompt,'lyrics':'[Instrumental]','seed':seed,'bpm':analysis['estimated_bpm'],'duration':analysis['excerpt_seconds'],'timesignature':'4','language':'unknown','keyscale':analysis['estimated_key'],'generate_audio_codes':False,'cfg_scale':2.0,'temperature':.85,'top_p':.9,'top_k':0,'min_p':0.0}},
            '7': {'class_type':'ConditioningZeroOut','inputs':{'conditioning':['6',0]}},
            '8': {'class_type':'ModelSamplingAuraFlow','inputs':{'model':['1',0],'shift':3.0}},
            '9': {'class_type':'KSampler','inputs':{'model':['8',0],'seed':seed,'steps':12,'cfg':1.0,'sampler_name':'euler','scheduler':'simple','positive':['6',0],'negative':['7',0],'latent_image':['5',0],'denoise':denoise}},
            '10': {'class_type':'VAEDecodeAudio','inputs':{'samples':['9',0],'vae':['3',0]}},
            '11': {'class_type':'SaveAudio','inputs':{'audio':['10',0],'filename_prefix':'Soulmonsters/opening-theme-v1/'+track}},
        }
        (ART/'workflows'/(track+'-api.json')).write_text(json.dumps(graph,indent=2), encoding='utf-8')
        response=requests.post(BASE+'/prompt',json={'prompt':graph,'client_id':'soulmonsters-opening-theme'},timeout=90)
        if response.status_code != 200: raise RuntimeError(response.text)
        jobs.append(dict(id=track,prompt_id=response.json()['prompt_id'],seed=seed,denoise=denoise,prompt=prompt))
        print(json.dumps(jobs[-1]))
        (ART/'jobs.json').write_text(json.dumps(jobs,indent=2),encoding='utf-8')

def collect():
    for job in json.loads((ART/'jobs.json').read_text()):
        hist=requests.get(BASE+'/history/'+job['prompt_id'],timeout=30).json().get(job['prompt_id'])
        if not hist:
            print(job['id']+': pending'); continue
        (ART/(job['id']+'-history.json')).write_text(json.dumps(hist,indent=2),encoding='utf-8')
        if hist['status']['status_str'] != 'success':
            print(json.dumps(hist['status'])); continue
        for out in hist['outputs'].values():
            for file in out.get('audio',[]):
                result=requests.get(BASE+'/view',params=file,timeout=90)
                result.raise_for_status()
                target=ART/(job['id']+Path(file['filename']).suffix)
                target.write_bytes(result.content)
                print(str(target))

def package():
    target = ROOT/'godot/assets/audio/music/opening-theme-v1'
    target.mkdir(parents=True, exist_ok=True)
    records=[]
    for source_name, game_name in [('01-vento-menu','vento-menu'),('02-vento-aventura','vento-aventura')]:
        source=ART/(source_name+'.flac')
        # Conservative playback master, with short endpoint fades to avoid clicks.
        scan=subprocess.run([str(FF),'-nostdin','-hide_banner','-i',str(source),'-af','loudnorm=I=-22:TP=-2:LRA=9:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
        measured=json.JSONDecoder().raw_decode(scan.stderr[scan.stderr.rfind('{'):])[0]
        normalizer=('loudnorm=I=-22:TP=-2:LRA=9:linear=true:measured_I='+measured['input_i']+
                    ':measured_TP='+measured['input_tp']+':measured_LRA='+measured['input_lra']+
                    ':measured_thresh='+measured['input_thresh']+':offset='+measured['target_offset'])
        info=subprocess.run([str(FF),'-v','error','-i',str(source),'-f','f32le','-ac','2','-ar','48000','-'],capture_output=True,check=True)
        x=np.frombuffer(info.stdout,dtype='<f4').reshape(-1,2)
        seconds=len(x)/48000
        filters=normalizer+f',afade=t=in:d=0.012,afade=t=out:st={max(0,seconds-.025)}:d=0.025'
        preview=ART/(source_name+'.mp3')
        game=target/(game_name+'.ogg')
        for path, codec in [(preview,['-c:a','libmp3lame','-b:a','192k']), (game,['-c:a','libvorbis','-q:a','5'])]:
            subprocess.run([str(FF),'-nostdin','-v','error','-y','-i',str(source),'-af',filters,'-ar','48000']+codec+[str(path)],check=True)
        records.append(dict(id=source_name,seconds=seconds,reference_conditioned=True,
                            preview=preview.relative_to(ROOT).as_posix(),game=game.relative_to(ROOT).as_posix(),
                            source_loudness_measurement=measured,requested_master_lufs=-22,requested_true_peak_db=-2,
                            notes='Full decode, loudness analysis, endpoint anti-click fades; perceptual listening and musical loop continuity pending.'))
    manifest=dict(tool='ACE-Step 1.5 Turbo local audio-to-audio, 12 steps',reference='o-vento-nos-chamou-v1.mp3',
                  reference_uploaded_to='ComfyUI on this computer only',paid_api=False,tracks=records,
                  integrated='Native title/menu and prologue after TV film; preview arrangement pending listening approval',
                  limitations=['Not a verified note-for-note transcription','Instrumental requested; absence of residual voice not certified by listening','Loop repetition enabled, musical seam requires listening'])
    (ART/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>O Vento Nos Chamou · jogo</title><style>body{max-width:760px;margin:60px auto;padding:24px;background:#101c29;color:#f0e9d5;font:18px system-ui;line-height:1.6}audio{width:100%}section{margin:32px 0;padding:24px;background:#203747;border-radius:12px}p{color:#b6c9ce}</style><h1>O Vento Nos Chamou</h1><p>Duas propostas instrumentais para o jogo, geradas localmente com o MP3 como referência de áudio. A semelhança melódica, possíveis resíduos de voz e a emenda do loop ainda precisam de escuta.</p><section><h2>01 · Menu / início da jornada</h2><audio controls src="01-vento-menu.mp3"></audio></section><section><h2>02 · Aventura / prólogo</h2><audio controls src="02-vento-aventura.mp3"></audio></section><p>As duas já estão conectadas como primeira proposta no cliente Godot. Volume em Configurações → Áudio → Música. A música da cinemática da TV foi preservada.</p><script>document.addEventListener('play',e=>document.querySelectorAll('audio').forEach(a=>{if(a!==e.target)a.pause()}),true)</script></html>'''
    (ART/'ouvir.html').write_text(page,encoding='utf-8')
    print(json.dumps(records,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('action',choices=['prepare','submit','collect','package'])
    {'prepare':prepare,'submit':submit,'collect':collect,'package':package}[parser.parse_args().action]()
