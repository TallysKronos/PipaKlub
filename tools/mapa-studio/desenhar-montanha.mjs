import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=56,H=48;
const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const names=['Sopé','Encosta','Cume'],id=p=>'kronasta-montanha-'+p.toLowerCase();
// Inline height vocabulary isolates six absolute elevations from shared rascunho.
const heights={...source,name:'montanha-alturas',image:'../tiles/rascunho.png',firstgid:101,tiles:[]};
for(let n=0;n<=6;n++)heights.tiles.push({id:n,type:'altura',properties:props({nivel:n})});
heights.tiles.push({id:7,type:'altura',properties:props({nivel:-1})});
heights.tiles.push({id:20,type:'altura',properties:props({nivel:-18})});
heights.tiles.push({id:21,type:'altura',properties:props({nivel:7})});
for(let n=0;n<=5;n++)for(const [d,k] of [['v-',8],['u-',14]])heights.tiles.push({id:k+n,type:'altura',properties:props({nivel:n,rampa:d})});
export function mountainPart(part){
 const base=(part.charCodeAt(0)-65)*2,ix=(u,v)=>v*W+u;
 const mat=Array(W*H).fill('rocha'),level=[],ramp=Array(W*H).fill(null),events=[],pieces=[];let next=1;
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){
  const lower=36+(u<8||u>=48?-4:0),upper=20+(u<8?-4:u>=48?-2:0);
  level.push(base+(v<upper?2:v<lower?1:0));
 }
 const paint=(u,v,w,h,m='terra')=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H)mat[ix(x,y)]=m;};
 const path=(points,width=4)=>{for(let n=1;n<points.length;n++){const a=points[n-1],b=points[n],steps=Math.ceil(Math.hypot(b[0]-a[0],b[1]-a[1])*4);for(let k=0;k<=steps;k++)paint(Math.round(a[0]+(b[0]-a[0])*k/steps)-Math.floor(width/2),Math.round(a[1]+(b[1]-a[1])*k/steps)-Math.floor(width/2),width,width);}};
 const oval=(cx,cy,rx,ry,m)=>{for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(((u-cx)/rx)**2+((v-cy)/ry)**2<=1)mat[ix(u,v)]=m;};
 const object=(type,name,u,v,p={})=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const access=(u,v)=>{paint(u,v-2,3,6);for(let x=u;x<u+3;x++)ramp[ix(x,v)]='v-';};
 const leftFirst=part!=='B',low=leftFirst?12:40,high=leftFirst?42:12,entry=part==='A'?13:24;
 path([[entry,47],[entry,42],[low+1,42],[low+1,38]]);
 const middleRoute=part==='A'?[[13,34],[20,32],[30,32],[36,34],[43,34],[43,22]]:part==='B'?[[41,34],[35,31],[29,31],[23,34],[13,34],[13,22]]:[[13,34],[23,31],[33,31],[43,27],[43,22]];path(middleRoute,3);
 path([[high+1,18],[24,18],[24,part==='C'?10:0]]);
 access(low,36);access(high,20);
 // Open landing pockets punctuate long narrow traverses.
 paint(low-2,40,8,4,'grama');paint(low-1,30,7,6,'grama');paint(high-2,24,8,6,'grama');paint(20,10,10,8,'grama');
 if(part!=='C')path([[24,16],[24,0]],4);
 const middleEnd=part==='B'?44:7,upperEnd=part==='B'?8:46,lowerEnd=part==='A'?38:8;
 path([[26,34],[26,26],[middleEnd,26]],3);path([[24,12],[upperEnd,12]],3);path([[entry,42],[lowerEnd,42]],3);
 paint(part==='B'?40:5,25,4,3,'mato');
 if(part==='C'){
  // A real downhill return loop, no teleport from summit to the foot.
  access(36,36);access(16,20);
  path([[24,42],[37,42],[37,38]],3);path([[37,34],[17,34],[17,22]],3);path([[17,18],[24,18]],3);
  paint(21,8,8,6,'grama');
 }
 // Distinct landings: sheltered foothill, lean exposed shoulder, broad summit.
 if(part==='A'){oval(16,41,7,3,'grama');oval(18,32,7,3,'grama');}
 if(part==='B'){oval(42,31,4,3,'grama');}
 if(part==='C'){oval(25,12,9,5,'grama');path([[24,18],[24,10]],3);path([[24,12],[upperEnd,12]],3);}
 // Carve the valley out of the rock mass. Walkable terraces retain their actual
 // absolute heights; the rear massif and middle shoulder provide continuous rock.
 path([[entry,47],[entry,42],[low+1,42],[low+1,38]],3);path([[entry,42],[lowerEnd,42]],3);
 path(middleRoute,3);
 // Connected geological support, with contour built in 2x2 blocks.
 for(let v=0;v<H;v+=2)for(let u=0;u<W;u+=2){
  const x=u+1,y=v+1,cx=part==='B'?25+(y-24)*.28:28,rx=part==='A'?31:part==='B'?27:26,ry=part==='C'?27:28,edge=((x-cx)/rx)**2+((y-23)/ry)**2;
  const wave=Math.sin(x*.19)*1.6+Math.cos(x*.35)*.8;
  const lower=36+Math.round(wave/2)*2,upper=19+Math.round(Math.sin(x*.16+base)*2)*2;
  for(let dy=0;dy<2;dy++)for(let dx=0;dx<2;dx++){const i=ix(u+dx,v+dy);if(mat[i]!=='rocha')continue;
   level[i]=edge>1.08?-18:base+(y<upper?2:y<lower?1:0);
  }
 }
 if(part!=='A')for(const v of [36,37])for(const u of part==='B'?[38,39]:[10,11]){mat[ix(u,v)]='rocha';level[ix(u,v)]=base;}
 if(part==='C')for(const v of [20,21])level[ix(19,v)]=base+2;
 for(let i=0;i<level.length;i++)if(mat[i]==='rocha'&&level[i]>=0)level[i]++;
 // Trim single-cell rock needles and pointed grass tips after carving the trail.
 const sloped=new Set();ramp.forEach((d,i)=>{if(d){sloped.add(i);sloped.add(i+W);}});
 for(let pass=0;pass<24;pass++){
  let changed=false;
  for(let v=0;v<H;v++)for(let u=0;u<W;u++){
   const i=ix(u,v);if(level[i]<0||sloped.has(i)||mat[i]==='terra')continue;
   const ns=[[u-1,v],[u+1,v],[u,v-1],[u,v+1]].filter(([x,y])=>x>=0&&y>=0&&x<W&&y<H).map(([x,y])=>ix(x,y)).filter(j=>!sloped.has(j)&&level[j]>=0);
   if(ns.filter(j=>level[j]===level[i]).length>=2)continue;
   const counts=new Map();for(const j of ns)counts.set(level[j],(counts.get(level[j])||0)+1);
   const target=[...counts].sort((a,b)=>b[1]-a[1]).find(([h,n])=>n>=2);
   if(target){level[i]=target[0];mat[i]='rocha';changed=true;}else if(mat[i]==='rocha'&&(u===0||v===0||u===W-1||v===H-1||[[u-1,v],[u+1,v],[u,v-1],[u,v+1]].some(([x,y])=>x>=0&&y>=0&&x<W&&y<H&&level[ix(x,y)]<0))){level[i]=-18;changed=true;}
  }
  if(!changed)break;
 }
 const feature={nativeProps:true,mountain:true,baseLevel:base,followTrail:true,artRevision:2,part:part,guards:[],shots:[],clearViews:[],crag:{u:part==='B'?8:part==='C'?23:38,v:4,w:3,h:3},deadEnds:[[lowerEnd,42],[middleEnd,26],[upperEnd,12]],climb:[base,base+2]};
 events.push(object('entrada','Entrada da montanha',entry,44));
 if(part!=='A')events.push(object('saida','Descer à parte anterior',24,47,{destino:id(String.fromCharCode(part.charCodeAt(0)-1)),chegada_u:24,chegada_v:2}));
 if(part!=='C')events.push(object('saida','Continuar a subida',24,0,{destino:id(String.fromCharCode(part.charCodeAt(0)+1)),chegada_u:24,chegada_v:44}));
 else events.push(object('interacao','Mirante do cume',24,10,{texto:'O caminho inteiro fica para trás. O vento chega livre ao cume.'}));
 for(const [name,u,v,item,visibility] of [['Material do abrigo',lowerEnd,42,'cola-reparo','brilho'],['Varetas no beco',middleEnd,26,'vareta-bambu','escondido'],['Papel do mirante',upperEnd,12,'papel-seda','brilho']])events.push(object('item',name,u,v,{item,quantidade:1,visibilidade:visibility,trajetoria:'ambas'}));
 pieces.push(object('peca','Crista de pedra',feature.crag.u,4,{asset:'montanha-crista',pegada:'3x3'}));
 ramp.forEach((d,i)=>{if(d)feature.clearViews.push([i%W+.5,Math.floor(i/W)+.5],[i%W+.5,Math.floor(i/W)+2.5]);});
 for(const [n,u,v] of [['sopre',entry,42],['travessia',28,34],['patamar-alto',24,16],['beco',middleEnd,26]])feature.shots.push({name:n,u,v,zoom:1,kind:'jogo'});
 feature.shots.push({name:'crista-base',u:feature.crag.u+1.5,v:7,zoom:2.3});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:next,properties:props({nome:'Montanha · '+names[part.charCodeAt(0)-65],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'montanha-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramp[i]?101+8+l:l===7?122:l===-18?121:l<0?108:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return {id:id(part),part,raw,feature};
}
export function generateMountain(){
 const parts=['A','B','C'].map(mountainPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':source})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:24,v:0,direction:'v-'},to:{area:id(b),u:24,v:47,direction:'v+'}}));
 fs.mkdirSync(root+'documentation/overworld/montanha/relatorios',{recursive:true});
 for(const p of parts){const m=region.find(r=>r.id===p.id).map,result=auditZeroBreak(m,{region,links,requiredRoute:[m.spawn,...m.events.filter(e=>e.type==='saida'||e.name==='Mirante do cume')]});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));writeCapturePlan(out,p.feature,'documentation/overworld/montanha');fs.writeFileSync(root+'documentation/overworld/montanha/relatorios/'+p.id+'-auditoria.json',JSON.stringify(result,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Montanha · '+names[p.part.charCodeAt(0)-65],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateMountain();
