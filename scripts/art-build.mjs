import {hudAssets} from './hud-assets.mjs';
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
 const portraits=JSON.parse(fs.readFileSync('assets/portraits.json','utf8'));
 const designs=JSON.parse(fs.readFileSync('assets/designs.json','utf8'));
 const encounters=JSON.parse(fs.readFileSync('assets/encounter-scenes.json','utf8'));
 designs.encounters=Object.fromEntries(Object.entries(encounters).map(([id,scene])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',scene.image))).digest('hex').slice(0,12);return [id,{...scene,url:'assets/'+scene.image+'?v='+hash}]}));
 const city=JSON.parse(fs.readFileSync('assets/packs/cidade-v1/manifest.json','utf8'));
 const districtPlaces=JSON.parse(fs.readFileSync('assets/district-places.json','utf8'));
 const images=Object.fromEntries(Object.entries({home:'backgrounds/quintal-clube-v1.png',city:'packs/cidade-v1/mapa.png',badges:'packs/cidade-v1/insignias.png',...Object.fromEntries(Object.entries(districtPlaces).map(([id,p])=>['district-'+id,p.image]))}).map(([id,image])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);return [id,{image,url:'assets/'+image+'?v='+hash}]}));
 const courtyard={places:districtPlaces,images,districts:city.districts,badges:city.sheets.insignias.frames};
 return {atlases,intro,dex,items,menu,designs,portraits,courtyard,hud:hudAssets(),kit:kitAssets()};
}
// Papel e Bambu kit: PNG bases and battle icons are served as files; the small glyph SVGs ride inline.
const KIT='ui/kit-switch-v1/';
export function kitFiles(){const m=JSON.parse(fs.readFileSync(path.join('assets',KIT,'manifest.json'),'utf8'));return {m,components:Object.keys(m.components),icons:Object.entries(m.icons).filter(([,i])=>i.image.endsWith('.png')).map(([id])=>id)};}
function kitAssets(){
 const {m,components,icons}=kitFiles(),url=image=>{const file=path.join('assets',KIT,image);return 'assets/'+KIT+image+'?v='+createHash('sha256').update(fs.readFileSync(file)).digest('hex').slice(0,12);};
 return {components:Object.fromEntries(components.map(id=>[id,url(m.components[id].image)])),icons:Object.fromEntries(icons.map(id=>[id,url(m.icons[id].image)])),glyphs:Object.fromEntries(Object.entries(m.glyphs).map(([id,g])=>[id,fs.readFileSync(path.join('assets',KIT,g.image),'utf8')]))};
}
export function copyArt(directory){const config=artConfig();for(const image of [...Object.values(config.atlases).map(a=>a.meta.image),...config.items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',...Object.values(config.menu).map(a=>a.image),...Object.values(config.designs.encounters).map(a=>a.image),...Object.values(config.courtyard.images).map(a=>a.image),...Object.values(config.hud.sheets).map(a=>a.image),...[...Object.values(config.kit.components),...Object.values(config.kit.icons)].map(u=>u.slice(7).split('?')[0])]){const dest=path.join(directory,'assets',image);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join('assets',image),dest);}}
export function artSource(){return 'const ART_CONFIG = '+JSON.stringify(artConfig())+';\n'+fs.readFileSync('src/art-client.js','utf8').replace('export function','function')+'\nconst art=createArtAssets(ART_CONFIG);';}
