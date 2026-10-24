import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {hudAssets,hudSpriteCSS} from './hud-assets.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
export const workshopFiles=['index.html','game.mjs','model.mjs','protocol.mjs','live-client.mjs','look.mjs','hand.mjs','style.css','atelier-v1.png','mesa.jpg','rabbito.png','assis.png'];
export const workshopMime={'.html':'text/html; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.jpg':'image/jpeg','.png':'image/png'};
export function workshopFile(name){
 if(workshopFiles.includes(name))return fs.readFileSync(path.join(root,'tools/oficina-v3',name));
 if(name==='hud-skin.mjs')return fs.readFileSync(path.join(root,'src/hud-skin.js'));
 if(name==='hud.css')return Buffer.from(hudSpriteCSS().replaceAll('assets/ui/hud-papel-bambu-v1/','../assets/ui/hud-papel-bambu-v1/'));
 if(name==='hud.json')return Buffer.from(JSON.stringify(hudAssets()));
 return null;
}
export function copyWorkshopV3(directory){const dest=path.join(directory,'oficina-v3');fs.mkdirSync(dest,{recursive:true});for(const name of [...workshopFiles,'hud-skin.mjs','hud.css','hud.json'])fs.writeFileSync(path.join(dest,name),workshopFile(name));}
