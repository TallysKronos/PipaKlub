import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const folder=fileURLToPath(new URL('./refined-rig-v3/',import.meta.url)),slices=JSON.parse(fs.readFileSync(folder+'slices.json'));
const scale=.25;
const project={schema:'soulgen-studio',version:1,name:'Dóber de papel · recorte refinado',creatureId:'doberman-c',artRevision:3,rigRevision:4,preserveSourceAspect:true,width:slices.sourceSize[0]*scale,height:slices.sourceSize[1]*scale,rootPivot:[217.25,160],brief:{species:'Dóber de papel (nome provisório)',view:'Três quartos para a direita',reference:'art/soulgen/keys/doberman-c/refined-rig-v3/source.png',kiteAnatomy:'Imagem enviada pelo autor, recortada sem redesenho. Duas orelhas na cabeça; quatro patas; duas velas da rabiola; peito e tirantes no tronco.',notes:'Reconstrução de RGBA visível exata. Não há preenchimento inventado de áreas ocultas. Movimentos locais contidos; montagem com Kael preservada.'},assets:{},parts:[],clips:{}};
for(const [id,p]of Object.entries(slices.parts)){const [x,y,w,h]=p.crop;project.assets[id]={name:p.name,src:'/art/soulgen/keys/doberman-c/refined-rig-v3/'+id+'.png',width:w,height:h};project.parts.push({id,name:p.name,asset:id,source:[0,0,w,h],rect:[x*scale,y*scale,w*scale,h*scale],pivot:p.pivot.map(n=>n*scale),z:p.z,parent:id==='body'?null:'body',visible:true,lag:id==='tail'?.05:0});}
const registration=JSON.parse(fs.readFileSync(folder+'registration.json'));
const head=project.parts.find(p=>p.id==='head');head.faceWindows=registration.windows;head.faces={};
for(const face of ['fierce','happy','hurt']){const a=project.assets.head;project.assets[face]={name:face,src:'/art/soulgen/keys/doberman-c/refined-rig-v3/head-'+face+'.png',width:a.width,height:a.height};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
const body=project.parts.find(p=>p.id==='body');project.anatomy={version:1,ratios:[],behind:[],joints:project.parts.filter(p=>p.parent).map(p=>({part:p.id,parent:'body',anchor:[(p.pivot[0]-p.rect[0])/p.rect[2],(p.pivot[1]-p.rect[1])/p.rect[3]],socket:[(p.pivot[0]-body.rect[0])/body.rect[2],(p.pivot[1]-body.rect[1])/body.rect[3]],maxGap:.05}))};
const frame=(t,changes={},ease='smooth')=>({t,ease,values:Object.fromEntries(['root',...project.parts.map(p=>p.id)].map(id=>[id,{...identity(),...changes[id]}]))});
function cycle(id,label,seconds,fn){const frames=Array.from({length:13},(_,i)=>frame(i*seconds/12,fn(Math.PI*2*i/12),'spline'));frames.at(-1).values=structuredClone(frames[0].values);project.clips[id]={label,seconds,loop:true,frames,expressions:[]};}
cycle('idle','Vigília de papel',2.4,t=>({root:{y:-.45*Math.sin(t)},head:{rotation:.35*Math.sin(t)},tailNear:{rotation:2*Math.sin(t)}}));
cycle('flight','Na corrente do vento',1.2,t=>({root:{y:-2+1.1*Math.sin(t)},head:{rotation:.55*Math.sin(t)},frontNear:{rotation:1.5*Math.sin(t)},frontFar:{rotation:-1.5*Math.sin(t)},hindNear:{rotation:-1.2*Math.sin(t)},hindFar:{rotation:1.2*Math.sin(t)},tailNear:{rotation:3*Math.sin(t)}}));
project.clips.skill={label:'Bote de estalactite',seconds:1.4,loop:false,hitTime:.55,frames:[frame(0),frame(.25,{root:{x:-5,y:2,rotation:-1},head:{rotation:1.5},tailNear:{rotation:-3}}),frame(.4,{root:{x:-6,y:2,rotation:-1}}),frame(.55,{root:{x:10,y:-3,rotation:1},head:{rotation:-1.5},frontNear:{rotation:-2},frontFar:{rotation:-1.5},hindNear:{rotation:1},tailNear:{rotation:4}}),frame(.8,{root:{x:4,y:-1},tailNear:{rotation:2}}),frame(1.15),frame(1.4)],expressions:[]};
project.clips.hurt={label:'Recuo da armação',seconds:.7,loop:false,frames:[frame(0),frame(.12,{root:{x:-6,rotation:-2},head:{rotation:1.5},tailNear:{rotation:-4}}),frame(.3,{root:{x:-2,rotation:1},head:{rotation:-.5},tailNear:{rotation:2}}),frame(.52),frame(.7)],expressions:[]};
project.clips.victory={label:'Velas erguidas',seconds:2,loop:false,frames:[frame(0),frame(.3,{head:{rotation:1.5},tailNear:{rotation:-4}}),frame(.65,{root:{y:-3},head:{rotation:-1.5},frontNear:{rotation:-1},tailNear:{rotation:5}}),frame(1.1,{root:{y:-1},head:{rotation:-.6},tailNear:{rotation:-4}}),frame(1.55,{tailNear:{rotation:3}}),frame(2)],expressions:[]};
const down={root:{y:5,rotation:-3},head:{rotation:2},frontNear:{rotation:-2},frontFar:{rotation:-1.5},tailNear:{rotation:-6}};
project.clips.defeat={label:'Armação abatida',seconds:.9,loop:false,frames:[frame(0),frame(.25,{root:{y:2,rotation:-1},head:{rotation:1}}),frame(.6,down),frame(.9,down)],expressions:[]};
project.clips.skill.expressions=[{start:.18,end:1.15,face:'fierce'}];
project.clips.hurt.expressions=[{start:.01,end:.52,face:'hurt'}];
project.clips.victory.expressions=[{start:.15,end:1.75,face:'happy'}];
project.clips.defeat.expressions=[{start:.15,end:.9,face:'hurt'}];
project.brief.notes='Sete peças refinadas; rabiola completa com fios e duas folhas. Expressões registradas: ataque, vitória e dano. Montagem com Kael preservada.';
await exportReview(project,folder,{registration});
