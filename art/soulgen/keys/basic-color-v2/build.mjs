import fs from 'node:fs';
import {identity,validate} from '../../../../tools/soulgen-studio/model.mjs';
const root=new URL('../',import.meta.url),previous=JSON.parse(fs.readFileSync(new URL('../basic-color-v1/registry.json',import.meta.url)));
const specs={
 'mata-verde':{body:[53,18,55,78],wingNear:[12,54,49,36],wingFar:[98,58,51,35],tail:[42,93,44,40],pivots:{wingNear:[56,57],wingFar:[104.5,61],tail:[82,96]},anchors:{wingNear:[.90,.08],wingFar:[.13,.08],tail:[.90,.08]}},
 'azulao':{body:[52,18,58,78],wingNear:[11,43,50,48],wingFar:[102,46,50,44],tail:[76,93,24,43],pivots:{wingNear:[56,60],wingFar:[106,61],tail:[80,96]},anchors:{wingNear:[.90,.36],wingFar:[.09,.34],tail:[.15,.07]}},
 'raio-de-sol':{body:[51,22,58,70],wingNear:[10,49,49,42],wingFar:[103,49,49,42],tail:[77,89,45,46],pivots:{wingNear:[55,53],wingFar:[107,53],tail:[81,92]},anchors:{wingNear:[.91,.10],wingFar:[.07,.10],tail:[.09,.06]}},
 'rabbito':{body:[65,100,53,46.5],head:[58,64,60,51],earNear:[40,6,53,76],earFar:[96,6,31,74.5],armNear:[63,110,23,22],armFar:[103,107,16,20],tail:[13,95,65,38.5],pivots:{head:[88,109],earNear:[88,79],earFar:[115,77],armNear:[74.5,112.6],armFar:[109.5,109.5],tail:[77,127]},anchors:{earNear:[.90,.96],earFar:[.62,.95],armNear:[.50,.12],armFar:[.40,.12],tail:[.98,.83]}}
};
const registry={};
for(const [id,s]of Object.entries(specs)){
 const folder=new URL(id+'/color-rig-v2/',root),registration=JSON.parse(fs.readFileSync(new URL('registration.json',folder))),p=structuredClone(previous[id].project),bunny=id==='rabbito';
 p.name=previous[id].name+' · papel artesanal v2';p.artRevision=2;p.artDirection='art/soulgen/DIRECAO-ARTE-CARCARA.md';
 p.brief.reference=`art/soulgen/keys/${id}/color-rig-v2/concept.png`;
 p.brief.notes='Regerado a partir do Carcará como referência de ARTE: olhos pequenos e escuros, papel facetado e reparos costurados. Pivôs medidos novamente. Revisão artística final pendente; atlas do jogo preservado.';
 if(id==='azulao'){p.brief.species='Azulão · ave-pipa azul';p.brief.kiteAnatomy='Vela azul/creme, bico curto de papel, asas de penas com pintura de nuvens, armação de bambu e rabiola-nuvem.';}
 p.assets={};const base=`/art/soulgen/keys/${id}/color-rig-v2/`;
 for(const [part,size]of Object.entries(registration.sizes))p.assets[part]={src:base+part+'.png',width:size[0],height:size[1],name:part};
 const face=registration.facialPart;
 for(const exp of ['fierce','hurt','happy'])p.assets[exp]={src:base+face+'-'+exp+'.png',width:registration.sizes[face][0],height:registration.sizes[face][1],name:exp};
 // The generated Rabbito arms are opposite the requested sheet labels: the broad
 // arm is anatomically near. Assign the measured art, rather than trust the slots.
 if(bunny){[p.assets.armNear,p.assets.armFar]=[p.assets.armFar,p.assets.armNear];p.assets.armNear.name='armNear';p.assets.armFar.name='armFar';}
 p.parts=p.parts.map(part=>{const a=p.assets[part.id];return {...part,rect:s[part.id],source:[0,0,a.width,a.height],pivot:s.pivots[part.id]||[80,65],...part.id===face?{faces:Object.fromEntries(['fierce','hurt','happy'].map(exp=>[exp,{asset:exp,source:[0,0,a.width,a.height]}])),faceWindows:registration.faceWindows}:{}};});
 p.rootPivot=bunny?[85,107]:[80,65];
 p.anatomy={version:1,ratios:bunny?[{part:'head',relativeTo:'body',min:1,max:1.25,label:'Cabeça / torso'},{part:'earNear',relativeTo:'head',min:.8,max:.98,label:'Orelha / cabeça'}]:[{part:'wingNear',relativeTo:'body',min:.75,max:.95,label:'Asa / vela central'}],behind:[{part:'tail',other:'body'},...(bunny?[{part:'earNear',other:'head'},{part:'earFar',other:'head'},{part:'armFar',other:'body'}]:[{part:'wingFar',other:'body'}])],joints:Object.entries(s.anchors).map(([id,anchor])=>{const part=p.parts.find(x=>x.id===id),parent=p.parts.find(x=>x.id===part.parent);return {part:id,parent:parent.id,anchor,socket:part.pivot.map((v,i)=>Math.max(0,Math.min(1,(v-parent.rect[i])/parent.rect[i+2]))),maxGap:3.5};})};
 const manualFile=new URL('user-hierarchy.json',folder);
 if(fs.existsSync(manualFile)){
  const manual=JSON.parse(fs.readFileSync(manualFile));
  if(manual.schema!=='soulgen-user-hierarchy-v1'||manual.baseArtRevision!==p.artRevision)throw Error('Hierarquia manual incompatível: '+id);
  const [dx,dy]=manual.frame.translate;
  for(const part of p.parts){const edited=manual.parts.find(x=>x.id===part.id);if(!edited)throw Error('Peça manual ausente: '+part.id);Object.assign(part,structuredClone(edited));part.rect[0]+=dx;part.rect[1]+=dy;part.pivot[0]+=dx;part.pivot[1]+=dy;}
  p.width=manual.frame.width;p.height=manual.frame.height;p.rootPivot[0]+=dx;p.rootPivot[1]+=dy;
  // The author's placement supersedes the old contact locations. Re-register
  // sockets from the measured artwork anchor; do not loosen the allowed gap.
  for(const joint of p.anatomy.joints){const part=p.parts.find(x=>x.id===joint.part),parent=p.parts.find(x=>x.id===part.parent);joint.parent=parent.id;joint.socket=joint.anchor.map((v,i)=>(part.rect[i]+v*part.rect[i+2]-parent.rect[i])/parent.rect[i+2]);}
  p.rigRevision=manual.rigRevision;p.userHierarchy={source:'art/soulgen/keys/'+id+'/color-rig-v2/'+manual.source,sha256:manual.sha256,frameTranslation:[dx,dy],note:'Hierarquia, proporções e encaixes do responsável preservados. Translação global apenas para margem de exportação.'};
 }
 const check=validate(p);if(!check.ok||check.warnings.length)throw Error(id+JSON.stringify(check));
 fs.writeFileSync(new URL(id+'.soulgen.json',folder),JSON.stringify(p,null,2)+'\n');
 const portable=structuredClone(p);for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+fs.readFileSync(new URL(a.src.slice(base.length),folder)).toString('base64');
 fs.writeFileSync(new URL(id+'.portable.soulgen.json',folder),JSON.stringify(portable)+'\n');
 fs.writeFileSync(new URL('manifest.json',folder),JSON.stringify({schema:'soulgen-color-cutout-delivery-v2',id,status:'ready-for-art-review',tool:'image_gen.imagegen',styleReference:'art/soulgen/keys/carcara/source/layers-generated.png',concept:'concept.png',source:'source.png',dimensions:registration.sourceSize,logicalSize:[p.width,p.height],rigRevision:p.rigRevision||0,userHierarchy:p.userHierarchy||null,parts:p.parts,anatomy:p.anatomy,clips:p.clips,prompts:'../../basic-color-v2/prompts.json',gameIntegration:false,productionPublished:false},null,2)+'\n');
 registry[id]={name:previous[id].name,project:p};
}
fs.writeFileSync(new URL('registry.json',import.meta.url),JSON.stringify(registry,null,2)+'\n');
console.log('Four Carcará-style v2 rigs built; v1 preserved.');
