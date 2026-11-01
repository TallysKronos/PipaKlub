import fs from 'node:fs/promises';import path from 'node:path';import {execFileSync} from 'node:child_process';
const base=process.argv[2],out=path.resolve('art/concepts/montaria-doberman/animation-v1'),manifest=path.join(out,'manifest.json'),ffmpeg=path.resolve('tmp/video-encoder/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe');
if(!base)throw Error('Local ComfyUI URL required.');
const labels={s:'Sul',sw:'Sudoeste',w:'Oeste',nw:'Noroeste',n:'Norte',ne:'Nordeste',e:'Leste',se:'Sudeste'};
async function gallery(m){const jobs=m.shots.filter(s=>s.action!=='idle'),count=jobs.filter(s=>s.status==='completed').length,done=jobs.every(s=>['completed','error','failed'].includes(s.status));
 const cards=jobs.map(s=>{const video=s.outputs?.find(f=>f.endsWith('.mp4'));return '<article><h2>'+({walk:'Caminhada',run:'Corrida'})[s.action]+' · '+labels[s.direction]+'</h2>'+(video?'<video controls loop muted playsinline preload="metadata" src="'+video+'"></video>':'<img src="'+s.reference+'" alt="Referência editada">')+'<p>'+({prepared:'Preparado',submitted:'Na fila / gerando',completed:'Vídeo gerado · revisar',error:'Falhou',failed:'Falhou'})[s.status]+'</p>'+(s.review?.state==='needs-background-correction'?'<p>Revisão: fundo variando; corrigir antes de extrair os sprites.</p>':'')+'</article>';}).join('');
 await fs.writeFile(path.join(out,'index.html'),'<!doctype html><html lang="pt-BR"><meta charset="utf-8">'+(!done?'<meta http-equiv="refresh" content="30">':'')+'<title>Montaria · animações editadas</title><style>body{margin:0;background:#10202a;color:#e6edf0;font:16px system-ui}header{padding:28px;max-width:1100px;margin:auto}h1{font-size:28px}p{color:#a9c0c9}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:18px;max-width:1200px;padding:24px;margin:auto}article{background:#1b303c;border:1px solid #3d606e;border-radius:12px;padding:14px}h2{font-size:18px}video,img{width:100%;border-radius:8px}strong{color:#79dfd5}</style><header><h1>Kael + montaria</h1><p><strong>'+count+' / '+jobs.length+' vídeos gerados</strong> · MiniMax H3 local · referências com seus retoques</p><p>Vídeos em revisão. Fundo magenta será removido na preparação dos sprites. Os arquivos ativos do jogo continuam preservados.</p></header><main>'+cards+'</main></html>');}
let errors=0;while(true){try{
 let m=JSON.parse(await fs.readFile(manifest));
 for(const shot of m.shots.filter(s=>s.promptId&&!['completed','error','failed'].includes(s.status))){
  const r=await fetch(new URL('/history/'+shot.promptId,base),{signal:AbortSignal.timeout(15000)});if(!r.ok)throw Error('ComfyUI history unavailable');const h=await r.json(),history=h[shot.promptId];if(!history)continue;
  execFileSync(process.execPath,['tools/soulgen-studio/run-mount-motion.mjs',base,'collect',shot.id],{stdio:'inherit'});
  if(history.status?.completed){try{execFileSync(ffmpeg,['-hide_banner','-loglevel','error','-i',path.join(out,'video-original',shot.id+'.mp4'),'-vf','fps=2,scale=256:256,tile=5x2','-frames:v','1','-update','1','-y',path.join(out,'review',shot.id+'-contact.png')],{stdio:'pipe'});}catch(e){console.error('Contact preview failed:',shot.id);}}
 }
 m=JSON.parse(await fs.readFile(manifest));await gallery(m);errors=0;const active=m.shots.filter(s=>s.action!=='idle');if(active.every(s=>['completed','error','failed'].includes(s.status)))break;
 }catch(e){console.error(e.message);if(++errors>=3)throw e;}
 await new Promise(r=>setTimeout(r,20000));
}
console.log('All submitted mount clips collected; gallery updated.');
