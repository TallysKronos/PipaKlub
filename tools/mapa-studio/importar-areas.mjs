// Converte as áreas externas que o jogo já tem (cenas ortogonais do art-build) em plantas overworld-1 para o Tiled.
// A geometria vem do jogo: chão andável, níveis, escadas, água, colisões, portas e NPCs. Rodar de novo sobrescreve os .tmj.
// Uso: node tools/mapa-studio/importar-areas.mjs [id-da-planta ...]
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {artConfig} from '../../scripts/art-build.mjs';
import {VEREDAS_CHESTS} from '../../src/park-boss-layout.js';
import {parseTiled,audit,verdict} from './model.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url)),CELL=64,LEVEL=96;
const GID={grama:1,terra:2,mato:3,agua:4,rocha:5,ponte:6,piso:7,calcada:8,asfalto:9,bosque:10,construcao:11,canteiro:12,n1:17,n2:18,n3:19,'u+':21,'u-':22,'v+':23,'v-':24};
// Plantas: id do arquivo, cena do jogo, bioma (define o kit de arte) e materiais de cada tipo de chão.
const AREAS=[
 {id:'rua-dos-ventos',scene:'quintal',bioma:'bairro',fill:'canteiro',frames:{road:'asfalto',sidewalk:'calcada',dirt:'terra'}},
 {id:'jardim-das-pipas',scene:'park-trail',bioma:'parque',fill:'bosque',frames:{grass:'grama',dirt:'terra',sidewalk:'piso','park-tall-grass':'mato'}},
 {id:'clareira-do-papel',scene:'park-clearing',bioma:'parque',fill:'bosque',frames:{grass:'grama',dirt:'terra',sidewalk:'piso','park-tall-grass':'mato'}},
 {id:'veredas-do-encanamento',scene:'park-veredas',bioma:'veredas',fill:'bosque',frames:{grass:'grama',dirt:'terra',sidewalk:'piso','park-tall-grass':'mato',bridge:'ponte',stairs:'terra'}},
 {id:'morro-praca-da-chegada',road:0,bioma:'morro',fill:'construcao',frames:{},base:'calcada',marcos:[['banca-pipas','oeste'],['caixa-dagua','norte']]},
 {id:'morro-escadaria-da-sombra',road:1,bioma:'morro',fill:'construcao',frames:{},base:'calcada',marcos:[['arvore-grande','oeste'],['varal','leste']]},
 {id:'morro-laje-dos-ventos',road:2,bioma:'morro',fill:'construcao',frames:{},base:'piso',marcos:[['varal','oeste'],['banca-pipas','leste']]},
 {id:'morro-mirante-da-caixa-dagua',road:3,bioma:'morro',fill:'construcao',frames:{},base:'calcada',marcos:[['caixa-dagua','norte'],['mirante-guarda-corpo','leste']]},
 {id:'morro-parque-dos-ventos',road:4,bioma:'morro',fill:'construcao',frames:{},base:'grama',marcos:[['arvore-grande','oeste'],['toldo-bandeirolas','leste']]}];
// Nome da peça no jogo -> asset do kit (o mesmo id que o Codex vai desenhar).
function assetOf(r){const n=(r.name||'').toLowerCase(),p=r.properties;
 if(p.world_prop==='tree'||/tree|árvore|tronco/.test(n))return n.includes('flower')?['arvore',{variante:'florida'}]:n.endsWith('-a')?['arvore',{variante:'a'}]:n.includes('tronco')?['arvore',{variante:'tronco-largo'}]:['arvore',{variante:'b'}];
 const table=[[/^house$/,'casa-kael'],[/professorhouse/,'casa-assis'],[/^shop$/,'loja-pipas'],[/noticeboard/,'mural'],[/workbench/,'bancada-rua'],[/bench/,'banco'],[/lamp/,'poste'],[/entry-map/,'placa-mapa'],[/planter/,'vaso'],[/bin/,'lixeira'],[/mesa do artesao/,'mesa-artesao'],[/pilar/,'portao']];
 for(const [re,a] of table)if(re.test(n))return [a,{}];return [n.replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'')||'peca',{}];}
function build(def,scene){
 const L=scene.tiled.layers,W=Math.ceil(scene.width/CELL),H=Math.ceil(scene.height/CELL),N=W*H;
 const contains=(r,x,y)=>x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h;
 const mat=Array(N).fill(null),lvl=Array(N).fill(-1),ramp=Array(N).fill(null);
 const water=scene.veredas?.water||[];
 // 1) Chão andável: o retângulo que contém o centro da célula (o de nível mais alto, se houver dois).
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){const x=u*CELL+CELL/2,y=v*CELL+CELL/2,i=v*W+u;
  // Nível mais alto primeiro; no mesmo nível, o retângulo menor (ponte, escada, trilha) vence o chão grande.
  const cellBox={x:u*CELL,y:v*CELL,w:CELL,h:CELL},overlap=(a,b)=>Math.max(0,Math.min(a.x+a.w,b.x+b.w)-Math.max(a.x,b.x))*Math.max(0,Math.min(a.y+a.h,b.y+b.h)-Math.max(a.y,b.y))/(CELL*CELL);
  const wet=water.reduce((s,w)=>s+overlap(cellBox,w),0);
  const hits=L.Walkable.filter(r=>contains(r,x,y)&&!(r.properties.ground_frame==='bridge'&&wet===0)).sort((a,b)=>(b.properties.level||0)-(a.properties.level||0)||a.w*a.h-b.w*b.h);const r=hits[0];
  // Água que cobre metade da célula vence o chão da margem (o canal não pode sumir entre duas células).
  if(!r||(wet>=.5&&r.properties.ground_frame!=='bridge'))continue;
  const f=r.properties.ground_frame;mat[i]=def.frames[f]||def.base||'grama';lvl[i]=r.properties.elevation?Math.round(r.properties.elevation/LEVEL):r.properties.level||0;
  if(f==='bridge')mat[i]='ponte';}
 // 2) Escadas: só a última fileira sobe; o resto é o caminho de acesso no nível de baixo.
 const stairs=L.Walkable.filter(r=>r.properties.connects_to!==undefined);
 for(const r of stairs){const cells=[];for(let v=0;v<H;v++)for(let u=0;u<W;u++){const x=u*CELL+CELL/2,y=v*CELL+CELL/2;if(contains(r,x,y))cells.push({u,v});}
  if(!cells.length)continue;const vTop=Math.min(...cells.map(c=>c.v)),vBot=Math.max(...cells.map(c=>c.v)),up=r.properties.connects_to;
  const northUp=cells.some(c=>c.v===vTop&&lvl[(c.v-1)*W+c.u]===up),southUp=cells.some(c=>c.v===vBot&&lvl[(c.v+1)*W+c.u]===up);
  for(const c of cells){lvl[c.v*W+c.u]=up-1;if(northUp&&c.v===vTop)ramp[c.v*W+c.u]='v-';else if(!northUp&&southUp&&c.v===vBot)ramp[c.v*W+c.u]='v+';}}
 const walkable=mat.map(m=>m!==null);
 // 3) Fora do chão andável: água, construção (sob prédios) ou o preenchimento do bioma, no nível do chão mais próximo.
 const solidsBig=L.Solids.filter(r=>/house|shop|contencao/i.test(r.name||''));
 for(let v=0;v<H;v++)for(let u=0;u<W;u++){const i=v*W+u;if(walkable[i])continue;const x=u*CELL+CELL/2,y=v*CELL+CELL/2;
  mat[i]=water.some(r=>contains(r,x,y))?'agua':solidsBig.some(r=>contains(r,x,y))?'construcao':def.fill;}
 const q=[];for(let i=0;i<N;i++)if(lvl[i]>=0)q.push(i);
 for(let k=0;k<q.length;k++){const i=q[k],u=i%W,v=(i/W)|0;for(const [du,dv] of [[1,0],[-1,0],[0,1],[0,-1]]){const a=u+du,b=v+dv;if(a<0||b<0||a>=W||b>=H)continue;const j=b*W+a;if(lvl[j]<0){lvl[j]=mat[j]==='agua'?0:lvl[i];q.push(j);}}}
 for(let i=0;i<N;i++)if(lvl[i]<0)lvl[i]=0;
 // 4) Peças: colisões do jogo (árvores, prédios, mobiliário) e decoração conhecida das Veredas.
 const objects=[];let next=1;const cellOf=(x,y)=>({u:Math.min(W-1,Math.floor(x/CELL)),v:Math.min(H-1,Math.floor(y/CELL))});
 const obj=(layer,name,type,u,v,props={})=>objects.push({layer,o:{id:next++,name,type,x:(u+.5)*32,y:(v+.5)*32,point:true,width:0,height:0,rotation:0,visible:true,properties:Object.entries(props).filter(([,v])=>v!==undefined&&v!=='').map(([name,value])=>({name,type:typeof value==='boolean'?'bool':typeof value==='number'?'int':'string',value}))}});
 const coreto=L.Solids.filter(r=>/coreto/.test(r.name||''));
 if(coreto.length){const x0=Math.min(...coreto.map(r=>r.x)),y0=Math.min(...coreto.map(r=>r.y)),x1=Math.max(...coreto.map(r=>r.x+r.w)),y1=Math.max(...coreto.map(r=>r.y+r.h)),a=cellOf(x0,y0),b=cellOf(x1,y1);obj('pecas','Coreto','peca',a.u,a.v,{asset:'coreto',pegada:`${b.u-a.u+1}x${b.v-a.v+1}`});}
 const pilares=L.Solids.filter(r=>/pilar/i.test(r.name||''));
 if(pilares.length){const x0=Math.min(...pilares.map(r=>r.x)),y1=Math.max(...pilares.map(r=>r.y+r.h)),x1=Math.max(...pilares.map(r=>r.x+r.w)),a=cellOf(x0,y1-1),b=cellOf(x1,y1-1);obj('pecas','Portão de casa','peca',a.u,a.v,{asset:'portao',pegada:`${b.u-a.u+1}x1`,bloqueia:false});}
 for(const r of L.Solids){const n=r.name||'';if(/coreto|pilar|contencao/i.test(n))continue;const [asset,extra]=assetOf(r);
  const tree=asset==='arvore',foot=tree?cellOf(r.x+r.w/2,r.y+r.h):cellOf(r.x+1,r.y+1),end=cellOf(r.x+r.w-1,r.y+r.h-1);
  const fu=tree?1:Math.max(1,Math.round(r.w/CELL)),fv=tree?1:Math.max(1,Math.round(r.h/CELL));void end;
  obj('pecas',tree?'Árvore':n,'peca',foot.u,foot.v,{asset,pegada:fu>1||fv>1?`${fu}x${fv}`:undefined,...extra});}
 if(scene.veredas){
  for(const c of VEREDAS_CHESTS){const p=cellOf(c.x,c.y);obj('pecas',c.name,'peca',p.u,p.v,{asset:'bau',interacao:'abrir',bau:c.id});}
  for(const [x,y,asset,name] of [[384,784,'placa-mapa','Placa do mapa'],[1480,960,'biruta','Biruta'],[2800,232,'biruta','Biruta do pátio'],[2800,256,'banco','Banco do pátio'],[576,1216,'pipa-presa','Papel rasgado (pipa presa)']]){const p=cellOf(x,y);obj('pecas',name,'peca',p.u,p.v,{asset,bloqueia:false});}
  for(const [x,y] of [[256,448],[608,448],[1056,1216],[1312,1440],[1888,480],[2528,480],[2656,1600]]){const p=cellOf(x,y);obj('pecas','Flores','peca',p.u,p.v,{asset:'flores',bloqueia:false});}}
 // 4b) Morro: o jogo atual pinta casas e muros numa ilustração; a planta ganha as mesmas peças para o conceito seguir a geometria.
 if(def.bioma==='morro'){const walk=i=>walkable[i],blocked=new Uint8Array(N),near=(u,v,d)=>{for(let b=v-d;b<=v+d;b++)for(let a=u-d;a<=u+d;a++)if(a>=0&&b>=0&&a<W&&b<H&&walk(b*W+a))return true;return false;};
  const free=(u,v,w,h)=>{for(let b=v;b<v+h;b++)for(let a=u;a<u+w;a++){if(a>=W||b>=H)return false;const i=b*W+a;if(walk(i)||blocked[i]||mat[i]!=='construcao'||lvl[i]!==lvl[v*W+u])return false;}return true;};
  const take=(u,v,w,h)=>{for(let b=v-1;b<=v+h;b++)for(let a=u-1;a<=u+w;a++)if(a>=0&&b>=0&&a<W&&b<H)blocked[b*W+a]=1;};
  for(const [asset,side] of def.marcos||[]){const cands=[];for(let v=0;v<H-1;v++)for(let u=0;u<W-1;u++)if(free(u,v,2,2)&&near(u,v,2))cands.push({u,v});
   const key={oeste:c=>c.u,leste:c=>-c.u,norte:c=>c.v,sul:c=>-c.v}[side];cands.sort((a,b)=>key(a)-key(b)||a.v-b.v);const c=cands[0];if(c){obj('pecas',asset.replace(/-/g,' '),'peca',c.u,c.v,{asset,pegada:'2x2'});take(c.u,c.v,2,2);}}
  // Casas de frente para o chão andável, 3x3, com uma célula de folga entre elas.
  let houses=0;for(let v=0;v<H-2&&houses<10;v++)for(let u=0;u<W-2&&houses<10;u++)if(free(u,v,3,3)&&near(u+1,v+1,3)){obj('pecas','Casa do morro','peca',u,v,{asset:'casa-morro',pegada:'3x3',variante:['telha','laje','muro-chapisco'][houses%3]});take(u,v,3,3);houses++;}}
 // 5) Eventos: entrada, saídas, NPCs e interações, com a ação original do jogo.
 for(const r of L.Spawns){const p=cellOf(r.x+r.w/2,r.y+r.h/2);obj('eventos',r.name||'Entrada','entrada',p.u,p.v);}
 const seen=new Set();
 for(const r of [...L.Exits,...L.Interactions]){const P=r.properties,p=cellOf(r.x+r.w/2,r.y+r.h/2),key=p.u+','+p.v+','+r.name;if(seen.has(key))continue;seen.add(key);
  if(P.action==='veredasChest')continue;
  const door=['street_scene','quintal','road_next','road_back','city'].includes(P.action);
  if(door)obj('eventos',r.name,'saida',p.u,p.v,{destino:P.target||(P.action==='quintal'?'quintal':P.action==='city'||P.action==='road_next'?'cidade':''),requer:P.requires_stage});
  else if(P.stage||['veredasNina','parkBoss','wildGuide','pilot_story'].includes(P.action)&&/nina|lacertubo|assis|zeca/i.test(r.name))obj('eventos',r.name,'npc',p.u,p.v,{acao:P.action,desafio:P.stage,texto:P.story});
  else obj('eventos',r.name,'interacao',p.u,p.v,{acao:P.action||'',requer:P.requires_stage,alvo:P.target,texto:P.story});}
 const chao=mat.map(m=>GID[m]),altura=lvl.map((l,i)=>ramp[i]?GID[ramp[i]]:l>0?GID['n'+Math.min(3,l)]:0);
 const layer=(id,name,data)=>({id,name,type:'tilelayer',width:W,height:H,x:0,y:0,opacity:1,visible:true,data});
 const group=(id,name)=>({id,name,type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:objects.filter(o=>o.layer===name).map(o=>o.o)});
 return {type:'map',version:'1.10',tiledversion:'1.10.2',orientation:'isometric',renderorder:'right-down',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,
  properties:[{name:'nome',type:'string',value:scene.name},{name:'regras',type:'string',value:'overworld-1'},{name:'bioma',type:'string',value:def.bioma},{name:'cena_jogo',type:'string',value:def.scene||def.cena},{name:'origem',type:'string',value:'importada do jogo; ajuste no Tiled'}],
  tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],layers:[layer(1,'chao',chao),layer(2,'altura',altura),group(3,'pecas'),group(4,'eventos')],nextlayerid:5,nextobjectid:next};
}
const world=artConfig().courtyard.world;for(const d of AREAS)if(d.road!==undefined)d.cena=world.morroRoad[d.road].id;
const only=process.argv.slice(2),sets={'rascunho.tsj':JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj','utf8'))};
for(const def of AREAS){if(only.length&&!only.includes(def.id))continue;const scene=def.scene?world.scenes[def.scene]:world.morroRoad[def.road].scene;
 const map=build(def,scene);fs.writeFileSync(root+`art/overworld/mapas/${def.id}.tmj`,JSON.stringify(map,null,1));
 const items=audit(parseTiled(map,sets)),bad=items.filter(i=>i.level!=='ok');
 console.log(`${def.id.padEnd(30)} ${map.width}×${map.height} ${verdict(items).toUpperCase()}${bad.length?'\n  '+bad.map(i=>i.level+' '+i.rule+': '+i.text).join('\n  '):''}`);}
