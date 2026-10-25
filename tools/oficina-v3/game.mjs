import {createLiveSession} from './live-client.mjs';
import {dispatch} from './protocol.mjs';
import {renderWorkshopHud,installWorkshopLook,drawArtisanMat,drawPaperDetails,drawCraftTool} from './look.mjs';
import {STAGES,CLASSES,FLIGHT_TIME,ZONE,FALL,SOUL_ZONES,CENTER,geometry,createRun,restock as corerestock,placeRod as coreplaceRod,wobbleAt,holdKnot as coreholdKnot,tickKnot,releaseKnot as corereleaseKnot,cutAt as corecutAt,cutProgress,tickFlight,windAt,nextGust,holdSoul as coreholdSoul,tickSoul,releaseSoul as corereleaseSoul,starsOf,gradeLabel,distToPath,knotWindow,tickCraft,craftBonus} from './model.mjs';
const $=id=>document.getElementById(id),cv=$('board'),g=cv.getContext('2d');
const PAPER={comum:'#e66b4f',incomum:'#2f9c96',raro:'#e8b23f'};
const TIPS=['Cada vareta vai do centro até uma ponta. Arraste do leque até o círculo pontilhado e solte.','Segure em cima do nó. A faixa verde é pequena e muda a cada tentativa. Observe o anel e solte no verde; depois dela, a linha arrebenta.','Recorte pelo pontilhado, sem entrar na vela. Pode fazer em vários trechos.','O vento avisa antes: a seta mostra de onde vem a rajada. Arraste o cabresto para o lado contrário.','Agora é com você. Solte no Seguro para garantir. A variante rara é uma surpresa: chance de 1 em 459 nascimentos, independente da nota ou do momento de soltar. Elo firme vale +4% de atributos, mas a janela é muito estreita. Excesso parte o elo.'];
const mesa=new Image();mesa.src='mesa.jpg';const rabbito=new Image();rabbito.src='rabbito.png';
let run,ui,last=performance.now(),live=null,resultJob=null,exitPrompt=false,exitBusy=false,booting=!!new URLSearchParams(location.search).get('job');
const jobId=new URLSearchParams(location.search).get('job');
function command(event,fallback){if(!live)return fallback();live.record(event);return dispatch(run,event);}
const placeRod=(r,p,a)=>command(['rod',p.x,p.y],()=>coreplaceRod(r,p,a));
const holdKnot=(r,i)=>command(['knot',i],()=>coreholdKnot(r,i));
const releaseKnot=r=>command(['knot-up'],()=>corereleaseKnot(r));
const cutAt=(r,p,dt)=>command(['cut',p.x,p.y,dt],()=>corecutAt(r,p,dt));
const holdSoul=r=>command(['soul'],()=>coreholdSoul(r));
const releaseSoul=r=>command(['soul-up'],()=>corereleaseSoul(r));
const restock=r=>command(['restock'],()=>corerestock(r));
function reset(saved=null){if(live&&!saved?.step)return;run=saved?.step?saved:createRun($('kind').value,{artesao:$('artesao').checked,seed:crypto.getRandomValues(new Uint32Array(1))[0]});ui={pointer:{x:CENTER.x,y:CENTER.y},down:false,drag:null,cutLast:null,tears:[],pops:[],idle:0,t:0,anim:0,control:0,keys:{},seen:{},knob:false,grip:0};$('result').hidden=true;document.body.classList.remove('has-result');delete document.body.dataset.outcome;$('resultContinue').hidden=true;$('blocked').hidden=true;hud();tip();}
// ---------- HUD ----------
function hud(){
 const c=CLASSES[run.kind];let count='';
 if(run.stage===0)count=run.step.placed.length+'/'+c.rods;if(run.stage===1)count=run.step.tied.length+'/'+c.rods;if(run.stage===2)count=Math.round(cutProgress(run)*100)+'%';if(run.stage===3)count=Math.max(0,FLIGHT_TIME-run.step.t).toFixed(0)+' s';
 renderWorkshopHud(run,STAGES,CLASSES,count);
 $('blocked').hidden=!run.blocked;if(run.blocked)$('blockedTitle').textContent=run.blocked==='linha'?'Acabou a linha':'Acabou o papel';
 updateWakeGesture();
}
function updateWakeGesture(){const button=$('wakeGesture');button.hidden=run.stage!==4||!!run.outcome||booting||exitPrompt||!$('tip').hidden;if(button.hidden)return;const holding=!!run.step.holding,f=run.step.fill||0;button.setAttribute('aria-pressed',String(holding));const text=!holding?'Firmar o elo':f<SOUL_ZONES.weak?'Soltar · elo fraco':f<SOUL_ZONES.safe?'Soltar · Seguro':f<SOUL_ZONES.shine?'Soltar · Elo firme':'Soltar · excesso';if(button.textContent!==text)button.textContent=text;}
$('wakeGesture').onclick=()=>{if(booting||exitPrompt||run.stage!==4||run.outcome)return;ui.idle=0;ui.seen[4]=true;$('tip').hidden=true;if(run.step.holding){ui.down=false;const result=releaseSoul(run);report(result,{x:CENTER.x,y:CENTER.y});if(run.outcome)finish();}else{holdSoul(run);ui.down=true;}updateWakeGesture();};

function tip(){const i=run.stage;if(i>4||ui.seen[i]){$('tip').hidden=true;return;}$('tipText').textContent=TIPS[i]+(i===0&&CLASSES[run.kind].wobble?' Nesta classe a vareta balança: solte quando ela brilhar alinhada.':'');$('tip').hidden=false;}
$('tipOk').onclick=()=>{ui.seen[run.stage]=true;$('tip').hidden=true;cv.focus();};
function pop(text,x,y,color){ui.pops.push({text,x,y,color,life:1.1});}
const gradeColor=s=>s>=.85?'#4fbf7d':s>=.65?'#f0bd52':'#f7ead0';
function report(r,at=ui.pointer){if(!r)return;if(r.lost)pop(r.lost==='linha'?'−1 linha':'−1 folha',at.x,at.y-20,'#e2564a');if(r.msg)pop(r.msg,at.x,at.y-44,r.ok?'#f7ead0':'#ffd0c8');if(r.score!=null)pop(gradeLabel(r.score),at.x,at.y-20,gradeColor(r.score));if(r.grade!=null){pop(`${STAGES[run.stage-1]?.name}: ${gradeLabel(r.grade)}`,CENTER.x,90,gradeColor(r.grade));ui.anim=run.stage===3?1.2:0;}hud();if(r.done||r.grade!=null)tip();}
// ---------- entrada ----------
function point(e){const r=cv.getBoundingClientRect();return {x:(e.clientX-r.left)*960/r.width,y:(e.clientY-r.top)*640/r.height};}
const FAN={x:800,y:200};
cv.addEventListener('pointerdown',e=>{if(booting||run.blocked||run.outcome)return;cv.setPointerCapture(e.pointerId);const p=point(e);ui.pointer=p;ui.down=true;ui.idle=0;ui.seen[run.stage]=true;$('tip').hidden=true;
 if(run.stage===0){if(p.x>720&&p.y>150&&p.y<450)ui.drag='rod';}
 if(run.stage===1){const pts=geometry(run.kind).points;const i=pts.findIndex((q,i)=>!run.step.tied.includes(i)&&Math.hypot(q.x-p.x,q.y-p.y)<46);if(i>=0)holdKnot(run,i);}
 if(run.stage===2){ui.cutLast=p;report(cutAt(run,p,0));}
 if(run.stage===3){ui.knob=true;ui.knobStart=p.x;}
 if(run.stage===4)holdSoul(run);hud();});
cv.addEventListener('pointermove',e=>{const p=point(e),prev=ui.pointer;ui.pointer=p;if(!ui.down)return;ui.idle=0;
 if(run.stage===2&&ui.cutLast){const d=Math.hypot(p.x-ui.cutLast.x,p.y-ui.cutLast.y),n=Math.max(1,Math.ceil(d/4)),dt=(e.timeStamp-(ui.cutTime||e.timeStamp))/1000/n;for(let k=1;k<=n;k++){const q={x:ui.cutLast.x+(p.x-ui.cutLast.x)*k/n,y:ui.cutLast.y+(p.y-ui.cutLast.y)*k/n},r=cutAt(run,q,Math.min(.1,dt));if(r?.warn){if(!ui.tears.length||Math.hypot(ui.tears.at(-1).x-q.x,ui.tears.at(-1).y-q.y)>10)ui.tears.push(q);}if(r&&!r.warn){if(r.torn)ui.tears=[];report(r,q);if(run.stage!==2)break;}}ui.cutLast=p;}
 ui.cutTime=e.timeStamp;if(run.stage===3&&ui.knob)ui.control=Math.max(-1,Math.min(1,(p.x-ui.knobStart)/140));});
const up=e=>{if(!ui.down)return;ui.down=false;const p=e?point(e):ui.pointer;
 if(run.stage===0&&ui.drag==='rod'){report(placeRod(run,p,wobbleAt(run.kind,live?run.clock:ui.t)),p);}
 if(run.stage===1)report(releaseKnot(run),p);
 if(run.stage===2){ui.cutLast=null;ui.cutTime=null;}
 if(run.stage===3){ui.knob=false;ui.control=0;}
 if(run.stage===4){const r=releaseSoul(run);report(r,p);if(run.outcome)finish();}
 ui.drag=null;hud();};
cv.addEventListener('pointerup',up);cv.addEventListener('pointercancel',()=>{if(live&&!run.outcome){live.record(['cancel']);dispatch(run,['cancel']);}ui.down=false;ui.drag=null;ui.control=0;if(run.stage===1)run.step.holding=null;if(run.stage===4)run.step.holding=false;});
// Teclado: Espaço segura (nós, despertar) ou encaixa a próxima vareta; setas controlam o vento.
cv.addEventListener('keydown',e=>{if(e.repeat||booting||run.blocked||run.outcome)return;const inputStage=run.stage;if(e.key===' '){e.preventDefault();ui.idle=0;ui.seen[run.stage]=true;$('tip').hidden=true;
  if(inputStage===0){const r=geometry(run.kind).rods.find((_,i)=>!run.step.placed.includes(i));if(r)report(placeRod(run,r.mid,wobbleAt(run.kind,ui.t)),r.mid);}
  if(inputStage===1){const i=geometry(run.kind).points.findIndex((_,i)=>!run.step.tied.includes(i));holdKnot(run,i);ui.down=true;}
  if(inputStage===4){holdSoul(run);ui.down=true;}}
 if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();ui.keys[e.key]=1;}});
cv.addEventListener('keyup',e=>{if(e.key===' '&&ui.down&&(run.stage===1||run.stage===4))up();if(e.key in ui.keys)delete ui.keys[e.key];});
// ---------- desenho ----------
function rounded(x,y,w,h,r){g.beginPath();g.roundRect(x,y,w,h,r);}
function wood(x0,y0,x1,y1,w=9){g.save();g.lineCap='round';g.strokeStyle='#5b3a1c';g.lineWidth=w+4;g.beginPath();g.moveTo(x0,y0);g.lineTo(x1,y1);g.stroke();g.strokeStyle='#d9a35a';g.lineWidth=w;g.stroke();g.strokeStyle='#f1c886';g.lineWidth=2;g.stroke();g.restore();}
function background(){if(mesa.complete&&mesa.naturalWidth)g.drawImage(mesa,0,0,960,640);else{g.fillStyle='#b9793c';g.fillRect(0,0,960,640);}drawArtisanMat(g);}

function kitePolygon(fill,alpha=1){const pts=geometry(run.kind).points;g.save();g.globalAlpha=alpha;g.fillStyle=fill;g.beginPath();pts.forEach((p,i)=>i?g.lineTo(p.x,p.y):g.moveTo(p.x,p.y));g.closePath();g.fill();if(fill!=='#000')drawPaperDetails(g,pts,CENTER,fill);g.strokeStyle='#1d2b2a';g.lineWidth=3;g.stroke();g.restore();}
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
  else if(s.holding===i)ring(p.x,p.y,s.fill,knotWindow(run,i));else if(!run.artesao)ring(p.x,p.y,0,knotWindow(run,i));});
 // linha da borda (entre nós amarrados)
 g.strokeStyle='#f7ead0';g.lineWidth=2;s.tied.forEach(i=>{const a=geo.points[i],b=geo.points[(i+1)%geo.points.length];if(s.tied.includes((i+1)%geo.points.length)){g.beginPath();g.moveTo(a.x,a.y);g.lineTo(b.x,b.y);g.stroke();}});}
function drawStage2(){const geo=geometry(run.kind),s=run.step;
 g.fillStyle=PAPER[run.kind];g.globalAlpha=.92;rounded(CENTER.x-230,CENTER.y-215,460,430,8);g.fill();g.globalAlpha=1;
 frame();kitePolygon('#000',.12);
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
 g.save();g.translate(250,112);g.strokeStyle='rgba(0,0,0,.45)';g.lineWidth=10;g.beginPath();g.arc(0,60,60,Math.PI*1.18,Math.PI*1.82);g.stroke();g.strokeStyle='rgba(79,191,125,.9)';g.beginPath();g.arc(0,60,60,-Math.PI/2-ZONE*Math.PI/180,-Math.PI/2+ZONE*Math.PI/180);g.stroke();
 const a=-Math.PI/2+Math.max(-FALL,Math.min(FALL,s.theta))*Math.PI/180;g.strokeStyle=ok?'#4fbf7d':'#e2564a';g.lineWidth=4;g.beginPath();g.moveTo(0,60);g.lineTo(Math.cos(a)*68,60+Math.sin(a)*68);g.stroke();g.restore();
 // aviso da próxima rajada e rajada atual
 const tell=nextGust(s,s.t,c.wind.tell),F=windAt(s,s.t);
 if(tell){const x=tell.dir>0?190:770,pulse=.6+.4*Math.sin(ui.t*14);g.fillStyle=`rgba(255,250,240,${pulse})`;g.font='800 22px system-ui';g.textAlign='center';g.fillText(tell.dir>0?'Rajada ➜':'⬅ Rajada',x,300);g.textAlign='start';}
 if(Math.abs(F)>.1){g.strokeStyle='rgba(255,255,255,.55)';g.lineWidth=3;for(let k=0;k<5;k++){const y=160+k*70,x0=F>0?170+((ui.t*400+k*90)%240):790-((ui.t*400+k*90)%240);g.beginPath();g.moveTo(x0,y);g.lineTo(x0+Math.sign(F)*60,y);g.stroke();}}
 // cabresto
 const kx=CENTER.x+ui.control*140;g.fillStyle='rgba(0,0,0,.45)';rounded(CENTER.x-160,548,320,10,5);g.fill();g.fillStyle='#f7ead0';g.beginPath();g.arc(kx,553,16,0,Math.PI*2);g.fill();g.strokeStyle='#1d2b2a';g.lineWidth=3;g.stroke();g.fillStyle='#f7ead0';g.font='600 12px system-ui';g.fillText('cabresto: arraste para o lado contrário do vento',CENTER.x-150,540);
 const bar=Math.min(1,s.t/FLIGHT_TIME);g.fillStyle='rgba(0,0,0,.45)';rounded(170,95,120,10,5);g.fill();g.fillStyle='#f0bd52';rounded(170,95,120*bar,10,5);g.fill();}
function drawStage4(){const s=run.step,f=s.fill||0;kiteFlying(0,f);
 const x=760,y0=480,h=320,zone=(a,b,color)=>{g.fillStyle=color;g.fillRect(x,y0-h*b,34,h*(b-a));};
 g.fillStyle='rgba(0,0,0,.45)';rounded(x-6,y0-h-6,46,h+12,10);g.fill();zone(0,SOUL_ZONES.weak,'#4b5b58');zone(SOUL_ZONES.weak,SOUL_ZONES.safe,'#2f9c96');zone(SOUL_ZONES.safe,SOUL_ZONES.shine,'#f0bd52');zone(SOUL_ZONES.shine,1,'#e2564a');
 g.fillStyle='#fffaf0';g.fillRect(x-4,y0-h*Math.min(1,f)-3,42,6);g.font='700 12px system-ui';g.fillStyle='#f7ead0';[['excesso',.95],['elo firme +4%',.89],['seguro',.59],['fraco',.2]].forEach(([t,v])=>g.fillText(t,x+42,y0-h*v+4));
 const stars=starsOf(run);g.fillStyle='#f7ead0';g.font='700 14px system-ui';g.fillText(`Qualidade ${'★'.repeat(stars)}${'☆'.repeat(5-stars)} · montagem +${craftBonus(run).assemblyPercent}% · Elo firme +4%`,170,540);
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
function tool(){if(run.outcome||run.blocked)return;g.save();g.translate(ui.pointer.x,ui.pointer.y);drawCraftTool(g,STAGES[run.stage]?.tool,ui.down,ui.t,ui.grip);g.restore();}

function pops(dt){g.textAlign='center';for(const p of ui.pops){p.life-=dt;p.y-=24*dt;g.globalAlpha=Math.max(0,Math.min(1,p.life*1.6));g.font='800 18px system-ui';g.lineWidth=4;g.strokeStyle='#0b1f20';g.strokeText(p.text,p.x,p.y);g.fillStyle=p.color;g.fillText(p.text,p.x,p.y);}g.globalAlpha=1;g.textAlign='start';ui.pops=ui.pops.filter(p=>p.life>0);}
function finish(){document.body.classList.add('has-result');if(live&&!run.outcome?.confirmed){$('result').hidden=false;$('resultTitle').textContent='Confirmando nascimento…';$('resultArt').replaceChildren();$('resultStars').textContent='';$('resultMsg').textContent='Aguardando o servidor. Seu parceiro só será concedido uma vez.';$('resultList').replaceChildren();$('resultBonus').hidden=true;$('resultContinue').hidden=true;$('resultSaved').textContent='';$('again').hidden=true;void live.flush();return;}const o=run.outcome;$('result').hidden=false;const names=['Armação','Nós','Papel','Voo'];
 $('resultTitle').textContent=o.type==='broken'?'O elo partiu':o.variant?(resultJob?.name||'Rabbito')+' · variante rara!':(resultJob?.name||'Rabbito')+' nasceu!';
 $('resultArt').innerHTML=o.type==='broken'?'<p style="font-size:56px;margin:0">💔</p>':`<img src="rabbito.png" alt="Rabbito" class="${o.variant?'variant':''}">`;
 if(resultJob?.creature&&o.type!=='broken'){const {image,frame}=resultJob.creature,portrait=document.createElement('canvas');portrait.width=400;portrait.height=300;portrait.style.width='400px';portrait.style.height='300px';const source=new Image();source.onload=()=>{const ctx=portrait.getContext('2d');if(o.variant)ctx.filter='hue-rotate(160deg) saturate(1.5)';const scale=Math.min(400/frame.w,300/frame.h);ctx.drawImage(source,frame.x,frame.y,frame.w,frame.h,(400-frame.w*scale)/2,(300-frame.h*scale)/2,frame.w*scale,frame.h*scale);};source.src=image;portrait.setAttribute('role','img');portrait.setAttribute('aria-label',resultJob.name);$('resultArt').replaceChildren(portrait);}
 $('resultStars').textContent='★'.repeat(o.stars)+'☆'.repeat(5-o.stars);$('resultStars').setAttribute('aria-label',o.stars+' de 5 estrelas de acabamento');$('resultMsg').textContent=o.msg+(o.craftBonus?` Montagem: ${o.craftBonus.seconds.toFixed(1)} s · ${o.craftBonus.errors} erro(s).`:'');
 $('resultList').innerHTML=names.map((n,i)=>`<li><span>${n}</span><b>${gradeLabel(run.grades[i]||0)}</b></li>`).join('')+`<li><span>Materiais perdidos</span><b>${run.log.length?run.log.map(l=>l.lost==='linha'?'1 linha':'1 folha').join(' · '):'nenhum'}</b></li><li><span>Despertar</span><b>${o.type==='broken'?'Excesso':o.shine?'Elo firme':'Seguro'}</b></li>`+(o.craftBonus?`<li><span>Montagem · precisão e tempo</span><b>+${o.craftBonus.assemblyPercent}%</b></li><li><span>Elo firme</span><b>+${o.craftBonus.eloPercent}%</b></li><li><span>Bônus de atributos</span><b>+${o.craftBonus.totalPercent}%</b></li>`:'');$('again').hidden=!!live;$('resultContinue').hidden=!live;
 $('resultBonus').hidden=!o.craftBonus||o.type==='broken';
 if(o.craftBonus)$('resultBonus').innerHTML=`<strong>+${o.craftBonus.totalPercent.toLocaleString('pt-BR')}%</strong><span>Bônus de atributos<small>Precisão, tempo e força do elo</small></span>`;
 $('resultSaved').textContent=live?(o.type==='born'?'Seu parceiro já está salvo na coleção.':'A rabiola está preservada. Restaure-a na Oficina para tentar novamente.'):'Bancada de prática · nenhum parceiro será adicionado à conta.';
 $('resultContinue').querySelector('.button-content').textContent=o.type==='born'?'Continuar aventura':'Voltar à Oficina';
 document.body.dataset.outcome=o.type;
 hud();$('resultContinue').hidden?$('again').focus({preventScroll:true}):$('resultContinue').focus({preventScroll:true});if(live)parent.postMessage({type:'oficina-v3:saved',jobId,completed:o.type==='born'},location.origin);}
function loop(now){const dt=Math.min(.05,(now-last)/1000);last=now;ui.t+=dt;ui.idle+=dt;updateWakeGesture();
 ui.grip+=(Number(ui.down&&ui.drag==='rod')-ui.grip)*(1-Math.exp(-dt*22));
 if(ui.anim>0)ui.anim-=dt;
 if(live)live.tick(now);
 if(!exitPrompt&&!booting&&!run.blocked&&!run.outcome&&!document.hidden&&$('tip').hidden&&ui.anim<=0){
  if(live){const key=(ui.keys.ArrowRight?1:0)-(ui.keys.ArrowLeft?1:0),event=['t',Math.max(.000001,dt),key||ui.control];live.record(event);const r=dispatch(run,event);if(r){report(r);if(run.outcome)finish();}}
  else{
   tickCraft(run,dt);
   if(run.stage===1){const r=tickKnot(run,dt);if(r)report(r);}
   if(run.stage===3){const key=(ui.keys.ArrowRight?1:0)-(ui.keys.ArrowLeft?1:0),r=tickFlight(run,dt,key||ui.control);if(r)report(r,{x:CENTER.x,y:CENTER.y});}
   if(run.stage===4){const r=tickSoul(run,dt);if(r){report(r);if(run.outcome)finish();}}
  }
  if(run.stage===3&&Math.floor(run.step.t*4)!==ui.lastT){ui.lastT=Math.floor(run.step.t*4);hud();}
 }
 g.clearRect(0,0,960,640);background();
 [drawStage0,drawStage1,drawStage2,drawStage3,drawStage4,drawStage4][run.stage]();ghost();pops(dt);tool();requestAnimationFrame(loop);}
$('resultContinue').onclick=()=>$('liveExit').click();
$('restart').onclick=reset;$('again').onclick=reset;$('kind').onchange=reset;$('artesao').onchange=reset;$('restock').onclick=()=>{restock(run);ui.tears=[];hud();};
installWorkshopLook();reset();requestAnimationFrame(loop);cv.focus();
if(jobId){
 document.body.classList.add('live-mode');$('liveExit').setAttribute('aria-label','Sair da Oficina');$('liveExit').title='Sair da Oficina';$('kind').disabled=true;$('artesao').disabled=true;$('restart').hidden=true;document.querySelector('.class-picker').hidden=true;document.querySelector('.toggle').hidden=true;$('liveExit').hidden=false;$('liveSave').hidden=false;
 $('restock').querySelector('.button-content').textContent='Receber kit do ateliê';$('blocked').querySelector('p').textContent='O Sr. Assis fornece outro kit de linha e papel gratuitamente nesta versão. A qualidade considera o tempo e os erros da montagem inteira.';
 $('liveSave').onclick=()=>live?.flush();
 const leave=cancelled=>{if(parent!==window)parent.postMessage({type:'oficina-v3:close',jobId,cancelled},location.origin);else location.href='/';};
 $('liveExit').onclick=async()=>{
  if(!live){$('saveStatus').textContent='Aguarde carregar a montagem antes de sair.';return;}
  if(run.outcome){await live.flush();if(live.dirty||live.failed){$('saveStatus').textContent='Confirme o resultado em Salvar novamente antes de sair.';return;}leave(false);return;}
  if(exitBusy||$('exitConfirm').open)return;
  exitPrompt=true;ui.down=false;ui.drag=null;ui.keys={};ui.control=0;live.record(['cancel']);dispatch(run,['cancel']);
  $('exitError').textContent='';$('exitConfirm').showModal();$('exitStay').focus();
 };
 const stay=()=>{if(exitBusy)return;$('exitConfirm').close();exitPrompt=false;last=performance.now();cv.focus();};
 $('exitStay').onclick=stay;$('exitConfirm').addEventListener('cancel',event=>{event.preventDefault();stay();});
 $('exitYes').onclick=async()=>{if(exitBusy)return;exitBusy=true;$('exitYes').disabled=true;$('exitStay').disabled=true;$('exitError').textContent='Cancelando montagem…';try{const result=await live.cancel();$('exitConfirm').close();leave(result.status==='cancelled');}catch(error){$('exitError').textContent='Não foi possível cancelar. '+error.message+' Sua montagem continua aberta.';}finally{exitBusy=false;$('exitYes').disabled=false;$('exitStay').disabled=false;}};
 createLiveSession(jobId,text=>{$('saveStatus').textContent=text;},job=>{resultJob=job;run.outcome=job.state.outcome;run.stage=5;finish();}).then(session=>{live=session;resultJob=session.job;$('kind').value=live.run.kind;reset(live.run);booting=false;if(run.outcome)finish();else{live.record(['cancel']);dispatch(run,['cancel']);}$('saveStatus').textContent='Montagem salva na conta';}).catch(error=>{$('saveStatus').textContent=error.message;$('bubble').textContent='Não foi possível retomar. Use Sair da bancada e tente novamente.';});
}
// Depuração e testes de navegador: leitura do estado atual.
window.oficina={get run(){return run;}};

// The exit uses the same save/close path as the visible control.
addEventListener('keydown',event=>{
 if(event.key==='Escape'&&live&&!$('exitConfirm').open){event.preventDefault();$('liveExit').click();}
});
