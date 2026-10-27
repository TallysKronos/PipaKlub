import fs from 'node:fs';
import crypto from 'node:crypto';
import {parseTiled,MATERIALS} from '../mapa-studio/model.mjs';

const out='art/overworld/conceitos/parque';
fs.mkdirSync(out,{recursive:true});
const registry={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'))};
for(const id of ['jardim-das-pipas','clareira-do-papel']){
  const source=`art/overworld/mapas/${id}.tmj`;
  const raw=fs.readFileSync(source);
  const m=parseTiled(JSON.parse(raw),registry);
  const maxLevel=Math.max(...m.cells.map(c=>c.level+(c.ramp?1:0)));
  const bounds={x0:-m.h*32-40,x1:m.w*32+40,y0:-maxLevel*64-90,y1:(m.w+m.h)*16+30};
  const project=(u,v,h=0)=>[2*((u-v)*32-bounds.x0),2*((u+v)*16-h*64-bounds.y0)];
  const polygon=(u,v,a,b)=>[[u,v],[u+a,v],[u+a,v+b],[u,v+b]].map(([u,v])=>project(u,v));
  const counts={};for(const c of m.cells)counts[c.material]=(counts[c.material]||0)+1;
  const pairs={};
  for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++)for(const [du,dv] of [[1,0],[0,1]]){
    if(u+du>=m.w||v+dv>=m.h)continue;
    const a=m.cells[v*m.w+u],b=m.cells[(v+dv)*m.w+u+du];
    if(a.material===b.material)continue;
    const key=[a.material,b.material].sort().join('/');pairs[key]=(pairs[key]||0)+1;
  }
  const pieces=m.pieces.map(p=>({...p,polygon:polygon(p.u,p.v,p.fu,p.fv),groundCenter:project(p.u+p.fu/2,p.v+p.fv/2)}));
  const brief={issue:'PIP-85',id,source,sourceSha256:crypto.createHash('sha256').update(raw).digest('hex'),
    stage:'concept_review',approval:'pending_owner_review',alignment:'pending_pixel_review',
    style:'art/overworld/estilo/PRANCHA-ESTILO.png',
    projection:{cell:[64,32],levelPx:64,exportScale:2,bounds,imageSize:[(bounds.x1-bounds.x0)*2,(bounds.y1-bounds.y0)*2],edgeTolerancePx:4},
    materials:Object.entries(counts).map(([id,cells])=>({id,cells,walk:MATERIALS[id].walk,plannedTileVariants:4})),
    transitions:Object.entries(pairs).map(([pair,edges])=>({pair,edges,plannedCornerMasks:16})),
    pieces,events:m.events.map(e=>({...e,center:project(e.u+.5,e.v+.5)})),
    encounterCells:m.cells.flatMap((c,i)=>c.material==='mato'?[[i%m.w,Math.floor(i/m.w)]]:[]),
    locks:['Preserve map dimensions, events, pieces and traversal','Level zero throughout: no stairs, raised platforms, rivers or cliffs','Bosque must look impassable; grama and terra must remain visibly open','Tall encounter grass differs from short lawn; no regular caret pattern','Shared entry furniture keeps its existing positions','No characters, creatures, UI or baked quest indicators'],
    integrationNotes:id==='jardim-das-pipas'?['Coreto footprint is 4x4 and non-blocking; five separate coreto-post-* source pieces provide pillar collision. The generated whole-map study is not geometry authority.']:[]};
  fs.writeFileSync(`${out}/${id}-brief.json`,JSON.stringify(brief,null,2)+'\n');
  for(const suffix of ['referencia','legendas'])fs.copyFileSync(`documentation/overworld/pip81/references/${id}-${suffix}.png`,`${out}/${id}-${suffix}.png`);
  console.log(JSON.stringify({id,size:brief.projection.imageSize,materials:brief.materials,transitions:brief.transitions,coreto:pieces.find(p=>p.asset==='coreto')}));
}
