import fs from'node:fs/promises';
import{homeProject}from'../src/home-layout.js';
import{normalizeIsoImage}from'./isometric-image-export.mjs';
import{pieceBox,manifest,auditSource,auditPiece,auditScene,verdict,roomSize}from'../tools/iso-studio/model.mjs';
const root='art/kael-home-iso-v1',out='assets/world/kael-home-iso-v1',project=structuredClone(homeProject),images={},reports=[];
await fs.mkdir(out,{recursive:true});
for(const p of project.pieces){const b=pieceBox(p),dest=`${out}/${p.id}.png`,reused=['tapete','janela'].includes(p.id),source=reused?`art/kael-bedroom-iso-v4/sources/${p.id}.png`:`${root}/sources/${p.id==='banco-fundo'?'banco-jantar':p.id}.png`;
 const img=await normalizeIsoImage(source,b.w,b.h,dest),items=[...auditSource(img),...auditPiece(p,img).items];reports.push({id:p.id,verdict:verdict(items),items});console.log(p.id,verdict(items),items.filter(i=>i.level==='fail').map(i=>i.text).join('; '));
 p.image='data:image/png;base64,'+(await fs.readFile(dest)).toString('base64');images['home-'+p.id]={image:`world/kael-home-iso-v1/${p.id}.png`,width:b.w,height:b.h,pivot:[b.anchor[0]/b.w,1]};
}
const size=roomSize(project.room);await normalizeIsoImage(`${root}/sources/casca.png`,size.w,size.h,`${out}/casca.png`);project.room.image='data:image/png;base64,'+(await fs.readFile(`${out}/casca.png`)).toString('base64');images['home-casca']={image:'world/kael-home-iso-v1/casca.png',width:size.w,height:size.h};
await fs.writeFile(`${out}/manifest.json`,JSON.stringify({...manifest(project),images,provenance:'Built-in image_gen sources; window/rug reused from original bedroom sources. Alpha crop, uniform contain resize and transparent padding only. No silhouette registration, column warp or aspect stretching. Geometry audit may reject source camera; visual approval remains separate.'},null,2)+'\n');
await fs.writeFile(`${root}/sala-kael.isostudio.json`,JSON.stringify(project));await fs.writeFile(`${root}/conferencia.json`,JSON.stringify({scene:auditScene(project.room,project.pieces),pieces:reports},null,2)+'\n');
if(reports.some(r=>r.verdict==='fail')||auditScene(project.room,project.pieces).some(i=>i.level==='fail'))process.exitCode=1;
