// Reproducible pixel cleanup of the Kael draft; keeps a single head model across poses.
import fs from 'node:fs/promises';
import {validateProject,serialize,audit} from '../core.mjs';
import {atlas} from '../animation.mjs';
import {aseprite} from '../aseprite.mjs';
import {extract} from '../document.mjs';
const dir=new URL('../../../art/characters/kael-walk-pixel-v1/',import.meta.url);
const project=validateProject(JSON.parse(await fs.readFile(new URL('draft.pixelgen.json',dir),'utf8')));
for(const frame of project.frames)frame.indices=frame.cels[0];
const head=project.frames[0].indices.slice(0,48*30);
for(const frame of project.frames)frame.indices.set(head,0);
project.name='Kael · caminhada esquerda';project.sequences=[{name:'walk-left',start:0,end:3,loop:true}];
project.frames.forEach((frame,index)=>{
 frame.duration=[140,110,140,110][index];frame.sourceRect=undefined;frame.sourceBounds=undefined;
});
extract(project,0,0,{x:0,y:0,w:48,h:30},true);project.layers[0].name='Corpo';project.layers[1].name='Cabeça';
const json=JSON.stringify(serialize(project));
await fs.writeFile(new URL('kael-walk.pixelgen.json',import.meta.url),json);
await fs.writeFile(new URL('kael-walk.pixelgen.json',dir),json);
await fs.writeFile(new URL('kael-walk.aseprite',dir),aseprite(project));
await fs.writeFile(new URL('kael-walk-atlas.json',dir),JSON.stringify(atlas(project,'kael-walk-sheet.png'),null,2));
await fs.writeFile(new URL('audit.json',dir),JSON.stringify(audit(project),null,2));
console.log(audit(project));
