// Pose skeleton, character sheet and animation recipes. Keypoints live on each frame
// (frame.pose), the sheet on the project (project.sheet). Recipes turn a standing frame into
// walk/run/idle cycles by moving part layers per frame; they also move the keypoints, so the
// generated frames can be checked like hand-drawn ones. See ESTILO-PIXEL.md for the reasons.
import {compositeFrame} from './document.mjs';
import {duplicateFrame,deleteFrame,sequencesFor} from './animation.mjs';
import {qualityReport} from './quality.mjs';
import {outsideRing} from './legibility.mjs';

export const POINTS=['topo','queixo','ombroTras','ombroFrente','maoTras','maoFrente','quadril','peTras','peFrente'];
export const DIRECTIONS=['S','SO','O','NO','N','NE','E','SE'];
// Default part layers. A sheet can rename them ("partes": {"pernaFrente": "Perna dir"}).
export const PARTS={pernaTras:'Perna de trás',pernaFrente:'Perna da frente',tronco:'Tronco',bracoTras:'Braço de trás',bracoFrente:'Braço da frente',cabeca:'Cabeça',cabelo:'Cabelo'};
// Keypoints follow the part that carries them. "Frente" is the limb nearer the camera.
const CARRY={topo:'cabeca',queixo:'cabeca',ombroTras:'tronco',ombroFrente:'tronco',quadril:'tronco',peTras:'pernaTras',peFrente:'pernaFrente',maoTras:'bracoTras',maoFrente:'bracoFrente'};

export function validatePose(pose,w,h){
 if(pose===undefined||pose===null)return undefined;
 if(typeof pose!=='object'||Array.isArray(pose))throw Error('Pose inválida.');
 const out={};for(const [k,v] of Object.entries(pose)){if(!POINTS.includes(k))throw Error(`Ponto de pose desconhecido: ${k}. Pontos: ${POINTS.join(', ')}`);
  if(!Array.isArray(v)||v.length!==2||v.some(n=>!Number.isInteger(n))||v[0]<0||v[1]<0||v[0]>=w||v[1]>=h)throw Error(`Ponto ${k} fora do quadro.`);out[k]=[v[0],v[1]];}
 return Object.keys(out).length?out:undefined;
}
const num=(v,a,b)=>v===undefined?undefined:Number.isFinite(Number(v))&&Number(v)>=a&&Number(v)<=b?Number(v):(()=>{throw Error(`Valor da ficha fora do intervalo ${a}–${b}: ${v}`);})();
// Character sheet: the numbers every frame of this character must respect.
export function validateSheet(s,p){
 if(s===undefined||s===null)return undefined;if(typeof s!=='object'||Array.isArray(s))throw Error('Ficha inválida.');
 const out={nome:s.nome===undefined?undefined:String(s.nome).slice(0,80),cabecas:num(s.cabecas,1,8),altura:num(s.altura,4,p.height),base:num(s.base,1,p.height-1),
  larguraMax:num(s.larguraMax,2,p.width),cores:num(s.cores,2,255),preenchimentoMax:num(s.preenchimentoMax,.2,1),referencia:s.referencia===undefined?undefined:String(s.referencia).slice(0,80),
  rampas:s.rampas===undefined?undefined:[].concat(s.rampas).map(String).slice(0,64),partes:undefined,notas:s.notas===undefined?undefined:String(s.notas).slice(0,2000)};
 if(s.partes!==undefined){if(typeof s.partes!=='object'||Array.isArray(s.partes))throw Error('Partes da ficha inválidas.');out.partes={};for(const [k,v] of Object.entries(s.partes)){if(!PARTS[k])throw Error(`Parte desconhecida: ${k}. Partes: ${Object.keys(PARTS).join(', ')}`);out.partes[k]=String(v).slice(0,80);}}
 for(const k of Object.keys(out))if(out[k]===undefined)delete out[k];return out;
}
const dist=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
// Measurements of one frame from its keypoints (and pixels for the silhouette).
export function measure(p,index){
 const f=p.frames[index],pose=f.pose||{},ind=compositeFrame(p,f),m={frame:index,name:f.name};
 let minX=p.width,minY=p.height,maxX=-1,maxY=-1,count=0;for(let i=0;i<ind.length;i++)if(ind[i]){count++;const x=i%p.width,y=(i-x)/p.width;minX=Math.min(minX,x);maxX=Math.max(maxX,x);minY=Math.min(minY,y);maxY=Math.max(maxY,y);}
 if(count){m.altura=maxY-minY+1;m.largura=maxX-minX+1;m.base=maxY;m.preenchimento=count/(m.altura*m.largura);}
 if(pose.topo&&pose.queixo){m.cabeca=pose.queixo[1]-pose.topo[1]+1;if(m.altura)m.cabecas=m.altura/m.cabeca;}
 if(pose.queixo&&pose.quadril)m.tronco=dist(pose.queixo,pose.quadril);
 for(const s of ['Tras','Frente']){if(pose['ombro'+s]&&pose['mao'+s])m['braco'+s]=dist(pose['ombro'+s],pose['mao'+s]);if(pose.quadril&&pose['pe'+s])m['perna'+s]=dist(pose.quadril,pose['pe'+s]);}
 return m;
}
const seqOf=(p,i)=>sequencesFor(p).find(s=>i>=s.start&&i<=s.end&&p.sequences);
// Pose and sheet checks. Errors block delivery, warnings ask for a look.
export function rigReport(p,{frames}={}){
 const list=frames||p.frames.map((_,i)=>i),sheet=p.sheet||{},errors=[],warnings=[],ms=list.map(i=>measure(p,i));
 const ref=sheet.referencia!==undefined?p.frames.findIndex(f=>f.name===sheet.referencia):-1,base=ref>=0?measure(p,ref):null;
 if(sheet.referencia!==undefined&&ref<0)errors.push(`Quadro de referência da ficha não existe: ${sheet.referencia}.`);
 for(const m of ms){const tag=`Quadro ${m.frame} (${m.name})`;if(!m.altura)continue;
  // Actions that change the body's height or hide part of it are exempt from height and feet line.
  const free=/^(run|fall|hurt|attack|victory|defeat|swim|climb)/.test(m.name);
  if(sheet.altura&&Math.abs(m.altura-sheet.altura)>2&&!free)errors.push(`${tag}: altura ${m.altura}px, a ficha pede ${sheet.altura}±2.`);
  if(sheet.base!==undefined&&m.base!==sheet.base&&!free)(Math.abs(m.base-sheet.base)>1?errors:warnings).push(`${tag}: pés na linha ${m.base}, a ficha pede ${sheet.base}.`);
  if(sheet.larguraMax&&m.largura>sheet.larguraMax)warnings.push(`${tag}: largura ${m.largura}px passa de ${sheet.larguraMax}.`);
  if(sheet.preenchimentoMax&&m.preenchimento>sheet.preenchimentoMax)warnings.push(`${tag}: a silhueta preenche ${Math.round(m.preenchimento*100)}% da caixa (máx. ${Math.round(sheet.preenchimentoMax*100)}%); separe braços e pernas do corpo.`);
  if(sheet.cabecas&&m.cabecas&&!free&&Math.abs(m.cabecas-sheet.cabecas)>.3)errors.push(`${tag}: ${m.cabecas.toFixed(2)} cabeças de altura, a ficha pede ${sheet.cabecas}.`);
  if(base&&m.frame!==base.frame&&!free){
   if(base.cabeca&&m.cabeca&&Math.abs(m.cabeca-base.cabeca)>1)errors.push(`${tag}: cabeça com ${m.cabeca}px, a referência tem ${base.cabeca}px.`);
   if(base.tronco&&m.tronco&&Math.abs(m.tronco-base.tronco)>2)warnings.push(`${tag}: tronco ${m.tronco.toFixed(1)}px, referência ${base.tronco.toFixed(1)}px.`);
   for(const k of ['bracoTras','bracoFrente','pernaTras','pernaFrente'])if(base[k]&&m[k]&&Math.abs(m[k]-base[k])>Math.max(2,base[k]*.3))warnings.push(`${tag}: ${k} ${m[k].toFixed(1)}px, referência ${base[k].toFixed(1)}px (encurtar só por perspectiva).`);}
 }
 // Colours: the sheet limits how many, and every colour should belong to a ramp.
 const q=qualityReport(p);if(sheet.cores&&q.colorsUsed>sheet.cores)errors.push(`${q.colorsUsed} cores em uso; a ficha permite ${sheet.cores}.`);
 if(p.ramps&&Object.keys(p.ramps).length){const inRamp=new Set(Object.values(p.ramps).flat()),loose=new Set();for(const i of list)for(const v of p.frames[i].indices)if(v&&!inRamp.has(v))loose.add(v);if(loose.size)warnings.push(`${loose.size} cor(es) fora das rampas: ${[...loose].slice(0,8).join(', ')}.`);}
 if(sheet.rampas)for(const r of sheet.rampas)if(!p.ramps?.[r])errors.push(`A ficha pede a rampa ${r}, que não existe.`);
 // Feet: in a cycle the planted foot moves at constant ground speed; in idle it never moves.
 const feet=[];for(const s of sequencesFor(p)){if(!p.sequences)break;const idx=[];for(let i=s.start;i<=s.end;i++)if(list.includes(i))idx.push(i);if(idx.length<2)continue;
  const still=/^(idle|parado)/.test(s.name),speeds=[],ground=Math.max(-1,...idx.flatMap(i=>['peTras','peFrente'].map(k=>p.frames[i].pose?.[k]?.[1]??-1)));
  for(let n=0;n<idx.length;n++){const a=p.frames[idx[n]].pose,b=p.frames[idx[(n+1)%idx.length]].pose;if(!a||!b||(n===idx.length-1&&s.loop===false))continue;
   for(const k of ['peTras','peFrente']){if(!a[k]||!b[k]||a[k][1]<ground||b[k][1]<ground)continue;const dx=b[k][0]-a[k][0],dy=b[k][1]-a[k][1];
    if(still&&(dx||dy))errors.push(`${s.name}: ${k} desliza ${dx},${dy}px entre ${p.frames[idx[n]].name} e ${p.frames[idx[(n+1)%idx.length]].name}.`);else if(/^(walk|run)/.test(s.name))speeds.push({k,dx,from:idx[n]});}}
  if(speeds.length>1){const dxs=speeds.map(v=>v.dx),spread=Math.max(...dxs)-Math.min(...dxs);if(spread>1)warnings.push(`${s.name}: o pé apoiado anda ${dxs.join('/')}px por quadro; mantenha a mesma velocidade de chão (diferença ≤ 1).`);}
  feet.push({sequence:s.name,speeds:speeds.map(v=>v.dx)});}
 const posed=list.filter(i=>p.frames[i].pose).length;if(posed&&posed<list.length)warnings.push(`${list.length-posed} quadro(s) sem pose marcada.`);
 return {measures:ms,reference:base,feet,errors,warnings};
}
// Direction class drives where "forward" points. Front/back views step in depth (a lifted foot
// is 1px shorter), sides step across, diagonals both.
export function directionVector(dir){return {S:[0,1],N:[0,-1],E:[1,0],O:[-1,0],SE:[1,1],SO:[-1,1],NE:[1,-1],NO:[-1,-1]}[dir];}
// Offsets per frame for each part: [dx,dy] where dx is "forward" in side views.
// walk: contact, passing (body up 1), contact mirrored, passing. run: 6 frames, flight up 2.
// idle: exhale, torso/head/arms down 1 with feet planted.
export const RECIPES={
 idle:{durations:[700,350],frames:[{},{body:[0,1]}]},
 walk:{durations:[140,110,140,110],frames:[
  {pernaFrente:['f',3],pernaTras:['f',-3],bracoFrente:['f',-2],bracoTras:['f',2]},
  {body:[0,-1],lift:'pernaTras'},
  {pernaFrente:['f',-3],pernaTras:['f',3],bracoFrente:['f',2],bracoTras:['f',-2]},
  {body:[0,-1],lift:'pernaFrente'}]},
 run:{durations:[90,90,90,90,90,90],frames:[
  {lean:1,pernaFrente:['f',5],pernaTras:['f',-5],bracoFrente:['f',-3],bracoTras:['f',3]},
  {lean:1,body:[0,-1],pernaFrente:['f',2],pernaTras:['f',-2],bracoFrente:['f',-1],bracoTras:['f',1],lift:'pernaTras'},
  {lean:1,all:[0,-2],pernaFrente:['f',-2],pernaTras:['f',2],bracoFrente:['f',1],bracoTras:['f',-1]},
  {lean:1,pernaFrente:['f',-5],pernaTras:['f',5],bracoFrente:['f',3],bracoTras:['f',-3]},
  {lean:1,body:[0,-1],pernaFrente:['f',-2],pernaTras:['f',2],bracoFrente:['f',1],bracoTras:['f',-1],lift:'pernaFrente'},
  {lean:1,all:[0,-2],pernaFrente:['f',2],pernaTras:['f',-2],bracoFrente:['f',-1],bracoTras:['f',1]}]}};
const UPPER=['tronco','cabeca','cabelo','bracoTras','bracoFrente'],LIMBS=['pernaTras','pernaFrente','bracoTras','bracoFrente'];
// Builds frames <motion>-<dir>-1..n after the last frame, from a base frame, plus the sequence.
export function recipe(p,{motion,dir,base,replace=false,stride=1,parts:custom}={}){
 const r=RECIPES[motion];if(!r)throw Error(`Receita desconhecida: ${motion}. Receitas: ${Object.keys(RECIPES).join(', ')}`);
 if(!DIRECTIONS.includes(dir))throw Error(`Direção inválida: ${dir}. Use ${DIRECTIONS.join(' ')}.`);
 const names={...PARTS,...(p.sheet?.partes||{}),...(custom||{})},layerOf=k=>p.layers.findIndex(l=>l.name===names[k]);
 const missing=Object.keys(PARTS).filter(k=>k!=='cabelo'&&layerOf(k)<0);if(missing.length)throw Error(`Faltam camadas para a receita: ${missing.map(k=>names[k]).join(', ')}. Desenhe uma camada por parte (ver AGENTS.md).`);
 const name=`${motion}-${dir}`,b=typeof base==='number'?base:p.frames.findIndex(f=>f.name===base);if(b<0||!p.frames[b])throw Error(`Quadro base inexistente: ${base}`);
 const old=p.frames.map((f,i)=>f.name.startsWith(name+'-')&&/^\d+$/.test(f.name.slice(name.length+1))?i:-1).filter(i=>i>=0);
 if(old.length&&!replace)throw Error(`Já existem quadros ${name}-*. Use replace para refazer.`);
 const snap={cels:p.frames[b].cels.map(c=>c.slice()),pose:p.frames[b].pose?structuredClone(p.frames[b].pose):undefined};
 if(p.sequences)p.sequences=p.sequences.filter(s=>s.name!==name);
 const [vx,vy]=directionVector(dir),front=vx===0,side=vy===0,w=p.width,created=[];
 r.frames.forEach((spec,n)=>{
  // Append after the last frame: duplicating the last one keeps every sequence range intact.
  const i=duplicateFrame(p,p.frames.length-1),fr=p.frames[i];p.sequences=p.sequences?.map(q=>q.end===i?{...q,end:i-1}:q);
  fr.cels=snap.cels.map(c=>c.slice());fr.name=`${name}-${n+1}`;fr.duration=r.durations[n];const pose=snap.pose?structuredClone(snap.pose):undefined;
  // 'f' = forward along the facing. Sides slide across; diagonals across and half in depth;
  // front/back views raise the limb that goes away from the camera by 1px (never below the base).
  const base=k=>{const [bx,by]=spec.all||(UPPER.includes(k)&&spec.body)||[0,0];return [bx+(spec.lean&&UPPER.includes(k)&&!front?spec.lean*Math.sign(vx):0),by];};
  const move={};for(const k of Object.keys(PARTS)){let [dx,dy]=spec.all||(UPPER.includes(k)&&spec.body)||[0,0];const o=spec[k];
   if(o){const s=Math.round(o[1]*stride);if(front){if(Math.sign(s)*vy<0)dy-=1;}else{dx+=s*Math.sign(vx);if(!side&&Math.sign(s)*vy<0)dy-=Math.ceil(Math.abs(s)/2);}}
   if(spec.lean&&UPPER.includes(k)&&!front)dx+=spec.lean*Math.sign(vx);
   if(spec.lift===k)dy-=1;
   move[k]=[dx,dy];}
  // Limbs swing from the hip/shoulder: the top row stays, the foot/hand row takes the whole
  // forward offset (a shear), so the stride opens instead of the leg sliding. The body offset
  // (bob, lean) moves the limb as a whole.
  for(const [k,[dx,dy]] of Object.entries(move)){const l=layerOf(k);if(l<0||(!dx&&!dy))continue;const cel=fr.cels[l],src=cel.slice();cel.fill(0);
   const swing=LIMBS.includes(k)?dx-base(k)[0]:0,whole=dx-swing;let top=p.height,bottom=-1;if(swing)for(let i=0;i<src.length;i++)if(src[i]){const y=(i/w)|0;top=Math.min(top,y);bottom=Math.max(bottom,y);}
   for(let y=0;y<p.height;y++){const sx=swing?Math.round(swing*(y-top)/Math.max(1,bottom-top)):0;for(let x=0;x<w;x++){const v=src[y*w+x];const nx=x+whole+sx,ny=y+dy;if(v&&nx>=0&&ny>=0&&nx<w&&ny<p.height)cel[ny*w+nx]=v;}}}
  if(pose){const bump=(pt,part)=>{if(pose[pt]){pose[pt][0]=Math.max(0,Math.min(w-1,pose[pt][0]+move[part][0]));pose[pt][1]=Math.max(0,Math.min(p.height-1,pose[pt][1]+move[part][1]));}};
   for(const [pt,part] of Object.entries(CARRY))bump(pt,part);fr.pose=pose;}
  // An outer outline drawn on the base would stay behind; redraw it around the moved parts.
  const ol=p.layers.findIndex(l=>l.name==='Contorno');if(ol>=0){const cel=fr.cels[ol],count=new Map();for(const v of cel)if(v)count.set(v,(count.get(v)||0)+1);
   if(count.size){const color=[...count].sort((x,y)=>y[1]-x[1])[0][0];cel.fill(0);const ring=outsideRing(compositeFrame(p,fr),w,p.height);ring.forEach((v,k)=>{if(v)cel[k]=color;});}}
  compositeFrame(p,fr);created.push(fr);});
 const kept=new Set((p.sequences||[]).map(q=>q.name));for(const i of [...old].sort((x,y)=>y-x))deleteFrame(p,i);
 if(p.sequences)p.sequences=p.sequences.filter(q=>kept.has(q.name));
 const at=created.map(f=>p.frames.indexOf(f)),start=at[0],end=at.at(-1);p.sequences=[...(p.sequences||[]),{name,start,end,loop:true,direction:'forward'}];
 return {sequence:name,frames:at};
}
// Draws keypoints and bones over an RGBA review canvas (render --pose).
export function drawPose(cv,pose,ox,oy,zoom){
 if(!pose)return;const col={topo:[255,214,102,255],queixo:[255,214,102,255],quadril:[255,120,120,255],ombroTras:[90,140,200,255],ombroFrente:[120,200,255,255],maoTras:[80,190,130,255],maoFrente:[120,255,170,255],peTras:[190,100,170,255],peFrente:[255,140,220,255]};
 const bones=[['topo','queixo'],['queixo','quadril'],['ombroTras','maoTras'],['ombroFrente','maoFrente'],['ombroTras','ombroFrente'],['quadril','peTras'],['quadril','peFrente']];
 const c=pt=>[ox+pose[pt][0]*zoom+(zoom>>1),oy+pose[pt][1]*zoom+(zoom>>1)];
 for(const [a,b] of bones){if(!pose[a]||!pose[b])continue;const [x0,y0]=c(a),[x1,y1]=c(b),n=Math.max(Math.abs(x1-x0),Math.abs(y1-y0),1);for(let t=0;t<=n;t++)cv.set(Math.round(x0+(x1-x0)*t/n),Math.round(y0+(y1-y0)*t/n),[255,255,255,170]);}
 for(const pt of Object.keys(pose)){const [x,y]=c(pt),r=Math.max(1,zoom>>2);cv.rect(x-r-1,y-r-1,r*2+3,r*2+3,[20,24,30,255]);cv.rect(x-r,y-r,r*2+1,r*2+1,col[pt]);}
}
