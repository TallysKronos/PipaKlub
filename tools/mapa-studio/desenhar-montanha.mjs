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
 const object=(type,name,u,v,p={})=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const access=(u,v)=>{paint(u,v-2,3,6);for(let x=u;x<u+3;x++)ramp[ix(x,v)]='v-';};
 const leftFirst=part!=='B',low=leftFirst?12:40,high=leftFirst?42:12,entry=part==='A'?13:24;
 path([[entry,47],[entry,42],[low+1,42],[low+1,38]]);
 path([[low+1,34],[high+1,34],[high+1,22]]);
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
 // Carve the valley out of the rock mass. Walkable terraces retain their actual
 // absolute heights; the rear massif and middle shoulder provide continuous rock.
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[ix(u,v)]==='rocha'&&!(v<8||(u>=10&&u<48&&v>=20&&v<30)))level[ix(u,v)]=-1;
 if(part!=='A')for(const v of [36,37]){const u=part==='B'?39:11;mat[ix(u,v)]='rocha';level[ix(u,v)]=-1;}
 const feature={nativeProps:true,mountain:true,baseLevel:base,followTrail:true,guards:[],shots:[],clearViews:[],crag:{u:part==='B'?8:part==='C'?23:38,v:4,w:3,h:3},deadEnds:[[lowerEnd,42],[middleEnd,26],[upperEnd,12]],climb:[base,base+2]};
 events.push(object('entrada','Entrada da montanha',entry,44));
 if(part!=='A')events.push(object('saida','Descer à parte anterior',24,47,{destino:id(String.fromCharCode(part.charCodeAt(0)-1)),chegada_u:24,chegada_v:2}));
 if(part!=='C')events.push(object('saida','Continuar a subida',24,0,{destino:id(String.fromCharCode(part.charCodeAt(0)+1)),chegada_u:24,chegada_v:44}));
 else events.push(object('interacao','Mirante do cume',24,10,{texto:'O caminho inteiro fica para trás. O vento chega livre ao cume.'}));
 for(const [name,u,v,item,visibility] of [['Material do abrigo',lowerEnd,42,'cola-reparo','brilho'],['Varetas no beco',middleEnd,26,'vareta-bambu','escondido'],['Papel do mirante',upperEnd,12,'papel-seda','brilho']])events.push(object('item',name,u,v,{item,quantidade:1,visibilidade:visibility,trajetoria:'ambas'}));
 pieces.push(object('peca','Crista de pedra',feature.crag.u,4,{asset:'montanha-crista',pegada:'3x3'}));
 ramp.forEach((d,i)=>{if(d)feature.clearViews.push([i%W+.5,Math.floor(i/W)+.5],[i%W+.5,Math.floor(i/W)+2.5]);});
 for(const [n,u,v] of [['sopre',entry,42],['travessia',28,34],['patamar-alto',24,16],['beco',middleEnd,26]])feature.shots.push({name:n,u,v,zoom:1,kind:'jogo'});
 feature.shots.push({name:'crista-base',u:feature.crag.u+1.5,v:7,zoom:2.3});
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:next,properties:props({nome:'Montanha · '+names[part.charCodeAt(0)-65],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'montanha-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramp[i]?101+8+l:l<0?108:101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
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
