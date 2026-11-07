import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity} from '../../../../tools/soulgen-studio/model.mjs';
import {exportReview} from '../../../../tools/soulgen-studio/export-review.mjs';
const configs=JSON.parse(fs.readFileSync(new URL('./family-config.json',import.meta.url)));
// Anchors belong to the unscaled cutout; pivots belong to the common stage.
const layouts={
 'lince-de-cerco':{
 body:[1,160,105,470,330,3],head:[.57,155,292,385,315,8],
 frontNear:[.62,153,31,455,332,5],frontFar:[.60,115,30,403,321,1],
 rearNear:[.64,66,47,637,337,5],rearFar:[.62,50,42,595,324,0],
 tail:[.58,145,29,643,302,2],bowNear:[.75,65,272,503,261,6],bowFar:[.72,54,235,551,248,2]},
 'lince-de-cerco-young':{
 body:[1,145,70,470,332,3],head:[.54,160,278,349,327,8],
 frontNear:[.60,115,31,462,331,5],frontFar:[.59,87,27,419,325,1],
 rearNear:[.61,57,40,625,337,5],rearFar:[.60,46,39,592,327,0],
 tail:[.54,139,24,640,302,2],yoke:[.85,180,148,494,284,6]},
 'lince-de-cerco-child':{
 body:[.92,145,80,476,340,3],head:[.59,155,275,357,337,8],
 frontNear:[.52,108,26,459,340,5],frontFar:[.51,76,25,421,330,1],
 rearNear:[.53,48,34,609,343,5],rearFar:[.53,41,33,579,333,0],
 tail:[.50,128,22,624,315,2],bowNear:[.54,32,181,492,286,6],bowFar:[.52,29,175,535,283,2]},
 'lince-de-cerco-baby':{
 body:[.82,188,190,484,302,4],flapNear:[.60,157,83,354,314,3],
 flapFar:[.60,34,83,614,314,2],tail:[.45,123,25,484,444,1],knot:[.25,74,71,484,442,5]}
};
for(const cfg of configs){
 const id=cfg.id,dir=fileURLToPath(new URL(`../${id}/cutout-rig-v1/`,import.meta.url));
 if(fs.existsSync(dir+'author-import.json'))throw Error(`Preserve author edits: ${id}`);
 const slices=JSON.parse(fs.readFileSync(dir+'slices.json')),reg=JSON.parse(fs.readFileSync(dir+'registration.json'));
 const p={schema:'soulgen-studio',version:1,name:cfg.label,creatureId:id,artRevision:1,rigRevision:1,preserveSourceAspect:true,width:1000,height:720,rootPivot:[485,340],assets:{},parts:[],clips:{},brief:{view:'Três quartos à esquerda',notes:'Conversão da família Lince de Cerco para revisão no Soulgen. Sem integração ao jogo. Bebê flutuante; demais formas quadrúpedes.'}};
 for(const [part,l]of Object.entries(layouts[id])){
  const [s,ax,ay,x,y,z]=l,b=slices.boxes[part],w=b[2]-b[0],h=b[3]-b[1];
  p.assets[part]={name:part,src:`/art/soulgen/keys/${id}/cutout-rig-v1/${part}.png`,width:w,height:h};
  p.parts.push({id:part,name:part,asset:part,source:[0,0,w,h],rect:[x-ax*s,y-ay*s,w*s,h*s],pivot:[x,y],z,parent:part==='body'?null:'body',visible:true,lag:0});
 }
 const head=p.parts.find(x=>x.id===reg.headPart);head.faces={};head.faceWindows=reg.windows;
 for(const face of ['fierce','hurt','happy']){const a=p.assets[reg.headPart];p.assets[face]={...a,name:face,src:`/art/soulgen/keys/${id}/cutout-rig-v1/head-${face}.png`};head.faces[face]={asset:face,source:[0,0,a.width,a.height]};}
 const body=p.parts[0];p.anatomy={version:1,ratios:[],behind:p.parts.filter(x=>x.z<3).map(x=>({part:x.id,other:'body'})),joints:p.parts.filter(x=>x.parent).map(x=>({part:x.id,parent:'body',anchor:[(x.pivot[0]-x.rect[0])/x.rect[2],(x.pivot[1]-x.rect[1])/x.rect[3]],socket:[(x.pivot[0]-body.rect[0])/body.rect[2],(x.pivot[1]-body.rect[1])/body.rect[3]],maxGap:2}))};
 const frame=(t,c={})=>({t,ease:'smooth',values:Object.fromEntries(['root',...p.parts.map(x=>x.id)].map(k=>[k,{...identity(),...c[k]}]))});
 const baby=id.endsWith('baby');
 function cycle(k,label,seconds,fn){const frames=Array.from({length:17},(_,i)=>frame(seconds*i/16,fn(2*Math.PI*i/16)));frames.at(-1).values=structuredClone(frames[0].values);p.clips[k]={label,seconds,loop:true,frames,expressions:[]};}
 cycle('idle',baby?'Flutuação curiosa':'Respiração vigilante',2.8,t=>baby?{root:{y:3*Math.sin(t)},flapNear:{rotation:2*Math.sin(t)},flapFar:{rotation:-2*Math.sin(t)},tail:{rotation:3*Math.sin(t)}}:{head:{rotation:.5*Math.sin(t)},tail:{rotation:2*Math.sin(t)},bowNear:{rotation:.5*Math.sin(t)},yoke:{rotation:.5*Math.sin(t)}});
 cycle('flight',baby?'Deslizar':'Passo de patrulha',1.15,t=>baby?{root:{y:4*Math.sin(t),rotation:1.5*Math.sin(t)},flapNear:{rotation:6*Math.sin(t)},flapFar:{rotation:-6*Math.sin(t)},tail:{rotation:6*Math.sin(t)}}:{root:{y:1.3*Math.sin(2*t)},frontNear:{rotation:4*Math.sin(t)},frontFar:{rotation:-4*Math.sin(t)},rearNear:{rotation:-4*Math.sin(t)},rearFar:{rotation:4*Math.sin(t)},head:{rotation:.5*Math.sin(2*t)},tail:{rotation:3*Math.sin(t)}});
 function action(k,label,seconds,hit,keys,face){p.clips[k]={label,seconds,loop:false,...(hit?{hitTime:hit}:{}),frames:keys.map(([t,v])=>frame(t,v)),expressions:[{start:.04,end:seconds-.04,face}]};}
 action('skill',baby?'Ímpeto':'Investida de cerco',1.5,.55,[[0,{}],[.25,{root:{x:7,y:2},head:{rotation:-2}}],[.55,{root:{x:-19,y:-2},head:{rotation:2},frontNear:{rotation:6},bowNear:{rotation:-2},yoke:{rotation:-2}}],[1.0,{root:{x:-5}}],[1.5,{}]],'fierce');
 action('hurt','Dano',.8,null,[[0,{}],[.12,{root:{x:8,rotation:1},head:{rotation:-2}}],[.4,{root:{x:3}}],[.8,{}]],'hurt');
 action('victory','Vitória',2,null,[[0,{}],[.5,{head:{rotation:-2},tail:{rotation:5},flapNear:{rotation:-5},flapFar:{rotation:5}}],[1.15,{root:{y:-2},tail:{rotation:-3}}],[2,{}]],'happy');
 action('defeat','Derrota',1.2,null,[[0,{}],[.5,{root:{y:5},head:{rotation:3}}],[1.2,{root:{y:7},head:{rotation:4},tail:{rotation:4}}]],'hurt');
 // Keep channels restricted to actual pieces, including the legless baby.
 for(const clip of Object.values(p.clips))for(const f of clip.frames)for(const k of Object.keys(f.values))if(k!=='root'&&!p.parts.some(x=>x.id===k))delete f.values[k];
 await exportReview(p,dir,{registration:reg});console.log(id+' exported');
}
