import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {validate,identity} from '../tools/soulgen-studio/model.mjs';
const require=createRequire(import.meta.url);
let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const dir='art/soulgen/keys/kael',partsDir=dir+'/parts';await fs.mkdir(partsDir,{recursive:true});
const source=dir+'/source/parts-generated.png';
const crops={head:[65,65,340,310],spiky:[420,40,420,325],blue:[845,110,310,270],blueRight:[1270,85,190,295],blueLeft:[125,400,180,280],legRight:[525,400,220,285],legLeft:[840,400,230,285],backpack:[1190,425,310,260],curly:[35,675,400,310],clay:[505,705,330,275],clayLeft:[935,705,165,280],clayRight:[1260,705,165,280]};
const skins={mel:null,claro:[255,218,177],castanho:[173,109,70],escuro:[106,62,43]},colors={navy:null,brown:[90,48,29],black:[25,25,34],copper:[153,65,30]};
const assets={},checks=[];
async function crop(id){const [left,top,width,height]=crops[id];const cut=await sharp(source).extract({left,top,width,height}).png().toBuffer();return sharp(cut).trim({threshold:4}).png().toBuffer();}
const base={};for(const id of Object.keys(crops))base[id]=await crop(id);
async function texture(id,input,{skin=null,hair=null}={}){
 const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true}),alpha=Buffer.alloc(info.width*info.height);
 for(let i=0;i<data.length;i+=4){alpha[i/4]=data[i+3];if(!data[i+3])continue;const [r,g,b]=data.subarray(i,i+3),px=(i/4%info.width)/info.width,py=Math.floor(i/4/info.width)/info.height;
  const skinRegion=id.startsWith("head-")||id.startsWith("arm-")&&py>.48||id.startsWith("leg-")&&py>.45&&py<.62||id.startsWith("body-")&&py<.2&&px>.3&&px<.7;
  const eyeWindow=r<160&&id.startsWith("head-")&&py>.43&&py<.71&&(px>.16&&px<.43||px>.58&&px<.85);
  if(skin&&skinRegion&&!eyeWindow&&r>80&&r>g*1.08&&g>b*1.12&&r-g>15){const light=(r+g+b)/(252+186+124);for(let c=0;c<3;c++)data[i+c]=Math.min(255,Math.round(skin[c]*light));}
  if(hair){const light=(r+g+b)/3;if(light>16){const k=light/(id.includes("curly")?64:49);for(let c=0;c<3;c++)data[i+c]=Math.min(255,Math.round(hair[c]*k));}}
 }
 for(let i=0;i<alpha.length;i++)if(alpha[i]!==data[i*4+3])throw Error('Alpha alterado: '+id);
 const file=partsDir+'/'+id+'.png';await sharp(data,{raw:info}).png().toFile(file);
 assets[id]={name:id,src:'/art/soulgen/keys/kael/parts/'+id+'.png',width:info.width,height:info.height};checks.push({id,width:info.width,height:info.height,alphaPreserved:true});
}
for(const [skin,rgb]of Object.entries(skins)){
 await texture('head-'+skin,base.head,{skin:rgb});
 for(const side of ['Left','Right'])await texture('leg-'+side.toLowerCase()+'-'+skin,base['leg'+side],{skin:rgb});
 for(const outfit of ['blue','clay']){
  await texture('body-'+outfit+'-'+skin,base[outfit],{skin:rgb});
  for(const side of ['Left','Right'])await texture('arm-'+side.toLowerCase()+'-'+outfit+'-'+skin,base[outfit+side],{skin:rgb});
 }
}
for(const cut of ['spiky','curly'])for(const [color,rgb]of Object.entries(colors))await texture('hair-'+cut+'-'+color,base[cut],{hair:rgb||(cut==='curly'?[31,45,83]:null)});
await texture('backpack',base.backpack);
const p=(id,name,asset,rect,pivot,z,parent=null)=>({id,name,asset,source:[0,0,assets[asset].width,assets[asset].height],rect,pivot,z,parent,visible:true});
const parts=[
 p('backpack','Mochila','backpack',[194,271,124,119],[256,281],0,'body'),
 p('legLeft','Perna esquerda','leg-left-mel',[203,362,56,126],[232,371],1),
 p('legRight','Perna direita','leg-right-mel',[255,362,56,126],[280,371],2),
 p('armLeft','Braço esquerdo','arm-left-blue-mel',[168,264,53,126],[199,280],3,'body'),
 p('armRight','Braço direito','arm-right-blue-mel',[291,264,53,126],[313,280],4,'body'),
 p('body','Tronco e roupa','body-blue-mel',[195,256,122,126],[256,368],5),
 p('head','Cabeça e pele','head-mel',[166,102,180,176],[256,269],6,'body'),
 p('hair','Cabelo','hair-spiky-navy',[143,34,226,170],[256,152],7,'head')
];
const key=(t,values,ease='smooth')=>({t,ease,values:Object.fromEntries(Object.entries(values).map(([id,v])=>[id,{...identity(),...v}]))});
const cycle=(seconds,pose)=>({seconds,loop:true,expressions:[],frames:Array.from({length:17},(_,i)=>key(seconds*i/16,pose(i===16?0:i/16*Math.PI*2),'spline'))});
const stride=(a,run=false)=>({root:{y:-(run?3.2:1.4)*(1-Math.cos(a*2))},body:{rotation:(run?1.3:.65)*Math.sin(a)},head:{rotation:-.6*Math.sin(a)},armLeft:{rotation:(run?18:10)*Math.sin(a)},armRight:{rotation:-(run?18:10)*Math.sin(a)},legLeft:{y:(run?6:3)*Math.sin(a),rotation:(run?10:5)*Math.sin(a)},legRight:{y:-(run?6:3)*Math.sin(a),rotation:-(run?10:5)*Math.sin(a)}});
const clips={
 idle:{label:'Repouso',...cycle(3.2,a=>({body:{y:-1.2*Math.sin(a)},head:{rotation:.45*Math.sin(a)},armLeft:{rotation:.7*Math.sin(a)},armRight:{rotation:-.7*Math.sin(a)}}))},
 walk:{label:'Caminhar · frontal',...cycle(.72,a=>stride(a))},
 run:{label:'Correr · frontal',...cycle(.48,a=>stride(a,true))},
 wave:{label:'Acenar',seconds:2.4,loop:false,expressions:[],frames:[key(0,{}),key(.4,{armRight:{rotation:-112},head:{rotation:-3}}),key(.7,{armRight:{rotation:-128}}),key(1,{armRight:{rotation:-108}}),key(1.3,{armRight:{rotation:-128}}),key(1.65,{armRight:{rotation:-108}}),key(2.4,{})]},
 hurt:{label:'Recuo',seconds:.8,loop:false,expressions:[],frames:[key(0,{}),key(.14,{root:{x:5,rotation:3},head:{rotation:4}}),key(.38,{root:{x:2,rotation:1}}),key(.8,{})]},
 victory:{label:'Comemorar',seconds:2,loop:false,expressions:[],frames:[key(0,{}),key(.4,{root:{y:-8},armLeft:{rotation:120},armRight:{rotation:-120}}),key(.7,{root:{y:-12},armLeft:{rotation:125},armRight:{rotation:-125}}),key(1.2,{root:{y:-4},armLeft:{rotation:110},armRight:{rotation:-110}}),key(2,{})]}
};
const project={schema:'soulgen-studio',version:1,name:'Kael · Avatar modular',width:512,height:560,rootPivot:[256,488],assets,parts,clips,avatar:{kind:'kael-modular-v1',view:'front',appearance:{skin:'mel',hair:'spiky',hairColor:'navy',outfit:'blue'}}};
project.anatomy={version:1,ratios:[{part:'head',relativeTo:'body',min:1.4,max:1.55,label:'Cabeça chibi / tronco'}],behind:[{part:'backpack',other:'body'},{part:'body',other:'head'},{part:'head',other:'hair'}],joints:['armLeft','armRight','head','hair'].map(id=>{const p=parts.find(p=>p.id===id),parent=parts.find(q=>q.id===p.parent),[x,y]=p.pivot;return {part:id,parent:parent.id,anchor:[(x-p.rect[0])/p.rect[2],(y-p.rect[1])/p.rect[3]],socket:[(x-parent.rect[0])/parent.rect[2],(y-parent.rect[1])/parent.rect[3]],maxGap:.01};})};
const report=validate(project);if(!report.ok)throw Error(report.errors.join('\n'));
await fs.writeFile(dir+'/rig-data.mjs','// Generated by scripts/build-kael-avatar.mjs\nexport const project='+JSON.stringify(project,null,2)+';\n');
const portable=structuredClone(project);for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+(await fs.readFile(a.src.slice(1))).toString('base64');
await fs.writeFile(dir+'/kael.soulgen.json',JSON.stringify(portable));await fs.writeFile(dir+'/asset-report.json',JSON.stringify({generator:'builtin imagegen + deterministic crop and palette mapping',source,crops,images:checks,validation:report},null,2));
console.log('Kael:',parts.length,'peças,',Object.keys(assets).length,'texturas,',Object.keys(clips).length,'ações.',report);
