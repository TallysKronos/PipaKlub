import fs from 'node:fs/promises';
import {createRequire} from 'node:module';
import {validate,identity} from '../tools/soulgen-studio/model.mjs';
import {project as previous} from '../art/soulgen/keys/kael/rig-data.mjs';
import {setKaelDirection} from '../tools/soulgen-studio/kael.mjs';
const require=createRequire(import.meta.url);let sharp;try{sharp=require('sharp');}catch{sharp=require('C:/Users/user/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');}
const dir='art/soulgen/keys/kael-v2';await fs.mkdir(dir+'/parts',{recursive:true});
const crops={
 south:{head:[50,45,345,320],spiky:[395,15,440,345],blue:[840,100,370,260],blueRight:[1280,70,175,290],blueLeft:[120,380,170,280],legRight:[510,380,235,295],legLeft:[845,380,240,295],backpack:[1200,400,310,280],curly:[25,675,410,300],clay:[490,690,390,275],clayLeft:[975,695,165,270],clayRight:[1280,695,165,270]},
 east:{head:[75,65,270,285],spiky:[410,65,365,285],blue:[865,105,245,250],blueRight:[1260,95,165,280],blueLeft:[130,390,170,270],legRight:[530,405,225,260],legLeft:[870,405,220,260],backpack:[1210,400,270,260],curly:[40,680,360,300],clay:[510,680,270,280],clayLeft:[940,690,170,275],clayRight:[1300,690,165,275]},
 north:{head:[55,45,335,310],spiky:[415,25,420,345],blue:[860,95,320,270],blueRight:[1290,80,165,290],blueLeft:[120,385,170,285],legRight:[535,385,180,290],legLeft:[895,385,180,290],backpack:[1195,405,310,275],curly:[30,695,405,305],clay:[480,685,340,290],clayLeft:[935,690,165,290],clayRight:[1285,690,160,290]}
};
const skins={mel:null,claro:[255,218,177],castanho:[173,109,70],escuro:[106,62,43]},colors={navy:[31,45,83],brown:[90,48,29],black:[25,25,34],copper:[153,65,30]};
const rects={
 south:{head:[166,108,180,176],hair:[143,43,226,170],body:[186,258,140,120],armLeft:[174,269,54,125],armRight:[284,269,54,125],legLeft:[200,354,56,88],legRight:[256,354,56,88],backpack:[201,266,110,105]},
 east:{head:[184,100,170,176],hair:[165,40,200,170],body:[210,258,122,120],armLeft:[228,264,54,112],armRight:[228,264,54,112],legLeft:[234,354,62,88],legRight:[234,354,62,88],backpack:[179,271,94,100]},
 north:{head:[166,108,180,176],hair:[143,35,226,230],body:[186,258,140,120],armLeft:[174,269,54,125],armRight:[284,269,54,125],legLeft:[200,354,56,88],legRight:[256,354,56,88],backpack:[204,279,104,98]}
};
const pivots={south:{body:[256,360],head:[256,261],hair:[256,150],armLeft:[201,286],armRight:[311,286],legLeft:[228,360],legRight:[284,360],backpack:[256,290]},east:{body:[267,360],head:[266,261],hair:[260,150],armLeft:[255,281],armRight:[255,281],legLeft:[263,360],legRight:[265,360],backpack:[224,290]},north:{body:[256,360],head:[256,261],hair:[256,150],armLeft:[201,286],armRight:[311,286],legLeft:[228,360],legRight:[284,360],backpack:[256,290]}};
const base={};
for(const view of ['south','east','north']){base[view]={};for(const [id,[left,top,width,height]]of Object.entries(crops[view])){const cut=await sharp(dir+'/source/'+(view==='south'?'front':view)+'.png').extract({left,top,width,height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});for(let i=3;i<cut.data.length;i+=4)if(cut.data[i]<64)cut.data[i]=0;const normalized=await sharp(cut.data,{raw:cut.info}).png().toBuffer();base[view][id]=await sharp(normalized).trim({threshold:4}).png().toBuffer();}}
// Repainted cloth underlays remove the circular shoulder sockets exposed by gestures.
const torsoCrops={south:{blue:[35,75,495,420],clay:[35,540,495,420]},east:{blue:[605,65,365,435],clay:[600,540,370,425]},north:{blue:[1000,75,515,420],clay:[1010,540,510,410]}};
for(const view of ['south','east','north'])for(const outfit of ['blue','clay']){const [left,top,width,height]=torsoCrops[view][outfit],cut=await sharp(dir+'/source/torsos.png').extract({left,top,width,height}).ensureAlpha().raw().toBuffer({resolveWithObject:true});for(let i=3;i<cut.data.length;i+=4)if(cut.data[i]<64)cut.data[i]=0;const image=await sharp(cut.data,{raw:cut.info}).png().toBuffer();base[view][outfit]=await sharp(image).trim({threshold:4}).png().toBuffer();}
// Profiles share the strap-free limb painting. The torso supplies backpack straps.
for(const outfit of ['blue','clay'])for(const side of ['Left','Right'])base.east[outfit+side]=base.south[outfit+side];
const assets={},slots={},alphaMasks={},regions={};
async function recolor(input,slot,skin,hair,cut,view){
 const {data,info}=await sharp(input).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 for(let i=0;i<data.length;i+=4){if(!data[i+3])continue;const [r,g,b]=data.subarray(i,i+3),x=(i/4%info.width)/info.width,y=Math.floor(i/4/info.width)/info.height;
  const region=slot==='head'||slot.startsWith('arm')&&y>.48||slot.startsWith('leg')&&y>.43&&y<.62||slot==='body'&&y<.2&&x>.3&&x<.7;
  const eye=slot==='head'&&view!=='north'&&r<160&&y>.4&&y<.72;
  if(skin&&region&&!eye&&r>80&&r>g*1.08&&g>b*1.12&&r-g>15){const light=(r+g+b)/562;for(let c=0;c<3;c++)data[i+c]=Math.min(255,Math.round(skin[c]*light));}
  if(hair){const light=(r+g+b)/3;if(light>16){const k=light/(cut==='curly'?64:49);for(let c=0;c<3;c++)data[i+c]=Math.min(255,Math.round(hair[c]*k));}}
 }
 return sharp(data,{raw:info}).png().toBuffer();
}
async function writeTexture(id,slot,key,{skin=null,hair=null,cut=null}={}){
 const tiles=[];
 for(const view of ['south','west','east','north']){
  const v=view==='west'?'east':view,im=await recolor(base[v][key],slot,skin,hair,cut,v),[x,y,w,h]=rects[v][slot];
  const resized=await sharp(im).resize({width:Math.round(w*.625),height:Math.round(h*.625),fit:slot==='hair'&&v==='north'?'fill':'contain',position:'top',background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
  let frame=await sharp({create:{width:320,height:320,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite([{input:resized,left:Math.round(x*.625),top:Math.round(y*.625)}]).png().toBuffer();
  if(view==='west')frame=await sharp(frame).flop().png().toBuffer();tiles.push(frame);
 }
 const output=await sharp({create:{width:1280,height:320,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(tiles.map((input,i)=>({input,left:i*320,top:0}))).png().toBuffer();
 await fs.writeFile(dir+'/parts/'+id+'.png',output);assets[id]={name:id,src:'/art/soulgen/keys/kael-v2/parts/'+id+'.png',width:1280,height:320};slots[id]=slot;
 const alpha=await sharp(output).extractChannel(3).raw().toBuffer();
 for(const [index,view]of ['south','west','east','north'].entries()){
  let x0=320,y0=320,x1=-1,y1=-1;for(let y=0;y<320;y++)for(let x=0;x<320;x++)if(alpha[y*1280+index*320+x]>0){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y);}
  if(x1<0)throw Error('Peça vazia: '+id+'/'+view);regions[slot]??={};const old=regions[slot][view];regions[slot][view]=old?[Math.min(x0,old[0]),Math.min(y0,old[1]),Math.max(x1,old[2]),Math.max(y1,old[3])]:[x0,y0,x1,y1];
 }
 const shapeKey=slot+'-'+(slot==='hair'?cut:slot==='body'||slot.startsWith('arm')?key:'base');
 if(alphaMasks[shapeKey]&&!alpha.equals(alphaMasks[shapeKey]))throw Error('A paleta mudou a silhueta: '+id);alphaMasks[shapeKey]=alpha;
}
for(const [skin,rgb]of Object.entries(skins)){
 await writeTexture('head-'+skin,'head','head',{skin:rgb});
 for(const side of ['Left','Right'])await writeTexture('leg-'+side.toLowerCase()+'-'+skin,'leg'+side,'leg'+side,{skin:rgb});
 for(const outfit of ['blue','clay']){await writeTexture('body-'+outfit+'-'+skin,'body',outfit,{skin:rgb});for(const side of ['Left','Right'])await writeTexture('arm-'+side.toLowerCase()+'-'+outfit+'-'+skin,'arm'+side,outfit+side,{skin:rgb});}
}
for(const cut of ['spiky','curly'])for(const [color,rgb]of Object.entries(colors))await writeTexture('hair-'+cut+'-'+color,'hair',cut,{hair:color==='navy'&&cut==='spiky'?null:rgb,cut});
await writeTexture('backpack','backpack','backpack');
const parents={body:null,head:'body',hair:'head',armLeft:'body',armRight:'body',legLeft:null,legRight:null,backpack:'body'};
const z={south:{backpack:0,legLeft:1,legRight:2,body:3,armLeft:4,armRight:5,head:6,hair:7},east:{armLeft:0,legLeft:1,backpack:2,body:3,legRight:4,armRight:5,head:6,hair:7},north:{legLeft:0,legRight:1,body:2,armLeft:3,armRight:4,backpack:5,head:6,hair:7}};
const views={};for(const [index,view]of ['south','west','east','north'].entries()){const v=view==='west'?'east':view;views[view]=Object.fromEntries(Object.keys(parents).map(id=>{const [x0,y0,x1,y1]=regions[id][view],w=x1-x0+1,h=y1-y0+1;return [id,{pivot:[view==='west'?512-pivots[v][id][0]:pivots[v][id][0],pivots[v][id][1]],z:z[v][id],parent:parents[id],source:[index*320+x0,y0,w,h],rect:[x0*1.6,y0*1.6,w*1.6,h*1.6]}];}));}
const project=structuredClone(previous);project.name='Kael · Avatar modular · revisão 2';project.width=512;project.height=512;project.rootPivot=[256,442];project.assets=assets;project.avatar={kind:'kael-modular-v1',revision:2,view:'south',directions:['south','west','east','north'],cell:320,views,appearance:{skin:'mel',hair:'spiky',hairColor:'navy',outfit:'blue'}};
for(const p of project.parts)Object.assign(p,views.south[p.id]);
setKaelDirection(project,'south');
// Keep shoulders under cloth at action extremes. Whole-arm gestures need an elbow rig.
const key=(t,values)=>({t,ease:'smooth',values:Object.fromEntries(Object.entries(values).map(([id,v])=>[id,{...identity(),...v}]))});
project.clips.wave.frames=[key(0,{}),key(.4,{armRight:{rotation:-38},head:{rotation:-2}}),key(.7,{armRight:{rotation:-48}}),key(1,{armRight:{rotation:-34}}),key(1.3,{armRight:{rotation:-48}}),key(1.65,{armRight:{rotation:-34}}),key(2.4,{})];
project.clips.victory.frames=[key(0,{}),key(.4,{root:{y:-6},armLeft:{rotation:25},armRight:{rotation:-25}}),key(.7,{root:{y:-10},armLeft:{rotation:32},armRight:{rotation:-32}}),key(1.2,{root:{y:-3},armLeft:{rotation:22},armRight:{rotation:-22}}),key(2,{})];
project.clips.walk.label='Caminhar';project.clips.run.label='Correr';
const report=validate(project);if(!report.ok)throw Error(report.errors.join('\n'));
await fs.writeFile(dir+'/rig-data.mjs','export const project='+JSON.stringify(project,null,2)+';\n');
const portable=structuredClone(project);for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+(await fs.readFile(a.src.slice(1))).toString('base64');
await fs.writeFile(dir+'/kael-v2.soulgen.json',JSON.stringify(portable));await fs.writeFile(dir+'/manifest.json',JSON.stringify({revision:2,cell:320,directions:project.avatar.directions,sourceCrops:crops,bindArtRects:rects,assetSlots:slots,paletteAlphaInvariant:true,validation:report},null,2));
console.log('Kael v2: quatro direções,',Object.keys(assets).length,'atlases.',report);
