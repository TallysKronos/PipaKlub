import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export function auditBosque(){
 const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const region=['A','B','C'].map(part=>{const id='kronasta-bosque-'+part.toLowerCase(),raw=JSON.parse(fs.readFileSync(root+'art/overworld/mapas/'+id+'.tmj'));return {id,part,map:parseTiled(raw,{'rascunho.tsj':ts})};});
 const links=[{from:{area:'kronasta-bosque-a',u:24,v:1,direction:'v-'},to:{area:'kronasta-bosque-b',u:24,v:43,direction:'v+'}},{from:{area:'kronasta-bosque-b',u:24,v:0,direction:'v-'},to:{area:'kronasta-bosque-c',u:24,v:43,direction:'v+'}},{from:{area:'kronasta-bosque-c',u:32,v:43,direction:'v+'},to:{area:'kronasta-bosque-a',u:24,v:1,direction:'v-'}}];
 const reports=region.map(r=>{const data=JSON.parse(fs.readFileSync(root+'godot/assets/overworld/maps/'+r.id+'.json'));return {id:r.id,...auditZeroBreak(r.map,{region,links,guards:data.forest?.guards??[]})};});
 const output=reports.map(r=>r.id+'\n'+r.lines.join('\n')).join('\n\n')+'\n';
 fs.mkdirSync(root+'documentation/overworld/kronasta/relatorios',{recursive:true});
 fs.writeFileSync(root+'documentation/overworld/kronasta/relatorios/conferencia-automatica.txt',output);
 fs.writeFileSync(root+'documentation/overworld/kronasta/relatorios/conferencia-automatica.json',JSON.stringify(reports,null,2)+'\n');
 console.log(output);if(reports.some(r=>!r.ok))process.exitCode=1;return reports;
}
if(process.argv[1]===fileURLToPath(import.meta.url))auditBosque();
