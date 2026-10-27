import fs from 'node:fs';
import crypto from 'node:crypto';
import {parseTiled} from '../mapa-studio/model.mjs';
const out='art/overworld/conceitos/veredas';
fs.mkdirSync(out,{recursive:true});
const registry={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'))};
for(const id of ['veredas-piloto','veredas-do-encanamento']){
  const source=`art/overworld/mapas/${id}.tmj`, raw=fs.readFileSync(source);
  const m=parseTiled(JSON.parse(raw),registry),counts={},pairs={};
  for(const c of m.cells)counts[c.material]=(counts[c.material]||0)+1;
  for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++)for(const [du,dv] of [[1,0],[0,1]]){
    if(u+du>=m.w||v+dv>=m.h)continue;
    const a=m.cells[v*m.w+u],b=m.cells[(v+dv)*m.w+u+du];
    if(a.material!==b.material){const key=[a.material,b.material].sort().join('/');pairs[key]=(pairs[key]||0)+1;}
  }
  const record={issue:'PIP-86',id,source,sourceSha256:crypto.createHash('sha256').update(raw).digest('hex'),
    stage:'pilot_assembly',conceptFeedback:'Owner liked initial study and requested faithful implementation; not a pixel-alignment approval',
    projection:{cell:[64,32],levelPx:64},size:[m.w,m.h],materials:counts,transitions:pairs,
    pieces:m.pieces,events:m.events,ramps:m.cells.flatMap((c,i)=>c.ramp?[{u:i%m.w,v:Math.floor(i/m.w),...c}]:[]),
    locks:['Source map is geometry authority','Five chests, Nina, Lacertubo and all interactions stay at exact source cells','Ramp tops and cheeks derive from height_at','Bridge deck spans water and meets both banks','No canopy sampled into floor','Sparse upright vegetation only; no automatic tree fill']};
  fs.writeFileSync(`${out}/${id}-brief.json`,JSON.stringify(record,null,2)+'\n');
  console.log(`${id}: ${m.w}x${m.h}, ${m.pieces.length} pieces, ${m.events.length} events`);
}
