import {copyWorkshopV3} from './workshop-v3-build.mjs';
import {avatarConfig,avatarSource} from './avatar-build.mjs';
import {createParkIsometricScene} from '../src/park-isometric-layout.js';
import {BEDROOM_LAYOUT,bedroomRoom,bedroomMap} from '../src/bedroom-layout.js';
import {HOME_LAYOUT,homeRoom,homeMap} from '../src/home-layout.js';
import {streetMap} from '../src/street-layout.js';
import {serviceMap} from '../src/service-interiors.js';
import {parseWorldMap} from '../src/world-map.js';
import {buildWorldArtPlan,validateWorldPaintedImages} from '../src/world-art.js';
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
 const title=JSON.parse(fs.readFileSync('assets/title/elo-das-ruinas-v1/manifest.json','utf8'));
 for(const [id,def]of Object.entries(title.images)){const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',def.image))).digest('hex').slice(0,12);images['title-'+id]={...def,url:'assets/'+def.image+'?v='+hash};}
 const plaza=JSON.parse(fs.readFileSync('assets/hub/praca-v1/manifest.json','utf8'));
 for(const file of plaza.files){const image='hub/praca-v1/'+file,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['plaza-'+file.replace('.png','')]={image,url:'assets/'+image+'?v='+hash};}
 const world=JSON.parse(fs.readFileSync('assets/world/identity-v2/manifest.json','utf8'));
 world.actors=JSON.parse(fs.readFileSync('assets/characters/overworld-v1/manifest.json','utf8'));
 world.companions=JSON.parse(fs.readFileSync('assets/creatures/overworld-v1/manifest.json','utf8'));
 for(const [id,actor]of Object.entries(world.companions.species)){const image=actor.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-companion-'+id]={image,url:'assets/'+image+'?v='+hash};}
 const mom=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8'));world.actors.characters.mother={name:'Mãe',image:mom.images.mother.image,frames:mom.actors.mother.frames.map(f=>({...f,footAnchor:{x:f.bounds.x+f.bounds.w/2,y:f.bounds.y+f.bounds.h}})),referenceHeight:Math.max(...mom.actors.mother.frames.map(f=>f.bounds.h))};
 for(const [id,actor]of Object.entries(world.actors.characters)){const image=actor.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-npc-'+id]={image,url:'assets/'+image+'?v='+hash};}
 world.kit=JSON.parse(fs.readFileSync('assets/world/morro-kit-v1/manifest.json','utf8'));
 world.quintalKit=JSON.parse(fs.readFileSync('assets/world/quintal-kit-v1/manifest.json','utf8'));
 for(const [id,sheet]of Object.entries(world.quintalKit.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 const morroRoad=JSON.parse(fs.readFileSync('assets/world/morro-road-v1/manifest.json','utf8'));
 Object.assign(world.kit.sheets,JSON.parse(fs.readFileSync('assets/world/morro-plaza-v1/manifest.json','utf8')).sheets,morroRoad.sheets);
 for(const [id,sheet]of Object.entries(world.kit.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const [id,scene]of Object.entries(world.scenes)){const image='world/identity-v2/'+scene.image,hash=createHash('sha256').update(fs.readFileSync(path.join('assets',image))).digest('hex').slice(0,12);images['world-'+id]={image,url:'assets/'+image+'?v='+hash};}
 world.scenes.quintal=parseWorldMap(JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/blockout.tmj','utf8')));
 world.scenes.quintal.art=buildWorldArtPlan(world.scenes.quintal,world.quintalKit,JSON.parse(fs.readFileSync('assets/world/quintal-modular-v1/art.json','utf8')));
 world.legacyCourtyard=world.scenes.quintal;
 const street=JSON.parse(fs.readFileSync('assets/world/street-v1/manifest.json','utf8'));world.street=street;
 for(const [id,sheet]of Object.entries(street.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync('assets/'+image)).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const [id,map]of Object.entries(street.scenes)){world.scenes[id]=validateWorldPaintedImages(parseWorldMap(JSON.parse(fs.readFileSync('assets/'+map,'utf8'))),street.sheets);world.scenes[id].painted=true;}
 world.pilot=parseWorldMap(JSON.parse(fs.readFileSync('assets/world/morro-pilot/blockout.tmj','utf8')));
 world.pilot.art=buildWorldArtPlan(world.pilot,world.kit,JSON.parse(fs.readFileSync('assets/world/morro-pilot/art.json','utf8')));
 world.paintedPilot=validateWorldPaintedImages(parseWorldMap(JSON.parse(fs.readFileSync('assets/world/morro-plaza-v1/plaza.tmj','utf8'))),world.kit.sheets);world.paintedPilot.painted=true;
 world.morroRoad=morroRoad.chapters.map(c=>{const scene=validateWorldPaintedImages(parseWorldMap(JSON.parse(fs.readFileSync('assets/'+c.map,'utf8'))),world.kit.sheets);scene.painted=true;return {...c,scene};});
 const parkKit=JSON.parse(fs.readFileSync('assets/world/park-kit-v3/manifest.json','utf8')),parkArtKit={...world.quintalKit,sheets:{...world.quintalKit.sheets,...parkKit.sheets},frames:{...world.quintalKit.frames,...parkKit.frames}};
 for(const [id,sheet]of Object.entries(parkKit.sheets)){const image=sheet.image,hash=createHash('sha256').update(fs.readFileSync('assets/'+image)).digest('hex').slice(0,12);images['world-kit-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const id of ['park-trail','park-clearing']){const scene=parseWorldMap(JSON.parse(fs.readFileSync('assets/world/park-v1/'+id+'.tmj','utf8')));scene.art=buildWorldArtPlan(scene,parkArtKit,JSON.parse(fs.readFileSync('assets/world/park-v1/'+id+'.art.json','utf8')));world.scenes[id]=scene;}
 world.parkIsometric=JSON.parse(fs.readFileSync('assets/world/park-isometric-v1/manifest.json','utf8'));
 for(const [id,a]of Object.entries(world.parkIsometric.images)){const image=a.image,hash=createHash('sha256').update(fs.readFileSync('assets/'+image)).digest('hex').slice(0,12);images['park-iso-'+id]={image,url:'assets/'+image+'?v='+hash};}
 for(const id of ['park-trail','park-clearing'])world.scenes[id]=createParkIsometricScene(JSON.parse(fs.readFileSync('assets/world/park-v1/'+id+'.tmj','utf8')),world.scenes[id].art,{production:true});
 world.villageIsometric=JSON.parse(fs.readFileSync('assets/world/village-isometric-v1/manifest.json','utf8'));
 Object.assign(world.villageIsometric.images,JSON.parse(fs.readFileSync('assets/world/kael-bedroom-iso-v4/manifest.json','utf8')).images);
 Object.assign(world.villageIsometric.images,JSON.parse(fs.readFileSync('assets/world/kael-home-iso-v1/manifest.json','utf8')).images);
 Object.assign(world.villageIsometric.images,JSON.parse(fs.readFileSync('assets/world/village-grid-v2/manifest.json','utf8')).images);
 for(const [id,a]of Object.entries(world.villageIsometric.images)){const image=a.image,hash=createHash('sha256').update(fs.readFileSync('assets/'+image)).digest('hex').slice(0,12);images['village-iso-'+id]={image,url:'assets/'+image+'?v='+hash};}
  world.scenes['kael-bedroom']=parseWorldMap(bedroomMap());
  world.scenes['kael-home']=parseWorldMap(homeMap());
  world.scenes.quintal=parseWorldMap(streetMap());
  for(const id of ['professor-home','kite-shop'])world.scenes[id]=parseWorldMap(serviceMap(id));
  world.bedroomLayout=BEDROOM_LAYOUT;
  for(const id of ['quintal','kael-home','kael-bedroom','professor-home','kite-shop'])Object.assign(world.scenes[id],{isometric:true,village:id});
 const opening=JSON.parse(fs.readFileSync('assets/story/kael-birthday-v1/manifest.json','utf8'));
  opening.rooms.bedroom=bedroomRoom();
  opening.rooms.downstairs=homeRoom();
  opening.homeLayout=HOME_LAYOUT;
 for(const def of Object.values(opening.images))def.url='assets/'+def.image+'?v='+createHash('sha256').update(fs.readFileSync('assets/'+def.image)).digest('hex').slice(0,12);
 const courtyard={places:districtPlaces,images,plaza,world,districts:city.districts,badges:city.sheets.insignias.frames};
 // Soulgen rigs (drawn only with ?rig): hashed URLs for each source PNG of each rig project.
 const rigs=Object.fromEntries(Object.entries(JSON.parse(fs.readFileSync('assets/creatures/rig-v1/manifest.json','utf8')).rigs).map(([id,r])=>[id,{...r,urls:Object.fromEntries(Object.entries(r.project.assets).map(([asset,a])=>{const hash=createHash('sha256').update(fs.readFileSync(path.join('assets',a.src))).digest('hex').slice(0,12);return [asset,'assets/'+a.src+'?v='+hash];}))}]));
 const workshop=JSON.parse(fs.readFileSync("assets/workshop/v1/manifest.json","utf8"));for(const def of Object.values(workshop.images)){def.url="assets/"+def.image+"?v="+createHash("sha256").update(fs.readFileSync("assets/"+def.image)).digest("hex").slice(0,12);}
 return {avatar:avatarConfig(),workshop,opening,atlases,intro,dex,items,menu,designs,portraits,courtyard,hud:hudAssets(),kit:kitAssets(),rigs};
}
// Papel e Bambu kit: PNG bases and battle icons are served as files; the small glyph SVGs ride inline.
const KIT='ui/kit-switch-v1/';
export function kitFiles(){const m=JSON.parse(fs.readFileSync(path.join('assets',KIT,'manifest.json'),'utf8'));return {m,components:Object.keys(m.components),icons:Object.entries(m.icons).filter(([,i])=>i.image.endsWith('.png')).map(([id])=>id)};}
function kitAssets(){
 const {m,components,icons}=kitFiles(),url=image=>{const file=path.join('assets',KIT,image);return 'assets/'+KIT+image+'?v='+createHash('sha256').update(fs.readFileSync(file)).digest('hex').slice(0,12);};
 return {components:Object.fromEntries(components.map(id=>[id,url(m.components[id].image)])),icons:Object.fromEntries(icons.map(id=>[id,url(m.icons[id].image)])),glyphs:Object.fromEntries(Object.entries(m.glyphs).map(([id,g])=>[id,fs.readFileSync(path.join('assets',KIT,g.image),'utf8')]))};
}
export function copyArt(directory){copyWorkshopV3(directory);const config=artConfig();for(const image of [...Object.values(config.avatar.images).map(u=>u.slice(7).split('?')[0]),...Object.values(config.workshop.images).map(a=>a.image),...Object.values(config.opening.images).map(a=>a.image),...Object.values(config.atlases).map(a=>a.meta.image),...config.items.map(i=>i.image),'vfx/trade-celestial.png','vfx/trade-sky.png','vfx/trade-spirit-16.png',...Object.values(config.menu).map(a=>a.image),...Object.values(config.designs.encounters).map(a=>a.image),...Object.values(config.designs.rivals).map(a=>a.image),...Object.values(config.courtyard.images).map(a=>a.image),...Object.values(config.hud.sheets).map(a=>a.image),...[...Object.values(config.kit.components),...Object.values(config.kit.icons)].map(u=>u.slice(7).split('?')[0]),...Object.values(config.rigs).flatMap(r=>Object.values(r.project.assets).map(a=>a.src))]){const dest=path.join(directory,'assets',image);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(path.join('assets',image),dest);}}
export function artSource(){return 'const ART_CONFIG = '+JSON.stringify(artConfig())+';\n'+fs.readFileSync('src/art-client.js','utf8').replace('export function','function')+'\nconst art=createArtAssets(ART_CONFIG);\n'+rigSource()+avatarSource();}
// The Studio's own sampler (tools/soulgen-studio/model.mjs) runs the rigs in game, scoped inside soulgenRigs.
export function rigSource(){return fs.readFileSync('src/soulgen-rig-client.js','utf8').replace('/* SOULGEN_MODEL */',fs.readFileSync('tools/soulgen-studio/model.mjs','utf8').replace(/^export /gm,''));}
