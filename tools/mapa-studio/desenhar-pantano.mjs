import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {compile} from '../import-overworld.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=48,H=40;
const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const gid=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
const id=p=>'kronasta-pantano-'+p.toLowerCase();
const names=['Entrada alagada','Curva dos cipós','Clareira das raízes'];
export function swampPart(part){
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),ramps=Array(W*H).fill(0),pieces=[],events=[];let next=1;
 const ix=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m=null,l=null)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++)if(x>=0&&y>=0&&x<W&&y<H){if(m)mat[ix(x,y)]=m;if(l!==null)level[ix(x,y)]=l;}};
 const obj=(type,name,u,v,p={})=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const feature={nativeProps:true,swamp:true,followTrail:true,guards:[],shots:[],water:{contour:[],channel:[],depth:12,channelDepth:12,bridge:{u:23,v:19,w:3,h:8}}};
 rect(0,0,20,16,null,1);rect(28,0,20,16,null,1);rect(0,28,18,4,null,1);rect(30,28,18,4,null,1);
 rect(0,0,W,4,'bosque');rect(0,H-4,W,4,'bosque');rect(0,0,4,H,'bosque');rect(W-4,0,4,H,'bosque');
 rect(22,0,5,H,'terra',0);rect(10,16,28,3,'terra',0);rect(10,32,28,3,'terra',0);
 const access=(u,v)=>{rect(u,v-2,2,2,'grama',1);rect(u,v,2,4,'terra',0);for(let x=u;x<u+2;x++)ramps[ix(x,v)]=24;};
 access(10,16);access(34,16);access(10,32);access(34,32);
 const phase=part.charCodeAt(0)-65;
 const center=u=>23+Math.sin((u-24)*.16+phase*.6)*1.2*Math.min(1,Math.abs(u-24)/9);
 const half=u=>2.1+.6*Math.sin(u*.21+phase)**2;
 for(let u=-10;u<=58;u++)feature.water.channel.push([u,center(u)-half(u)]);
 for(let u=58;u>=-10;u--)feature.water.channel.push([u,center(u)+half(u)]);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(Math.abs(v+.5-center(u+.5))<half(u+.5)+.65)rect(u,v,1,1,'agua',0);
 rect(23,18,3,1,'terra',0);rect(23,19,3,8,'ponte',0);rect(23,27,3,2,'terra',0);
 rect(6,8,5,5,'bosque',1);rect(36,6,6,6,'bosque',1);rect(5,29,3,2,'mato',1);rect(38,29,3,2,'mato',1);
 events.push(obj('entrada','Entrada do pântano',24,37));
 if(part!=='A')events.push(obj('saida','Retorno pela margem',24,39,{destino:id(String.fromCharCode(part.charCodeAt(0)-1)),chegada_u:24,chegada_v:2}));
 if(part!=='C')events.push(obj('saida','Seguir pelo pântano',24,0,{destino:id(String.fromCharCode(part.charCodeAt(0)+1)),chegada_u:24,chegada_v:37}));
 if(part==='C')events.push(obj('saida','Voltar à entrada do pântano',24,0,{destino:id('A'),chegada_u:24,chegada_v:37}));
 for(const [name,u,v,item,vis]of [['Papel no aterro',15,30,'papel-seda','brilho'],['Varetas entre raízes',5,15,'vareta-bambu','escondido'],['Cola na margem alta',32,8,'cola-reparo','brilho']])events.push(obj('item',name,u,v,{item,quantidade:1,visibilidade:vis,trajetoria:'ambas'}));
 events.push(obj('interacao','Margem tranquila',21,30,{texto:'Só o vento entre as folhas e a água parada. Prévia independente.'}));
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:next,properties:props({nome:'Pântano · '+names[phase],regras:'overworld-1',bioma:'floresta',cena_jogo:id(part),regiao:'pantano-previa',parte:part,trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,i)=>ramps[i]||(l?16+l:0))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 const model=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(model,model.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(model,u,v)&&!seen[ix(u,v)])mat[ix(u,v)]='bosque';
 // Grouped vegetation only in blocked forest, kept away from access landings.
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(mat[ix(u,v)]==='bosque'&&![[8,9],[9,9],[38,8],[39,8]].some(p=>p[0]===u&&p[1]===v))pieces.push(obj('peca','Mata alagada',u,v,{asset:'arvore',variante:(u+v)%3?'a':'b'}));
 for(const [u,v] of [[8,9],[9,9],[38,8],[39,8]])pieces.push(obj('peca','Raízes e cipós',u,v,{asset:'pantano-arvore',pegada:'1x1'}));
 feature.waterTrees=[[8,center(8)],[10,center(10)+.3],[12,center(12)-.5],[36,center(36)],[38,center(38)+.3],[40,center(40)-.4]];
 feature.clearViews=[];ramps.forEach((r,i)=>{if(r){const u=i%W,v=Math.floor(i/W);feature.clearViews.push([u+.5,v+.5],[u+.5,v+1.5],[u+.5,v+2.5]);}});
 feature.shots.push({name:'travessia',u:24.5,v:23,zoom:1,kind:'jogo'},{name:'aterro-seco',u:12,v:32,zoom:1,kind:'jogo'},{name:'raizes-norte',u:37,v:11,zoom:1,kind:'jogo'},{name:'cabeceira-norte',u:24.5,v:19,zoom:2.3},{name:'cabeceira-sul',u:24.5,v:27,zoom:2.3});
 for(const u of [4,12,20,28,36,44]){feature.shots.push({name:'margem-norte-'+u,u,v:center(u)-half(u),zoom:2.3},{name:'margem-sul-'+u,u,v:center(u)+half(u),zoom:2.3});}
 return {id:id(part),part,raw:raw(),feature};
}
export function generateSwamp(){
 const parts=['A','B','C'].map(swampPart),region=parts.map(p=>({id:p.id,part:p.part,map:parseTiled(p.raw,{'rascunho.tsj':ts})}));
 const links=[['A','B'],['B','C']].map(([a,b])=>({from:{area:id(a),u:24,v:0,direction:'v-'},to:{area:id(b),u:24,v:39,direction:'v+'}}));
 fs.mkdirSync(root+'documentation/overworld/pantano/relatorios',{recursive:true});
 for(const p of parts){const result=auditZeroBreak(region.find(r=>r.id===p.id).map,{region,links});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error(p.id+' rejected');
  fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');const out=compile(p.raw,p.id);fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(out));
  writeCapturePlan(out,{...p.feature,industrial:true},'documentation/overworld/pantano');fs.writeFileSync(root+'documentation/overworld/pantano/relatorios/'+p.id+'-auditoria.json',JSON.stringify(result,null,2)+'\n');
 }
 const file=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(file));
 for(const p of parts){index.areas=index.areas.filter(a=>a.id!==p.id);index.areas.push({id:p.id,name:'Pântano · '+names[p.part.charCodeAt(0)-65],scene:p.id,biome:'floresta'});index.scenes[p.id]=p.id;}fs.writeFileSync(file,JSON.stringify(index,null,2)+'\n');return parts;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateSwamp();



