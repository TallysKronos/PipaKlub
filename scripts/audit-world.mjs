import fs from 'node:fs';
import {parseWorldMap} from '../src/world-map.js';
import {buildWorldArtPlan,auditWorldStructure} from '../src/world-art.js';
const file=process.argv[2]||'assets/world/quintal-modular-v1/project.json';
try{
 const project=JSON.parse(fs.readFileSync(file,'utf8')),scene=parseWorldMap(project.map),plan=buildWorldArtPlan(scene,project.kit,project.layout,{audit:false}),errors=auditWorldStructure(scene,plan);
 if(errors.length){console.error(errors.join('\n'));process.exitCode=1;}
 else console.log(project.name+': estrutura aprovada · '+plan.objects.length+' peças · '+scene.nodes.length+' pontos de caminhada. Revisão visual ainda obrigatória: tools/atelie/AUDIT-RULES.md');
}catch(e){console.error(e.message);process.exitCode=1;}
