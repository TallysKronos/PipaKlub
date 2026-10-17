import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
export function artConfig(){
 const manifest=JSON.parse(fs.readFileSync('assets/atlas.json','utf8').replace(/^\uFEFF/,''));
 const intro=JSON.parse(fs.readFileSync('assets/onboarding/sr-assis.json','utf8').replace(/^\uFEFF/,''));
 const atlases=manifest.atlases;
 for(const a of Object.values(atlases)){const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',a.meta.image))).digest('hex').slice(0,12);a.meta.url='assets/'+a.meta.image+'?v='+hash;}
 const dex=JSON.parse(fs.readFileSync('assets/pipa-dex.json','utf8'));
 const items=JSON.parse(fs.readFileSync('assets/pipa-items.json','utf8')).items;
 for(const item of items){const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',item.image))).digest('hex').slice(0,12);item.url='assets/'+item.image+'?v='+hash;}
 const menu=Object.fromEntries(["collection","trades","summon","farm","profile","history"].map(id=>{const image='ui/club-'+id+'-v2.png',hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);return [id,{image,url:'assets/'+image+'?v='+hash}];}));
 return {atlases,intro,dex,items,menu};
}
export function copyArt(directory){const config=artConfig();for(const image of [...Object.values(config.atlases).map(a=>a.meta.image),...config.items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',...Object.values(config.menu).map(a=>a.image)]){const dest=path.join(directory,'assets',image);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join('assets',image),dest);}}
export function artSource(){return 'const ART_CONFIG = '+JSON.stringify(artConfig())+';\n'+fs.readFileSync('src/art-client.js','utf8').replace('export function','function')+'\nconst art=createArtAssets(ART_CONFIG);';}
