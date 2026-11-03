import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {render,sample} from '../../../../tools/soulgen-studio/model.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const folder=fileURLToPath(new URL('./cutout-rig-v1/',import.meta.url)),project=JSON.parse(fs.readFileSync(folder+'tufanocorte.soulgen.json'));
const images={};for(const [id,a]of Object.entries(project.assets))images[id]=await loadImage(folder+path.basename(a.src));
const poses=[['idle',0],['flight',.4],['flight',1.2],['skill',.55],['skill',.8],['hurt',.14],['victory',.9],['defeat',1.2]];
const canvas=createCanvas(1600,840),g=canvas.getContext('2d');
for(const [i,[id,t]]of poses.entries()){
 const x=(i%4)*400,y=Math.floor(i/4)*420,tile=createCanvas(400,380);
 render(tile.getContext('2d'),project,images,sample(project,id,t),{scale:.55});
 g.fillStyle=i<4?'#f3ead6':'#182c3b';g.fillRect(x,y,400,420);g.drawImage(tile,x,y);g.font='17px sans-serif';g.fillStyle=i<4?'#182c3b':'#f3ead6';g.fillText(id+' · '+t.toFixed(2)+' s',x+12,y+405);
}
fs.writeFileSync(folder+'extremes-review.png',canvas.toBuffer('image/png'));
