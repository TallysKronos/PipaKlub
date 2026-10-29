// Authored blockout for review. Deterministic; no procedural content, runtime or kit edits.
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../../',import.meta.url));
const file=root+'art/overworld/mapas/jardim-das-pipas.tmj';
const old=JSON.parse(fs.readFileSync(file,'utf8')),W=40,H=32;
if(old.properties?.some(p=>p.name==='origem'&&p.value==='parque-abc-v1'))throw Error('A planta regional substituiu este estudo. Use tools/mapa-studio/parque-abc.mjs para não regredir o Jardim.');
const ground=Array(W*H).fill(10),height=Array(W*H).fill(0);
function rect(layer,g,u0,v0,u1,v1){for(let v=v0;v<=v1;v++)for(let u=u0;u<=u1;u++)layer[v*W+u]=g;}
rect(ground,1,1,1,38,30);
rect(height,17,3,3,16,12);
// Main path: entrance, Nina's quiet square, south trail and exit.
rect(ground,2,3,24,6,29);rect(ground,7,5,21,12,26);
rect(ground,2,10,23,34,25);rect(ground,2,31,5,34,25);
rect(ground,7,29,5,35,9);
// A second loop around a visible grove; it rejoins the main route.
rect(ground,10,22,14,28,21);
rect(ground,2,18,10,20,24);rect(ground,2,18,9,33,11);
// Low optional detour with treasure, not a forced grass encounter.
rect(ground,2,10,25,12,29);rect(ground,2,10,28,28,30);rect(ground,2,26,24,28,30);
// The useful high branch: three-cell ramp, a coreto, view and a chest.
rect(ground,2,9,4,11,22);rect(ground,7,3,3,16,12);
rect(ground,2,9,4,11,12);rect(ground,2,9,5,14,7);
rect(height,24,9,13,11,13);rect(ground,2,9,13,11,14);
// Wild pockets are all optional and remain well away from the dialogue/rest areas.
rect(ground,3,2,16,6,20);rect(ground,3,23,3,27,6);rect(ground,3,32,27,37,29);
const positions={
 1:[3,4],2:[1,5],3:[7,3],4:[12,3],5:[16,3],6:[19,3],7:[30,2],8:[37,4],
 9:[1,12],10:[2,22],11:[1,29],12:[38,10],13:[38,17],14:[37,24],15:[6,28],
 16:[15,28],17:[21,28],18:[30,29],19:[2,10],20:[15,10],21:[14,22],
 22:[6,24],23:[29,7],24:[5,24],25:[35,7],26:[21,14],27:[24,16],28:[27,19],
 29:[3,23],30:[6,22],31:[12,22],32:[6,26],33:[35,9],34:[8,7],35:[31,3],
 36:[4,27],37:[4,29],38:[33,5],39:[5,23],40:[8,24],41:[29,8],42:[3,24]
};
const groups={};
for(const name of ['pecas','eventos']){
 groups[name]=old.layers.find(l=>l.name===name).objects.filter(o=>o.id<=42).map(o=>{
  const [u,v]=positions[o.id];return {...o,x:(u+.5)*32,y:(v+.5)*32};
 });
}
const prop=(name,value)=>({name,type:typeof value==='boolean'?'bool':'string',value});
function add(id,name,type,u,v,p,layer='eventos'){
 groups[layer].push({id,name,type,x:(u+.5)*32,y:(v+.5)*32,point:true,width:0,height:0,rotation:0,visible:true,
  properties:Object.entries(p).map(([k,v])=>prop(k,v))});
}
add(43,'Nina · a rabiola perdida','npc',9,23,{fala:'nina-jardim-proposta',texto:'Meu Carcará ficou lá dentro… Eu voltei sem a rabiola dele.',missao:'nina',fase:'resgate-inicio',bloqueia:false});
add(44,'Vestígio na trilha · releitura após o resgate','interacao',19,23,{texto:'Um fiapo preso entre as pedras. Nina pode reconhecer o que aconteceu.',missao:'nina',fase:'investigacao-pos-resgate',libera_apos:'nina-devolucao'});
add(45,'Baú do coreto','peca',14,5,{asset:'bau',pegada:'1x1',interacao:'abrir',texto:'Conteúdo de preparação a definir; a planta não concede itens.'},'pecas');
add(46,'Baú do laço baixo','peca',26,28,{asset:'bau',pegada:'1x1',interacao:'abrir',texto:'Recompensa de exploração a definir; a planta não concede itens.'},'pecas');
const props=old.properties.filter(p=>!['origem','libera_apos','trajetoria','estado'].includes(p.name));
props.push(prop('origem','planta autoral da missão de Nina; 2026-10-29'),prop('libera_apos','primeira-criacao-assis'),prop('trajetoria','ambas'),prop('estado','planta-proposta-nina-v1'));
const layer=(id,name,data)=>({id,name,type:'tilelayer',width:W,height:H,x:0,y:0,opacity:1,visible:true,data});
const group=(id,name)=>({id,name,type:'objectgroup',draworder:'topdown',x:0,y:0,opacity:1,visible:true,objects:groups[name]});
const map={...old,width:W,height:H,infinite:false,properties:props,layers:[layer(1,'chao',ground),layer(2,'altura',height),group(3,'pecas'),group(4,'eventos')],nextobjectid:47};
fs.writeFileSync(file,JSON.stringify(map,null,1)+'\n');
console.log('Jardim das Pipas: 40×32, dois níveis, rampa 3 células, duas rotas e dois baús.');
