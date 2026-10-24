import {STAGES,CLASSES,FLIGHT_TIME,ZONE,FALL,SOUL_ZONES,CENTER,geometry,createRun,restock,placeRod,wobbleAt,holdKnot,tickKnot,releaseKnot,cutAt,cutProgress,tickFlight,windAt,nextGust,holdSoul,tickSoul,releaseSoul,starsOf,gradeLabel,distToPath} from './model.mjs';
const $=id=>document.getElementById(id),cv=$('board'),g=cv.getContext('2d');
const PAPER={comum:'#e66b4f',incomum:'#2f9c96',raro:'#e8b23f'};
const TIPS=['Cada vareta vai do centro até uma ponta. Arraste do leque até o círculo pontilhado e solte.','Segure em cima do nó. O anel enche: solte quando estiver no verde. No vermelho a linha arrebenta.','Recorte pelo pontilhado, sem entrar na vela. Pode fazer em vários trechos.','O vento avisa antes: a seta mostra de onde vem a rajada. Arraste o cabresto para o lado contrário.','Agora é com você. Solte no Seguro para garantir. Se esperar o Brilho pode nascer uma variante rara… mas se passar, o elo parte.'];
const mesa=new Image();mesa.src='mesa.jpg';const rabbito=new Image();rabbito.src='rabbito.png';
let run,ui,last=performance.now();
function reset(){run=createRun($('kind').value,{artesao:$('artesao').checked,seed:Math.floor(Math.random()*1e6)});ui={pointer:{x:CENTER.x,y:CENTER.y},down:false,drag:null,cutLast:null,tears:[],pops:[],idle:0,t:0,anim:0,control:0,keys:{},seen:{},knob:false};$('result').hidden=true;$('blocked').hidden=true;hud();tip();}
// ---------- HUD ----------
function hud(){
 $('steps').replaceChildren(...STAGES.map((s,i)=>{const e=document.createElement('span');e.textContent=`${i+1} ${s.name}`;if(i===run.stage)e.className='now';else if(i<run.stage)e.className='done';return e;}));
 const m=run.materials;$('mats').innerHTML=`<b class="${m.linha<=1?'low':''}" title="Carretéis de linha">🧵 ${m.linha}</b><b class="${m.folha<=1?'low':''}" title="Folhas de papel">📄 ${m.folha}</b>`;
 const s=STAGES[run.stage],c=CLASSES[run.kind];let count='';
 if(run.stage===0)count=`${run.step.placed.length}/${c.rods}`;if(run.stage===1)count=`${run.step.tied.length}/${c.rods}`;if(run.stage===2)count=`${Math.round(cutProgress(run)*100)}%`;if(run.stage===3)count=`${Math.max(0,FLIGHT_TIME-run.step.t).toFixed(0)} s`;
 $('bubble').innerHTML=s?`${s.verb}${count?` · ${count}`:''}<small>${c.label} · ${c.shape}${run.artesao?' · modo artesão (+ nota, sem guias)':''}</small>`:'';$('bubble').hidden=!s;
 $('blocked').hidden=!run.blocked;if(run.blocked)$('blockedTitle').textContent=run.blocked==='linha'?'Acabou a linha':'Acabou o papel';}
function tip(){const i=run.stage;if(i>4||ui.seen[i]){$('tip').hidden=true;return;}$('tipText').textContent=TIPS[i]+(i===0&&CLASSES[run.kind].wobble?' Nesta classe a vareta balança: solte quando ela brilhar alinhada.':'');$('tip').hidden=false;}
$('tipOk').onclick=()=>{ui.seen[run.stage]=true;$('tip').hidden=true;cv.focus();};
function pop(text,x,y,color){ui.pops.push({text,x,y,color,life:1.1});}
const gradeColor=s=>s>=.85?'#4fbf7d':s>=.65?'#f0bd52':'#f7ead0';
function report(r,at=ui.pointer){if(!r)return;if(r.lost)pop(r.lost==='linha'?'−1 linha':'−1 folha',at.x,at.y-20,'#e2564a');if(r.msg)pop(r.msg,at.x,at.y-44,r.ok?'#f7ead0':'#ffd0c8');if(r.score!=null)pop(gradeLabel(r.score),at.x,at.y-20,gradeColor(r.score));if(r.grade!=null){pop(`${STAGES[run.stage-1]?.name}: ${gradeLabel(r.grade)}`,CENTER.x,90,gradeColor(r.grade));ui.anim=run.stage===3?1.2:0;}hud();if(r.done||r.grade!=null)tip();}
// ---------- entrada ----------
function point(e){const r=cv.getBoundingClientRect();return {x:(e.clientX-r.left)*960/r.width,y:(e.clientY-r.top)*640/r.height};}
const FAN={x:800,y:200};
cv.addEventListener('pointerdown',e=>{if(run.blocked||run.outcome)return;cv.setPointerCapture(e.pointerId);const p=point(e);ui.pointer=p;ui.down=true;ui.idle=0;ui.seen[run.stage]=true;$('tip').hidden=true;
 if(run.stage===0){if(p.x>720&&p.y>150&&p.y<450)ui.drag='rod';}
 if(run.stage===1){const pts=geometry(run.kind).points;const i=pts.findIndex((q,i)=>!run.step.tied.includes(i)&&Math.hypot(q.x-p.x,q.y-p.y)<46);if(i>=0)holdKnot(run,i);}
 if(run.stage===2){ui.cutLast=p;report(cutAt(run,p,0));}
 if(run.stage===3){ui.knob=true;ui.knobStart=p.x;}
 if(run.stage===4)holdSoul(run);hud();});
cv.addEventListener('pointermove',e=>{const p=point(e),prev=ui.pointer;ui.pointer=p;if(!ui.down)return;ui.idle=0;
 if(run.stage===2&&ui.cutLast){const d=Math.hypot(p.x-ui.cutLast.x,p.y-ui.cutLast.y),n=Math.max(1,Math.ceil(d/4)),dt=(e.timeStamp-(ui.cutTime||e.timeStamp))/1000/n;for(let k=1;k<=n;k++){const q={x:ui.cutLast.x+(p.x-ui.cutLast.x)*k/n,y:ui.cutLast.y+(p.y-ui.cutLast.y)*k/n},r=cutAt(run,q,Math.min(.1,dt));if(r?.warn){if(!ui.tears.length||Math.hypot(ui.tears.at(-1).x-q.x,ui.tears.at(-1).y-q.y)>10)ui.tears.push(q);}if(r&&!r.warn){if(r.torn)ui.tears=[];report(r,q);if(run.stage!==2)break;}}ui.cutLast=p;}
 ui.cutTime=e.timeStamp;if(run.stage===3&&ui.knob)ui.control=Math.max(-1,Math.min(1,(p.x-ui.knobStart)/140));});
const up=e=>{if(!ui.down)return;ui.down=false;const p=e?point(e):ui.pointer;
 if(run.stage===0&&ui.drag==='rod'){report(placeRod(run,p,wobbleAt(run.kind,ui.t)),p);}
 if(run.stage===1)report(releaseKnot(run),p);
 if(run.stage===2){ui.cutLast=null;ui.cutTime=null;}
 if(run.stage===3){ui.knob=false;ui.control=0;}
 if(run.stage===4){const r=releaseSoul(run);report(r,p);if(run.outcome)finish();}
 ui.drag=null;hud();};
cv.addEventListener('pointerup',up);cv.addEventListener('pointercancel',()=>{ui.down=false;ui.drag=null;ui.control=0;if(run.stage===1)run.step.holding=null;if(run.stage===4)run.step.holding=false;});
// Teclado: Espaço segura (nós, despertar) ou encaixa a próxima vareta; setas controlam o vento.
cv.addEventListener('keydown',e=>{if(e.repeat)return;if(e.key===' '){e.preventDefault();ui.idle=0;ui.seen[run.stage]=true;$('tip').hidden=true;
  if(run.stage===0){const r=geometry(run.kind).rods.find((_,i)=>!run.step.placed.includes(i));if(r)report(placeRod(run,r.mid,wobbleAt(run.kind,ui.t)),r.mid);}
  if(run.stage===1){const i=geometry(run.kind).points.findIndex((_,i)=>!run.step.tied.includes(i));holdKnot(run,i);ui.down=true;}
  if(run.stage===4){holdSoul(run);ui.down=true;}}
 if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();ui.keys[e.key]=1;}});
cv.addEventListener('keyup',e=>{if(e.key===' '&&ui.down&&(run.stage===1||run.stage===4))up();if(e.key in ui.keys)delete ui.keys[e.key];});
// ---------- desenho ----------
function rounded(x,y,w,h,r){g.beginPath();g.roundRect(x,y,w,h,r);}
function wood(x0,y0,x1,y1,w=9){g.save();g.lineCap='round';g.strokeStyle='#5b3a1c';g.lineWidth=w+4;g.beginPath();g.moveTo(x0,y0);g.lineTo(x1,y1);g.stroke();g.strokeStyle='#d9a35a';g.lineWidth=w;g.stroke();g.strokeStyle='#f1c886';g.lineWidth=2;g.stroke();g.restore();}
function background(){if(mesa.complete&&mesa.naturalWidth)g.drawImage(mesa,0,0,960,640);else{g.fillStyle='#b9793c';g.fillRect(0,0,960,640);}
 g.fillStyle='rgba(23,59,61,.92)';rounded(150,60,660,500,22);g.fill();g.strokeStyle='rgba(255,255,255,.07)';g.lineWidth=1;for(let x=170;x<800;x+=32){g.beginPath();g.moveTo(x,70);g.lineTo(x,550);g.stroke();}for(let y=80;y<550;y+=32){g.beginPath();g.moveTo(160,y);g.lineTo(800,y);g.stroke();}}
function kitePolygon(fill,alpha=1){const pts=geometry(run.kind).points;g.save();g.globalAlpha=alpha;g.fillStyle=fill;g.beginPath();pts.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));g.closePath();g.fill();g.strokeStyle='#1d2b2a';g.lineWidth=3;g.stroke();g.restore();}
function frame(rodsDone=true){const geo=geometry(run.kind);geo.rods.forEach((r,i)=>{if(rodsDone||run.step.placed?.includes(i))wood(r.a.x,r.a.y,r.b.x,r.b.y);});}
function drawStage0(){const geo=geometry(run.kind),c=CLASSES[run.kind],s=run.step,pulse=.5+.5*Math.sin(ui.t*4);
 geo.rods.forEach((r,i)=>{if(s.placed.includes(i))return;g.save();g.setLineDash([8,8]);g.strokeStyle='rgba(247,234,208,.45)';g.lineWidth=3;g.beginPath();g.moveTo(r.a.x,r.a.y);g.lineTo(r.b.x,r.b.y);g.stroke();g.setLineDash([]);if(!run.artesao){g.strokeStyle=`rgba(240,189,82,${.5+pulse*.5})`;g.lineWidth=3;g.beginPath();g.arc(r.mid.x,r.mid.y,c.snap*.55,0,Math.PI*2);g.stroke();}g.restore();});
 frame(false);
 // Leque de varetas, ao lado da armação.
 const left=c.rods-s.placed.length-(ui.drag==='rod'?1:0);for(let i=0;i<left;i++)wood(760+i*7,200+i*4,770+i*7,420-i*4,8);
 g.fillStyle='rgba(247,234,208,.8)';g.font='700 13px system-ui';g.fillText('varetas',748,445);
 if(ui.drag==='rod'){let best=null,dist=Infinity;geo.rods.forEach((r,i)=>{if(s.placed.includes(i))return;const d=Math.hypot(r.mid.x-ui.pointer.x,r.mid.y-ui.pointer.y);if(d<dist){dist=d;best=r;}});
  const w=wobbleAt(run.kind,ui.t),ang=((best?.angle??90)+w)*Math.PI/180,len=176/2,p=ui.pointer,aligned=Math.abs(w)<5;g.save();if(aligned&&c.wobble){g.shadowColor='#ffe08a';g.shadowBlur=18;}wood(p.x-Math.cos(ang)*len,p.y-Math.sin(ang)*len,p.x+Math.cos(ang)*len,p.y+Math.sin(ang)*len);g.restore();
  if(best&&dist<c.snap){g.strokeStyle='#4fbf7d';g.lineWidth=3;g.beginPath();g.arc(best.mid.x,best.mid.y,c.snap*.55,0,Math.PI*2);g.stroke();}}}
function ring(x,y,fill,zones){const [a,b]=zones,R=34,arc=(f0,f1,color,w)=>{g.strokeStyle=color;g.lineWidth=w;g.beginPath();g.arc(x,y,R,-Math.PI/2+f0*Math.PI*2,-Math.PI/2+f1*Math.PI*2);g.stroke();};
 arc(0,1,'rgba(0,0,0,.35)',12);if(!run.artesao){arc(a,b,'rgba(79,191,125,.85)',12);arc(b,1,'rgba(226,86,74,.8)',12);}
 const color=run.artesao?'#f7ead0':fill<a?'#f0bd52':fill<=b?'#4fbf7d':'#e2564a';arc(0,fill,color,6);}
function drawStage1(){const geo=geometry(run.kind),s=run.step,c=CLASSES[run.kind];frame();
 geo.points.forEach((p,i)=>{const tied=s.tied.includes(i);g.fillStyle=tied?'#f0bd52':'#f7ead0';g.strokeStyle='#1d2b2a';g.lineWidth=3;g.beginPath();g.arc(p.x,p.y,tied?10:12,0,Math.PI*2);g.fill();g.stroke();
  if(tied){g.strokeStyle='#7a4a1e';g.lineWidth=2;g.beginPath();g.moveTo(p.x-8,p.y-8);g.lineTo(p.x+8,p.y+8);g.moveTo(p.x+8,p.y-8);g.lineTo(p.x-8,p.y+8);g.stroke();}
  else if(s.holding===i)ring(p.x,p.y,s.fill,c.ring.green);else{g.strokeStyle=`rgba(240,189,82,${.4+.4*Math.sin(ui.t*4+i)})`;g.lineWidth=3;g.beginPath();g.arc(p.x,p.y,22,0,Math.PI*2);g.stroke();}});
 // linha da borda (entre nós amarrados)
 g.strokeStyle='#f7ead0';g.lineWidth=2;s.tied.forEach(i=>{const a=geo.points[i],b=geo.points[(i+1)%geo.points.length];if(s.tied.includes((i+1)%geo.points.length)){g.beginPath();g.moveTo(a.x,a.y);g.lineTo(b.x,b.y);g.stroke();}});}
function drawStage2(){const geo=geometry(run.kind),s=run.step;
 g.fillStyle=PAPER[run.kind];g.globalAlpha=.92;rounded(CENTER.x-230,CENTER.y-215,460,430,8);g.fill();g.globalAlpha=1;
 frame();g.globalAlpha=.25;kitePolygon('#000');g.globalAlpha=1;
 if(!run.artesao){g.save();g.setLineDash([6,7]);g.strokeStyle='#fffaf0';g.lineWidth=3;g.beginPath();geo.path.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));g.closePath();g.stroke();g.restore();}
 g.fillStyle='#1d2b2a';geo.samples.forEach((p,i)=>{if(s.covered.has(i)){g.beginPath();g.arc(p.x,p.y,3.2,0,Math.PI*2);g.fill();}});
 g.strokeStyle='#b3261e';g.lineWidth=3;for(const t of ui.tears){g.beginPath();g.moveTo(t.x-6,t.y-5);g.lineTo(t.x-1,t.y+4);g.lineTo(t.x+3,t.y-3);g.lineTo(t.x+7,t.y+5);g.stroke();}
 // medidor de rasgo
 const w=180;g.fillStyle='rgba(0,0,0,.45)';rounded(CENTER.x-w/2,520,w,14,7);g.fill();g.fillStyle=s.tear>.6?'#e2564a':'#f0bd52';rounded(CENTER.x-w/2,520,w*Math.min(1,s.tear),14,7);g.fill();g.fillStyle='#f7ead0';g.font='600 12px system-ui';g.fillText('rasgo da folha',CENTER.x-w/2,514);}
function kiteFlying(theta,glow=0){const geo=geometry(run.kind);g.save();g.translate(CENTER.x,CENTER.y);g.rotate(theta*Math.PI/180);g.translate(-CENTER.x,-CENTER.y);if(glow){g.shadowColor='#ffe08a';g.shadowBlur=20+glow*40;}kitePolygon(PAPER[run.kind]);g.shadowBlur=0;frame();
 // rabiola
 const tx=CENTER.x,ty=geo.points.reduce((m,p)=>Math.max(m,p.y),0);g.strokeStyle='#f7ead0';g.lineWidth=3;g.beginPath();g.moveTo(tx,ty);for(let k=1;k<=6;k++)g.lineTo(tx+Math.sin(ui.t*3+k)*10,ty+k*14);g.stroke();for(let k=1;k<=6;k+=2){g.fillStyle=k%4===1?'#e66b4f':'#f0bd52';g.fillRect(tx+Math.sin(ui.t*3+k)*10-6,ty+k*14-3,12,6);}g.restore();}
function drawStage3(){const s=run.step,c=CLASSES[run.kind];if(ui.anim>0){kitePolygon(PAPER[run.kind]);frame();return;}
 kiteFlying(s.theta);const ok=Math.abs(s.theta)<ZONE;
 // indicador de inclinação
 g.save();g.translate(250,92);g.strokeStyle='rgba(0,0,0,.45)';g.lineWidth=10;g.beginPath();g.arc(0,60,60,Math.PI*1.18,Math.PI*1.82);g.stroke();g.strokeStyle='rgba(79,191,125,.9)';g.beginPath();g.arc(0,60,60,-Math.PI/2-ZONE*Math.PI/180,-Math.PI/2+ZONE*Math.PI/180);g.stroke();
 const a=-Math.PI/2+Math.max(-FALL,Math.min(FALL,s.theta))*Math.PI/180;g.strokeStyle=ok?'#4fbf7d':'#e2564a';g.lineWidth=4;g.beginPath();g.moveTo(0,60);g.lineTo(Math.cos(a)*68,60+Math.sin(a)*68);g.stroke();g.restore();
 // aviso da próxima rajada e rajada atual
 const tell=nextGust(s,s.t,c.wind.tell),F=windAt(s,s.t);
 if(tell){const x=tell.dir>0?190:770,pulse=.6+.4*Math.sin(ui.t*14);g.fillStyle=`rgba(255,250,240,${pulse})`;g.font='800 22px system-ui';g.textAlign='center';g.fillText(tell.dir>0?'Rajada ➜':'⬅ Rajada',x,300);g.textAlign='start';}
 if(Math.abs(F)>.1){g.strokeStyle='rgba(255,255,255,.55)';g.lineWidth=3;for(let k=0;k<5;k++){const y=160+k*70,x0=F>0?170+((ui.t*400+k*90)%240):790-((ui.t*400+k*90)%240);g.beginPath();g.moveTo(x0,y);g.lineTo(x0+Math.sign(F)*60,y);g.stroke();}}
 // cabresto
 const kx=CENTER.x+ui.control*140;g.fillStyle='rgba(0,0,0,.45)';rounded(CENTER.x-160,548,320,10,5);g.fill();g.fillStyle='#f7ead0';g.beginPath();g.arc(kx,553,16,0,Math.PI*2);g.fill();g.strokeStyle='#1d2b2a';g.lineWidth=3;g.stroke();g.fillStyle='#f7ead0';g.font='600 12px system-ui';g.fillText('cabresto: arraste para o lado contrário do vento',CENTER.x-150,540);
 const bar=Math.min(1,s.t/FLIGHT_TIME);g.fillStyle='rgba(0,0,0,.45)';rounded(170,78,120,10,5);g.fill();g.fillStyle='#f0bd52';rounded(170,78,120*bar,10,5);g.fill();}
function drawStage4(){const s=run.step,f=s.fill||0;kiteFlying(0,f);
 const x=760,y0=480,h=320,zone=(a,b,color)=>{g.fillStyle=color;g.fillRect(x,y0-h*b,34,h*(b-a));};
 g.fillStyle='rgba(0,0,0,.45)';rounded(x-6,y0-h-6,46,h+12,10);g.fill();zone(0,SOUL_ZONES.weak,'#4b5b58');zone(SOUL_ZONES.weak,SOUL_ZONES.safe,'#2f9c96');zone(SOUL_ZONES.safe,SOUL_ZONES.shine,'#f0bd52');zone(SOUL_ZONES.shine,1,'#e2564a');
 g.fillStyle='#fffaf0';g.fillRect(x-4,y0-h*Math.min(1,f)-3,42,6);g.font='700 12px system-ui';g.fillStyle='#f7ead0';[['excesso',.95],['brilho',.84],['seguro',.59],['fraco',.2]].forEach(([t,v])=>g.fillText(t,x+42,y0-h*v+4));
 const stars=starsOf(run);g.fillStyle='#f7ead0';g.font='700 14px system-ui';g.fillText(`Qualidade ${'★'.repeat(stars)}${'☆'.repeat(5-stars)} · chance de variante no brilho ${Math.round(Math.min(.65,.25+.1*(stars-1))*100)}%`,170,540);
 if(!s.holding){g.fillStyle=`rgba(240,189,82,${.5+.4*Math.sin(ui.t*4)})`;g.beginPath();g.arc(CENTER.x,505,26,0,Math.PI*2);g.fill();g.fillStyle='#1d2b2a';g.font='800 12px system-ui';g.textAlign='center';g.fillText('segure',CENTER.x,509);g.textAlign='start';}}
// Mão fantasma: mostra o gesto quando o jogador fica parado.
function ghost(){if(ui.idle<4||ui.down||run.blocked||run.outcome||!$('tip').hidden)return;const k=(ui.t%2)/2,geo=geometry(run.kind);let p=null,press=false;
 if(run.stage===0){const r=geo.rods.find((_,i)=>!run.step.placed.includes(i));if(r)p={x:770+(r.mid.x-770)*k,y:310+(r.mid.y-310)*k};}
 if(run.stage===1){const i=geo.points.findIndex((_,i)=>!run.step.tied.includes(i));if(i>=0){p=geo.points[i];press=true;}}
 if(run.stage===2){const n=geo.samples.length,i=Math.floor(k*n/3);p=geo.samples[i];}
 if(run.stage===3){p={x:CENTER.x+Math.sin(ui.t*2)*90,y:553};}
 if(run.stage===4){p={x:CENTER.x,y:505};press=true;}
 if(!p)return;g.save();g.globalAlpha=.75;g.fillStyle='#fffaf0';g.strokeStyle='#1d2b2a';g.lineWidth=3;g.beginPath();g.arc(p.x+14,p.y+18,14,0,Math.PI*2);g.fill();g.stroke();g.beginPath();g.roundRect(p.x+6,p.y-6,10,26,5);g.fill();g.stroke();if(press){g.strokeStyle='#f0bd52';g.beginPath();g.arc(p.x,p.y,10+8*k,0,Math.PI*2);g.stroke();}g.restore();}
// Ferramenta na mão: aparece sozinha conforme a etapa.
function tool(){if(run.outcome||run.blocked)return;const p=ui.pointer,id=STAGES[run.stage]?.tool;g.save();g.translate(p.x,p.y);g.strokeStyle='#1d2b2a';g.lineWidth=3;g.fillStyle='#f7ead0';
 if(id==='pinca'){g.beginPath();g.moveTo(-4,0);g.lineTo(-10,-34);g.moveTo(4,0);g.lineTo(10,-34);g.stroke();}
 if(id==='linha'){g.beginPath();g.roundRect(-12,-30,24,22,4);g.fill();g.stroke();g.beginPath();g.moveTo(0,-8);g.lineTo(0,0);g.stroke();}
 if(id==='tesoura'){g.beginPath();g.moveTo(0,0);g.lineTo(-10,-26);g.moveTo(0,0);g.lineTo(10,-26);g.stroke();g.beginPath();g.arc(-12,-32,6,0,Math.PI*2);g.arc(12,-32,6,0,Math.PI*2);g.stroke();}
 if(id==='mao'||id==='alma'){g.beginPath();g.arc(0,8,9,0,Math.PI*2);g.fill();g.stroke();}
 g.fillStyle='#1d2b2a';g.beginPath();g.arc(0,0,3,0,Math.PI*2);g.fill();g.restore();}
function pops(dt){g.textAlign='center';for(const p of ui.pops){p.life-=dt;p.y-=24*dt;g.globalAlpha=Math.max(0,Math.min(1,p.life*1.6));g.font='800 18px system-ui';g.lineWidth=4;g.strokeStyle='#0b1f20';g.strokeText(p.text,p.x,p.y);g.fillStyle=p.color;g.fillText(p.text,p.x,p.y);}g.globalAlpha=1;g.textAlign='start';ui.pops=ui.pops.filter(p=>p.life>0);}
function finish(){const o=run.outcome;$('result').hidden=false;const names=['Armação','Nós','Papel','Voo'];
 $('resultTitle').textContent=o.type==='broken'?'O elo partiu':o.variant?'Rabbito · variante rara!':'Rabbito nasceu!';
 $('resultArt').innerHTML=o.type==='broken'?'<p style="font-size:56px;margin:0">💔</p>':`<img src="rabbito.png" alt="Rabbito" class="${o.variant?'variant':''}">`;
 $('resultStars').textContent='★'.repeat(o.stars)+'☆'.repeat(5-o.stars);$('resultMsg').textContent=o.msg;
 $('resultList').innerHTML=names.map((n,i)=>`<li><span>${n}</span><b>${gradeLabel(run.grades[i]||0)}</b></li>`).join('')+`<li><span>Materiais perdidos</span><b>${run.log.length?run.log.map(l=>l.lost==='linha'?'🧵':'📄').join(' '):'nenhum'}</b></li><li><span>Despertar</span><b>${o.type==='broken'?'Excesso':o.shine?'Brilho':'Seguro'}</b></li>`;hud();}
function loop(now){const dt=Math.min(.05,(now-last)/1000);last=now;ui.t+=dt;ui.idle+=dt;
 if(ui.anim>0)ui.anim-=dt;
 if(!run.blocked&&!run.outcome){
  if(run.stage===1){const r=tickKnot(run,dt);if(r)report(r);}
  if(run.stage===3&&ui.anim<=0&&$('tip').hidden){const key=(ui.keys.ArrowRight?1:0)-(ui.keys.ArrowLeft?1:0),r=tickFlight(run,dt,key||ui.control);if(r)report(r,{x:CENTER.x,y:CENTER.y});if(Math.floor(run.step.t*4)!==ui.lastT){ui.lastT=Math.floor(run.step.t*4);hud();}}
  if(run.stage===4){const r=tickSoul(run,dt);if(r){report(r);if(run.outcome)finish();}}}
 g.clearRect(0,0,960,640);background();
 [drawStage0,drawStage1,drawStage2,drawStage3,drawStage4,drawStage4][run.stage]();ghost();pops(dt);tool();requestAnimationFrame(loop);}
$('restart').onclick=reset;$('again').onclick=reset;$('kind').onchange=reset;$('artesao').onchange=reset;$('restock').onclick=()=>{restock(run);ui.tears=[];hud();};
reset();requestAnimationFrame(loop);cv.focus();
// Depuração e testes de navegador: leitura do estado atual.
window.oficina={get run(){return run;}};
