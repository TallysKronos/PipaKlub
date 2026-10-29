// Pixel-level cleanup of the generated draft; no resampling or fabricated subpixels.
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {validateProject,serialize,audit} from '../core.mjs';
import {atlas} from '../animation.mjs';
import {aseprite} from '../aseprite.mjs';
const root=new URL('../../../',import.meta.url),dir=new URL('art/characters/professor-walk-pixel-v1/',root);
const p=validateProject(JSON.parse(await fs.readFile(new URL('draft.pixelgen.json',dir),'utf8')));
const originals=p.frames.map(f=>f.indices.slice());
// A single head model stops AI redrawing hair, eye and goggles on every pose.
for(const f of p.frames)for(let y=0;y<32;y++)for(let x=0;x<48;x++)f.indices[y*48+x]=originals[0][y*48+x];
// On the opposite contact the forward leg is the far leg. Darken it and
// bring the rear silhouette into the near-leg palette; preserve source outlines.
const c=p.frames[2].indices;
for(let y=49;y<57;y++)for(let x=8;x<39;x++){
 const i=y*48+x,v=c[i];if(!v)continue;const [r,g,b]=p.palette[v];
 if(x<23&&r>65&&r>g*1.3&&b<90)c[i]=11;
 else if(x>25&&r+g+b<150&&v!==1&&v!==2)c[i]=16;
}
p.name='Professor · caminhada esquerda';p.sequences=[{name:'walk-left',start:0,end:3,loop:true}];
p.frames.forEach((f,i)=>{f.duration=[140,110,140,110][i];f.sourceRect=undefined;f.sourceBounds=undefined;});
const json=JSON.stringify(serialize(p),null,1);
await fs.writeFile(new URL('professor-walk.pixelgen.json',import.meta.url),json);
await fs.writeFile(new URL('professor-walk.pixelgen.json',dir),json);
await fs.writeFile(new URL('professor-walk.aseprite',dir),aseprite(p));
await fs.writeFile(new URL('professor-walk-atlas.json',dir),JSON.stringify(atlas(p,'professor-walk-sheet.png'),null,2));
await fs.writeFile(new URL('audit.json',dir),JSON.stringify(audit(p),null,2));
console.log('Saved '+fileURLToPath(dir),audit(p));
