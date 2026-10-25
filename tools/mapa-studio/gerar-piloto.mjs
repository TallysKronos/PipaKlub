// Gera o rascunho do trecho piloto das Veredas (ponte, rampa, mirante) como mapa isométrico do Tiled.
// Depois de gerado, o mapa é editado no Tiled; rodar de novo sobrescreve art/overworld/mapas/veredas-piloto.tmj.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url)),W=36,H=30;
const GID={grama:1,terra:2,mato:3,agua:4,rocha:5,ponte:6,piso:7,calcada:8,asfalto:9,n1:17,n2:18,n3:19,'u+':21,'u-':22,'v+':23,'v-':24};
const chao=Array(W*H).fill(GID.grama),altura=Array(W*H).fill(0),set=(l,u,v,g)=>{if(u>=0&&v>=0&&u<W&&v<H)l[v*W+u]=g;};
const rect=(l,g,u0,v0,u1,v1)=>{for(let v=v0;v<=v1;v++)for(let u=u0;u<=u1;u++)set(l,u,v,g);};
// Trilha de duas células de largura, em trechos retos (primeiro u, depois v).
function trail(points){for(let i=0;i<points.length-1;i++){const [a,b]=[points[i],points[i+1]];for(let u=Math.min(a[0],b[0]);u<=Math.max(a[0],b[0]);u++)rect(chao,GID.terra,u,a[1],u,a[1]+1);for(let v=Math.min(a[1],b[1]);v<=Math.max(a[1],b[1]);v++)rect(chao,GID.terra,b[0],v,b[0]+1,v);}}
// Riacho de 3 células que serpenteia de cima para baixo.
const creek=v=>18+Math.round(2*Math.sin(v/5));
for(let v=0;v<H;v++)rect(chao,GID.agua,creek(v)-1,v,creek(v)+1,v);
// Mato alto dos encontros.
rect(chao,GID.mato,2,13,6,17);rect(chao,GID.mato,29,23,33,27);
// Trilhas: entrada → ponte → clareira da Nina → saída ao norte; ramal até a rampa do mirante.
trail([[3,27],[3,20],[15,20]]);trail([[8,20],[8,12]]);trail([[22,20],[27,20],[27,6],[32,6],[32,3]]);
// Ponte: substitui a água nas duas linhas da trilha.
for(const v of [20,21])for(let u=creek(v)-1;u<=creek(v)+1;u++)set(chao,u,v,GID.ponte);
for(const v of [20,21]){for(let u=15;u<creek(v)-1;u++)set(chao,u,v,GID.terra);for(let u=creek(v)+2;u<22;u++)set(chao,u,v,GID.terra);}
// Mirante: patamar de nível 1 com barranco; rampa de 2 células subindo para v- (para o fundo da tela).
rect(altura,GID.n1,3,3,12,10);rect(chao,GID.grama,3,3,12,10);trail([[8,9],[8,6],[5,6]]);
set(altura,8,11,GID['v-']);set(altura,9,11,GID['v-']);set(chao,8,11,GID.terra);set(chao,9,11,GID.terra);
// Clareira da Nina, do outro lado da ponte.
rect(chao,GID.piso,25,16,30,19);
const objects=[];let next=1;
const obj=(layer,name,type,u,v,properties={})=>objects.push({layer,o:{id:next++,name,type,x:(u+.5)*32,y:(v+.5)*32,point:true,width:0,height:0,rotation:0,visible:true,properties:Object.entries(properties).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':typeof value==='number'?'int':'string',value}))}});
obj('eventos','Entrada das Veredas','entrada',3,28);
obj('eventos','Nina','npc',27,17,{fala:'nina-ponte'});
obj('eventos','Rumo ao pátio dos canos','saida',33,3,{destino:'patio-canos'});
obj('pecas','Baú do mirante','peca',5,6,{asset:'bau',interacao:'abrir'});
obj('pecas','Baú da margem','peca',23,26,{asset:'bau',interacao:'abrir'});
// Árvores e pedras: enquadram as trilhas sem cobrir as ligações.
const trees=[[1,22],[6,24],[11,26],[13,16],[11,13],[1,9],[14,6],[2,1],[10,1],[24,4],[23,10],[31,10],[34,14],[33,19],[24,24],[27,28],[34,29],[13,24],[13,1],[34,8]];
for(const [u,v] of trees)obj('pecas','Árvore','peca',u,v,{asset:'arvore'});
for(const [u,v] of [[15,13],[23,9],[14,28],[22,15]])obj('pecas','Pedra','peca',u,v,{asset:'pedra'});
const layer=(id,name,data)=>({id,name,type:'tilelayer',width:W,height:H,x:0,y:0,opacity:1,visible:true,data});
const group=(id,name)=>({id,name,type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:objects.filter(o=>o.layer===name).map(o=>o.o)});
const map={type:'map',version:'1.10',tiledversion:'1.10.2',orientation:'isometric',renderorder:'right-down',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,
 properties:[{name:'nome',type:'string',value:'Veredas · trecho piloto (ponte, rampa e mirante)'},{name:'regras',type:'string',value:'overworld-1'}],
 tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'}],layers:[layer(1,'chao',chao),layer(2,'altura',altura),group(3,'pecas'),group(4,'eventos')],nextlayerid:5,nextobjectid:next};
fs.writeFileSync(root+'art/overworld/mapas/veredas-piloto.tmj',JSON.stringify(map,null,1));
console.log('veredas-piloto.tmj',W+'×'+H,objects.length,'objetos');
