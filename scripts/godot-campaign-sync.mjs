import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {KAEL_OPENING} from '../src/opening-story.js';
import {BEDROOM_LAYOUT,bedroomProject,bedroomRoom,bedroomProjectPoint} from '../src/bedroom-layout.js';
import {HOME_LAYOUT,homeProject,homeRoom} from '../src/home-layout.js';
import {placement,footprintRect} from '../tools/iso-studio/model.mjs';
import {createBedroomIsometricRenderer} from '../src/bedroom-isometric.js';
import {createFirstFlight} from '../src/first-flight.js';
import {paintStreetGround} from '../src/street-ground.js';
import {STREET_LAYOUT,streetObjects,streetMap} from '../src/street-layout.js';
import {serviceLayout,serviceMap} from '../src/service-interiors.js';
import {createServiceIsometricRenderer} from '../src/service-isometric.js';
const modulePath=process.env.SOULGEN_CANVAS_MODULE;
if(!modulePath)throw Error('Defina SOULGEN_CANVAS_MODULE para o runtime de canvas instalado.');
const {createCanvas,loadImage}=await import(pathToFileURL(modulePath));
const root='godot/assets/campaign';fs.mkdirSync(root,{recursive:true});
const copy=(source,name)=>{fs.copyFileSync(source,path.join(root,name));return name;};
const data={opening:KAEL_OPENING,rooms:{},portraits:{}};
for(const [id,layout,project,room,folder] of [['bedroom',BEDROOM_LAYOUT,bedroomProject,bedroomRoom(),'kael-bedroom-iso-v4'],['home',HOME_LAYOUT,homeProject,homeRoom(),'kael-home-iso-v1']]){
 const renderer=createBedroomIsometricRenderer({village:id==='home'?'kael-home':'kael-bedroom'},{},{},{},()=>createCanvas(1,1));
 const camera=renderer.camera({},960,640),canvas=createCanvas(960,640),ctx=canvas.getContext('2d');
 ctx.scale(camera.scale,camera.scale);ctx.translate(-camera.x,-camera.y);renderer.draw(ctx,{x:0,y:0},[]);
 fs.writeFileSync(path.join(root,id+'-floor.png'),canvas.toBuffer('image/png'));
 const base=bedroomProjectPoint({x:layout.floor.x,y:layout.floor.y});
 const props=project.pieces.map(p=>{const q=placement(project.room,p),rect=[(q.x+base.x-project.room.origin[0]-camera.x)*camera.scale,(q.y+base.y-project.room.origin[1]-camera.y)*camera.scale,q.box.w*camera.scale,q.box.h*camera.scale];return {id:p.id,kind:p.kind,footprint:footprintRect(p),rect,image:copy(`assets/world/${folder}/${p.id}.png`,id+'-'+p.id+'.png')};});
 data.rooms[id]={...room,layout,camera,props,floorImage:id+'-floor.png'};
}
const portraits=JSON.parse(fs.readFileSync('assets/ui/dialogue-v1/manifest.json','utf8'));
const village=JSON.parse(fs.readFileSync('assets/world/village-grid-v2/manifest.json','utf8'));
const street=streetMap(),layers=Object.fromEntries(street.layers.map(l=>[l.name,l.objects]));
const streetCanvas=createCanvas(4352,2304),streetContext=streetCanvas.getContext('2d');
streetContext.translate(1856,170);streetContext.transform(.82,.41,-.82,.41,0,0);paintStreetGround(streetContext);
fs.writeFileSync(path.join(root,'street-floor.png'),streetCanvas.toBuffer('image/png'));
const streetProps=[];
for(const object of streetObjects()){
 const definition=village.images[object.asset];
 if(!definition)continue; // Rig-only animated decorations remain outside this static export.
 const pivot=object.pivot||definition.pivot||[.5,.98],height=object.w*definition.height/definition.width;
 const image=copy('assets/'+definition.image,'street-'+object.asset+'.png');
 streetProps.push({id:object.asset,image,kind:'floor',footprint:{u0:object.x/96-.12,u1:object.x/96+.12,v0:object.y/96-.12,v1:object.y/96+.12},rect:[(object.x-object.y)*.82+1856-object.w*pivot[0],(object.x+object.y)*.41+170-height*pivot[1]-(object.lift||0),object.w,height]});
}
data.rooms.street={id:'street',projection:'street',floorImage:'street-floor.png',camera:{x:-1856,y:-170,scale:1},layout:{floor:{x:0,y:0},blocking:{kaelEntry:[480,768]}},props:streetProps,walkable:layers.Walkable.map(r=>[r.x,r.y,r.width,r.height]),blocked:layers.Solids.map(r=>[r.x,r.y,r.width,r.height]),hotspots:[...STREET_LAYOUT.houses.map(h=>({id:h.target,name:h.name,x:h.x,y:h.y+48})),{id:'park',name:'Parque dos Ventos',x:1792,y:1808},{id:'morro',name:'Morro do Sol',x:2592,y:1040}]};
const plan=serviceLayout('professor-home'),service=serviceMap('professor-home'),serviceLayers=Object.fromEntries(service.layers.map(l=>[l.name,l.objects]));
const renderer=createServiceIsometricRenderer({village:'professor-home'},{},{},{},()=>createCanvas(1,1));
const camera=renderer.camera({},960,640),floor=createCanvas(960,640),context=floor.getContext('2d'),origin=bedroomProjectPoint(plan.floor);
const shell=await loadImage('assets/'+village.images['assis-shell'].image);
context.scale(camera.scale,camera.scale);context.translate(-camera.x,-camera.y);context.drawImage(shell,origin.x-plan.room.origin[0],origin.y-plan.room.origin[1]);
fs.writeFileSync(path.join(root,'professor-floor.png'),floor.toBuffer('image/png'));
const props=plan.pieces.map(p=>{const q=placement(plan.room,p);return {id:p.id,image:copy('assets/'+village.images[plan.prefix+p.id].image,'professor-'+p.id+'.png'),kind:p.kind,footprint:footprintRect(p),rect:[(q.x+origin.x-plan.room.origin[0]-camera.x)*camera.scale,(q.y+origin.y-plan.room.origin[1]-camera.y)*camera.scale,q.box.w*camera.scale,q.box.h*camera.scale]};});
const exit=plan.hotspots.find(h=>h.id==='exit');
data.rooms.professor={id:'professor',floorImage:'professor-floor.png',camera,layout:{floor:plan.floor,blocking:{kaelEntry:[exit.x,exit.y-64],mother:plan.npc}},props,walkable:serviceLayers.Walkable.map(r=>[r.x,r.y,r.width,r.height]),blocked:serviceLayers.Solids.map(r=>[r.x,r.y,r.width,r.height]),hotspots:plan.hotspots};
const assis=JSON.parse(fs.readFileSync('assets/characters/overworld-v1/manifest.json')).characters['sr-assis'],frame=assis.frames[0],npc=await loadImage('assets/'+assis.image),crop=createCanvas(frame.bounds.w,frame.bounds.h);
crop.getContext('2d').drawImage(npc,frame.x+frame.bounds.x,frame.y+frame.bounds.y,frame.bounds.w,frame.bounds.h,0,0,frame.bounds.w,frame.bounds.h);
fs.writeFileSync(path.join(root,'assis-overworld.png'),crop.toBuffer('image/png'));
for(const [speaker,id]of Object.entries(portraits.speakers)){const a=portraits.images[id];if(a)data.portraits[speaker]=copy('assets/'+a.image,'portrait-'+id+'.png');}
copy('assets/story/kael-birthday-v1/tail.png','ancient-tail.png');
copy('assets/story/kael-birthday-v1/mother-overworld-v2.png','mother-overworld.png');
copy('assets/ui/dialogue-v1/frame.png','dialogue-frame.png');
copy('assets/backgrounds/bairro-morro-v1.png','broadcast-background.png');
const atlas=JSON.parse(fs.readFileSync('assets/atlas.json','utf8')).atlases;
data.lessons=createFirstFlight({}).lessons;
data.practice={};
for(const id of ['rabbito','nozinho']){
 const sheet=atlas[id];
 data.practice[id]={image:copy('assets/'+sheet.meta.image,'practice-'+id+'.png'),frames:sheet.animations.idle.map(key=>sheet.frames[key].frame)};
}
copy('assets/backgrounds/arena-morro-1-v1.png','practice-background.png');
copy('assets/ui/hud-papel-bambu-v1/panels.png','hud-panels.png');
copy('assets/ui/hud-papel-bambu-v1/icons.png','hud-icons.png');
copy('assets/ui/hud-papel-bambu-v1/manifest.json','hud-manifest.json');
copy('tools/oficina-v3/atelier-v1.png','workshop-background.png');
data.combat={};
for(const id of ['rabbito','basic-carcara','basic-mata-verde','basic-azulao','basic-raio-de-sol','lacertubo']){
 const sheet=atlas[id];if(!sheet)throw Error('Missing atlas '+id);
 data.combat[id]={image:copy('assets/'+sheet.meta.image,'combat-'+id+'.png'),animations:Object.fromEntries(['idle','attack','victory','defeat'].map(action=>[action,(sheet.animations[action]||sheet.animations.idle).map(key=>sheet.frames[key].frame)]))};
}
for(const [source,name]of [['assets/items/rabiolas/rabiola-carcara.png','nina-tail.png'],['assets/ui/guardian-veredas-v1/frame.png','guardian-frame.png'],['assets/ui/guardian-veredas-v1/crest.png','guardian-crest.png'],['assets/ui/battle-results-v1/victory.png','victory.png'],['assets/ui/battle-results-v1/defeat.png','defeat.png']])copy(source,name);
data.broadcast=[];
for(const id of ['basic-carcara','basic-azulao']){
 const sheet=atlas[id];
 data.broadcast.push({image:copy('assets/'+sheet.meta.image,id+'.png'),frames:sheet.animations.idle.map(key=>sheet.frames[key].frame)});
}
fs.writeFileSync(path.join(root,'content.json'),JSON.stringify(data,null,2)+'\n');
console.log('Godot campanha: falas e plantas originais, peças separadas e retratos sincronizados.');
