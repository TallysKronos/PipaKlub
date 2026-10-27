// Mapa Studio: mostra o rascunho do Tiled em isométrico, deixa o Kael andar e confere a planta.
import {CELL,LEVEL_PX,MATERIALS,RAMP_DIRS,parseTiled,at,blockedByPiece,walkable,canStep,findPath,toScreen,audit,verdict} from './model.mjs';
const $=id=>document.getElementById(id),canvas=$('view'),ctx=canvas.getContext('2d');
// Em pacote autônomo (sem servidor), os arquivos vêm embutidos em MAPA_EMBED.files.
const embed=globalThis.MAPA_EMBED;
const S={m:null,raw:null,sets:{},name:'',source:'repo',items:[],solid:new Set(),cam:{x:0,y:0,z:1},kael:null,path:[],flash:null,hover:null,keys:new Set(),drag:null};
const show={grid:true,block:false,labels:true};
const say=(text,bad=false)=>{const el=$('message');el.textContent=text;el.style.color=bad?'var(--bad)':'';};
async function getJSON(path){if(embed){const v=embed.files[path];if(!v)throw Error(`${path} não está no pacote.`);return structuredClone(v);}
 const r=await fetch(path,{cache:'no-store'});if(!r.ok)throw Error(`${path}: ${r.status===404?'não encontrado':'erro '+r.status}`);return r.json();}
const listMaps=async()=>embed?Object.keys(embed.files).filter(k=>/^mapas\/.+\.tmj$/.test(k)).map(k=>k.slice(6,-4)):getJSON('mapas/');
async function setsFor(raw,given={}){const sets={...given};for(const ts of raw.tilesets||[])if(ts.source){const f=ts.source.split('/').pop();if(!sets[f])sets[f]=await getJSON('tiles/'+f);}return sets;}
// ---------- carregar ----------
function use(raw,sets,name,source){
 let m;try{m=parseTiled(raw,sets);}catch(e){say(e.message,true);return false;}
 const fresh=!S.m||S.name!==name;Object.assign(S,{m,raw,sets,name,source,solid:blockedByPiece(m),items:audit(m),path:[]});
 const k=S.kael;if(fresh||!k||!walkable(m,k.cell.u,k.cell.v,S.solid))S.kael=m.spawn&&walkable(m,m.spawn.u,m.spawn.v,S.solid)?{cell:{u:m.spawn.u,v:m.spawn.v},u:m.spawn.u+.5,v:m.spawn.v+.5}:null;
 if(fresh)fit();
 $('mapName').textContent=m.name;$('mapInfo').textContent=`${name}.tmj · ${m.w}×${m.h} células · ${m.pieces.length} peças · ${m.events.length} eventos`;
 renderAudit();const v=verdict(S.items);say(v==='ok'?'Planta conferida. Clique no chão para andar.':v==='warn'?'Planta com avisos: veja a conferência.':'A planta tem erros: corrija no Tiled e recarregue.',v==='fail');return true;}
async function loadRepo(name){try{const raw=await getJSON(`mapas/${name}.tmj`);use(raw,await setsFor(raw),name,'repo');$('mapPick').value=name;}catch(e){say(e.message,true);}}
async function loadFiles(files){
 const read=f=>f.text().then(t=>{try{return JSON.parse(t);}catch{throw Error(`${f.name} não é JSON. No Tiled, salve como .tmj (JSON).`);}});
 try{const all=await Promise.all([...files].map(async f=>({f,json:await read(f)})));const map=all.find(x=>x.json.orientation);if(!map)throw Error('Escolha o arquivo do mapa (.tmj).');
  const given=Object.fromEntries(all.filter(x=>x!==map).map(x=>[x.f.name,x.json]));use(map.json,await setsFor(map.json,given),map.f.name.replace(/\.[^.]+$/,''),'file');}
 catch(e){say(e.message,true);}}
// ---------- geometria ----------
const P=(u,v,h)=>{const s=toScreen(u,v,h);return [s.x,s.y];};
// Altura de um ponto dentro da célula (a rampa é um plano inclinado).
function hIn(c,u,v,pu,pv){if(!c.ramp)return c.level;const d=RAMP_DIRS[c.ramp];if(!d)return c.level;const fu=pu-u,fv=pv-v,t=d[0]>0?fu:d[0]<0?1-fu:d[1]>0?fv:1-fv;return c.level+(c.rampFrom??0)+t*((c.rampTo??1)-(c.rampFrom??0));}
const corners=(u,v)=>[[u,v],[u+1,v],[u+1,v+1],[u,v+1]];
const topQuad=(c,u,v)=>corners(u,v).map(([a,b])=>P(a,b,hIn(c,u,v,a,b)));
// Faces visíveis (sudeste e sudoeste) descem até a altura do vizinho naquela aresta: barranco, cunha da rampa ou nada.
function faces(m,c,u,v){const out=[];
 for(const [du,dv,side] of [[1,0,'u'],[0,1,'v']]){const n=at(m,u+du,v+dv),edge=side==='u'?[[u+1,v],[u+1,v+1]]:[[u,v+1],[u+1,v+1]];
  const top=edge.map(([a,b])=>hIn(c,u,v,a,b)),bot=edge.map(([a,b],i)=>Math.min(top[i],n?.material?hIn(n,u+du,v+dv,a,b):0));
  if(top[0]>bot[0]+1e-6||top[1]>bot[1]+1e-6)out.push({side,poly:[P(...edge[0],top[0]),P(...edge[1],top[1]),P(...edge[1],bot[1]),P(...edge[0],bot[0])],top,bot,edge});}
 return out;}
function eachCell(m,fn){for(let k=0;k<=m.w+m.h-2;k++)for(let u=Math.max(0,k-m.h+1);u<=Math.min(m.w-1,k);u++)fn(u,k-u,k);}
function inPoly(x,y,poly){let inside=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)inside=!inside;}return inside;}
function pick(wx,wy){let hit=null;const m=S.m;eachCell(m,(u,v)=>{const c=at(m,u,v);if(c.material&&inPoly(wx,wy,topQuad(c,u,v)))hit={u,v};});return hit;}
function bounds(m){let maxL=0;for(const c of m.cells)maxL=Math.max(maxL,c.level+(c.ramp?1:0));return {x0:-m.h*CELL.w/2-40,x1:m.w*CELL.w/2+40,y0:-maxL*LEVEL_PX-90,y1:(m.w+m.h)*CELL.h/2+30};}
// ---------- desenho ----------
function shade(hex,f){const n=parseInt(hex.slice(1),16),c=[n>>16,n>>8&255,n&255].map(x=>Math.max(0,Math.min(255,Math.round(f>1?x+(255-x)*(f-1):x*f))));return `rgb(${c})`;}
function poly(g,pts,fill,stroke,lw=1){g.beginPath();pts.forEach(([x,y],i)=>i?g.lineTo(x,y):g.moveTo(x,y));g.closePath();if(fill){g.fillStyle=fill;g.fill();}if(stroke){g.strokeStyle=stroke;g.lineWidth=lw;g.stroke();}}
const lerp=(a,b,t)=>[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t];
function drawTop(g,c,u,v,o){const q=topQuad(c,u,v),mat=MATERIALS[c.material],base=mat?.color||'#ff00ff';
 const fill=shade(base,1+.07*c.level);poly(g,q,fill,fill,.8);if(o.grid)poly(g,q,null,'rgba(20,30,30,.22)',.8);
 const pt=(a,b)=>P(a,b,hIn(c,u,v,a,b));
 if(c.material==='agua'){g.strokeStyle='rgba(255,255,255,.35)';g.lineWidth=1.2;for(const t of [.35,.68]){const a=pt(u+.25,v+t),b=pt(u+.75,v+t-.1);g.beginPath();g.moveTo(...a);g.quadraticCurveTo((a[0]+b[0])/2,(a[1]+b[1])/2-3,...b);g.stroke();}}
 if(c.material==='mato'){g.strokeStyle='rgba(15,50,20,.55)';g.lineWidth=1.4;for(const [a,b] of [[.3,.35],[.65,.4],[.45,.7],[.75,.75]]){const [x,y]=pt(u+a,v+b);g.beginPath();g.moveTo(x-3,y);g.lineTo(x-1,y-7);g.moveTo(x,y);g.lineTo(x+1,y-9);g.moveTo(x+3,y);g.lineTo(x+4,y-6);g.stroke();}}
 if(c.material==='ponte'){g.strokeStyle='rgba(60,35,15,.5)';g.lineWidth=1;for(const t of [.25,.5,.75]){g.beginPath();g.moveTo(...lerp(q[0],q[3],t));g.lineTo(...lerp(q[1],q[2],t));g.stroke();}}
 if(c.ramp&&RAMP_DIRS[c.ramp]){const d=RAMP_DIRS[c.ramp],cu=u+.5,cv=v+.5;g.strokeStyle='rgba(255,250,235,.85)';g.lineWidth=2.2;g.lineCap='round';
  for(const s of [-.18,.14]){const tip=pt(cu+d[0]*(s+.2),cv+d[1]*(s+.2)),l=pt(cu+d[0]*s-d[1]*.2,cv+d[1]*s+d[0]*.2),r=pt(cu+d[0]*s+d[1]*.2,cv+d[1]*s-d[0]*.2);g.beginPath();g.moveTo(...l);g.lineTo(...tip);g.lineTo(...r);g.stroke();}}
 if(o.block&&(!mat?.walk||S.solid.has(v*S.m.w+u)))poly(g,q,'rgba(255,70,60,.38)');
 return q;}
function drawFaces(g,m,c,u,v,o){for(const f of faces(m,c,u,v)){poly(g,f.poly,f.side==='u'?'#8b6a48':'#6c5038','rgba(40,25,15,.35)',.8);
  // Linha de estrato a cada nível: ajuda a ler a altura do barranco.
  g.strokeStyle='rgba(40,25,15,.28)';g.lineWidth=1;for(let h=Math.ceil(Math.min(...f.bot)+.5);h<Math.max(...f.top);h++){const a=P(...f.edge[0],Math.max(f.bot[0],Math.min(h,f.top[0]))),b=P(...f.edge[1],Math.max(f.bot[1],Math.min(h,f.top[1])));g.beginPath();g.moveTo(...a);g.lineTo(...b);g.stroke();}}}
function shadow(g,x,y,rx){g.fillStyle='rgba(0,0,0,.25)';g.beginPath();g.ellipse(x,y,rx,rx/2,0,0,Math.PI*2);g.fill();}
function label(g,text,x,y,o,color='#fff6e2'){if(!o.labels||!text)return;const fs=13/Math.min(o.z,1);g.font=`700 ${fs}px system-ui,sans-serif`;g.textAlign='center';g.textBaseline='bottom';g.lineWidth=fs/3.2;g.strokeStyle='rgba(10,18,24,.9)';g.strokeText(text,x,y);g.fillStyle=color;g.fillText(text,x,y);}
function drawPiece(g,p,o){const m=S.m,c=at(m,p.u,p.v),h=c?.level||0,[x,y]=P(p.u+p.fu/2,p.v+p.fv/2,h);
 if(p.asset==='arvore'){shadow(g,x,y,18);g.fillStyle='#6b4528';g.fillRect(x-3.5,y-22,7,22);for(const [dx,dy,r,col] of [[0,-40,21,'#2f6b34'],[-8,-46,13,'#3d8241'],[7,-50,10,'#4d9a4c']]){g.fillStyle=col;g.beginPath();g.arc(x+dx,y+dy,r,0,Math.PI*2);g.fill();}}
 else if(p.asset==='pedra'){shadow(g,x,y,15);poly(g,[[x-15,y-2],[x-9,y-15],[x+5,y-18],[x+15,y-6],[x+11,y+3],[x-8,y+4]],'#9a948a','rgba(40,40,40,.4)');poly(g,[[x-9,y-15],[x+5,y-18],[x+15,y-6],[x+2,y-8]],'#b5b0a6');}
 else{const H=p.asset==='bau'?16:36,box=[[p.u,p.v],[p.u+p.fu,p.v],[p.u+p.fu,p.v+p.fv],[p.u,p.v+p.fv]];const inset=p.asset==='bau'?.22:.06,cu=p.u+p.fu/2,cv=p.v+p.fv/2;
  const b=box.map(([a,bv])=>[cu+(a-cu)*(1-2*inset),cv+(bv-cv)*(1-2*inset)]),lo=b.map(([a,bv])=>P(a,bv,h)),hi=lo.map(([px,py])=>[px,py-H]);
  const col=p.asset==='bau'?'#a4673a':'#b48f6c';shadow(g,x,y,14);poly(g,[lo[1],lo[2],hi[2],hi[1]],shade(col,.8));poly(g,[lo[2],lo[3],hi[3],hi[2]],shade(col,.62));poly(g,hi,col,'rgba(30,20,10,.4)');
  if(p.asset==='bau'){g.fillStyle='#f0bd52';g.fillRect(hi[2][0]-2,hi[2][1]+3,4,6);}else label(g,p.asset,x,y-H-4,o,'#e8dcc8');}
 if(p.interact)label(g,p.name,x,y-(p.asset==='bau'?24:58),o,'#f0bd52');}
function drawEvent(g,e,o){const c=at(S.m,e.u,e.v),h=c?hIn(c,e.u,e.v,e.u+.5,e.v+.5):0,[x,y]=P(e.u+.5,e.v+.5,h),q=c?topQuad(c,e.u,e.v):null;
 const col={entrada:'#7fd49e',npc:'#ff9f5a',saida:'#f0bd52'}[e.type]||'#c79bff';
 if(q)poly(g,q,col+'40',col,2);
 if(e.type==='npc'){shadow(g,x,y,9);g.fillStyle=col;g.beginPath();g.ellipse(x,y-12,7,12,0,0,Math.PI*2);g.fill();g.fillStyle='#ffd9b8';g.beginPath();g.arc(x,y-28,6,0,Math.PI*2);g.fill();label(g,e.name,x,y-37,o,col);}
 else{g.strokeStyle=col;g.lineWidth=2.5;g.beginPath();g.moveTo(x,y);g.lineTo(x,y-34);g.stroke();poly(g,[[x,y-34],[x+16,y-28],[x,y-22]],col);
  label(g,e.type==='saida'?`${e.name||'Saída'}${e.props.destino?' → '+e.props.destino:''}`:e.name||e.type,x,y-38,o,col);}}
function drawKael(g){const k=S.kael;if(!k)return;const c=at(S.m,k.cell.u,k.cell.v),h=c?hIn(c,k.cell.u,k.cell.v,k.u,k.v):0,[x,y]=P(k.u,k.v,h);
 shadow(g,x,y,10);g.fillStyle='#3d7be0';g.beginPath();g.ellipse(x,y-13,8,13,0,0,Math.PI*2);g.fill();g.fillStyle='#f4c79a';g.beginPath();g.arc(x,y-30,7,0,Math.PI*2);g.fill();g.fillStyle='#2b2320';g.beginPath();g.arc(x,y-32,7,Math.PI,0);g.fill();}
// Desenha a cena inteira em coordenadas do mundo, em ordem de profundidade (u+v): terreno da diagonal, depois o que está em pé nela.
function drawScene(g,o){const m=S.m;if(!m)return;const rows=Array.from({length:m.w+m.h},()=>[]);
 for(const p of m.pieces)rows[Math.min(rows.length-1,p.u+p.fu-1+p.v+p.fv-1)]?.push(gg=>drawPiece(gg,p,o));
 if(o.events)for(const e of m.events)rows[e.u+e.v]?.push(gg=>drawEvent(gg,e,o));
 if(o.kael&&S.kael)rows[S.kael.cell.u+S.kael.cell.v]?.push(drawKael);
 let k0=-1;const flush=k=>{for(;k0<k;k0++)if(k0>=0)for(const fn of rows[k0])fn(g);};
 eachCell(m,(u,v,k)=>{flush(k);const c=at(m,u,v);if(!c.material){if(o.grid)poly(g,topQuad(c,u,v),null,'rgba(255,255,255,.08)');return;}drawFaces(g,m,c,u,v,o);drawTop(g,c,u,v,o);
  if(o.path&&S.path.some(p=>p.u===u&&p.v===v)){const [x,y]=P(u+.5,v+.5,hIn(c,u,v,u+.5,v+.5));g.fillStyle='rgba(255,255,255,.7)';g.beginPath();g.arc(x,y,3,0,Math.PI*2);g.fill();}});
 flush(rows.length);
 if(o.labels)for(const zone of m.zones||[]){
  const q=[[zone.u,zone.v],[zone.u+zone.fu,zone.v],[zone.u+zone.fu,zone.v+zone.fv],[zone.u,zone.v+zone.fv]].map(([u,v])=>P(u,v,0));
  g.save();g.setLineDash([6,5]);poly(g,q,null,'#f0bd52',1.5);g.restore();
  const [x,y]=P(zone.u+zone.fu*.5,zone.v+zone.fv*.5,0);label(g,zone.name,x,y,o,'#f0bd52');
 }
 for(const [cell,col] of [[o.hover,'#f0bd52'],[o.flash,'#ff7a73']])if(cell){const c=at(m,cell.u,cell.v);if(c)poly(g,topQuad(c,cell.u,cell.v),null,col,2.5);}
 if(o.coords){g.font='600 11px ui-monospace,monospace';g.fillStyle='rgba(255,246,226,.75)';g.textAlign='center';g.textBaseline='middle';
  for(let u=0;u<m.w;u+=5){const [x,y]=P(u+.5,-.6,0);g.fillText('u'+u,x,y);}for(let v=0;v<m.h;v+=5){const [x,y]=P(-.6,v+.5,0);g.fillText('v'+v,x,y);}}}
// ---------- câmera e laço ----------
function resize(){const r=canvas.getBoundingClientRect(),d=devicePixelRatio||1;canvas.width=Math.round(r.width*d);canvas.height=Math.round(r.height*d);}
function fit(){resize();const b=bounds(S.m),d=devicePixelRatio||1,w=canvas.width/d,h=canvas.height/d,z=Math.min(w/(b.x1-b.x0),h/(b.y1-b.y0))*.96;S.cam={z,x:w/2-(b.x0+b.x1)/2*z,y:h/2-(b.y0+b.y1)/2*z};}
const toWorld=(sx,sy)=>[(sx-S.cam.x)/S.cam.z,(sy-S.cam.y)/S.cam.z];
function centerOn(cell){const d=devicePixelRatio||1,c=at(S.m,cell.u,cell.v),[x,y]=P(cell.u+.5,cell.v+.5,c?.level||0);S.cam.z=Math.max(S.cam.z,.9);S.cam.x=canvas.width/d/2-x*S.cam.z;S.cam.y=canvas.height/d/2-y*S.cam.z;}
let last=performance.now();
function frame(t){const dt=Math.min(.05,(t-last)/1000);last=t;step(dt);const d=devicePixelRatio||1;ctx.setTransform(1,0,0,1,0,0);ctx.fillStyle='#0c161e';ctx.fillRect(0,0,canvas.width,canvas.height);
 if(S.m){ctx.setTransform(S.cam.z*d,0,0,S.cam.z*d,S.cam.x*d,S.cam.y*d);const flash=S.flash&&t-S.flash.t<2400&&Math.floor((t-S.flash.t)/300)%2===0?S.flash:null;drawScene(ctx,{...show,z:S.cam.z,events:true,kael:true,path:true,hover:S.hover,flash});}
 requestAnimationFrame(frame);}
function step(dt){const k=S.kael;if(!k||!S.path.length)return;const n=S.path[0],tx=n.u+.5,ty=n.v+.5,du=tx-k.u,dv=ty-k.v,dist=Math.hypot(du,dv),sp=4.2*dt;
 // Troca a célula no meio do caminho, para a altura acompanhar a rampa.
 if(dist<=sp){k.u=tx;k.v=ty;k.cell={u:n.u,v:n.v};S.path.shift();return;}k.u+=du/dist*sp;k.v+=dv/dist*sp;if(dist<.5)k.cell={u:n.u,v:n.v};}
function walkTo(cell){const m=S.m,k=S.kael;if(!k)return say('O mapa não tem entrada onde se anda: o Kael não tem onde aparecer.',true);
 const c=at(m,cell.u,cell.v);if(!walkable(m,cell.u,cell.v,S.solid))return say(`${cell.u},${cell.v}: ${S.solid.has(cell.v*m.w+cell.u)?'ocupado por uma peça':MATERIALS[c.material]?.name||'sem chão'}, não dá para pisar.`);
 const from=S.path[0]||k.cell,path=findPath(m,from,cell,S.solid);if(!path)return say(`Sem caminho até ${cell.u},${cell.v}. Falta rampa, ponte ou passagem.`,true);
 S.path=S.path.length?[S.path[0],...path.slice(1)]:path.slice(1);say(`Andando até ${cell.u},${cell.v} (${path.length-1} passos).`);}
// ---------- painel ----------
function renderAudit(){const ul=$('audit');ul.replaceChildren(...S.items.map(i=>{const li=document.createElement('li');li.dataset.level=i.level;const b=document.createElement('b');b.textContent=({ok:'OK',warn:'AVISO',fail:'ERRO'})[i.level]+' · '+i.rule;const s=document.createElement('span');s.textContent=i.text;li.append(b,s);
 if(i.cell){li.tabIndex=0;li.title='Mostrar no mapa';const go=()=>{centerOn(i.cell);S.flash={u:i.cell.u,v:i.cell.v,t:performance.now()};};li.onclick=go;li.onkeydown=e=>{if(e.key==='Enter')go();};}return li;}));}
function renderLegend(){const li=(color,text)=>{const el=document.createElement('li'),i=document.createElement('i');i.style.background=color;el.append(i,text);return el;};
 $('legend').replaceChildren(...Object.values(MATERIALS).map(m=>li(m.color,m.name+(m.walk?'':' — bloqueia'))),li('#8b6a48','Barranco (sai da camada altura)'),li('#7fd49e','Entrada'),li('#ff9f5a','NPC'),li('#f0bd52','Saída / baú'));}
// ---------- exportar referência ----------
function exportPNG(withLabels){if(!S.m)return;const exportName=S.name,b=bounds(S.m),scale=withLabels?1.5:2,c=document.createElement('canvas');c.width=Math.ceil((b.x1-b.x0)*scale);c.height=Math.ceil((b.y1-b.y0)*scale);
 const g=c.getContext('2d');g.fillStyle=withLabels?'#0c161e':'#1b2a33';g.fillRect(0,0,c.width,c.height);g.setTransform(scale,0,0,scale,-b.x0*scale,-b.y0*scale);
 drawScene(g,{grid:withLabels,labels:withLabels,block:false,events:withLabels,kael:false,coords:withLabels,z:1});
 c.toBlob(async blob=>{if(!blob)return say('O navegador não gerou a imagem.',true);const previous=$('lastExport');if(previous){URL.revokeObjectURL(previous.href);previous.remove();}
  const a=document.createElement('a');a.id='lastExport';a.href=URL.createObjectURL(blob);a.download=`${exportName}-${withLabels?'legendas':'referencia'}.png`;
  say(`${a.download}: ${c.width}×${c.height}px${withLabels?'':' — sem textos, para o Codex pintar por cima'}. `);
  a.textContent='Salvar PNG';a.style.color='inherit';$('message').append(a);
  if(!embed&&new URLSearchParams(location.search).get('salvar')==='1'){
   try{const result=await fetch('/export-reference',{method:'POST',headers:{'Content-Type':'image/png','X-Export-Name':a.download},body:blob});if(!result.ok)throw Error('HTTP '+result.status);say(`Salvo no projeto: ${(await result.json()).saved} · ${c.width}×${c.height}px`);$('message').append(a);}catch(e){say(`Não foi possível salvar no projeto: ${e.message}. Use Salvar PNG.`,true);$('message').append(a);}
  }else a.click();},'image/png');}
// ---------- eventos ----------
for(const id of Object.keys(show)){$(id).checked=show[id];$(id).onchange=e=>{show[id]=e.target.checked;};}
$('open').onclick=()=>$('fileMap').click();$('fileMap').onchange=e=>{if(e.target.files.length)loadFiles(e.target.files);e.target.value='';};
$('reload').onclick=()=>S.source==='repo'?loadRepo(S.name):say('Mapa aberto do computador: use "Abrir .tmj" de novo depois de salvar (o navegador não relê o arquivo sozinho).');
$('mapPick').onchange=e=>loadRepo(e.target.value);$('refPlain').onclick=()=>exportPNG(false);$('refLabels').onclick=()=>exportPNG(true);
addEventListener('resize',()=>{resize();});
canvas.addEventListener('contextmenu',e=>e.preventDefault());
canvas.addEventListener('pointerdown',e=>{canvas.focus();if(e.button===2||e.button===1||S.keys.has(' ')){S.drag={x:e.clientX,y:e.clientY,cx:S.cam.x,cy:S.cam.y};canvas.setPointerCapture(e.pointerId);return;}
 if(e.button===0&&S.m){const r=canvas.getBoundingClientRect(),cell=pick(...toWorld(e.clientX-r.left,e.clientY-r.top));if(cell)walkTo(cell);}});
canvas.addEventListener('pointermove',e=>{if(S.drag){S.cam.x=S.drag.cx+e.clientX-S.drag.x;S.cam.y=S.drag.cy+e.clientY-S.drag.y;return;}if(!S.m)return;
 const r=canvas.getBoundingClientRect(),cell=pick(...toWorld(e.clientX-r.left,e.clientY-r.top));S.hover=cell;
 if(cell){const c=at(S.m,cell.u,cell.v);$('pos').textContent=`${cell.u},${cell.v} · ${MATERIALS[c.material]?.name||c.material||'vazio'} · nível ${c.level}${c.ramp?' · rampa '+c.ramp:''}${walkable(S.m,cell.u,cell.v,S.solid)?'':' · bloqueado'}`;}else $('pos').textContent='';});
canvas.addEventListener('pointerup',()=>{S.drag=null;});
canvas.addEventListener('wheel',e=>{e.preventDefault();const r=canvas.getBoundingClientRect(),sx=e.clientX-r.left,sy=e.clientY-r.top,[wx,wy]=toWorld(sx,sy),z=Math.max(.2,Math.min(4,S.cam.z*Math.exp(-e.deltaY*.0015)));S.cam={z,x:sx-wx*z,y:sy-wy*z};},{passive:false});
// Setas na tela: ↑ fundo-direita (v-), → frente-direita (u+), ↓ frente-esquerda (v+), ← fundo-esquerda (u-).
const KEYDIR={ArrowUp:[0,-1],w:[0,-1],ArrowRight:[1,0],d:[1,0],ArrowDown:[0,1],s:[0,1],ArrowLeft:[-1,0],a:[-1,0]};
canvas.addEventListener('keydown',e=>{S.keys.add(e.key);const d=KEYDIR[e.key.length===1?e.key.toLowerCase():e.key];if(e.key===' ')e.preventDefault();if(e.key==='Escape')S.path=S.path.slice(0,1);
 if(!d||!S.kael||!S.m)return;e.preventDefault();if(S.path.length>1)return;const a=S.path[0]||S.kael.cell,b={u:a.u+d[0],v:a.v+d[1]};if(at(S.m,b.u,b.v)&&canStep(S.m,a,b,S.solid))S.path.push(b);else say(`Não dá para ir de ${a.u},${a.v} para ${b.u},${b.v}: ${!at(S.m,b.u,b.v)?'borda do mapa':!walkable(S.m,b.u,b.v,S.solid)?'chão bloqueado':'desnível sem rampa'}.`);});
canvas.addEventListener('keyup',e=>S.keys.delete(e.key));
// ---------- início ----------
renderLegend();resize();requestAnimationFrame(frame);
(async()=>{try{const maps=await listMaps(),pickEl=$('mapPick');pickEl.replaceChildren(...maps.map(n=>Object.assign(document.createElement('option'),{value:n,textContent:n})));
 const want=new URLSearchParams(location.search).get('mapa');await loadRepo(maps.includes(want)?want:maps.includes('veredas-piloto')?'veredas-piloto':maps[0]);
 if(embed){$('reload').hidden=true;}}catch(e){say(`Não consegui listar os mapas (${e.message}). Use "Abrir .tmj".`,true);}})();
