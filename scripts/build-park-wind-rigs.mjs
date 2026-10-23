import fs from 'node:fs';
import path from 'node:path';
import {validate} from '../tools/soulgen-studio/model.mjs';
const family=process.argv[2]||'park-wind-v1';if(!['park-wind-v1','park-wind-v2'].includes(family))throw Error('Família desconhecida');
const dir='art/soulgen/keys/'+family,slices=JSON.parse(fs.readFileSync(dir+'/slices.json','utf8'));
const asset=id=>{const {src,width,height}=slices[id];return {name:id,src,width,height};};
function part(id,rect,pivot,z){const a=slices[id];return {id,name:id,asset:id,source:[0,0,a.width,a.height],rect,pivot,z,parent:null,visible:true};}
const sized=(id,x,y,w)=>[x,y,w,w*slices[id].height/slices[id].width];
const loop=(values)=>({label:'Brisa do parque',seconds:6,loop:true,hitTime:null,expressions:[],frames:values.map((v,i)=>({t:i*1.5,ease:'spline',values:v}))});
const trees=[0,1,0,-1,0].map(n=>({canopy:{rotation:n*.85,x:n*.9,scaleX:1+Math.abs(n)*.003},trunk:{rotation:0}}));
const sock=[0,1,0,-1,0].map(n=>({sock:{rotation:n*2.5,scaleY:1+n*.018},pole:{rotation:0}}));
const bunting=[0,1,0,-1,0].map(n=>({bunting:{scaleY:1+n*.035}}));
const projects={
 tree:{width:300,height:310,rootPivot:[150,296],assets:{canopy:asset('canopy'),trunk:asset('trunk')},parts:[part('trunk',sized('trunk',91,170,118),[150,296],0),part('canopy',sized('canopy',16,18,268),[150,185],1)],clips:{idle:loop(trees)}},
 windsock:{width:350,height:270,rootPivot:[68,254],assets:{pole:asset('pole'),sock:asset('sock')},parts:[part('pole',sized('pole',28,10,153),[68,254],0),part('sock',sized('sock',170,25,160),[174,53],1)],clips:{idle:loop(sock)}},
 bunting:{width:320,height:130,rootPivot:[160,116],assets:{bunting:asset('bunting')},parts:[part('bunting',sized('bunting',10,12,300),[160,12],0)],clips:{idle:loop(bunting)}}
};
const reports={};
projects.treeLandmark=structuredClone(projects.tree);
if(family==='park-wind-v1'){
 delete projects.treeLandmark.assets.canopy;
 projects.treeLandmark.assets.canopyLandmark=asset('canopyLandmark');
 projects.treeLandmark.parts.find(p=>p.id==='canopy').asset='canopyLandmark';
}else{
 const tree=projects.tree;
 tree.parts.find(p=>p.id==='trunk').rect=sized('trunk',91,296-118*slices.trunk.height/slices.trunk.width,118);
 tree.parts.find(p=>p.id==='canopy').rect=sized('canopy',16,18,268);
 projects.treeLandmark=structuredClone(tree);
 projects.treeLandmark.assets.kite=asset('kite');
 projects.treeLandmark.parts.push({...part('kite',sized('kite',206,118,48),[206,130],2),parent:'canopy'});
 const mastWidth=244*slices.pole.width/slices.pole.height;
 projects.windsock.width=390;projects.windsock.rootPivot=[78,254];
 projects.windsock.parts=[part('pole',sized('pole',10,10,mastWidth),[78,254],0),part('sock',sized('sock',mastWidth+1,32,158),[mastWidth+8,58],1)];
 projects.kite={width:180,height:150,rootPivot:[57,78],assets:{kite:asset('kite')},parts:[part('kite',sized('kite',10,10,150),[57,78],0)],clips:{idle:loop([0,1,0,-1,0].map(n=>({kite:{rotation:n*3,y:n*4}})))}};
}
for(const [id,p]of Object.entries(projects)){
 Object.assign(p,{schema:'soulgen-studio',version:1,name:'Parque dos Ventos · '+id});
 const check=validate(p);if(!check.ok)throw Error(check.errors.join('\n'));
 fs.writeFileSync(dir+'/'+id+'.json',JSON.stringify(p,null,2)+'\n');
 const portable=structuredClone(p);for(const a of Object.values(portable.assets))a.src='data:image/png;base64,'+fs.readFileSync(path.join('.',a.src)).toString('base64');
 fs.writeFileSync(dir+'/'+id+'.soulgen.json',JSON.stringify(portable)+'\n');
 reports[id]={valid:check.ok,warnings:check.warnings,parts:p.parts.length,seconds:6};
}
fs.writeFileSync(dir+'/validation.json',JSON.stringify(reports,null,2)+'\n');
console.log(reports);
