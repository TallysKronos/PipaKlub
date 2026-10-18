import fs from 'node:fs';
import {createHash} from 'node:crypto';
export function hudAssets(){
 const manifest=JSON.parse(fs.readFileSync('assets/ui/hud-papel-bambu-v1/manifest.json','utf8'));
 for(const sheet of Object.values(manifest.sheets)){const bytes=fs.readFileSync('assets/'+sheet.image);sheet.url='assets/'+sheet.image+'?v='+createHash('sha256').update(bytes).digest('hex').slice(0,12);}
 return manifest;
}
// Virtual cuts reuse the original alpha atlas without resampling its pixels.
export function hudSliceRects(atlas,id){
 const [sheet,x,y,w,h]=atlas.frames[id],spec=atlas.slices[id],[t,r,b,l]=spec.insets;
 if(!['three','nine'].includes(spec.mode)||[t,r,b,l].some(n=>!Number.isFinite(n)||n<0)||l+r>=w||t+b>=h||!(spec.scale>0))throw Error('Invalid HUD slices: '+id);
 if(spec.mode==='three')return {l:[sheet,spec.mirrorLeft?x+w-r:x,y,l,h],c:[sheet,x+(spec.centerStart??l),y,w-(spec.centerStart??l)-r,h],r:[sheet,x+w-r,y,r,h]};
 const columns=[[x,l],[x+l,w-l-r],[x+w-r,r]],rows=[[y,t],[y+t,h-t-b],[y+h-b,b]],names=[['tl','t','tr'],['l','c','r'],['bl','b','br']];
 return Object.fromEntries(rows.flatMap(([sy,sh],ri)=>columns.map(([sx,sw],ci)=>[names[ri][ci],[sheet,sx,sy,sw,sh]])));
}
function cropCSS(atlas,[sheet,x,y,w,h]){
 const s=atlas.sheets[sheet];if(w<=0||h<=0||x<0||y<0||x+w>s.width||y+h>s.height)throw Error('HUD crop outside sheet');
 return 'background-image:url("'+s.url+'")!important;background-size:'+s.width/w*100+'% '+s.height/h*100+'%!important;background-position:'+x/(s.width-w)*100+'% '+y/(s.height-h)*100+'%!important';
}
export function hudSpriteCSS(){
 const atlas=hudAssets();
 const sprites=Object.entries(atlas.frames).map(([id,rect])=>'.hud-art-'+id+'{'+cropCSS(atlas,rect)+'}');
 const sliced=Object.entries(atlas.slices).flatMap(([id,spec])=>{
  const [t,r,b,l]=spec.insets,s=spec.scale,px=n=>Number((n*s).toFixed(4));
  return ['.hud-sliced[data-hud-skin="'+id+'"]{--hud-cap-t:'+px(t)+'px;--hud-cap-r:'+px(r)+'px;--hud-cap-b:'+px(b)+'px;--hud-cap-l:'+px(l)+'px}',...Object.entries(hudSliceRects(atlas,id)).map(([part,rect])=>'.hud-sliced[data-hud-skin="'+id+'"]>.hud-slice-'+part+'{'+cropCSS(atlas,rect)+(spec.mirrorLeft&&part==='l'?'transform:scaleX(-1);':'')+'}')];
 });
 return sprites.concat(sliced).join('\n')+'\n'+fs.readFileSync('src/hud-skin.css','utf8');
}
