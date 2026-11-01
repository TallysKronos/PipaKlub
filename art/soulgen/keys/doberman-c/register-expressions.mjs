import fs from 'node:fs';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
import {decodePNG,encodePNG} from '../../../../tools/pixelgen/png.mjs';
const require=createRequire(import.meta.url),{createCanvas,loadImage}=require(process.env.SOULGEN_CANVAS_MODULE||'@napi-rs/canvas');
const folder=fileURLToPath(new URL('./refined-rig-v3/',import.meta.url)),slices=JSON.parse(fs.readFileSync(folder+'slices.json')),old=JSON.parse(fs.readFileSync(new URL('./sliced-rig-v2/slices.json',import.meta.url)));
const canonical=decodePNG(fs.readFileSync(folder+'head.png')),oldHead=old.parts.head.crop,head=slices.parts.head.crop,dx=head[0]-oldHead[0],dy=head[1]-oldHead[1];
const source=await loadImage(folder+'expressions-source.png'),sheet=createCanvas(oldHead[2]*3,oldHead[3]),ctx=sheet.getContext('2d');ctx.drawImage(source,0,0,sheet.width,sheet.height);
const polygons=[[[173,216],[244,216],[274,241],[273,270],[197,274],[180,258]],[[204,285],[248,285],[282,304],[282,329],[270,335],[243,331],[218,327],[204,314]]];
function inside(p,x,y){let at=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const [a,b]=p[i],[c,d]=p[j];if((b>y)!==(d>y)&&x<(c-a)*(y-b)/(d-b)+a)at=!at;}return at;}
function edgeDistance(poly,x,y){let best=1e9;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [ax,ay]=poly[j],[bx,by]=poly[i],vx=bx-ax,vy=by-ay,t=Math.max(0,Math.min(1,((x-ax)*vx+(y-ay)*vy)/(vx*vx+vy*vy)));best=Math.min(best,Math.hypot(x-ax-t*vx,y-ay-t*vy));}return best;}
const windows=[[166-dx,208-dy,134,74],[185-dx,265-dy,Math.min(169,canonical.width-(185-dx)),102]],report={canonicalSize:[canonical.width,canonical.height],windows,expressions:{},source:'expressions-source.png',method:'Facial RGB registered in two windows; canonical alpha, ears, neck and every external pixel unchanged.'};
for(const [index,face]of ['fierce','happy','hurt'].entries()){
 const patch=ctx.getImageData(index*oldHead[2],0,oldHead[2],oldHead[3]).data,data=new Uint8ClampedArray(canonical.data);let changed=0;
 for(let y=0;y<canonical.height;y++)for(let x=0;x<canonical.width;x++){const at=(y*canonical.width+x)*4,px=x+dx,py=y+dy;if(!polygons.some(p=>inside(p,px+.5,py+.5)))continue;const src=(py*oldHead[2]+px)*4;if(patch[src+3]<128)continue;
 let weight=0;for(const [a,b,w,h]of windows)if(x>=a&&y>=b&&x<a+w&&y<b+h)weight=Math.max(weight,Math.min(1,(x-a)/4,(a+w-1-x)/4,(y-b)/4,(b+h-1-y)/4));weight*=Math.min(1,Math.max(...polygons.filter(p=>inside(p,px+.5,py+.5)).map(p=>edgeDistance(p,px+.5,py+.5)))/4);for(let c=0;c<4;c++){if(c===3)continue;data[at+c]=Math.round(canonical.data[at+c]*(1-weight)+patch[src+c]*weight);}if(data[at]!==canonical.data[at]||data[at+1]!==canonical.data[at+1]||data[at+2]!==canonical.data[at+2])changed++;}
 let alphaIdentical=true,outsideIdentical=true;
 for(let i=0;i<data.length;i+=4){if(data[i+3]!==canonical.data[i+3])alphaIdentical=false;const x=(i/4)%canonical.width,y=Math.floor(i/4/canonical.width);if(!windows.some(([a,b,w,h])=>x>=a&&y>=b&&x<a+w&&y<b+h))for(let c=0;c<4;c++)if(data[i+c]!==canonical.data[i+c])outsideIdentical=false;}
 if(!outsideIdentical||changed<100)throw Error('Expression registration failed: '+face);
 fs.writeFileSync(folder+'head-'+face+'.png',encodePNG(data,canonical.width,canonical.height));report.expressions[face]={changed_pixels:changed,alpha_identical:alphaIdentical,outside_face_identical:outsideIdentical};
}
fs.writeFileSync(folder+'registration.json',JSON.stringify(report,null,2)+'\n');console.log(report.expressions);
