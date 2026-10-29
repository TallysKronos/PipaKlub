// Pixelgen conversion candidate of the four-pose generated climbing study.
// This is a preview candidate, not a claim of manually retouched production pixel art.
import fs from 'node:fs/promises';
import {convert,serialize,validateProject,audit} from '../core.mjs';
import {aseprite} from '../aseprite.mjs';
import {atlas} from '../animation.mjs';
const root=new URL('../../../',import.meta.url),dir=new URL('art/characters/kael-stairs-study-v1/',root);
const size=JSON.parse(await fs.readFile(new URL('tmp/kael-stairs-size.json',root),'utf8'));
const data=new Uint8ClampedArray(await fs.readFile(new URL('tmp/kael-stairs.rgba',root)));
const p=convert({...size,data},{cols:4,rows:1,width:64,height:80,colors:32,margin:3,background:'alpha',sample:'dominant',align:'feet',specks:1});
p.name='Kael · subir escada · estudo de quatro poses';
p.sequences=[{name:'stairs-up-N',start:0,end:3,loop:true,direction:'forward'}];
p.frames.forEach((f,i)=>{f.name=['Elevar pé esquerdo','Transferir peso à esquerda','Elevar pé direito','Transferir peso à direita'][i];f.duration=[180,140,180,140][i];});
const native=validateProject(JSON.parse(JSON.stringify(serialize(p))));native.layers[0].name='Estudo convertido · revisar pixels';
await fs.writeFile(new URL('kael-stairs.pixelgen.json',dir),JSON.stringify(serialize(native)));
await fs.writeFile(new URL('kael-stairs.aseprite',dir),aseprite(native));
await fs.writeFile(new URL('kael-stairs-atlas.json',dir),JSON.stringify(atlas(native,'kael-stairs-sheet.png'),null,2));
await fs.writeFile(new URL('audit.json',dir),JSON.stringify(audit(native),null,2));
console.log(audit(native));
