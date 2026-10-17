import fs from 'node:fs';
import {createHash} from 'node:crypto';
export function hudAssets(){
 const manifest=JSON.parse(fs.readFileSync('assets/ui/hud-papel-bambu-v1/manifest.json','utf8'));
 for(const sheet of Object.values(manifest.sheets)){const bytes=fs.readFileSync('assets/'+sheet.image);sheet.url='assets/'+sheet.image+'?v='+createHash('sha256').update(bytes).digest('hex').slice(0,12);}
 return manifest;
}
export function hudSpriteCSS(){
 const atlas=hudAssets();
 return Object.entries(atlas.frames).map(([id,[sheet,x,y,w,h]])=>{
  const s=atlas.sheets[sheet];if(x<0||y<0||x+w>s.width||y+h>s.height)throw Error('HUD frame outside sheet: '+id);
  return '.hud-art-'+id+'{background-image:url("'+s.url+'")!important;background-size:'+s.width/w*100+'% '+s.height/h*100+'%;background-position:'+x/(s.width-w)*100+'% '+y/(s.height-h)*100+'%}';
 }).join('\n');
}
