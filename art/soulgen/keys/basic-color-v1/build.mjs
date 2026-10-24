import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {identity,validate} from '../../../../tools/soulgen-studio/model.mjs';
const root=new URL('../',import.meta.url);
const specs={
 'mata-verde':{name:'Mata verde',personality:'Brincalhona e esquiva',anatomy:'Vela-folha, nervuras de vareta, asas de folha e rabiola de cipó',body:[50,30,60,55],wingNear:[13,43,51,27],wingFar:[100,43,51,27],tail:[75,81,36,43],pivots:{wingNear:[61,60],wingFar:[103,60],tail:[80,85]},speed:1.3,wing:8,tailWave:7},
 'azulao':{name:'Azulão',personality:'Tranquilo e protetor',anatomy:'Vela de papel azul, asas-nuvem e rabiola de chuva',body:[54,26,53,64],wingNear:[23,44,42,32],wingFar:[97,44,42,32],tail:[42,87,42,43],pivots:{wingNear:[61,66],wingFar:[101,66],tail:[78,91]},speed:1.8,wing:5,tailWave:5},
 'raio-de-sol':{name:'Raio de sol',personality:'Vivo e entusiasmado',anatomy:'Diamante de papel dourado, asas sanfonadas e rabiola dupla',body:[53,28,55,60],wingNear:[16,52,44,36],wingFar:[100,52,44,36],tail:[69,85,40,50],pivots:{wingNear:[56,59],wingFar:[104,59],tail:[77,89]},speed:.9,wing:10,tailWave:9},
 'rabbito':{name:'Rabbito',personality:'Curioso, corajoso e afetuoso',anatomy:'Orelhas de vela com varetas, corpo de papel dobrado e rabiola de laços',speed:1.15}
};
const key=(t,values,ease='smooth')=>({t,ease,values:Object.fromEntries(Object.entries(values).map(([id,v])=>[id,{...identity(),...v}]))});
function clips(spec,bunny){
 const channels=bunny?['root','body','head','earNear','earFar','armNear','armFar','tail']:['root','body','wingNear','wingFar','tail'];
 const rest=Object.fromEntries(channels.map(id=>[id,{}]));
 const fill=values=>({...rest,...values});
 const cycle=(seconds,pose)=>({seconds,loop:true,hitTime:null,expressions:[],frames:Array.from({length:17},(_,i)=>key(seconds*i/16,fill(pose(i===16?0:i/16*Math.PI*2)),'spline'))});
 const r={
  idle:cycle(bunny?3.2:3.6,a=>bunny?{root:{y:-.6*Math.sin(a)},head:{rotation:.6*Math.sin(a)},earNear:{rotation:1.8*Math.sin(a)},earFar:{rotation:-1.2*Math.sin(a)},tail:{rotation:3*Math.sin(a)}}:{root:{y:-1.4*Math.sin(a),rotation:.6*Math.sin(a)},wingNear:{rotation:spec.wing*.35*Math.sin(a)},wingFar:{rotation:-spec.wing*.35*Math.sin(a)},tail:{rotation:spec.tailWave*.5*Math.sin(a)}}),
  flight:cycle(spec.speed,a=>bunny?{root:{y:-4-1.5*Math.sin(a),rotation:3},head:{rotation:-2},earNear:{rotation:-8-3*Math.sin(a)},earFar:{rotation:5+2*Math.sin(a)},armNear:{rotation:-12+3*Math.sin(a)},armFar:{rotation:9-2*Math.sin(a)},tail:{rotation:6*Math.sin(a)}}:{root:{y:-3-2*Math.sin(a),rotation:1.5*Math.sin(a)},wingNear:{rotation:spec.wing*Math.sin(a)},wingFar:{rotation:-spec.wing*Math.sin(a)},tail:{rotation:spec.tailWave*Math.sin(a)}}),
 };
 const peak=bunny?{root:{x:9,y:-7,rotation:7},head:{rotation:-4},earNear:{rotation:-9},earFar:{rotation:7},armNear:{rotation:-38},armFar:{rotation:-17},tail:{rotation:-11}}:{root:{x:-7,y:-3,rotation:-9},wingNear:{rotation:-16},wingFar:{rotation:12},tail:{rotation:14}};
 r.skill={seconds:1.8,loop:false,hitTime:.68,expressions:[{start:.24,end:1.25,face:'fierce'}],frames:[key(0,rest),key(.35,fill({root:{x:bunny?-3:3,y:2,rotation:bunny?-4:4}})),key(.68,fill(peak)),key(.92,fill({root:{x:bunny?5:-4,y:-1,rotation:bunny?3:-3}})),key(1.45,rest),key(1.8,rest)]};
 r.hurt={seconds:1.2,loop:false,hitTime:null,expressions:[{start:.03,end:.7,face:'hurt'}],frames:[key(0,rest),key(.12,fill({root:{x:bunny?-5:5,y:2,rotation:bunny?-5:5},...(bunny?{earNear:{rotation:10},earFar:{rotation:-8},head:{rotation:3}}:{wingNear:{rotation:8},wingFar:{rotation:-8}}),tail:{rotation:-8}})),key(.4,fill({root:{x:bunny?-2:2,rotation:1}})),key(.9,rest),key(1.2,rest)]};
 r.victory={seconds:2.6,loop:false,hitTime:null,expressions:[{start:.28,end:2.05,face:'happy'}],frames:[key(0,rest),key(.55,fill(bunny?{root:{y:-5},armNear:{rotation:-65},armFar:{rotation:40},earNear:{rotation:-5},earFar:{rotation:5}}:{root:{y:-4,rotation:-4},wingNear:{rotation:12},wingFar:{rotation:-12},tail:{rotation:9}})),key(1.2,fill(bunny?{root:{y:-2},armNear:{rotation:-48},armFar:{rotation:32},earNear:{rotation:3},earFar:{rotation:-3}}:{root:{y:-2,rotation:4},wingNear:{rotation:8},wingFar:{rotation:-8},tail:{rotation:-9}})),key(1.8,fill({root:{y:-1}})),key(2.25,rest),key(2.6,rest)]};
 for(const [id,c]of Object.entries(r))c.label={idle:'Repouso',flight:bunny?'Planagem de orelhas':'Voo',skill:'Golpe',hurt:'Dano',victory:'Vitória'}[id];
 return r;
}
const registry={};
for(const [id,spec]of Object.entries(specs)){
 const dir=new URL(id+'/color-rig/',root),reg=JSON.parse(fs.readFileSync(new URL('registration.json',dir))),bunny=id==='rabbito';
 const p={schema:'soulgen-studio',version:1,name:spec.name+' · rig colorido',creatureId:id,artRevision:1,width:160,height:160,rootPivot:bunny?[85,107]:[80,65],brief:{species:spec.name,personality:spec.personality,kiteAnatomy:spec.anatomy,view:bunny?'Três quartos · direita':'Frontal com volume de papel',reference:bunny?'assets/story/kael-birthday-v1/rabbito.png':`assets/creatures/basicos-v2/${id}.png`,notes:'Arte image_gen em peças; face registrada sobre textura canônica. Não substitui o atlas do jogo.'},assets:{},parts:[],clips:clips(spec,bunny)};
 const base=`/art/soulgen/keys/${id}/color-rig/`;
 for(const [part,size]of Object.entries(reg.sizes))p.assets[part]={src:base+part+'.png',width:size[0],height:size[1],name:part};
 const face=reg.facialPart;
 for(const exp of ['fierce','hurt','happy'])p.assets[exp]={src:base+face+'-'+exp+'.png',width:reg.sizes[face][0],height:reg.sizes[face][1],name:exp};
 const add=(part,rect,pivot,z,parent=null,lag=0)=>{const size=reg.sizes[part];p.parts.push({id:part,name:{body:'Corpo de papel',head:'Cabeça e expressões',wingNear:'Asa próxima',wingFar:'Asa distante',tail:'Rabiola',earNear:'Orelha próxima',earFar:'Orelha distante',armNear:'Braço próximo',armFar:'Braço distante'}[part],asset:part,source:[0,0,...size],rect,pivot,z,parent,lag,visible:true,...part===face?{faces:Object.fromEntries(['fierce','hurt','happy'].map(exp=>[exp,{asset:exp,source:[0,0,...size]}])),faceWindows:[reg.faceWindow]}:{}});};
 if(bunny){
  add('tail',[33,116,47,27],[77,127],0,'body',.1);
  add('earFar',[94,9,28,70],[108,76],1,'head',.03);
  add('earNear',[45,10,55,66],[91,73],2,'head',.04);
  add('armFar',[100,104,18,24],[106,109],3,'body',.02);
  add('body',[62,99,50,44],[86,108],4);
  add('head',[54,63,66,55],[87,108],5);
  add('armNear',[61,108,20,23],[68,112],6,'body',.02);
 }else{
  add('tail',spec.tail,spec.pivots.tail,0,'body',.1);
  add('wingFar',spec.wingFar,spec.pivots.wingFar,1,'body',.04);
  add('body',spec.body,[80,65],2);
  add('wingNear',spec.wingNear,spec.pivots.wingNear,3,'body');
 }
 // Contact landmarks measured separately from the animated pivots. These catch
 // displaced parts after manual editing; they do not grant artistic approval.
 const anchors=bunny?{earNear:[.84,.96],earFar:[.5,.96],armNear:[.35,.17],armFar:[.33,.21],tail:[.94,.41]}:
  id==='mata-verde'?{wingNear:[.95,.56],wingFar:[.06,.56],tail:[.15,.10]}:
  id==='azulao'?{wingNear:[.90,.66],wingFar:[.10,.66],tail:[.86,.09]}:{wingNear:[.90,.20],wingFar:[.10,.20],tail:[.20,.08]};
 p.anatomy={version:1,ratios:bunny?[{part:'head',relativeTo:'body',min:1.2,max:1.4,label:'Cabeça / torso'},{part:'earNear',relativeTo:'head',min:.75,max:.9,label:'Vela da orelha / cabeça'}]:[{part:'wingNear',relativeTo:'body',min:.7,max:1,label:'Asa / vela central'}],behind:[{part:'tail',other:'body'},...(bunny?[{part:'earNear',other:'head'},{part:'earFar',other:'head'},{part:'armFar',other:'body'}]:[{part:'wingFar',other:'body'}])],joints:Object.entries(anchors).map(([id,anchor])=>{const part=p.parts.find(x=>x.id===id),parent=p.parts.find(x=>x.id===part.parent);return {part:id,parent:parent.id,anchor,socket:part.pivot.map((v,i)=>Math.max(0,Math.min(1,(v-parent.rect[i])/parent.rect[i+2]))),maxGap:3.5};})};
 const audit=validate(p);if(!audit.ok||audit.warnings.length)throw Error(id+JSON.stringify(audit));
 fs.writeFileSync(new URL(id+'.soulgen.json',dir),JSON.stringify(p,null,2)+'\n');
 const portable=structuredClone(p);
 for(const asset of Object.values(portable.assets))asset.src='data:image/png;base64,'+fs.readFileSync(new URL(asset.src.slice(base.length),dir)).toString('base64');
 fs.writeFileSync(new URL(id+'.portable.soulgen.json',dir),JSON.stringify(portable)+'\n');
 fs.writeFileSync(new URL('manifest.json',dir),JSON.stringify({schema:'soulgen-color-cutout-delivery-v1',id,name:spec.name,status:'ready-for-art-review',tool:'image_gen.imagegen',source:'source.png',reference:p.brief.reference,dimensions:reg.sourceSize,alpha:'RGBA; transparência real',filter:'Canvas smoothing high; fonte sem redução prévia',parts:p.parts,anatomy:p.anatomy,clips:Object.fromEntries(Object.entries(p.clips).map(([k,c])=>[k,{seconds:c.seconds,loop:c.loop,hitTime:c.hitTime,expressions:c.expressions}])),prompts:'../../basic-color-v1/prompts.json',runtime:'Soulgen Studio model.mjs',gameIntegration:false,productionPublished:false},null,2)+'\n');
 registry[id]={name:spec.name,project:p};
}
fs.writeFileSync(new URL('registry.json',import.meta.url),JSON.stringify(registry,null,2)+'\n');
console.log('Four registered Soulgen projects built.');
