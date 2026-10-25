// Normalize generated sprites; source illustration and portrait are preserved.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
const {createCanvas,loadImage}=await import(pathToFileURL(process.env.SOULGEN_CANVAS_MODULE||'C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/index.js'));
const root='assets/characters/nina-overworld-v2',source='art/characters/nina-overworld-v2/source.png';
const image=await loadImage(source),cw=image.width/4,ch=image.height/2,cell=192,target=144;
const atlas=createCanvas(cell*4,cell*2),g=atlas.getContext('2d'),frames=[];
for(let i=0;i<8;i++){
 const raw=createCanvas(cw,ch),r=raw.getContext('2d');r.drawImage(image,i%4*cw,Math.floor(i/4)*ch,cw,ch,0,0,cw,ch);
 const d=r.getImageData(0,0,cw,ch);let l=cw,t=ch,right=-1,bottom=-1;
 for(let y=0;y<ch;y++)for(let x=0;x<cw;x++)if(d.data[(y*cw+x)*4+3]>64){l=Math.min(l,x);right=Math.max(right,x);t=Math.min(t,y);bottom=Math.max(bottom,y);}
 if(right<l)throw Error('Célula vazia: '+i);
 const w=right-l+1,h=bottom-t+1,scale=target/h,dw=Math.round(w*scale),dx=Math.round((cell-dw)/2),dy=cell-12-target,x=i%4*cell,y=Math.floor(i/4)*cell;
 g.drawImage(raw,l,t,w,h,x+dx,y+dy,dw,target);
 frames.push({x,y,w:cell,h:cell,bounds:{x:dx,y:dy,w:dw,h:target},footAnchor:{x:cell/2,y:cell-12},direction:['south','west','east','north'][i%4],pose:i<4?'idle':'walk'});
}
fs.writeFileSync(root+'/overworld.png',atlas.toBuffer('image/png'));
fs.writeFileSync(root+'/manifest.json',JSON.stringify({name:'Nina',image:'characters/nina-overworld-v2/overworld.png',referenceHeight:target,directions:['south','west','east','north'],frames,presentation:'Dedicated chibi overworld sheet: four idle directions and four walking poses. No portrait reuse.'},null,2)+'\n');
const preview=createCanvas(768,384),p=preview.getContext('2d');p.fillStyle='#e8ecd9';p.fillRect(0,0,768,384);p.drawImage(atlas,0,0);fs.writeFileSync('art/characters/nina-overworld-v2/normalized-preview.png',preview.toBuffer('image/png'));
fs.writeFileSync(root+'/production.json',JSON.stringify({source,tool:'image_gen built-in',date:'2026-10-25',identityReference:'assets/characters/nina-v1/portrait.png',styleReference:'assets/characters/overworld-v1/sr-assis.png',sourceSize:[image.width,image.height],atlasSize:[atlas.width,atlas.height],cell,referenceHeight:target,frames:8,notes:'Alpha preserved. Measured opaque bounds per generated cell; shared height and foot baseline. Portrait and legacy illustration untouched.'},null,2)+'\n');
console.log('Nina: 8 quadros, 4 direções, atlas 768×384, apoio dos pés fixo.');
