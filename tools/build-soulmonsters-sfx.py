"""Original deterministic DSP sound library; no third-party samples or game mutation."""
from pathlib import Path
import hashlib
import html
import json
import math
import subprocess
import wave
import numpy as np
from scipy import signal

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'godot/assets/audio/sfx-v1'
ART = ROOT / 'art/sfx-study-v1'
SR = 48000
EVENTS = []

SOURCES = {
    'ui': 'godot/scripts/campaign/front_end.gd · _button / _pause_game / _resume_game / _show_settings',
    'dialogue': 'godot/scripts/campaign/front_end.gd · _advance / _dialog / _confirmation',
    'progress': 'godot/scripts/campaign/progression.gd · discover / acquire / award; session.gd · commit_operation',
    'inventory': 'godot/scripts/campaign/front_end.gd · _show_bag / _show_collection / _show_tail_workshop; exploration.gd · equip / repair',
    'world': 'godot/scripts/campaign/room_view.gd · _process / _safe; park_view.gd · _physics_process / _interact; exploration.gd · chest / collect_tail; overworld/fruit_tree.gd · hit / fruit_landed',
    'workshop': 'godot/scripts/campaign/workshop_model.gd · place_rod / hold_knot / release_knot / cut_at / hold_soul / release_soul / _finish / _lose',
    'battle': 'godot/scripts/campaign/encounter_model.gd · damage_applied / combat_feedback / _move_fighter / _signature_hit / _strike; morro_model.gd · _finish_round / _new_round',
    'creature': 'godot/scripts/campaign/encounter_view.gd · configure / _draw; workshop_birth_view.gd · nascimento',
    'ambience': 'godot/scripts/overworld/ · starter_neighborhood / cave_water / cave_waterfall / lava_showcase / pier_play; areas are not all campaign-enabled',
}

def add(group, key, title, recipe, dur, variants=1, notes='', state='existing', pitch=1.0):
    EVENTS.append(dict(id=f'{group}.{key}', category=group, title=title, recipe=recipe,
        duration_requested=dur, variants=variants, notes=notes, action_status=state,
        source=SOURCES[group], pitch=pitch))

def define():
    for key,title,recipe,dur in [
        ('focus','Mover foco','tick',.07),('confirm','Confirmar','confirm',.22),
        ('cancel','Voltar','cancel',.19),('open','Abrir painel','page_open',.25),
        ('close','Fechar painel','page_close',.2),('deny','Ação indisponível','deny',.2),
        ('tab','Trocar aba','tick',.1),('slider','Ajustar opção','tick',.065),
        ('pause','Pausar','pause',.28),('resume','Retomar','resume',.3),
        ('warning','Confirmação destrutiva','warning',.42),('map','Abrir mapa','page_open',.4),
    ]: add('ui',key,title,recipe,dur,2 if key in ['focus','confirm','cancel'] else 1)
    for key,title,recipe,dur in [
        ('open','Iniciar conversa','dialogue',.2),('advance','Avançar fala','tick',.08),
        ('choice','Escolher resposta','confirm',.22),('end','Encerrar conversa','cancel',.26),
        ('blip','Pulso de texto opcional','blip',.045),
    ]: add('dialogue',key,title,recipe,dur,3 if key=='blip' else 1, 'Não tocar a cada caractere; limitar a 8 Hz, desligável.' if key=='blip' else '')
    for key,title,recipe,dur in [
        ('save_ok','Gravação confirmada','save',.5),('save_error','Falha ao gravar','deny',.4),
        ('objective','Objetivo recebido','objective',.8),('quest_complete','Objetivo concluído','reward',1.2),
        ('item','Item recebido','pickup',.35),('coins','Moedas recebidas','coins',.42),
        ('xp','XP concedido','xp',.35),('level_up','Subiu de nível','level',1.3),
        ('discovery','Espécie descoberta','discovery',.9),('area','Área descoberta','area',1.0),
        ('tutorial','Exercício concluído','objective',.65),
    ]: add('progress',key,title,recipe,dur,2 if key in ['item','coins','xp'] else 1,'Disparar somente após operação confirmada; não ao iniciar gravação.')
    for key,title,recipe,dur in [
        ('bag','Abrir bolsa','bag',.3),('equip','Equipar parceiro','equip',.45),
        ('unequip','Retirar equipamento','cancel',.25),('inspect','Inspecionar parceiro','dialogue',.22),
        ('repair_start','Iniciar reparo','repair',.8),('repair_done','Reparo concluído','heal',1.4),
        ('tail_restore','Restaurar rabiola','repair',.9),('consume','Usar consumível','pickup',.45),
    ]: add('inventory',key,title,recipe,dur,notes='',state='future' if key in ['unequip','consume'] else 'existing')
    for key,title,recipe,dur,n in [
        ('step_stone','Passo em pedra/calçada','stone',.19,5),('step_soil','Passo em terra','soil',.22,5),
        ('step_grass','Passo em grama','grass',.25,5),('step_wood','Passo em madeira/escada','wood',.22,5),
        ('grass_rustle','Atravessar matinho','rustle',.45,3),('door_open','Abrir porta','door',.65,2),
        ('door_close','Fechar porta','door_close',.4,2),('stairs','Contato no degrau','wood',.2,3),
        ('chest_open','Abrir baú','chest',.8,2),('tail_pickup','Recolher rabiola','paper_pickup',.6,2),
        ('tree_hit','Bater na árvore','tree',.45,3),('canopy','Balanço da copa','rustle',.9,3),
        ('fruit_fall','Fruto soltando','fruit_fall',.4,2),('fruit_land','Fruto no chão','fruit',.3,3),
        ('transition','Trocar de área','transition',.65,1),('interact','Interagir','dialogue',.14,1),
        ('splash','Passo em água rasa','splash',.45,3),
    ]: add('world',key,title,recipe,dur,n,state='future' if key=='splash' else 'existing',notes='Passos por distância percorrida, não por tecla; sem som contra parede.' if key.startswith('step') else '')
    for key,title,recipe,dur,n in [
        ('select_tail','Escolher rabiola','paper_pickup',.45,2),('select_frame','Escolher gabarito','wood',.25,2),
        ('rod_place','Encaixar vareta','bamboo',.22,3),('rod_fail','Vareta fora do encaixe','wood_fail',.25,2),
        ('knot_pull','Tensionar nó','twang',.38,3),('knot_good','Nó correto','knot',.3,3),
        ('paper_cut','Recortar papel','paper_cut',.36,4),('paper_tear','Rasgar papel por erro','tear',.5,3),
        ('gust','Rajada no teste','gust',.7,3),('balance','Retomar equilíbrio','balance',.4,2),
        ('soul_charge','Carregar elo','soul',1.5,1),('stage_done','Etapa concluída','stage',.65,1),
        ('birth','Nascimento do parceiro','birth',2.4,1),('abort','Cancelar montagem','page_close',.45,1),
        ('restock','Repor materiais','bag',.5,2),
    ]: add('workshop',key,title,recipe,dur,n)
    for key,title,recipe,dur,n in [
        ('encounter','Encontro selvagem','encounter',.85,1),('launch','Lançar pipa','launch',.7,3),
        ('round_start','Início de rodada','round',.75,1),('attack','Ataque sem confirmar dano','swing',.25,4),
        ('line_hit','Acertou a linha','line_hit',.28,4),('hull_hit','Dano na estrutura','hull',.38,4),
        ('critical','Acerto crítico','critical',.48,3),('line_snap','Linha rompida','snap',.5,3),
        ('hull_break','Estrutura quebrada','break',.75,3),('pull','Puxão de linha','pull',.6,3),
        ('dodge','Esquiva ativada','dodge',.3,3),('evade','Golpe evitado','evade',.35,2),
        ('guard','Guarda de 0,5 s','guard',.5,2),('block','Golpe bloqueado','block',.35,3),
        ('counter','Janela de contra-ataque','counter',.45,2),('energy_ready','Energia suficiente','ready',.35,1),
        ('no_energy','Sem energia','deny',.18,1),('cooldown_ready','Recarga concluída','ready',.24,1),
        ('signature_charge','Preparação de assinatura','charge',1.5,1),('signature_banner','Entrada do banner','banner',.55,1),
        ('signature_rabbito','Rabbito · Pulo do Elo','rabbit',1.0,2),
        ('signature_nozinho','Nozinho · proposta de nó de vento','knot_special',1.1,2),
        ('signature_lacertubo','Lacertubo · pressão tubular','pvc',1.35,2),
        ('boss_intro','Entrada do Lacertubo','boss',1.8,1),('boss_phase','Mudança de fase','phase',1.15,1),
        ('low_line','Linha em estado crítico','low',.5,1),('victory','Vitória','victory',1.9,1),
        ('defeat','Derrota','defeat',1.4,1),('flee','Fuga concluída','flee',.75,1),
    ]: add('battle',key,title,recipe,dur,n,notes='Alerta discreto: intervalo mínimo 6 s; não depender apenas de áudio.' if key=='low_line' else '',state='legacy_or_proposed' if key=='signature_nozinho' else 'existing')
    for i,(key,title,pitch) in enumerate([
        ('rabbito','Rabbito',1.3),('carcara','Carcará',.9),('azulao','Azulão',1.15),
        ('mata','Mata Verde',.75),('raio','Raio de Sol',1.45),('lacertubo','Lacertubo',.48),
    ]): add('creature',key,'Chamado · '+title,'creature',.7 if key!='lacertubo' else 1.0,3, 'Voz estilizada sintética provisória, não gravação nem design vocal aprovado.',pitch=pitch)
    for key,title,recipe in [
        ('wind','Vento de campo','wind'),('leaves','Folhagem','leaves'),('water','Água corrente','water'),
        ('cave','Ar de caverna','cave'),('lava','Borbulhar vulcânico','lava'),('coast','Água do cais','coast'),
    ]: add('ambience',key,title,recipe,12,1,'Loop procedural periódico; não contém música nem pessoas.',state='showcase_or_campaign')

def env(t, attack=.004, decay=.13):
    return np.minimum(t/max(attack,1e-5),1)*np.exp(-t/max(decay,1e-5))

def band(rng,n,low,high):
    x = rng.standard_normal(n)
    return signal.sosfilt(signal.butter(2,[low,high],btype='bandpass',fs=SR,output='sos'),x)

def tone(t,f,fend=None):
    if fend is None: return np.sin(2*np.pi*f*t)
    return np.sin(2*np.pi*(f*t+(fend-f)*t*t/(2*max(t[-1],1e-5))))

def place(dst,src,start):
    at=max(0,round(start*SR)); count=min(len(src),len(dst)-at)
    if count>0:dst[at:at+count]+=src[:count]

def notes(t,frequencies,spacing,decay=.12):
    result=np.zeros(len(t))
    for i,f in enumerate(frequencies):
        u=t-i*spacing
        gate=u>=0
        result+=np.where(gate,(np.sin(2*np.pi*f*u)+.18*np.sin(2*np.pi*2*f*u))*env(np.maximum(0,u),.003,decay),0)
    return result

def render(event,variation):
    key=event['recipe']; duration=event['duration_requested']
    seed=int.from_bytes(hashlib.sha256((event['id']+str(variation)).encode()).digest()[:8],'little')
    rng=np.random.default_rng(seed); t=np.arange(round(duration*SR))/SR; n=len(t)
    p=event['pitch']*(1+rng.uniform(-.035,.035))
    hi=band(rng,n,1500,11000); mid=band(rng,n,350,3500); lo=band(rng,n,45,550)
    x=np.zeros(n)
    seq={
        'confirm':[740,1110], 'cancel':[660,440], 'deny':[175,164], 'warning':[330,311,330],
        'pause':[440,330], 'resume':[330,440], 'dialogue':[580,735], 'save':[660,880,1320],
        'objective':[440,660,740], 'reward':[523,659,784,1047], 'pickup':[880,1320],
        'coins':[1568,2093,1760], 'xp':[440,554,659], 'level':[523,659,784,1047,1318],
        'discovery':[392,587,740,880], 'area':[440,554,659,880], 'equip':[370,740,1110],
        'heal':[392,494,587,784,988], 'balance':[660,880], 'stage':[587,740,880],
        'round':[392,587,784], 'counter':[784,1175], 'ready':[880,1320],
        'victory':[523,659,784,1047,784,1318], 'defeat':[440,392,311,261],
    }
    if event['id'].startswith('world.step_'):
        # Soft sole contact, not the pitched impact used by props and UI.
        low, high = {'stone': (160, 2100), 'soil': (100, 1300),
                     'grass': (220, 2600), 'wood': (85, 1600)}[key]
        body = band(rng, n, 55, rng.uniform(300, 440))
        contact = band(rng, n, low, high * rng.uniform(.85, 1.08))
        x = .8 * body * env(t, .007, rng.uniform(.021, .034))
        x += .36 * contact * env(t, .006, rng.uniform(.018, .032))
        u = np.maximum(0, t - rng.uniform(.025, .043))
        x += (.14 if key == 'grass' else .08) * contact * env(u, .009, .025)
        if key == 'wood':
            x += .08 * tone(t, rng.uniform(110, 155)) * env(t, .006, .025)
        x = signal.sosfilt(signal.butter(2, 2800, fs=SR, output='sos'), x)
    elif key in seq:
        spacing=min(.16,duration/(len(seq[key])+1))
        x=notes(t,[f*p for f in seq[key]],spacing,max(.055,duration/4))
        x+=.08*hi*env(t,.001,.028)
    elif key in ['tick','blip']:
        x=(tone(t,1100*p,850*p)+.22*hi)*env(t,.001,.018 if key=='blip' else .025)
    elif key in ['page_open','page_close','bag','paper_pickup']:
        x=(hi*.65+mid*.35)*np.sin(np.pi*t/duration)**2*(.6+.4*np.sin(2*np.pi*27*t))
        x+=.25*tone(t,(480 if key in ['page_open','paper_pickup'] else 700)*p,(900 if key in ['page_open','paper_pickup'] else 350)*p)*env(t,.01,.08)
    elif key in ['stone','soil','grass','wood','bamboo','wood_fail','fruit','tree','door_close']:
        base={'stone':720,'soil':150,'grass':260,'wood':240,'bamboo':990,'wood_fail':180,'fruit':110,'tree':125,'door_close':95}[key]*p
        x=.8*tone(t,base,base*.68)*env(t,.001,.032)
        x+=.4*tone(t,base*2.71)*env(t,.001,.043)
        noise=hi if key in ['grass','stone'] else mid if key in ['soil','bamboo'] else lo
        x+=noise*env(t,.002,.045 if key!='grass' else .08)
        if key in ['grass','soil']:x+=.55*hi*env(np.maximum(0,t-.045),.003,.035)*(t>.045)
        if key in ['wood','tree']:x+=.2*tone(t,base*4.3)*env(t,.001,.1)
    elif key in ['rustle','paper_cut','tear']:
        speed={'rustle':17,'paper_cut':42,'tear':80}[key]
        x=(hi+.2*mid)*(.3+.7*np.maximum(0,np.sin(2*np.pi*speed*t+np.sin(2*np.pi*7*t))))*np.sin(np.pi*t/duration)**1.4
        if key=='tear':x+=.55*mid*env(t,.001,.08)
    elif key in ['door','chest']:
        x=.4*mid*env(t,.002,.08)+.65*tone(t,110*p,65*p)*env(t,.002,.09)
        x+=.4*tone(t,430*p,580*p)*np.sin(np.pi*t/duration)**2*(.5+.5*np.sin(2*np.pi*33*t))
        if key=='chest':x+=.35*notes(t,[784,1047],.25,.15)
    elif key in ['twang','knot','line_hit','snap','pull']:
        f={'twang':260,'knot':420,'line_hit':520,'snap':650,'pull':175}[key]*p
        for h in range(1,7):x+=tone(t,f*h,f*h*.83)*env(t,.001,.14/(h**.5))/h
        x+=.45*hi*env(t,.001,.015 if key=='snap' else .035)
        if key=='pull':x+=.5*mid*np.sin(np.pi*t/duration)**2
    elif key in ['gust','swing','dodge','evade','launch','flee','transition','banner']:
        envelope=np.sin(np.pi*t/duration)**(2 if key!='launch' else 1.3)
        x=(.45*mid+.5*hi+.15*lo)*envelope
        if key in ['evade','transition']:x+=.28*tone(t,300*p,1100*p)*envelope
        if key=='launch':x+=.3*tone(t,150*p,600*p)*envelope
    elif key in ['hull','critical','break','block','guard','repair']:
        x=.8*tone(t,145*p,65*p)*env(t,.001,.08)+.7*mid*env(t,.001,.075)
        if key in ['hull','break','repair']:
            for at in ([.04,.13,.23,.36] if key!='hull' else [.025,.08]):
                u=np.maximum(0,t-at); x+=.4*hi*env(u,.001,.035)*(t>=at)
        if key in ['guard','block']:
            for f in [730,1180,1930]:x+=.23*tone(t,f*p)*env(t,.002,.12)
            if key=='guard':x*=np.sin(np.pi*np.minimum(t/.5,1))**.3
        if key=='critical':x+=.6*notes(t,[1175,1568],.04,.14)
        if key=='repair':x+=.4*notes(t,[440,660,880],.18,.14)
    elif key in ['charge','soul','birth','encounter','boss','phase','rabbit','knot_special','pvc','low','fruit_fall','splash','creature']:
        if key in ['charge','soul']:
            x=(tone(t,180*p,1200*p)+.35*tone(t,362*p,1800*p))*(t/duration)**.8*np.sin(np.pi*t/duration)**.4
            x+=.3*hi*np.sin(np.pi*t/duration)**2
        elif key=='birth':
            x=notes(t,[392,494,587,784,988,1175],.21,.45)+.25*hi*np.sin(np.pi*t/duration)**2
        elif key in ['boss','phase']:
            x=.7*tone(t,100,40)*env(t,.02,.6)+lo*.7*np.sin(np.pi*t/duration)**1.3
            x+=.3*notes(t,[185,196,277],.22,.24)
        elif key=='encounter':
            x=notes(t,[554,587,740,1175],.12,.13)+.35*mid*np.sin(np.pi*t/duration)**2
        elif key=='rabbit':
            x=.55*tone(t,220*p,1100*p)*env(t,.003,.12)+.65*hi*np.sin(np.pi*t/duration)**3
            u=np.maximum(t-.55,0); x+=(t>=.55)*(.8*tone(u,160,60)+mid)*env(u,.001,.12)
        elif key=='knot_special':
            for at in [0,.16,.31]:
                u=np.maximum(t-at,0);x+=(t>=at)*tone(u,360+at*700,200)*env(u,.002,.16)
            x+=.5*hi*np.sin(np.pi*t/duration)**2
        elif key=='pvc':
            for f in [92,184,278,460]:x+=.35*tone(t,f*p,f*p*.6)*env(t,.012,.34)
            x+=lo*np.sin(np.pi*t/duration)**1.3+.35*mid*env(t,.002,.09)
        elif key=='low':x=notes(t,[330,294],.22,.08)
        elif key=='fruit_fall':x=.6*tone(t,600*p,150*p)*np.sin(np.pi*t/duration)**2+.25*hi*env(t,.02,.08)
        elif key=='splash':x=(mid+hi)*env(t,.004,.09)+.3*tone(t,440,140)*env(t,.008,.13)
        elif key=='creature':
            base=360*p
            phase=2*np.pi*np.cumsum(base*(1+.3*np.sin(2*np.pi*4*t)))/SR
            x=(np.sin(phase+1.1*np.sin(phase*.5))+.25*np.sin(phase*2.02))*np.sin(np.pi*t/duration)**1.3
            x+=.12*hi*np.sin(np.pi*t/duration)**2
    elif key in ['wind','leaves','water','cave','lava','coast']:
        # Circular FFT filtering: endpoints are adjacent samples of a periodic signal.
        freq=np.fft.rfftfreq(n,1/SR)
        spectrum=np.fft.rfft(rng.standard_normal(n))
        low,high={'wind':(45,1000),'leaves':(900,7500),'water':(180,6500),'cave':(28,250),'lava':(35,900),'coast':(90,4200)}[key]
        shape=(1-np.exp(-(freq/max(low,1))**2))*np.exp(-(freq/high)**2)
        shape[0]=0
        x=np.fft.irfft(spectrum*shape,n)
        x*=.65+.15*np.sin(2*np.pi*2*t/duration)+.15*np.sin(2*np.pi*5*t/duration)
        if key in ['water','lava']:
            for _ in range(16):
                at=rng.uniform(0,duration-.2); u=np.maximum(t-at,0)
                x+=.15*(t>=at)*tone(u,rng.uniform(90,500),80)*env(u,.004,.06)
    else:raise ValueError(key)
    if not np.isfinite(x).all() or np.max(np.abs(x))<1e-8:raise ValueError(event['id'])
    if event['category']!='ambience':
        fade=min(240,n//4);x[:fade]*=np.linspace(0,1,fade);x[-fade:]*=np.linspace(1,0,fade)
    peak={'ui':-13,'dialogue':-19,'progress':-7,'inventory':-9,'world':-12,'workshop':-10,'battle':-7,'creature':-12,'ambience':-21}[event['category']]
    if event['id'].startswith('world.step_'): peak = -18 - rng.uniform(0, 2)
    x=x/np.max(np.abs(x))*10**(peak/20)
    return x

def write_wav(path,x):
    path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR)
        w.writeframes((np.clip(x,-.9999,.9999)*32767).astype('<i2').tobytes())

def main():
    define(); ART.mkdir(parents=True,exist_ok=True)
    records=[]; reels={}
    for e in EVENTS:
        files=[]
        for i in range(e['variants']):
            x=render(e,i);path=OUT/e['category']/(e['id'].split('.')[1]+f'_{i+1:02}.wav')
            write_wav(path,x)
            files.append({'path':'res://'+path.relative_to(ROOT/'godot').as_posix(),
                'seconds':round(len(x)/SR,4),'sample_peak_dbfs':round(20*math.log10(max(abs(x))),2)})
            if i==0:
                clip=x[:SR*3] if e['category']=='ambience' else x
                reels.setdefault(e['category'],[]).append((e['title'],clip))
        loop=e['category']=='ambience'
        bus='Ambience' if loop else 'UI' if e['category'] in ['ui','dialogue'] else 'SFX'
        records.append({**e,'files':files,'method':'original procedural DSP','bus':bus,
            'loop':loop,'integration_status':'mapped_asset_not_wired',
            'cooldown_ms':6000 if e['id']=='battle.low_line' else 80 if e['category']=='ui' else 100,
            'max_voices':1 if loop else 4,'pitch_variation':0 if loop or e['recipe'] in ['victory','defeat','level'] else .025,
            'review_status':'technical_pass_listening_pending'})
    manifest={'version':1,'sample_rate':SR,'channels':1,'encoding':'PCM16 WAV',
        'events':records,'event_count':len(records),'file_count':sum(len(e['files']) for e in records),
        'sources':'Original mathematical oscillators, filtered seeded noise and envelopes. No sampled commercial game audio.',
        'technical_review':'Finite signals, non-silence, conservative sample peaks, PCM decode. Musical/perceptual quality requires listening.',
        'note':'Mapped hooks indicate candidate consumers, not implemented wiring. Existing/future status refers to the action, not audio integration.'}
    (OUT/'catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (ART/'catalog.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    preview=ART/'previews';preview.mkdir(exist_ok=True)
    cue_manifest={}
    ff=ROOT/'tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
    for group,items in reels.items():
        pieces=[];at=0; cues=[]
        for title,x in items:
            cues.append({'at_seconds':round(at,3),'title':title})
            pieces.extend([x,np.zeros(round(SR*.45))]);at+=len(x)/SR+.45
        wav=preview/(group+'.wav');write_wav(wav,np.concatenate(pieces))
        subprocess.run([str(ff),'-nostdin','-hide_banner','-loglevel','error','-y','-i',str(wav),'-c:a','libmp3lame','-b:a','160k',str(preview/(group+'.mp3'))],check=True)
        cue_manifest[group]=cues
    (preview/'cues.json').write_text(json.dumps(cue_manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    rows=['# Mapa de eventos sonoros V1','', 'Pontos de conexão são propostas derivadas dos consumidores; nenhum evento está conectado automaticamente.','', '| Evento | Ação | Situação da ação | Arquivos | Conexão sugerida |','| --- | --- | --- | --- | --- |']
    for e in records:rows.append(f"| `{e['id']}` | {e['title']} | {e['action_status']} | {len(e['files'])} | {e['source']} |")
    (ART/'mapa-de-acoes.md').write_text('\n'.join(rows)+'\n',encoding='utf-8')
    build_board(records)
    print(json.dumps({'events':manifest['event_count'],'files':manifest['file_count'],'path':str(OUT)},indent=2))

def build_board(records):
    data=[]
    for e in records:
        item={k:e[k] for k in ['id','category','title','notes','method','loop','action_status']}
        item['files']=['../../godot/'+f['path'].removeprefix('res://') for f in e['files']]
        data.append(item)
    page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soulmonsters · biblioteca sonora</title><style>body{margin:32px auto;padding:0 20px;max-width:1120px;background:#101c29;color:#f0e9d5;font:16px system-ui}h1{font-size:32px}p{line-height:1.5;color:#b6c9ce}input,select,button{padding:10px;border:1px solid #668187;border-radius:6px;background:#203747;color:#fff}input{width:40%}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px;margin-top:20px}article{padding:16px;border:1px solid #395564;border-radius:8px}small{display:block;color:#8ac9ca;margin:8px 0}audio{width:100%}label{display:block;margin-top:12px}button{cursor:pointer}#stop{background:#744335}h2{font-size:18px}</style><h1>Soulmonsters · efeitos V1</h1><p>Biblioteca de efeitos originais. Estes arquivos estão mapeados, ainda sem conexão automática às ações do jogo. Alterne as variações e compare. Chamados dos parceiros são estudos provisórios.</p><input id="search" placeholder="Buscar ação ou evento" aria-label="Buscar"><select id="category" aria-label="Categoria"><option value="">Todas as categorias</option></select> <button id="stop">Parar todos</button><p id="count"></p><div id="grid"></div><script>const events=DATA;const grid=document.querySelector('#grid'), search=document.querySelector('#search'),cat=document.querySelector('#category');for(const c of [...new Set(events.map(e=>e.category))]){const o=document.createElement('option');o.value=c;o.textContent=c;cat.append(o)}function render(){grid.replaceChildren();const selected=events.filter(e=>(!cat.value||e.category===cat.value)&&(e.id+' '+e.title).toLowerCase().includes(search.value.toLowerCase()));document.querySelector('#count').textContent=selected.length+' eventos';for(const e of selected){const card=document.createElement('article'),h=document.createElement('h2'),s=document.createElement('small'),a=document.createElement('audio');h.textContent=e.title;s.textContent=e.id+' · '+e.method+(e.loop?' · loop':'');a.controls=true;a.preload='none';a.src=e.files[0];card.append(h,s,a);if(e.files.length>1){const sel=document.createElement('select');sel.setAttribute('aria-label','Variação de '+e.title);e.files.forEach((f,i)=>{const o=document.createElement('option');o.value=f;o.textContent='Variação '+(i+1);sel.append(o)});sel.onchange=()=>{a.pause();a.src=sel.value};card.append(sel)}if(e.notes){const p=document.createElement('p');p.textContent=e.notes;card.append(p)}grid.append(card)}}search.oninput=render;cat.onchange=render;document.querySelector('#stop').onclick=()=>document.querySelectorAll('audio').forEach(a=>{a.pause();a.currentTime=0});document.addEventListener('play',ev=>document.querySelectorAll('audio').forEach(a=>{if(a!==ev.target)a.pause()}),true);render();</script></html>'''
    (ART/'ouvir.html').write_text(page.replace('DATA',json.dumps(data,ensure_ascii=False).replace('</','<\\/')),encoding='utf-8')

if __name__=='__main__':main()
