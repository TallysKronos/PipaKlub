// Lê todas as plantas de art/overworld/mapas e gera art/overworld/INVENTARIO-CODEX.md:
// o que precisa ser desenhado por bioma (chão, transições, barrancos, rampas, pontes, peças) e por área.
// Rodar de novo depois de editar as plantas no Tiled.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict,cliffs,at,MATERIALS} from './model.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),dir=root+'art/overworld/mapas/';
const sets={'rascunho.tsj':JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'))};
const prop=(raw,name)=>raw.properties?.find(p=>p.name===name)?.value;
const BIOMAS={bairro:'Bairro (Rua dos Ventos)',parque:'Parque dos Ventos',veredas:'Veredas do Encanamento',morro:'Morro do Sol'};
const areas=fs.readdirSync(dir).filter(f=>f.endsWith('.tmj')&&!f.startsWith('veredas-piloto')).sort().map(f=>{const raw=JSON.parse(fs.readFileSync(dir+f,'utf8')),m=parseTiled(raw,sets);
 const mats=new Map(),pairs=new Map(),assets=new Map(),ramps=new Map(),events=[];
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const c=at(m,u,v);mats.set(c.material,(mats.get(c.material)||0)+1);if(c.ramp)ramps.set(c.ramp,(ramps.get(c.ramp)||0)+1);
  for(const [du,dv] of [[1,0],[0,1]]){const n=at(m,u+du,v+dv);if(n&&n.material!==c.material){const k=[c.material,n.material].sort().join(' / ');pairs.set(k,(pairs.get(k)||0)+1);}}}
 for(const p of m.pieces){const k=p.asset+(p.props.variante?` (${p.props.variante})`:'')+(p.fu>1||p.fv>1?` ${p.fu}x${p.fv}`:'');assets.set(k,(assets.get(k)||0)+1);}
 for(const e of m.events)if(e.type!=='entrada')events.push(`${e.type}: ${e.name}${e.props.destino?' → '+e.props.destino:''}`);
 const cl=cliffs(m),faces={};for(const c of cl){const k=`${c.top-c.bottom} nível · face ${c.side==='u'?'sudeste':'sudoeste'}`;faces[k]=(faces[k]||0)+1;}
 const bridges=m.cells.filter(c=>c.material==='ponte').length;
 return {id:f.slice(0,-4),name:m.name,bioma:prop(raw,'bioma')||'?',cena:prop(raw,'cena_jogo')||'',w:m.w,h:m.h,verdict:verdict(audit(m)),mats,pairs,assets,ramps,faces,bridges,events,maxLevel:Math.max(...m.cells.map(c=>c.level))};});
const sum=(list,key)=>{const out=new Map();for(const a of list)for(const [k,v] of a[key])out.set(k,(out.get(k)||0)+v);return [...out].sort((a,b)=>b[1]-a[1]);};
let md=`# Inventário para o Codex — mapas do overworld

Gerado por \`node tools/mapa-studio/inventario.mjs\` a partir das plantas em \`art/overworld/mapas/\`. Não edite à mão: ajuste as plantas no Tiled e rode de novo.
Regras de desenho, grade (64×32, 1 nível = 64 px de parede) e pedidos A (conceito) e B (kit) em [ESPECIFICACAO-MAPAS.md](ESPECIFICACAO-MAPAS.md). Estilo geral: anime 2D, contorno firme, cor em massas, a mesma luz alto-esquerda em todas as áreas.

## Como usar

1. **Kit do bioma primeiro** (seção por bioma abaixo): chão, transições, barrancos, rampas/escadas, pontes e peças. As peças vêm do Iso Studio na grade comum, para que árvore, banco e poste tenham a mesma escala em todas as áreas.
2. **Conceito de cada área** sobre a referência exportada pelo Mapa Studio (\`<area>-referencia.png\`), usando só peças do kit.
3. Uma peça que aparece em mais de um bioma (banco, poste, árvore, placa) é **desenhada uma vez** e recebe só variação de cor/material quando o bioma pedir.

## Resumo das áreas

| Área | Bioma | Cena do jogo | Tamanho | Níveis | Conferência |
| --- | --- | --- | --- | --- | --- |
${areas.map(a=>`| ${a.name} (\`${a.id}\`) | ${BIOMAS[a.bioma]||a.bioma} | \`${a.cena}\` | ${a.w}×${a.h} | 0–${a.maxLevel} | ${a.verdict.toUpperCase()} |`).join('\n')}
`;
for(const [bioma,label] of Object.entries(BIOMAS)){const list=areas.filter(a=>a.bioma===bioma);if(!list.length)continue;
 const mats=sum(list,'mats'),pairs=sum(list,'pairs'),assets=sum(list,'assets'),ramps=sum(list,'ramps');const faces={};for(const a of list)for(const [k,v] of Object.entries(a.faces))faces[k]=(faces[k]||0)+v;
 md+=`
## Bioma: ${label}

Áreas: ${list.map(a=>a.name).join(' · ')}

**Chão (tiles 64×32, 4 variações lisas cada):**
${mats.map(([k,v])=>`- \`${k}\` — ${MATERIALS[k]?.name||k}${MATERIALS[k]?.walk===false?' (bloqueio: precisa ler como "não dá para passar")':''} · ${v} células`).join('\n')}

**Transições (autotile de cantos, 16 peças por par):**
${pairs.length?pairs.map(([k,v])=>`- ${k} · ${v} bordas`).join('\n'):'- nenhuma'}

**Barrancos e muros de contenção:**
${Object.keys(faces).length?Object.entries(faces).map(([k,v])=>`- ${k} · ${v} faces`).join('\n')+'\n- cantos externo e interno para cada altura usada; topo casando com o chão do nível de cima':'- nenhum'}

**Rampas / escadas:** ${ramps.length?ramps.map(([k,v])=>`${k} ×${v}`).join(', ')+' (tampo inclinado + cunhas laterais; no Morro e no Bairro, desenhar como **escadaria** de concreto)':'nenhuma'}
**Pontes:** ${list.reduce((s,a)=>s+a.bridges,0)?list.reduce((s,a)=>s+a.bridges,0)+' células de tabuleiro, nos dois eixos, com cabeceiras':'nenhuma'}

**Peças (Iso Studio, grade comum):**
${assets.length?assets.map(([k,v])=>`- ${k} ×${v}`).join('\n'):'- nenhuma peça na planta ainda'}
`;}
md+=`
## Por área
`;
for(const a of areas)md+=`
### ${a.name} — \`${a.id}.tmj\`

- Cena do jogo: \`${a.cena}\` · ${a.w}×${a.h} células · níveis 0–${a.maxLevel} · conferência ${a.verdict.toUpperCase()}
- Chão: ${[...a.mats].sort((x,y)=>y[1]-x[1]).map(([k,v])=>`${k} ${v}`).join(', ')}
- Peças: ${[...a.assets].map(([k,v])=>`${k} ×${v}`).join(', ')||'nenhuma'}
- Eventos: ${a.events.join(' · ')||'nenhum'}
- Referência para o conceito: abra no Mapa Studio e use **Baixar referência para o Codex**.
`;
md+=`
## Pendências conhecidas das plantas importadas

- **Morro do Sol (5 áreas):** no jogo atual o Morro é um corredor andável sobre uma ilustração pintada. A planta traz só o chão andável, a encosta (nível 1) e o resto como \`construcao\`. Antes do conceito, **vestir a planta** no Tiled com as peças do bairro (casas, lajes, muros, escadarias, caixa-d'água, varais, postes) usando a arte pintada atual como referência de conteúdo.
- **Rua dos Ventos:** gramados fora da calçada estão como \`canteiro\` (bloqueio). Decidir quais viram quintal, muro ou jardim.
- **Escadas:** a planta marca só a última fileira como rampa; o resto é o caminho de acesso. No jogo a subida é gradual.
- Interiores (quarto, sala, ateliê, loja) seguem no Iso Studio e não entram aqui.
`;
fs.writeFileSync(root+'art/overworld/INVENTARIO-CODEX.md',md);
console.log('INVENTARIO-CODEX.md:',areas.length,'áreas');
