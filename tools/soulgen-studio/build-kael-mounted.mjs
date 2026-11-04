import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {validate} from './model.mjs';
import {decodePNG} from '../pixelgen/png.mjs';
const folder=new URL('../../art/soulgen/keys/kael-mounted-rig-v1/',import.meta.url);
const png=await fs.readFile(new URL('parts.png',folder)),image=decodePNG(png);
const project={schema:'soulgen-studio',version:1,name:'Kael montado · rig SE',width:384,height:512,rootPivot:[200,325],creatureId:'kael-mounted',artRevision:1,direction:'se',assets:{atlas:{src:'data:image/png;base64,'+png.toString('base64'),width:image.width,height:image.height,name:'Kael · peças SE'}},parts:[],clips:{idle:{label:'Respiração · montado',seconds:2,loop:true,frames:[{t:0,values:{}},{t:1,ease:'smooth',values:{torso:{rotation:-.5},head:{rotation:.5},'coat-near':{rotation:2}}},{t:2,values:{}}]}}};
function piece(id,name,source,scale,pivot,localPivot,parent,z,rotation=0){project.parts.push({id,name,asset:'atlas',source,rect:[pivot[0]-localPivot[0]*scale,pivot[1]-localPivot[1]*scale,source[2]*scale,source[3]*scale],pivot,parent,z,visible:true,artTransform:{rotation,scale:1,flipX:false,flipY:false}});}
function limb(id,name,source,start,end,pivot,target,parent,z){const a=Math.atan2(end[1]-start[1],end[0]-start[0]),b=Math.atan2(target[1]-pivot[1],target[0]-pivot[0]),scale=Math.hypot(target[0]-pivot[0],target[1]-pivot[1])/Math.hypot(end[0]-start[0],end[1]-start[1]);piece(id,name,source,scale,pivot,start,parent,z,(b-a)*180/Math.PI);}
piece('pelvis','Quadril · assento',[697,213,248,141],.4,[200,325],[120,84],null,5);
piece('torso','Tronco',[374,127,234,236],.56,[200,300],[116,211],'pelvis',6);
piece('head','Cabeça · pescoço',[59,27,250,325],.43,[201,196],[118,310],'torso',10);
limb('upper-near','Braço próximo',[148,404,150,212],[48,22],[128,191],[154,205],[155,260],'torso',5);
limb('fore-near','Antebraço próximo',[505,515,128,110],[25,25],[99,74],[155,260],[185,282],'upper-near',8);
limb('hand-near','Mão próxima',[772,497,120,100],[14,30],[100,80],[185,282],[215,298],'fore-near',9);
limb('upper-far','Braço distante',[101,652,154,212],[116,23],[27,183],[250,209],[270,260],'torso',5);
limb('fore-far','Antebraço distante',[396,775,146,95],[121,21],[23,62],[270,260],[280,284],'upper-far',8);
limb('hand-far','Mão distante',[762,738,116,103],[91,19],[16,82],[280,284],[300,300],'fore-far',9);
limb('thigh-near','Coxa próxima',[66,909,230,177],[33,41],[203,141],[178,315],[148,371],'pelvis',4);
limb('shin-near','Canela e bota próximas',[430,1020,145,194],[90,8],[65,170],[148,371],[142,437],'thigh-near',3);
limb('thigh-far','Coxa distante',[687,907,186,120],[162,33],[56,88],[228,316],[263,357],'pelvis',-12);
limb('shin-far','Canela e bota distantes',[1080,985,110,223],[60,15],[53,180],[263,357],[269,420],'thigh-far',-11);
limb('coat-near','Cauda próxima do casaco',[1030,385,175,248],[29,22],[148,220],[168,285],[105,400],'torso',2);
limb('coat-far','Cauda distante do casaco',[1039,101,170,272],[23,21],[141,240],[255,280],[300,400],'torso',2);
const result=validate(project);if(!result.ok)throw Error(result.errors.join('\n'));
await fs.writeFile(new URL('kael-mounted.soulgen.json',folder),JSON.stringify(project));
const runtime=new URL('../../godot/assets/mounts/kael-mounted-rig-v1/',import.meta.url);await fs.mkdir(runtime,{recursive:true});await fs.writeFile(new URL('project.json',runtime),JSON.stringify(project));
console.log('Kael: '+project.parts.length+' peças; '+image.width+'×'+image.height+'; '+fileURLToPath(new URL('kael-mounted.soulgen.json',folder)));
