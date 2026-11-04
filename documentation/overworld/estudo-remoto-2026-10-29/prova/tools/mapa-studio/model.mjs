// Mapas do overworld: lê um mapa isométrico do Tiled (64×32), deriva colisão, alturas e barrancos, e confere a planta.
// Sem DOM: o mesmo módulo serve à bancada, aos testes e ao jogo.
export const CELL={w:64,h:32},LEVEL_PX=64,RULES='overworld-1';
// Materiais do rascunho. "anda" diz se o Kael pisa; "agua" e "rocha" bloqueiam.
export const MATERIALS={
 grama:{name:'Grama',color:'#7fb85a',walk:true},terra:{name:'Terra (trilha)',color:'#d9a24b',walk:true},mato:{name:'Mato alto (encontros)',color:'#3f8f3a',walk:true,encounter:true},
 agua:{name:'Água',color:'#3aa7c4',walk:false},rocha:{name:'Rocha (bloqueio)',color:'#8d8478',walk:false},ponte:{name:'Ponte',color:'#a8743d',walk:true,bridge:true},
 piso:{name:'Piso de pedra',color:'#b9ab90',walk:true},calcada:{name:'Calçada',color:'#cfc8ba',walk:true},asfalto:{name:'Asfalto',color:'#5b6066',walk:true},
 bosque:{name:'Mata fechada (bloqueio)',color:'#2f5d34',walk:false},construcao:{name:'Construção / muro (bloqueio)',color:'#a0705a',walk:false},canteiro:{name:'Canteiro / gramado (bloqueio)',color:'#93b86a',walk:false}};
// Rampa: a seta aponta para onde sobe. u = coluna do Tiled (desce para a direita na tela), v = linha (desce para a esquerda).
export const RAMP_DIRS={'u+':[1,0],'u-':[-1,0],'v+':[0,1],'v-':[0,-1]};
const DIR4=[[1,0],[-1,0],[0,1],[0,-1]];
// ---------- leitura ----------
function props(list){const out={};for(const p of list||[])out[p.name]=p.value;return out;}
// tilesets: {nome do arquivo .tsj: conteúdo} para tilesets externos.
export function parseTiled(map,tilesets={}){
 if(map.orientation!=='isometric')throw Error('O mapa precisa ser isométrico no Tiled (Mapa → Propriedades → Orientação: Isométrica).');
 if(map.tilewidth!==CELL.w||map.tileheight!==CELL.h)throw Error(`Célula ${map.tilewidth}×${map.tileheight}; o overworld usa ${CELL.w}×${CELL.h}.`);
 if(map.infinite)throw Error('Desligue "Mapa infinito" nas propriedades do mapa.');
 const tileProps=new Map();
 for(const ts of map.tilesets||[]){const def=ts.source?tilesets[ts.source.split('/').pop()]:ts;if(!def)throw Error(`Tileset ${ts.source} não encontrado.`);for(const t of def.tiles||[])tileProps.set(ts.firstgid+t.id,props(t.properties));}
 const W=map.width,H=map.height,cells=Array.from({length:W*H},()=>({material:null,level:0,ramp:null}));
 const layer=name=>map.layers.find(l=>l.type==='tilelayer'&&l.name.toLowerCase()===name);
 const chao=layer('chao');if(!chao)throw Error('Falta a camada de tiles "chao".');
 const read=(l,fn)=>l?.data.forEach((gid,i)=>{const id=gid&0x1fffffff;if(id)fn(cells[i],tileProps.get(id)||{});});
 read(chao,(c,p)=>{if(p.material)c.material=p.material;});
 read(layer('altura'),(c,p)=>{if(p.nivel!=null)c.level=Number(p.nivel);if(p.rampa)c.ramp=p.rampa;});
 // A rampa fica no nível de baixo e sobe para o vizinho na direção da seta.
 const objects=name=>map.layers.find(l=>l.type==='objectgroup'&&l.name.toLowerCase()===name)?.objects||[];
 const cellOf=o=>({u:Math.floor(o.x/CELL.h),v:Math.floor(o.y/CELL.h)});
 const pieces=objects('pecas').map(o=>{const p=props(o.properties),[fu,fv]=String(p.pegada||'1x1').split('x').map(Number),{u,v}=cellOf(o);return {id:o.id,name:o.name||p.asset,asset:p.asset||o.name,u,v,fu:fu||1,fv:fv||1,blocks:p.bloqueia!==false,interact:p.interacao||null,props:p};});
 const events=objects('eventos').map(o=>{const p=props(o.properties),{u,v}=cellOf(o);return {id:o.id,type:o.type||o.class||p.tipo||'evento',name:o.name||'',u,v,props:p};});
 const spawn=events.find(e=>e.type==='entrada');
 const zones=objects('zonas').map(o=>({name:o.name,u:o.x/CELL.h,v:o.y/CELL.h,fu:o.width/CELL.h,fv:o.height/CELL.h,props:props(o.properties)}));
 // A long ramp occupies existing trail cells downhill from the original
 // landing marker. The map explicitly opts in; other biomes keep one cell.
 const length=Number(props(map.properties).rampa_comprimento||1);
 if(length>1){
  const seeds=cells.flatMap((c,i)=>c.ramp?[{...c,u:i%W,v:Math.floor(i/W)}]:[]);
  for(const seed of seeds){
   const d=RAMP_DIRS[seed.ramp];if(!d)continue;
   for(let n=0;n<length;n++){
    const u=seed.u-d[0]*n,v=seed.v-d[1]*n,c=cells[v*W+u];
    if(u<0||v<0||u>=W||v>=H||!c||c.level!==seed.level||c.material!=='terra')throw Error(`Rampa longa sai da trilha em ${u},${v}.`);
    if(pieces.some(p=>p.blocks&&u>=p.u&&u<p.u+p.fu&&v>=p.v&&v<p.v+p.fv)||events.some(e=>e.u===u&&e.v===v))throw Error(`Rampa longa ocupa peça ou evento em ${u},${v}.`);
    c.ramp=seed.ramp;c.rampFrom=(length-n-1)/length;c.rampTo=(length-n)/length;
   }
  }
 }
 return {name:props(map.properties).nome||'Mapa',w:W,h:H,cells,pieces,events,spawn,zones,closedTerrain:length>1};
}
// ---------- movimento ----------
export const at=(m,u,v)=>u>=0&&v>=0&&u<m.w&&v<m.h?m.cells[v*m.w+u]:null;
export function blockedByPiece(m){const set=new Set();for(const p of m.pieces)if(p.blocks)for(let du=0;du<p.fu;du++)for(let dv=0;dv<p.fv;dv++)set.add((p.v+dv)*m.w+p.u+du);return set;}
export function walkable(m,u,v,solid=blockedByPiece(m)){const c=at(m,u,v);return !!c&&!!MATERIALS[c.material]?.walk&&!solid.has(v*m.w+u);}
// Pode passar de a para b (vizinhos de lado)? Mesmo nível, ou pela rampa no sentido certo.
export function canStep(m,a,b,solid){
 if(!walkable(m,a.u,a.v,solid)||!walkable(m,b.u,b.v,solid))return false;
 const ca=at(m,a.u,a.v),cb=at(m,b.u,b.v),du=b.u-a.u,dv=b.v-a.v;
 if((ca.rampFrom!=null||cb.rampFrom!=null)&&(ca.ramp||cb.ramp)){
  const d=RAMP_DIRS[(ca.ramp?ca:cb).ramp];
  if(d[0]*du+d[1]*dv===0)return ca.ramp===cb.ramp&&ca.level===cb.level&&(ca.rampFrom??0)===(cb.rampFrom??0)&&(ca.rampTo??1)===(cb.rampTo??1);
  const x=a.u+.5+du*.5,y=a.v+.5+dv*.5,e=.000001;
  return Math.abs(heightAt(m,x-du*e,y-dv*e)-heightAt(m,x+du*e,y+dv*e))<.00001;
 }
 const up=(c,d)=>c.ramp&&RAMP_DIRS[c.ramp][0]===d[0]&&RAMP_DIRS[c.ramp][1]===d[1];
 if(ca.ramp&&up(ca,[du,dv]))return cb.level===ca.level+1;
 if(cb.ramp&&up(cb,[-du,-dv]))return ca.level===cb.level+1;
 // Ao longo de uma rampa larga (mesma direção, mesmo nível) ou entrando pelo pé dela.
 if(ca.ramp||cb.ramp){const r=ca.ramp?ca:cb,d=RAMP_DIRS[r.ramp],along=d[0]*du+d[1]*dv===0;if(along)return ca.ramp===cb.ramp&&ca.level===cb.level;return ca.level===cb.level;}
 return ca.level===cb.level;
}
export function reachable(m,start,solid=blockedByPiece(m)){const seen=new Uint8Array(m.w*m.h);if(!start||!walkable(m,start.u,start.v,solid))return seen;const q=[start];seen[start.v*m.w+start.u]=1;
 while(q.length){const a=q.shift();for(const [du,dv] of DIR4){const b={u:a.u+du,v:a.v+dv};if(!at(m,b.u,b.v)||seen[b.v*m.w+b.u])continue;if(canStep(m,a,b,solid)){seen[b.v*m.w+b.u]=1;q.push(b);}}}return seen;}
// Caminho em 4 direções (A*), usado pelo clique para andar na bancada.
export function findPath(m,from,to,solid=blockedByPiece(m)){const key=p=>p.v*m.w+p.u,open=[{...from,g:0,f:0}],came=new Map(),g=new Map([[key(from),0]]);
 while(open.length){open.sort((a,b)=>a.f-b.f);const a=open.shift();if(a.u===to.u&&a.v===to.v){const path=[{u:a.u,v:a.v}];let k=key(a);while(came.has(k)){const p=came.get(k);path.unshift(p);k=key(p);}return path;}
  for(const [du,dv] of DIR4){const b={u:a.u+du,v:a.v+dv};if(!at(m,b.u,b.v)||!canStep(m,a,b,solid))continue;const ng=g.get(key(a))+1;if(ng<(g.get(key(b))??Infinity)){g.set(key(b),ng);came.set(key(b),{u:a.u,v:a.v});open.push({...b,g:ng,f:ng+Math.abs(b.u-to.u)+Math.abs(b.v-to.v)});}}}
 return null;}
// Altura contínua para desenhar o personagem na rampa.
export function heightAt(m,u,v){const c=at(m,Math.floor(u),Math.floor(v));if(!c)return 0;if(!c.ramp)return c.level;const d=RAMP_DIRS[c.ramp],fu=u-Math.floor(u),fv=v-Math.floor(v),t=d[0]>0?fu:d[0]<0?1-fu:d[1]>0?fv:1-fv;return c.level+(c.rampFrom??0)+t*((c.rampTo??1)-(c.rampFrom??0));}
export const toScreen=(u,v,h=0)=>({x:(u-v)*CELL.w/2,y:(u+v)*CELL.h/2-h*LEVEL_PX});
// ---------- barrancos ----------
// Faces visíveis na vista 2:1: as que olham para u+ (sudeste) e v+ (sudoeste), quando o vizinho é mais baixo.
export function cliffs(m){const out=[];for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const c=at(m,u,v);if(!c||!c.level)continue;
 for(const [du,dv,side] of [[1,0,'u'],[0,1,'v']]){const n=at(m,u+du,v+dv),low=n?n.level:0;if(low>=c.level)continue;
  if(n?.rampFrom!=null){
   const e=.000001,ax=side==='u'?u+1+e:u+e,ay=side==='u'?v+e:v+1+e;
   const bx=u+1+(side==='u'?e:-e),by=v+1+(side==='v'?e:-e);
   const bottomA=heightAt(m,ax,ay),bottomB=heightAt(m,bx,by);
   if(Math.min(bottomA,bottomB)>=c.level-e*2)continue;
   out.push({u,v,side,top:c.level,bottom:Math.min(bottomA,bottomB),bottomA,bottomB});continue;
  }
  if(n?.ramp&&RAMP_DIRS[n.ramp][0]===-du&&RAMP_DIRS[n.ramp][1]===-dv&&n.level===c.level-1)continue;out.push({u,v,side,top:c.level,bottom:low});}}
 // Concave stepped boundaries need their reverse faces as well. Native
 // ground-depth sorting puts these behind their own top and over low ground.
 if(m.closedTerrain)for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){
  const c=at(m,u,v);if(!c?.level)continue;
  for(const [du,dv,side]of[[-1,0,'u-'],[0,-1,'v-']]){
   const n=at(m,u+du,v+dv);if(n&&n.level>=c.level)continue;
   const a=side==='u-'?[u,v+1]:[u+1,v],b=[u,v],e=.000001;
   const sample=p=>n?heightAt(m,Math.min(u+du+1-e,Math.max(u+du+e,p[0])),Math.min(v+dv+1-e,Math.max(v+dv+e,p[1]))):0;
   const bottomA=sample(a),bottomB=sample(b);
   if(Math.min(bottomA,bottomB)>=c.level-e*2)continue;
   out.push({u,v,side,top:c.level,bottom:Math.min(bottomA,bottomB),bottomA,bottomB});
  }
 }
 return out;}
// ---------- conferência ----------
export function audit(m){const items=[],solid=blockedByPiece(m),add=(level,rule,text,cell)=>items.push({level,rule,text,cell});
 // Separate solid props cannot occupy the same footprint. Non-blocking edge
 // ornaments (e.g. two perpendicular fence faces) may intentionally meet.
 const occupied=new Map(),collisions=new Set();
 for(const p of m.pieces.filter(p=>p.blocks))for(let dv=0;dv<p.fv;dv++)for(let du=0;du<p.fu;du++){
  const u=p.u+du,v=p.v+dv,k=v*m.w+u,other=occupied.get(k);
  if(other){const pair=[other.id,p.id].sort((a,b)=>a-b).join(':');if(!collisions.has(pair)){collisions.add(pair);add('fail','Sobreposição',`${other.name} e ${p.name} ocupam a mesma célula (${u},${v}).`,{u,v});}}
  else occupied.set(k,p);
 }
 for(const [i,c] of m.cells.entries())if(c.material&&!MATERIALS[c.material])add('fail','Material',`Material desconhecido "${c.material}".`,{u:i%m.w,v:Math.floor(i/m.w)});
 const empty=m.cells.filter(c=>!c.material).length;if(empty)add('warn','Chão',`${empty} células sem chão: aparecem como vazio.`);
 if(!m.spawn)add('fail','Entrada','Falta o evento "entrada" (onde o jogador aparece).');else if(!walkable(m,m.spawn.u,m.spawn.v,solid))add('fail','Entrada','A entrada está numa célula onde não se anda.',m.spawn);
 const seen=reachable(m,m.spawn,solid);
 // Eventos e peças com interação precisam ser alcançáveis: na própria célula ou numa vizinha.
 const near=(u,v)=>[[0,0],...DIR4].some(([du,dv])=>{const x=u+du,y=v+dv;return at(m,x,y)&&seen[y*m.w+x];});
 for(const e of m.events)if(e.type!=='entrada'&&!near(e.u,e.v))add('fail','Acesso',`${e.name||e.type} não pode ser alcançado a partir da entrada.`,e);
 for(const p of m.pieces)if(p.interact){let ok=false;for(let du=-1;du<=p.fu&&!ok;du++)for(let dv=-1;dv<=p.fv&&!ok;dv++){const x=p.u+du,y=p.v+dv;ok=!!at(m,x,y)&&!!seen[y*m.w+x];}if(!ok)add('fail','Acesso',`${p.name} (${p.interact}) não pode ser alcançado.`,p);}
 // Áreas onde se anda, mas que ninguém alcança (plataformas soltas, margem sem ponte).
 const cut=new Uint8Array(m.w*m.h);let islands=0;
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const i=v*m.w+u;if(cut[i]||seen[i]||!walkable(m,u,v,solid))continue;const r=reachable(m,{u,v},solid);let n=0;for(let k=0;k<r.length;k++)if(r[k]){cut[k]=1;n++;}if(n>=6){islands++;add('warn','Acesso',`Área de ${n} células sem acesso pela entrada (perto de ${u},${v}).`,{u,v});}}
 // Rampas: pé no nível de baixo e chegada no de cima.
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const c=at(m,u,v);if(!c?.ramp)continue;const d=RAMP_DIRS[c.ramp];if(!d){add('fail','Rampa',`Direção de rampa inválida "${c.ramp}".`,{u,v});continue;}
  const hi=at(m,u+d[0],v+d[1]),lo=at(m,u-d[0],v-d[1]);
  if(c.rampFrom!=null){
   if(!hi||!canStep(m,{u,v},{u:u+d[0],v:v+d[1]},solid))add('fail','Rampa',`Trecho em ${u},${v} não encaixa na chegada.`,{u,v});
   if(!lo||!canStep(m,{u,v},{u:u-d[0],v:v-d[1]},solid))add('fail','Rampa',`Trecho em ${u},${v} não encaixa no pé.`,{u,v});
   continue;
  }
  if(!hi||hi.level!==c.level+1||!walkable(m,u+d[0],v+d[1],solid))add('fail','Rampa',`Rampa em ${u},${v} não chega ao nível ${c.level+1}.`,{u,v});
  if(!lo||(lo.level!==c.level&&!(lo.ramp===c.ramp&&lo.level===c.level-1))||!walkable(m,u-d[0],v-d[1],solid))add('fail','Rampa',`Rampa em ${u},${v} não começa no chão do nível ${c.level}.`,{u,v});}
 // Pontes: cada ponte precisa tocar terra firme nas duas pontas.
 const done=new Uint8Array(m.w*m.h);
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const i=v*m.w+u;if(done[i]||at(m,u,v).material!=='ponte')continue;const comp=[],q=[{u,v}];done[i]=1;
  while(q.length){const a=q.shift();comp.push(a);for(const [du,dv] of DIR4){const b={u:a.u+du,v:a.v+dv},c=at(m,b.u,b.v);if(c?.material==='ponte'&&!done[b.v*m.w+b.u]){done[b.v*m.w+b.u]=1;q.push(b);}}}
  // A travessia segue o eixo mais comprido da ponte; as pontas precisam dar em terra firme nesse eixo.
  const us=comp.map(a=>a.u),vs=comp.map(a=>a.v),alongU=Math.max(...us)-Math.min(...us)>=Math.max(...vs)-Math.min(...vs),lands=new Set();
  for(const a of comp)for(const [du,dv] of alongU?[[1,0],[-1,0]]:[[0,1],[0,-1]]){const c=at(m,a.u+du,a.v+dv);if(c&&c.material!=='ponte'&&MATERIALS[c.material]?.walk&&canStep(m,a,{u:a.u+du,v:a.v+dv},solid))lands.add(`${du},${dv}`);}
  const twoEnds=lands.size===2;
  if(!twoEnds)add('fail','Ponte',`Ponte perto de ${u},${v} não encosta em terra nas duas pontas.`,{u,v});
  if(!comp.some(a=>DIR4.some(([du,dv])=>at(m,a.u+du,a.v+dv)?.material==='agua')))add('warn','Ponte',`Ponte perto de ${u},${v} não atravessa água.`,{u,v});}
 // Trilha sem saída: terra com um único vizinho de trilha e nada para fazer ali.
 const trail=c=>c&&['terra','ponte','piso','calcada'].includes(c.material)||c?.ramp;
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const c=at(m,u,v);if(c?.material!=='terra')continue;const n=DIR4.filter(([du,dv])=>trail(at(m,u+du,v+dv))).length;if(n>1)continue;
  const busy=[...m.events,...m.pieces.filter(p=>p.interact)].some(e=>Math.abs(e.u-u)+Math.abs(e.v-v)<=2);if(!busy)add('warn','Trilha',`Trilha termina em ${u},${v} sem nada lá (beco sem saída).`,{u,v});}
 // Peças sobre água ou fora do mapa.
 for(const p of m.pieces){for(let du=0;du<p.fu;du++)for(let dv=0;dv<p.fv;dv++){const c=at(m,p.u+du,p.v+dv);if(!c)add('fail','Peça',`${p.name} sai do mapa.`,p);else if(c.material==='agua'&&p.asset!=='ponte')add('warn','Peça',`${p.name} está sobre a água.`,p);}}
 if(m.w*m.h>96*96)add('warn','Tamanho',`Mapa de ${m.w}×${m.h} células: acima de 96×96, divida em áreas para não pesar no celular.`);
 if(!items.some(i=>i.level==='fail'||i.level==='warn'))add('ok','Mapa',`Planta conferida: entrada, acessos, rampas, pontes e trilhas. ${seen.reduce((s,x)=>s+x,0)} células alcançáveis.`);
 return items;}
export const verdict=items=>items.some(i=>i.level==='fail')?'fail':items.some(i=>i.level==='warn')?'warn':'ok';
