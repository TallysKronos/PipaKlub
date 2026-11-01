import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,audit,verdict} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
export const ID='encosta-dos-ventos-piloto';
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function encosta(){
 const W=30,H=26,i=(u,v)=>v*W+u;
 const source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const gid=Object.fromEntries(source.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
 const mat=Array(W*H).fill('grama'),level=Array(W*H).fill(0),alt=Array(W*H).fill(0);
 const rect=(u,v,w,h,m,l)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){mat[i(x,y)]=m;if(l!==undefined)level[i(x,y)]=l;}};
 rect(0,0,W,3,'bosque');rect(0,3,3,H-3,'bosque');rect(27,3,3,H-3,'bosque');rect(3,24,24,2,'bosque');
 rect(3,3,13,14,'grama',1);rect(18,3,9,14,'grama',1);
 rect(16,3,2,8,'grama',1);rect(16,6,2,2,'terra',1);
 rect(4,4,8,6,'grama',2);
 // Main route is broad; side tracks never cut across a height boundary.
 rect(9,21,16,2,'terra');rect(9,11,3,10,'terra');rect(10,11,6,3,'terra');
 rect(18,11,7,3,'terra');rect(22,14,2,7,'terra');rect(7,6,9,2,'terra');
 const ramps=[{u:10,v:17,w:2,h:4,dir:'v-',base:0},{u:22,v:17,w:2,h:4,dir:'v-',base:0},{u:12,v:6,w:4,h:2,dir:'u-',base:1}];
 // A height tileset local to this source supports upper ramps without changing rascunho.
 const heights={...source,firstgid:101,name:'encosta-alturas',image:'../tiles/rascunho.png',tiles:[{id:0,properties:props({nivel:0})},{id:1,properties:props({nivel:1})},{id:2,properties:props({nivel:2})},{id:3,properties:props({nivel:1,rampa:'u-'})}]};
 for(const r of ramps)for(let y=r.v;y<r.v+r.h;y++)for(let x=r.u;x<r.u+r.w;x++){mat[i(x,y)]='terra';level[i(x,y)]=r.base;if(r.dir==='v-'?y===r.v:x===r.u)alt[i(x,y)]=r.dir==='v-'?24:104;}
 rect(4,12,3,3,'mato');rect(24,5,2,3,'mato');
 // Supported, closed masses frame the north; no scenery hides any ramp mouth.
 rect(3,3,24,1,'bosque');rect(3,4,1,13,'bosque');rect(26,4,1,13,'bosque');rect(3,23,24,1,'bosque');
 let n=1;const obj=(type,name,u,v,p={})=>({id:n++,type,name,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const events=[obj('entrada','Entrada do laboratório',10,22),obj('item','Marca do mirante',7,6,{texto:'Marcador de teste. Nenhum item foi concedido.'}),obj('item','Marca entre o mato',5,13,{texto:'Você encontrou o desvio oculto. Prévia sem recompensa.',visibilidade:'escondido'}),obj('item','Marca da travessia',24,12,{texto:'Travessia concluída. Prévia sem recompensa.'})];
 const pieces=[obj('peca','Biruta do mirante',7,4,{asset:'biruta',pegada:'1x1',bloqueia:true})];
 const links=[{id:'salto-ida',kind:'jump',from:[15.5,12.5],to:[18.5,12.5]},{id:'salto-volta',kind:'jump',from:[18.5,12.5],to:[15.5,12.5]},{id:'descida',kind:'drop',from:[20.5,16.5],to:[20.5,18.5]}];
 const raw={type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:n,properties:props({nome:'Encosta dos Ventos · mobilidade',regras:'overworld-1',bioma:'veredas',cena_jogo:ID,rampa_comprimento:4,forest:JSON.stringify({nativeProps:true,followTrail:true})}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},heights],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gid[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:level.map((l,k)=>alt[k]||101+l)},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]};
 return {raw,links,ramps};
}
export function generate(){
 const {raw,links,ramps}=encosta(),source=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
 const model=parseTiled(raw,{'rascunho.tsj':source}),issues=audit(model);
 console.log(JSON.stringify({id:ID,verdict:verdict(issues),issues},null,2));
 if(verdict(issues)==='fail')throw Error('Planta reprovada');
 const check=auditZeroBreak(model,{frameDepth:3,requiredRoute:[model.spawn,{u:7,v:6},{u:24,v:12}]});
 // The approved one-map laboratory deliberately has no regional A/B/C links.
 check.issues=check.issues.filter(i=>i.rule!=='Partes da região');
 if(check.issues.some(i=>i.level==='fail'))throw Error(JSON.stringify(check.issues));
 console.log('ZERO QUEBRA '+JSON.stringify({stats:check.stats,issues:check.issues.filter(i=>i.level!=='ok')}));
 const out=compile(raw,ID);out.mobility={version:1,previewOnly:true,links,ramps};
 fs.writeFileSync(root+'art/overworld/mapas/'+ID+'.tmj',JSON.stringify(raw,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/'+ID+'.json',JSON.stringify(out));
 // Standalone scene, intentionally absent from the regular selector and campaign.
 console.log('OK: mapa independente, 3 cotas; '+links.length+' travessias opcionais; sem alterações de economia.');
 return out;
}
if(process.argv[1]===fileURLToPath(import.meta.url))generate();
