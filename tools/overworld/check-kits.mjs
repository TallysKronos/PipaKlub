import fs from 'node:fs';
import path from 'node:path';
import {auditScene,normalizePiece,pieceBox} from '../iso-studio/model.mjs';
import {parseTiled} from '../mapa-studio/model.mjs';
const root='art/overworld/kits';let checks=0;const failures=[],report={kits:[],areas:[]};
const assert=(ok,text)=>{checks++;if(!ok)failures.push(text);};
const kits=[];
for(const biome of ['comum','morro']){
 const kit=JSON.parse(fs.readFileSync(`${root}/${biome}/kit.json`,'utf8'));kits.push(kit);
 const studio=JSON.parse(fs.readFileSync(`${root}/${biome}/${biome}.isostudio.json`,'utf8'));
 const issues=auditScene(studio.room,studio.pieces);
 assert(!issues.some(i=>i.level==='fail'),`${biome}: Studio footprint errors ${JSON.stringify(issues)}`);
 const ids=studio.pieces.map(p=>normalizePiece(p).id);
 assert(new Set(ids).size===ids.length,`${biome}: duplicate Studio ids`);
 for(const piece of studio.pieces){const box=pieceBox(piece);assert(box.w>0&&box.h>0,`${biome}: valid Studio box ${piece.id}`);}
 let count=0;
 for(const[asset,group]of Object.entries(kit.pieces))for(const[variant,entry]of Object.entries(group.variants)){
  count++;
  assert(fs.existsSync(path.join(root,biome,entry.file)),`${asset}/${variant}: image`);
  assert(fs.existsSync(path.join(root,biome,entry.shadow)),`${asset}/${variant}: separate contact shadow`);
  assert(entry.anchor.length===2&&entry.visualFootprint.length===2&&entry.footprint.length===2,`${asset}/${variant}: anchors and footprints`);
 }
 for(const transition of Object.values(kit.transitions)){
  assert(transition.files.length===16,`${biome}: all corner masks`);
  for(const file of transition.files)assert(fs.existsSync(path.join(root,biome,file)),`${biome}: transition ${file}`);
 }
 report.kits.push({biome,pieceVariants:count,studioFootprintIssues:issues,approval:kit.approval});
}
const ts={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj','utf8'))};
for(const file of fs.readdirSync('art/overworld/mapas').filter(f=>f.startsWith('morro-')&&f.endsWith('.tmj'))){
 const m=parseTiled(JSON.parse(fs.readFileSync('art/overworld/mapas/'+file)),ts);const missing=[];
 for(const p of m.pieces){const group=kits.map(k=>k.pieces[p.asset]).find(Boolean);if(!group||p.props.variante&&!group.variants[p.props.variante])missing.push(`${p.asset}/${p.props.variante||'default'}`);}
 assert(!missing.length,file+': '+missing.join(', '));report.areas.push({id:file,pieces:m.pieces.length,missing});
}
report.checks=checks;report.failures=failures;report.scope='Studio model footprint audit + manifest coverage; irregular sprite edge slope audit is separate';
fs.mkdirSync('documentation/overworld/reports',{recursive:true});fs.writeFileSync('documentation/overworld/reports/kits.json',JSON.stringify(report,null,2)+'\n');
console.log(`${checks} checks de kit; ${failures.length} falhas; projetos Iso Studio e ids das plantas conferidos.`);
if(failures.length){console.error(failures);process.exitCode=1;}
