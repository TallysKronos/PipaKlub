import {parseWorldMap} from '../src/world-map.js';
import {buildWorldArtPlan} from '../src/world-art.js';
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
 const rivals=JSON.parse(fs.readFileSync('assets/rival-art.json','utf8'));
 designs.rivals=Object.fromEntries(Object.entries(rivals).map(([name,rival])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',rival.image))).digest('hex').slice(0,12);return [name,{...rival,url:'assets/'+rival.image+'?v='+hash}]}));
 designs.encounters=Object.fromEntries(Object.entries(encounters).map(([id,scene])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',scene.image))).digest('hex').slice(0,12);return [id,{...scene,url:'assets/'+scene.image+'?v='+hash}]}));
 const city=JSON.parse(fs.readFileSync('assets/packs/cidade-v1/manifest.json','utf8'));
 const districtPlaces=JSON.parse(fs.readFileSync('assets/district-places.json','utf8'));
 const images=Object.fromEntries(Object.entries({home:'backgrounds/quintal-clube-v1.png',city:'packs/cidade-v1/mapa.png',badges:'packs/cidade-v1/insignias.png',...Object.fromEntries(Object.entries(districtPlaces).map(([id,p])=>['district-'+id,p.image]))}).map(([id,image])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);return [id,{image,url:'assets/'+image+'?v='+hash}]}));
 const plaza=JSON.parse(fs.readFileSync('assets/hub/praca-v1/manifest.json','utf8'));
 for(const file of plaza.files){const image='hub/praca-v1/'+file,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['plaza-'+file.replace('.png','')]={image,url:'assets/'+image+'?v='+hash};}
 const world=JSON.parse(fs.readFileSync('assets/world/identity-v2/manifest.json','utf8'));
 world.actors=JSON.parse(fs.readFileSync('assets/characters/overworld-v1/manifest.json','utf8'));
 for(const [id,actor]of Object.entries(world.actors.characters)){const image=actor.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-npc-'+id]={image,url:'assets/'+image+'?v='+hash};}
 world.kit=JSON.parse(fs.readFileSync('assets/world/morro-kit-v1/manifest.json','utf8'));
 world.quintalKit=JSON.parse(fs.readFileSync('assets/world/quintal-kit-v1/manifest.json','utf8'));
 for(const [id,sheet]of Object.entries(world.quintalKit.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const [id,sheet]of Object.entries(world.kit.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const [id,scene]of Object.entries(world.scenes)){const image='world/identity-v2/'+scene.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-'+id]={image,url:'assets/'+image+'?v='+hash};}
 world.scenes.quintal=parseWorldMap(JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/blockout.tmj','utf8')));
 world.scenes.quintal.art=buildWorldArtPlan(world.scenes.quintal,world.quintalKit,JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/art.json','utf8')));
 world.pilot=parseWorldMap(JSON.parse(fs.readFileSync('assets/world/morro-pilot/blockout.tmj','utf8')));
 world.pilot.art=buildWorldArtPlan(world.pilot,world.kit,JSON.parse(fs.readFileSync('assets/world/morro-pilot/art.json','utf8')));
 const courtyard={places:districtPlaces,images,plaza,world,districts:city.districts,badges:city.sheets.insignias.frames};
 return {atlases,intro,dex,items,menu,designs,portraits,courtyard,hud:hudAssets(),kit:kitAssets()};
}
// Papel e Bambu kit: PNG bases and battle icons are served as files; the small glyph SVGs ride inline.
const KIT='ui/kit-switch-v1/';
export function kitFiles(){const m=JSON.parse(fs.readFileSync(path.join('assets',KIT,'manifest.json'),'utf8'));return {m,components:Object.keys(m.components),icons:Object.entries(m.icons).filter(([,i])=>i.image.endsWith('.png')).map(([id])=>id)};}
function kitAssets(){
 const {m,components,icons}=kitFiles(),url=image=>{const file=path.join('assets',KIT,image);return 'assets/'+KIT+image+'?v='+createHash('sha256').update(fs.readFileSync(file)).digest('hex').slice(0,12);};
 return {components:Object.fromEntries(components.map(id=>[id,url(m.components[id].image)])),icons:Object.fromEntries(icons.map(id=>[id,url(m.icons[id].image)])),glyphs:Object.fromEntries(Object.entries(m.glyphs).map(([id,g])=>[id,fs.readFileSync(path.join('assets',KIT,g.image),'utf8')]))};
}
export function copyArt(directory){const config=artConfig();for(const image of [...Object.values(config.atlases).map(a=>a.meta.image),...config.items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',...Object.values(config.menu).map(a=>a.image),...Object.values(config.designs.encounters).map(a=>a.image),...Object.values(config.designs.rivals).map(a=>a.image),...Object.values(config.courtyard.images).map(a=>a.image),...Object.values(config.hud.sheets).map(a=>a.image),...[...Object.values(config.kit.components),...Object.values(config.kit.icons)].map(u=>u.slice(7).split('?')[0])]){const dest=path.join(directory,'assets',image);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join('assets',image),dest);}}
export function artSource(){return 'const ART_CONFIG = '+JSON.stringify(artConfig())+';\n'+fs.readFileSync('src/art-client.js','utf8').replace('export function','function')+'\nconst art=createArtAssets(ART_CONFIG);';}
