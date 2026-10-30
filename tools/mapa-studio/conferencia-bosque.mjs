// Conferência complementar da skill: não altera planta nem corrige defeitos silenciosamente.
import {at,walkable,canStep,reachable,blockedByPiece,RAMP_DIRS,audit,heightAt} from './model.mjs';
const D=[[1,0],[-1,0],[0,1],[0,-1]],key=(m,p)=>p.v*m.w+p.u;
const plus=(p,d,n=1)=>({u:p.u+d[0]*n,v:p.v+d[1]*n});
const opposite={'u-':'u+','u+':'u-','v-':'v+','v+':'v-'};
const covers=(p,c)=>c.u>=p.u&&c.u<p.u+p.fu&&c.v>=p.v&&c.v<p.v+p.fv;

// A passagem tem duas faixas adjacentes, inclusive em rampas; apenas grau do nó não basta.
export function wideEdge(m,a,b,solid=blockedByPiece(m)){
 if(Math.abs(a.u-b.u)+Math.abs(a.v-b.v)!==1||!canStep(m,a,b,solid))return false;
 const side=[-(b.v-a.v),b.u-a.u];
 return [1,-1].some(sign=>{const x=plus(a,side,sign),y=plus(b,side,sign);return canStep(m,a,x,solid)&&canStep(m,b,y,solid)&&canStep(m,x,y,solid);});
}
export function wideReachable(m,start,solid=blockedByPiece(m)){
 const seen=new Set();if(!start||!walkable(m,start.u,start.v,solid))return seen;
 const queue=[start];seen.add(key(m,start));for(let i=0;i<queue.length;i++)for(const d of D){const p=plus(queue[i],d),k=key(m,p);if(!at(m,p.u,p.v)||seen.has(k)||!wideEdge(m,queue[i],p,solid))continue;seen.add(k);queue.push(p);}return seen;
}
export function auditZeroBreak(m,{region=[],links=[],requiredRoute,accesses=[],guards=[],frameDepth=4}={}){
 const issues=[...audit(m)],solid=blockedByPiece(m),seen=reachable(m,m.spawn,solid);
 const add=(level,rule,text,cell)=>issues.push({level,rule,text,...(cell?{cell}: {})});
 let plateau=0,unreachable=0,loose=0,ramps=0;
 const accessCells=new Map();const protect=(p,label)=>accessCells.set(key(m,p),{...p,label});
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){
  const p={u,v},c=at(m,u,v);if(c.level>0)plateau++;
  if(walkable(m,u,v,solid)&&!seen[key(m,p)]){unreachable++;add('fail','Bolsão inalcançável',`Chão caminhável sem rota desde a entrada em ${u},${v}.`,p);}
  if(c.level>0&&!c.ramp&&D.filter(d=>{const n=at(m,u+d[0],v+d[1]);return n&&!n.ramp&&n.level===c.level;}).length<2){loose++;add('fail','Degrau solto',`Cota ${c.level} sem duas vizinhas da mesma cota em ${u},${v}.`,p);}
  if(!c.ramp)continue;ramps++;
  if(!['u-','v-'].includes(c.ramp)){add('fail','Rampa para a câmera',`Rampa ${c.ramp} proibida em ${u},${v}.`,p);continue;}
  const d=RAMP_DIRS[c.ramp],down=plus(p,d,-1),up=plus(p,d);
  protect(p,'rampa/escada');
  const isFoot=c.rampFrom==null||c.rampFrom===0;
  const isTop=c.rampTo==null||c.rampTo===1;
  if(isFoot){protect(down,'pé de rampa/escada');const foot=at(m,down.u,down.v);if(!foot||foot.ramp||foot.level!==c.level||foot.material!=='terra'||!canStep(m,p,down,solid))add('fail','Pé da rampa',`Pé precisa de terra livre na cota ${c.level} em ${down.u},${down.v}.`,down);}
  if(isTop)for(let n=1;n<=2;n++){const landing=plus(p,d,n),cell=at(m,landing.u,landing.v);protect(landing,'chegada de rampa/escada');if(!cell||cell.ramp||cell.level!==c.level+1||!walkable(m,landing.u,landing.v,solid))add('fail','Chegada da rampa',`Faltam duas células livres na cota ${c.level+1} após ${u},${v}.`,landing);}
 }
 // Cada extremidade de uma faixa de ponte precisa de chão firme, sem prop/evento em cima.
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++)if(at(m,u,v).material==='ponte'){
  const p={u,v};for(const d of D){const q=plus(p,d),c=at(m,q.u,q.v),back=at(m,u-d[0],v-d[1]);if(c&&c.material!=='ponte'&&back?.material==='ponte'&&walkable(m,q.u,q.v,solid)){protect(q,'cabeceira de ponte');protect(p,'ponta do tabuleiro');}}
 }
 for(const e of m.events)if(['entrada','saida'].includes(e.type))protect(e,e.type);
 for(const a of accesses)for(const p of a.cells||[a])protect(p,a.name||'acesso declarado');
 for(const p of m.pieces)for(const a of accessCells.values())if(covers(p,a))add('fail',/mureta|muro|cerca/.test(p.asset+' '+p.name)?'Mureta cruzando acesso':'Peça sobre acesso',`${p.name||p.asset} ocupa ${a.label} em ${a.u},${a.v}.`,a);
 for(const e of m.events){const access=accessCells.get(key(m,e));if(access&&!['entrada','saida'].includes(e.type))add('fail','Evento sobre acesso',`${e.name||e.type} ocupa ${access.label}.`,e);}
 for(const guard of guards){
  const d=guard.side==='u'?[1,0]:guard.side==='v'?[0,1]:null,c=at(m,guard.u,guard.v);
  if(!d||!c){add('fail','Mureta inválida','Aresta de mureta não corresponde a uma célula.',guard);continue;}
  const next=plus(guard,d),n=at(m,next.u,next.v);
  if(c.ramp||n?.ramp||n&&canStep(m,guard,next,solid))add('fail','Mureta cruzando acesso',`Mureta ${guard.side} em ${guard.u},${guard.v} cruza ligação caminhável/rampa.`,guard);
  else if(c.level<=0||n&&n.level>=c.level)add('fail','Mureta sem borda',`Guarda-corpo ${guard.side} em ${guard.u},${guard.v} não está sobre queda exposta.`,guard);
 }
 const near=e=>[[0,0],...D].some(d=>{const p=plus(e,d);return at(m,p.u,p.v)&&seen[key(m,p)];});
 const items=m.events.filter(e=>e.type==='item');for(const e of items)if(!near(e))add('fail','Item inalcançável',`${e.name||e.props?.item} não está ao alcance.`,e);
 if(items.length<3)add('warn','Itens por parte',`Somente ${items.length} itens; mínimo 3.`);
 if(!items.some(e=>e.props?.visibilidade==='escondido'))add('warn','Item escondido','Falta item escondido fora do caminho principal.');
 const ratio=plateau/m.cells.length;if(ratio<.4)add('warn','Platôs',`${(ratio*100).toFixed(1)}% de platô; mínimo 40%.`);
 const trees=m.pieces.filter(p=>/arvore|árvore/.test((p.asset+' '+p.name).toLowerCase()));
 const isolated=trees.filter(p=>!trees.some(q=>q!==p&&Math.max(Math.abs(p.u-q.u),Math.abs(p.v-q.v))<=1));
 // Janela de 16×12 células equivale à pegada aproximada de uma câmera 1280×720 em zoom 1.
 const crowded=isolated.filter(p=>isolated.filter(q=>Math.abs(p.u-q.u)<=8&&Math.abs(p.v-q.v)<=6).length>2);
 if(crowded.length)add('warn','Árvore solta',`${isolated.length} árvores isoladas; ${crowded.length} excedem duas na mesma janela de jogo.`,crowded[0]);
 const route=requiredRoute||[m.spawn,...m.events.filter(e=>e.type==='saida')];
 for(let i=1;i<route.length;i++)if(!wideReachable(m,route[i-1],solid).has(key(m,route[i])))add('fail','Corredor estreito',`Sem corredor contínuo de duas células entre ${route[i-1].u},${route[i-1].v} e ${route[i].u},${route[i].v}.`,route[i]);
 const safe={...m,cells:m.cells.map(c=>c.material==='mato'?{...c,material:'bosque'}:c)};
 const safeSeen=reachable(safe,m.spawn,solid);
 for(const e of m.events.filter(e=>e.type==='saida'))if(!safeSeen[key(m,e)])add('fail','Encontro obrigatório',`Saída ${e.name||e.props?.destino} exige atravessar mato de encontro.`,e);
 const frame=[];for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++)if(Math.min(u,v,m.w-1-u,m.h-1-v)<frameDepth&&walkable(m,u,v,solid)&&!m.events.some(e=>['entrada','saida'].includes(e.type)&&Math.max(Math.abs(u-e.u),Math.abs(v-e.v))<=frameDepth+1))frame.push({u,v});
 if(frame.length)add('warn','Moldura',`${frame.length} células caminháveis na moldura fora dos acessos; conferir captura.`,frame[0]);
 if(region.length){const parts=new Set(region.map(r=>r.part));if(!['A','B','C'].every(p=>parts.has(p)))add('fail','Partes da região','Região precisa das partes A, B e C.');
  for(const r of region)for(const other of region.filter(q=>Math.abs(q.part.charCodeAt(0)-r.part.charCodeAt(0))===1))if(!r.map.events.some(e=>e.type==='saida'&&e.props?.destino===other.id))add('fail','Ligação entre partes',`${r.id} não tem saída para ${other.id}.`);
 }else add('fail','Partes da região','Informe as três partes para conferir a região.');
 const lookup=id=>region.find(r=>r.id===id)?.map;
 for(const link of links){const a=link.from,b=link.to,ma=lookup(a.area),mb=lookup(b.area),ca=ma&&at(ma,a.u,a.v),cb=mb&&at(mb,b.u,b.v);
  if(!ca||!cb){add('fail','Ligação entre partes','Extremidade de ligação ausente.');continue;}
  if(opposite[a.direction]!==b.direction)add('fail','Direção de ligação',`${a.area} ${a.direction} não combina com ${b.area} ${b.direction}.`);
  if(ca.material!==cb.material||Math.abs(heightAt(ma,a.u+.5,a.v+.5)-heightAt(mb,b.u+.5,b.v+.5))>1e-6)add('fail','Cota/material da ligação',`${a.area} e ${b.area} divergem em piso ou altura.`);
  for(const [p,map]of [[a,ma],[b,mb]])if(!reachable(map,map.spawn)[key(map,p)])add('fail','Acesso à ligação',`${p.area} tem extremidade inalcançável.`,p);
 }
 if(region.length&&links.length<2)add('fail','Conferência das ligações','Informe pelo menos A↔B e B↔C com direção e coordenadas.');
 const errors=issues.filter(i=>i.level==='fail'),warnings=issues.filter(i=>i.level==='warn');
 const stats={plateau:ratio,items:items.length,hidden:items.filter(e=>e.props?.visibilidade==='escondido').length,ramps,unreachable,loose,isolatedTrees:isolated.length,accesses:accessCells.size};
 const lines=[`CONFERÊNCIA ZERO QUEBRA: ${errors.length?'REPROVADO':'SEM ERRO'} · ${errors.length} erros · ${warnings.length} avisos`,`Platô ${(ratio*100).toFixed(1)}% · ${items.length} itens (${stats.hidden} escondidos) · ${ramps} células de rampa · ${unreachable} inalcançáveis · ${loose} degraus soltos`,...issues.filter(i=>i.level!=='ok').map(i=>`${i.level==='fail'?'ERRO':'AVISO'} [${i.rule}] ${i.text}`)];
 return {ok:!errors.length,issues,stats,lines};
}
