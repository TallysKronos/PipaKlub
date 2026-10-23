// Neutral kite construction. Species identity is deliberately absent from this model.
export const CRAFT_CLASSES={
 common:{label:'Comum',shape:'Diamante',sides:4,tolerance:25,cutTolerance:22,pull:[24,64]},
 uncommon:{label:'Incomum',shape:'Hexagonal',sides:6,tolerance:21,cutTolerance:18,pull:[29,60]},
 rare:{label:'Raro',shape:'Estrela de vento',sides:8,tolerance:17,cutTolerance:14,pull:[33,57]}
};
export function craftClass(value){return ({comum:'common',incomum:'uncommon',raro:'rare',rara:'rare',epic:'rare',legendary:'rare',épico:'rare',lendário:'rare'})[value]|| (CRAFT_CLASSES[value]?value:'common');}
export function craftGeometry(kind='common'){
 const c=CRAFT_CLASSES[craftClass(kind)],center={x:480,y:294},points=Array.from({length:c.sides},(_,i)=>{
  const a=-Math.PI/2+i*Math.PI*2/c.sides,r=c.sides===8&&i%2?142:184;
  return {x:center.x+Math.cos(a)*r,y:center.y+Math.sin(a)*r};
 });
 const samples=[];points.forEach((p,i)=>{const q=points[(i+1)%points.length],n=Math.ceil(Math.hypot(q.x-p.x,q.y-p.y)/9);for(let j=0;j<n;j++)samples.push({x:p.x+(q.x-p.x)*j/n,y:p.y+(q.y-p.y)*j/n});});
 return {center,points,samples,rods:points.map(p=>({x:(p.x+480)/2,y:(p.y+294)/2,a:p,b:center}))};
}
export function createCraft(kind='common',stage=0){
 kind=craftClass(kind);return {version:2,kind,stage,tool:stage===0?'pinça':stage===1?'linha':stage===2?'tesoura':stage===3?'vento':'pinça',rods:[],knots:[],cut:[],glue:[],seated:false,damage:0,grade:100,balance:32,tested:false,tail:false,synced:false,drag:null,cursor:{x:480,y:294},last:null,carrying:null,cutPhase:'cut',light:true,paused:false,message:'',flash:0};
}
export const CRAFT_TOOLS=[['pinça','Pinça'],['linha','Linha'],['tesoura','Tesoura'],['cola','Cola'],['vento','Vento'],['luz','Gabarito']];
export function craftReady(s){const n=craftGeometry(s.kind).points.length;return !craftFailed(s)&&(s.stage===0?s.rods.length===n:s.stage===1?s.knots.length===n:s.stage===2?s.seated:s.stage===3?s.tested&&Math.abs(s.balance-50)<14:s.stage===4?s.tail&&s.synced:true);}
export function craftFailed(s){return s.damage>=100;}
export function craftProgress(s){if(s.stage>=5)return 1;const g=craftGeometry(s.kind);return s.stage===0?s.rods.length/g.points.length:s.stage===1?s.knots.length/g.points.length:s.stage===2?s.cutPhase==='cut'?s.cut.length/g.samples.length*.5:s.cutPhase==='glue'?.5+s.glue.length/g.points.length*.35:s.seated?1:.85:s.stage===3?s.tested?1-Math.min(1,Math.abs(s.balance-50)/50):0:s.tail?(s.synced?1:.6):0;}
export function craftInstruction(s){
 if(craftFailed(s))return 'O papel rasgou. Refaça a etapa; a rabiola está segura.';
 if(craftReady(s))return s.stage===4?'O elo respondeu. Desperte seu parceiro.':'Pronto! Confirme para guardar esta etapa.';
 if(s.stage===0)return s.carrying?'Leve a vareta ao encaixe pontilhado e solte.':'Pegue uma vareta na bandeja à direita com a pinça.';
 if(s.stage===1)return 'Puxe a linha de cada união até a faixa marcada e solte.';
 if(s.stage===2)return s.cutPhase==='cut'?'Pegue a tesoura e siga o contorno. Corte para dentro causa rasgo.':s.cutPhase==='glue'?'Passe cola nas uniões marcadas. Preserve o centro da vela.':'Com a pinça, leve o papel da bandeja para a armação.';
 if(s.stage===3)return 'Teste com o vento. Arraste o cabresto até a pipa parar de pender.';
 return s.tail?'Puxe o fio até a faixa dourada e solte para firmar o elo.':'A alma continua oculta. Leve a rabiola selada ao pé da pipa.';
}
export function craftPayload(s){
 if(!craftReady(s))throw Error('Conclua a interação antes de confirmar.');
 if(s.stage===0)return {joints:[0,1,2,3]};if(s.stage===1)return {tension:Math.round(65-(100-s.grade)/3)};
 if(s.stage===2)return {cuts:[0,1,2,3],reveal:Math.max(0,Math.round(100-s.damage))};if(s.stage===3)return {balance:Math.round(s.balance)};
 return {wind:50,tension:50};
}
const craftDistance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
function craftInside(p,points){let v=false;for(let i=0,j=points.length-1;i<points.length;j=i++)if((points[i].y>p.y)!==(points[j].y>p.y)&&p.x<(points[j].x-points[i].x)*(p.y-points[i].y)/(points[j].y-points[i].y)+points[i].x)v=!v;return v;}
export function craftSelect(s,tool){if(s.paused)return;if(tool==='luz'){s.light=!s.light;return;}s.tool=tool;s.drag=null;s.last=null;s.carrying=null;s.message='';}
export function craftDown(s,p){
 if(s.paused||craftFailed(s)||s.stage>=5)return;
 s.cursor={...p};s.message='';s.last=null;const g=craftGeometry(s.kind),c=CRAFT_CLASSES[s.kind];
 if(s.carrying){s.drag={type:s.carrying};return;}
 if(s.stage===0&&s.tool==='pinça'){
  if(p.x>770&&p.y>120&&p.y<480){s.carrying='rod';s.drag={type:'rod'};return;}
  if(s.carrying==='rod'){s.drag={type:'rod'};return;}
 }
 if(s.stage===1&&s.tool==='linha'){
  const i=g.points.findIndex((q,i)=>!s.knots.includes(i)&&craftDistance(q,p)<c.tolerance+8);
  if(i>=0){s.drag={type:'knot',i,start:g.points[i]};return;}
 }
 if(s.stage===2){
  if(s.cutPhase==='cut'&&s.tool==='tesoura'){s.drag={type:'cut',distance:0};craftMove(s,p);return;}
  if(s.cutPhase==='glue'&&s.tool==='cola'){s.drag={type:'glue',distance:0};craftMove(s,p);return;}
  if(s.cutPhase==='seat'&&s.tool==='pinça'&&p.x>770&&p.y>120&&p.y<480){s.carrying='paper';s.drag={type:'paper'};return;}
 }
 if(s.stage===3){if(s.tool==='vento'){s.tested=true;s.message='Observe a inclinação e ajuste o cabresto.';}if(craftDistance(p,{x:350+s.balance*2.6,y:510})<38){s.drag={type:'balance'};craftMove(s,p);}return;}
 if(s.stage===4){
  if(!s.tail&&s.tool==='pinça'&&p.x>770&&p.y>120&&p.y<480){s.carrying='tail';s.drag={type:'tail'};return;}
  if(s.tail&&craftDistance(p,{x:480,y:505})<40){s.drag={type:'soul',start:{x:480,y:505}};return;}
 }
}
export function craftMove(s,p){
 s.cursor={x:Math.max(185,Math.min(925,p.x)),y:Math.max(100,Math.min(565,p.y))};if(s.paused||!s.drag)return;
 const g=craftGeometry(s.kind),c=CRAFT_CLASSES[s.kind];
 if(s.drag.type==='balance'){s.balance=Math.max(0,Math.min(100,(p.x-350)/2.6));return;}
 if(!['cut','glue'].includes(s.drag.type))return;
 // Resample by travelled distance, including residual distance across events.
 if(!s.last){s.last={...p};craftStrokeAt(s,p,g,c);return;}
 let from=s.last,dx=p.x-from.x,dy=p.y-from.y,d=Math.hypot(dx,dy),remaining=4-(s.drag.distance||0);
 while(d>=remaining&&s.drag){const q={x:from.x+dx*remaining/d,y:from.y+dy*remaining/d};craftStrokeAt(s,q,g,c);from=q;dx=p.x-q.x;dy=p.y-q.y;d=Math.hypot(dx,dy);remaining=4;}
 if(!s.drag)return;
 s.drag.distance=4-remaining+d;s.last={...p};
}
function craftStrokeAt(s,p,g,c){
 if(s.cutPhase==='cut'){
  let near=false;g.samples.forEach((q,i)=>{if(craftDistance(q,p)<=c.cutTolerance){near=true;if(!s.cut.includes(i))s.cut.push(i);}});
  if(!near&&craftInside(p,g.points)){s.damage=Math.min(100,s.damage+.8);s.flash=1;s.message='Cuidado: a tesoura entrou na vela.';}
  if(s.cut.length/g.samples.length>=.92){s.cutPhase='glue';s.drag=null;s.last=null;s.message='Contorno pronto. Pegue a cola.';}
 }else if(s.cutPhase==='glue'){
  let near=false;g.points.forEach((q,i)=>{if(craftDistance(q,p)<c.tolerance+10){near=true;if(!s.glue.includes(i))s.glue.push(i);}});
  if(!near&&craftInside(p,g.points)){s.damage=Math.min(100,s.damage+.12);s.flash=1;s.message='Cola no centro pesa a vela. Use as uniões.';}
  if(s.glue.length===g.points.length){s.cutPhase='seat';s.drag=null;s.last=null;s.message='Uniões prontas. Pegue o papel com a pinça.';}
 }
}
export function craftUp(s,p){
 if(s.paused||!s.drag)return;const d=s.drag,g=craftGeometry(s.kind),c=CRAFT_CLASSES[s.kind];s.cursor={...p};
 if(d.type==='rod'){
  const i=g.rods.findIndex((q,i)=>!s.rods.includes(i)&&craftDistance(q,p)<c.tolerance+8);
  if(i>=0){s.rods.push(i);s.carrying=null;s.message='Vareta assentada.';}else{s.message='Aproxime o centro da vareta do apoio pontilhado.';}
 }
 if(d.type==='knot'||d.type==='soul'){
  const pull=craftDistance(p,d.start),[min,max]=c.pull;
  if(pull>=min&&pull<=max){if(d.type==='knot'){s.knots.push(d.i);s.grade=Math.min(s.grade,Math.round(100-Math.abs(pull-(min+max)/2)));}else{s.synced=true;}s.message='Fio firme.';}
  else{s.message=pull<min?'Ficou frouxo. Puxe um pouco mais.':'Tensão excessiva. Solte antes da faixa externa.';s.flash=1;}
 }
 if(d.type==='paper'||d.type==='tail'){
  const target=d.type==='paper'?g.center:{x:480,y:478};if(craftDistance(p,target)<c.tolerance+16){if(d.type==='paper'){s.seated=true;s.message='Papel aderiu à armação.';}else{s.tail=true;s.message='Rabiola presa. Firme o fio abaixo.';}s.carrying=null;}else{s.message='Siga a sombra de encaixe antes de soltar.';}
 }
 s.drag=null;s.last=null;
}
export function craftCancel(s){s.drag=null;s.last=null;s.carrying=null;}
export function craftRestore(saved,kind,stage){
 const clean=createCraft(kind,stage);if(!saved||saved.version!==2||saved.kind!==clean.kind||saved.stage!==stage)return clean;
 const n=craftGeometry(kind).points.length,m=craftGeometry(kind).samples.length;
 for(const [key,max]of [['rods',n],['knots',n],['cut',m],['glue',n]]){if(!Array.isArray(saved[key])||saved[key].some(v=>!Number.isInteger(v)||v<0||v>=max))return clean;clean[key]=[...new Set(saved[key])];}
 for(const key of ['damage','grade','balance']){if(!Number.isFinite(saved[key])||saved[key]<0||saved[key]>100)return createCraft(kind,stage);clean[key]=saved[key];}
 for(const key of ['seated','tested','tail','synced'])clean[key]=saved[key]===true;
 clean.cutPhase=clean.seated?'seat':clean.glue.length===n?'seat':clean.cut.length/m>=.92?'glue':'cut';return clean;
}
