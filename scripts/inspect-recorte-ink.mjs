// Asset preflight, not a gameplay suite. Reads PNGs and native review captures.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const require=createRequire(import.meta.url);
let sharp;
try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const root=fileURLToPath(new URL('../',import.meta.url)),directory=path.join(root,'godot/assets/ui/recorte-v1');
const manifest=JSON.parse(await fs.readFile(path.join(directory,'manifest.json'),'utf8'));
const report={issue:'PIP-63',assets:manifest.assets.length,exports:0,issues:[],rasters:[],native_corner_comparisons:[],
  scope:'PNG dimensions, alpha, center transparency, native fixed-corner comparison; not gameplay tests or owner visual approval'};
for(const asset of manifest.assets)for(const density of [1,2]){
  const file=density===1?asset.file:asset.file_2x;
  const bytes=await fs.readFile(path.join(directory,file));
  const {data,info}=await sharp(bytes).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  let alphaMin=255,alphaMax=0,visible=0;
  for(let i=3;i<data.length;i+=4){alphaMin=Math.min(alphaMin,data[i]);alphaMax=Math.max(alphaMax,data[i]);if(data[i]>0)visible++;}
  const issues=[];
  if(info.width!==asset.size[0]*density||info.height!==asset.size[1]*density)issues.push('wrong raster dimensions');
  if(visible===0)issues.push('empty image');
  if(asset.alpha==='straight'&&alphaMin!==0)issues.push('missing transparent pixels');
  if(asset.alpha==='opaque-data'&&alphaMin!==255)issues.push('wipe sampling data is not opaque');
  if(asset.slice?.mode==='nine_patch'){
    const center=((Math.floor(info.height/2)*info.width)+Math.floor(info.width/2))*4+3;
    if(data[center]!==0)issues.push('frame center is not transparent');
  }
  if(asset.id==='splat_mask'){
    if(data[(Math.floor(info.height/2)*info.width+Math.floor(info.width/2))*4]>1)issues.push('wipe center is not black');
    if(data[0]!==255)issues.push('wipe corner does not close at white');
    for(let i=0;i<data.length;i+=4)if(data[i]!==data[i+1]||data[i]!==data[i+2]){issues.push('wipe is not grayscale');break;}
  }
  report.exports++;
  report.rasters.push({file,size:[info.width,info.height],bytes:bytes.length,alphaMin,alphaMax,visiblePixels:visible,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
  for(const issue of issues)report.issues.push(file+': '+issue);
}
for(const asset of manifest.assets.filter(a=>a.slice)){
  const file=path.join(root,'documentation/evidence/pip63/stretch-'+asset.id+'.png');
  try{await fs.access(file);}catch{report.issues.push('Missing native capture: '+asset.id);continue;}
  const height=asset.slice.mode==='three_slice'?64:asset.id.startsWith('balloon-')?160:120,step=height+56;
  const y0=180,x0=32,corner=asset.slice.mode==='three_slice'?32:48;
  const corners=[];
  for(const [row,width]of [200,400,800,1600].entries()){
    const tiles=[];
    for(const [x,y]of [[x0,y0+row*step],[x0+width-corner,y0+row*step],
      [x0,y0+row*step+height-corner],[x0+width-corner,y0+row*step+height-corner]]){
      tiles.push(await sharp(file).extract({left:x,top:y,width:corner,height:corner}).raw().toBuffer());
    }
    corners.push(tiles);
  }
  const identical=corners.slice(1).every(tiles=>tiles.every((tile,index)=>tile.equals(corners[0][index])));
  report.native_corner_comparisons.push({asset:asset.id,widths:[200,400,800,1600],logicalCorner:corner,identicalPixels:identical});
  if(!identical)report.issues.push('Native corner pixels differ across widths: '+asset.id);
}
await fs.mkdir(path.join(root,'documentation/evidence/pip63'),{recursive:true});
await fs.writeFile(path.join(root,'documentation/evidence/pip63/asset-preflight.json'),JSON.stringify(report,null,2)+'\n');
manifest.approval.technical=report.issues.length?'needs-correction':'png-and-native-corner-preflight-passed';
await fs.writeFile(path.join(directory,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({assets:report.assets,exports:report.exports,nativeComparisons:report.native_corner_comparisons.length,issues:report.issues},null,2));
process.exitCode=report.issues.length?1:0;
