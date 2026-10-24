// Oficina das Almas v3 — cinco minijogos de um gesto. Regras puras (sem DOM), testáveis em Node.
// Tempo sempre recebido de fora (dt em segundos), então a mesma sequência de entradas dá o mesmo resultado.
export const STAGES=[
 {id:'armacao',name:'Armação',verb:'Arraste cada vareta até a pipa',tool:'mao'},
 {id:'nos',name:'Nós',verb:'Segure cada nó e solte no verde',tool:'linha'},
 {id:'papel',name:'Papel',verb:'Recorte seguindo o pontilhado',tool:'tesoura'},
 {id:'voo',name:'Voo',verb:'Mantenha a pipa reta no vento',tool:'mao'},
 {id:'despertar',name:'Despertar',verb:'Segure para acordar a alma',tool:'alma'}];
// A classe muda a dificuldade (janela, velocidade, vento), não a quantidade de repetições.
export const CLASSES={
 comum:{label:'Comum',shape:'Diamante',rods:4,snap:48,wobble:0,ring:{speed:.5,width:.16},cut:{tol:18,target:14,tear:.022},wind:{gusts:4,power:[.8,1.05],tell:1},soul:{speed:.3}},
 incomum:{label:'Incomum',shape:'Pentágono',rods:5,snap:42,wobble:10,ring:{speed:.62,width:.12},cut:{tol:15,target:12,tear:.028},wind:{gusts:5,power:[.95,1.25],tell:.8},soul:{speed:.36}},
 raro:{label:'Raro',shape:'Estrela de vento',rods:6,snap:36,wobble:18,ring:{speed:.75,width:.09},cut:{tol:12,target:10,tear:.034},wind:{gusts:6,power:[1.1,1.45],tell:.62},soul:{speed:.42}}};
export const MATERIALS={linha:3,folha:2},FLIGHT_TIME=9,ZONE=12,FALL=46,GUST=1.4;
export const SOUL_ZONES={weak:.4,safe:.86,shine:.92};
export const VARIANT_ODDS=459,VARIANT_CHANCE=1/VARIANT_ODDS;
export const CENTER={x:480,y:286};
export function rng(seed){let a=seed>>>0||1;return ()=>{a=a+0x6d2b79f5>>>0;let t=a;t=Math.imul(t^t>>>15,t|1);t^=t+Math.imul(t^t>>>7,t|61);return ((t^t>>>14)>>>0)/4294967296;};}
export const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
export const gradeLabel=g=>g>=.85?'Perfeito':g>=.65?'Bom':'Ok';
// ---------- geometria ----------
export function geometry(kind){const c=CLASSES[kind],n=c.rods,points=Array.from({length:n},(_,i)=>{const a=-Math.PI/2+i*Math.PI*2/n,r=kind==='raro'&&i%2?128:176;return {x:CENTER.x+Math.cos(a)*r,y:CENTER.y+Math.sin(a)*r};});
 const rods=points.map(p=>({a:CENTER,b:p,mid:{x:(CENTER.x+p.x)/2,y:(CENTER.y+p.y)/2},angle:Math.atan2(p.y-CENTER.y,p.x-CENTER.x)*180/Math.PI}));
 // Linha de corte: o contorno da pipa afastado 16 px (margem de papel para colar).
 const path=points.map(p=>{const dx=p.x-CENTER.x,dy=p.y-CENTER.y,l=Math.hypot(dx,dy);return {x:p.x+dx/l*16,y:p.y+dy/l*16};}),samples=[];
 path.forEach((p,i)=>{const q=path[(i+1)%path.length],k=Math.ceil(Math.hypot(q.x-p.x,q.y-p.y)/8);for(let j=0;j<k;j++)samples.push({x:p.x+(q.x-p.x)*j/k,y:p.y+(q.y-p.y)*j/k});});
 return {points,rods,path,samples};}
export function inside(p,poly){let v=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a.y>p.y)!==(b.y>p.y)&&p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x)v=!v;}return v;}
export function distToPath(p,path){let best=Infinity;for(let i=0;i<path.length;i++){const a=path[i],b=path[(i+1)%path.length],dx=b.x-a.x,dy=b.y-a.y,t=clamp(((p.x-a.x)*dx+(p.y-a.y)*dy)/(dx*dx+dy*dy));best=Math.min(best,Math.hypot(p.x-a.x-dx*t,p.y-a.y-dy*t));}return best;}
// ---------- partida ----------
export function createRun(kind='comum',{artesao=false,seed=7}={}){const run={kind,artesao,seed,stage:0,materials:{...MATERIALS},grades:[],log:[],blocked:null,outcome:null,knotSequence:0,variantRoll:rng((seed^0x51f15e)>>>0)(),firstTime:{},elapsed:[0,0,0,0,0],active:[false,false,false,false,false],errors:[0,0,0,0,0]};startStage(run);return run;}
export function startStage(run){const g=geometry(run.kind);
 run.step=[()=>({placed:[],scores:[]}),()=>({tied:[],scores:[],holding:null,fill:0,windows:g.points.map(()=>nextKnotWindow(run))}),()=>({covered:new Set(),tear:0,sumD:0,nD:0,time:0,done:false,samples:g.samples.length}),()=>({t:0,theta:0,omega:0,inZone:0,gusts:windSchedule(run.kind,run.seed+run.log.length),done:false}),()=>({fill:0,holding:false})][run.stage]();return run.step;}
const lose=(run,what,msg)=>{run.errors[run.stage]++;run.materials[what]--;run.log.push({stage:run.stage,lost:what});if(run.materials[what]<=0)run.blocked=what;return {ok:false,lost:what,msg:run.materials[what]<=0?`${msg} Acabou ${what==='linha'?'a linha':'o papel'}: busque mais na exploração.`:msg};};
function finishStage(run,grade){const g=clamp(grade+(run.artesao?.06:0));run.grades[run.stage]=g;run.stage++;if(run.stage<STAGES.length)startStage(run);return g;}
export function restock(run){run.materials.linha=Math.max(run.materials.linha,2);run.materials.folha=Math.max(run.materials.folha,1);run.blocked=null;startStage(run);}
// 1. Armação: a vareta balança (classes altas); soltar perto do encaixe e alinhada dá nota alta.
export const wobbleAt=(kind,t)=>CLASSES[kind].wobble*Math.sin(t*3.1);
export function placeRod(run,p,angleError=0){if(run.stage!==0||run.blocked)return {ok:false};const c=CLASSES[run.kind],g=geometry(run.kind),s=run.step;
 run.active[0]=true;let best=-1,dist=Infinity;g.rods.forEach((r,i)=>{if(s.placed.includes(i))return;const d=Math.hypot(r.mid.x-p.x,r.mid.y-p.y);if(d<dist){dist=d;best=i;}});
 if(best<0||dist>c.snap){run.errors[0]++;return {ok:false,msg:'Leve a vareta até um encaixe pontilhado.'};}
 if(Math.abs(angleError)>14){run.errors[0]++;return {ok:false,msg:'Torta! Solte quando ela brilhar alinhada.'};}
 const score=clamp(1-dist/c.snap*.35-Math.abs(angleError)/14*.45);s.placed.push(best);s.scores.push(score);
 if(s.placed.length===c.rods)return {ok:true,slot:best,score,grade:finishStage(run,avg(s.scores)),done:true};
 return {ok:true,slot:best,score};}
function nextKnotWindow(run){const width=CLASSES[run.kind].ring.width,r=rng((run.seed^Math.imul(++run.knotSequence,0x45d9f3b))>>>0)(),start=.22+r*(.86-width-.22);return [start,start+width];}
export const knotWindow=(run,i)=>run.step.windows[i];
// 2. Nós: o anel enche cada vez mais rápido enquanto o dedo segura.
export function holdKnot(run,i){if(run.stage!==1||run.blocked||run.step.tied.includes(i)||!Number.isInteger(i)||!run.step.windows[i])return false;run.active[1]=true;run.step.holding=i;run.step.fill=0;return true;}
export function tickKnot(run,dt){const s=run.step;if(run.stage!==1||s.holding==null)return null;s.fill+=CLASSES[run.kind].ring.speed*dt*(.55+s.fill);if(s.fill>=1){s.windows[s.holding]=nextKnotWindow(run);s.holding=null;s.fill=0;return lose(run,'linha','A linha arrebentou: soltou tarde.');}return null;}
export function releaseKnot(run){const s=run.step;if(run.stage!==1||s.holding==null)return {ok:false};const i=s.holding,[g0,g1]=knotWindow(run,i),f=s.fill;s.holding=null;s.fill=0;
 if(f<g0){run.errors[1]++;s.windows[i]=nextKnotWindow(run);return {ok:false,msg:'Frouxo. Tente acertar a nova faixa verde.'};}
 if(f>g1){s.windows[i]=nextKnotWindow(run);return lose(run,'linha','Apertou demais e a linha arrebentou.');}
 const mid=(g0+g1)/2,score=clamp(1-Math.abs(f-mid)/((g1-g0)/2)*.5);s.tied.push(i);s.scores.push(score);
 if(s.tied.length===CLASSES[run.kind].rods)return {ok:true,score,grade:finishStage(run,avg(s.scores)),done:true};
 return {ok:true,score};}
// 3. Papel: cortar perto da linha cobre o contorno; entrar na vela rasga.
export function cutAt(run,p,dt=0){const s=run.step;if(run.stage!==2||run.blocked||s.done)return null;run.active[2]=true;const c=CLASSES[run.kind].cut,g=geometry(run.kind),d=distToPath(p,g.path);s.time+=dt;
 if(d<=c.tol){g.samples.forEach((q,i)=>{if(Math.hypot(q.x-p.x,q.y-p.y)<=c.tol*1.3)s.covered.add(i);});s.sumD+=d;s.nD++;}
 else if(inside(p,g.path)){s.tear+=c.tear*Math.min(3,d/c.tol);if(s.tear>=1){startStage(run);return {...lose(run,'folha','A vela rasgou. Pegue outra folha.'),torn:true};}return {warn:true};}
 if(s.covered.size/g.samples.length>=.95){s.done=true;const accuracy=s.nD?1-s.sumD/s.nD/c.tol:0,speed=clamp(c.target/Math.max(1,s.time));return {done:true,grade:finishStage(run,clamp(.65*accuracy+.35*speed-s.tear*.35))};}
 return null;}
export const cutProgress=run=>run.stage===2?run.step.covered.size/run.step.samples:0;
// 4. Voo: rajadas avisadas antes; o jogador compensa. Pouco controle tomba, controle demais tomba para o outro lado.
export function windSchedule(kind,seed){const c=CLASSES[kind].wind,r=rng(seed*31+kind.length),list=[];let t=1.1;for(let i=0;i<c.gusts;i++){list.push({t,dir:r()<.5?-1:1,power:c.power[0]+r()*(c.power[1]-c.power[0])});t+=(FLIGHT_TIME-1.6)/c.gusts*(.75+r()*.4);}return list.filter(g=>g.t<FLIGHT_TIME-.6);}
export function windAt(step,t){let f=0;for(const g of step.gusts){const k=t-g.t;if(k>=0&&k<GUST)f+=g.dir*g.power*Math.sin(Math.PI*k/GUST);}return f;}
export const nextGust=(step,t,tell)=>step.gusts.find(g=>g.t>t&&g.t-t<=tell)||null;
export function tickFlight(run,dt,control){const s=run.step;if(run.stage!==3||run.blocked||s.done)return null;run.active[3]=true;const u=clamp(control,-1,1),F=windAt(s,s.t);
 s.omega+=(150*F+110*u-3.2*s.omega-4.2*s.theta)*dt;s.theta+=s.omega*dt;s.t+=dt;if(Math.abs(s.theta)<ZONE)s.inZone+=dt;
 if(Math.abs(s.theta)>FALL){startStage(run);return {...lose(run,'linha','A pipa caiu e a linha enroscou.'),fell:true};}
 if(s.t>=FLIGHT_TIME){s.done=true;return {done:true,grade:finishStage(run,clamp(s.inZone/FLIGHT_TIME*1.08))};}
 return null;}
// 5. Despertar: o gesto firma o elo; variante independente, sorteada uma vez por montagem.
export function holdSoul(run){if(run.stage!==4||run.outcome)return false;run.step.holding=true;run.step.fill=0;return true;}
export function tickSoul(run,dt){const s=run.step;if(run.stage!==4||!s.holding)return null;s.fill=(s.fill+1/3)*Math.exp(CLASSES[run.kind].soul.speed*1.5*dt)-1/3;if(s.fill>=1){s.holding=false;return settle(run,1);}return null;}
export function releaseSoul(run){const s=run.step;if(run.stage!==4||!s.holding)return {ok:false};s.holding=false;const f=s.fill;s.fill=0;if(f<SOUL_ZONES.weak)return {ok:false,msg:'O elo não pegou. Segure mais tempo.'};return settle(run,f);}
function settle(run,f){const stars=starsOf(run);
 if(f>=SOUL_ZONES.shine)run.outcome={type:'broken',stars,craftBonus:null,msg:'O elo partiu no excesso de brilho. A rabiola ficou danificada; restaure-a no menu da Oficina.'};
 else {const variant=run.variantRoll<VARIANT_CHANCE;run.outcome={type:'born',shine:f>=SOUL_ZONES.safe,variant,chance:VARIANT_CHANCE,stars,craftBonus:craftBonus(run,f>=SOUL_ZONES.safe),msg:variant?'Um nascimento especial! A alma revelou uma variante rara.':'O elo se firmou. Seu Soulmonster nasceu!'};}
 run.stage=5;return {ok:true,outcome:run.outcome};}
const avg=a=>a.length?a.reduce((s,x)=>s+x,0)/a.length:0;
// The client supplies active simulation time; tips, blocked states and hidden tabs do not count.
export function tickCraft(run,dt){if(run.stage<4&&!run.blocked&&!run.outcome&&run.active[run.stage]&&Number.isFinite(dt)&&dt>0)run.elapsed[run.stage]+=dt;}
export function craftQuality(run){
 const completed=run.grades.slice(0,4).map((grade,i)=>({grade,i})).filter(x=>x.grade!=null);
 if(!completed.length)return {precision:0,speed:0,quality:0,errors:0,seconds:0};
 const c=CLASSES[run.kind],targets=[c.rods*3,c.rods*2.2,c.cut.target,FLIGHT_TIME];
 const precision=avg(completed.map(x=>x.grade)),speed=avg(completed.filter(x=>x.i!==3).map(x=>clamp(targets[x.i]/Math.max(targets[x.i],run.elapsed[x.i]))));
 const errors=run.errors.slice(0,4).reduce((a,b)=>a+b,0),quality=clamp(precision*.75+speed*.25-Math.min(.4,errors*.025));
 return {precision,speed,quality,errors,seconds:run.elapsed.slice(0,4).reduce((a,b)=>a+b,0)};
}
export function craftBonus(run,firm=false){const detail=craftQuality(run),assemblyPercent=Math.round(detail.quality*80)/10,eloPercent=firm?4:0;return {...detail,assemblyPercent,eloPercent,totalPercent:Math.round((assemblyPercent+eloPercent)*10)/10,multiplier:1+(assemblyPercent+eloPercent)/100};}
export function applyCraftBonus(baseStats,outcome){const multiplier=outcome?.type==='born'?outcome.craftBonus?.multiplier||1:1;return Object.fromEntries(Object.entries(baseStats).map(([key,value])=>[key,typeof value==='number'&&Number.isFinite(value)&&value>0?Math.round(value*multiplier*100)/100:value]));}
export function starsOf(run){const q=craftQuality(run).quality;return q>=.9?5:q>=.78?4:q>=.62?3:q>=.45?2:1;}
