import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {parseTiled,reachable,walkable} from './model.mjs';
import {compile} from '../import-overworld.mjs';
import {auditZeroBreak} from './conferencia-bosque.mjs';
import {writeCapturePlan} from './capturas-bosque.mjs';
import {industrialPart} from './desenhar-industrial.mjs';
const root=fileURLToPath(new URL('../../',import.meta.url));
const ts=JSON.parse(fs.readFileSync(root+'art/overworld/tiles/rascunho.tsj'));
const gids=Object.fromEntries(ts.tiles.filter(t=>t.id<16).map(t=>[t.properties[0].value,t.id+1]));
const props=p=>Object.entries(p).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
export function industrialWarehouse({dressed=true}={}){
 const W=40,H=36,id='kronasta-industrial-d',mat=Array(W*H).fill('terra'),height=Array(W*H).fill(0),ramps=Array(W*H).fill(0),events=[],pieces=[];let next=1;
 const ix=(u,v)=>v*W+u;
 const rect=(u,v,w,h,m,l)=>{for(let y=v;y<v+h;y++)for(let x=u;x<u+w;x++){mat[ix(x,y)]=m;height[ix(x,y)]=l;}};
 rect(0,0,W,4,'rocha',1);rect(0,0,4,H,'rocha',1);rect(36,0,4,H,'rocha',0);rect(0,32,W,4,'rocha',0);
 rect(4,4,32,12,'grama',1);rect(4,16,12,12,'grama',1);
 rect(8,32,4,4,'terra',0);
 const feature={nativeProps:true,industrial:true,interior:true,baseLevel:1,closedStairs:true,followTrail:true,buildings:[],guards:[],stairs:[],shots:[]};
 const object=(type,name,u,v,p={})=>({id:next++,name,type,x:u*32+16,y:v*32+16,point:true,properties:props(p)});
 const stair=(u,v,width)=>{for(let x=u;x<u+width;x++){rect(x,v,1,4,'terra',0);ramps[ix(x,v)]=101;}feature.stairs.push({u,v,width,length:2});};
 stair(12,16,4);stair(8,28,4);
 const cargo=(name,u,v,w,h,z,style)=>{pieces.push(object('peca',name,u,v,{asset:'industrial-volume',pegada:w+'x'+h,style}));feature.buildings.push({name,u,v,w,h,z,style});};
 // Identical blocking footprints in both passes; flat geometry only changes rendering.
 cargo('Reserva de carga',5,6,5,4,46,'container');
 cargo('Bobinas de manutenção',26,6,4,3,28,'carretel');
 cargo('Equipamento do fundo',18,5,4,3,80,'caldeira');
 cargo('Carga de recebimento',19,27,5,3,40,'carga');
 cargo('Tambores laterais',32,23,2,3,32,'tambor');
 if(dressed)feature.mangaDressing=true;
 events.push(object('entrada','Entrada do galpão',10,34));
 events.push(object('saida','Voltar ao pátio',10,35,{destino:'kronasta-industrial-b',chegada_u:26,chegada_v:12}));
 for(const [name,u,v,item,hidden]of [['Papel de manutenção',23,12,'papel-seda',false],['Vareta atrás da reserva',5,12,'vareta-bambu',true],['Cola no recebimento',29,29,'cola-reparo',false]])events.push(object('item',name,u,v,{item,quantidade:1,visibilidade:hidden?'escondido':'brilho',trajetoria:'ambas'}));
 events.push(object('interacao','Confronto no galpão',24,24,{acao:'warehouseStory',texto:'Três rabiolas foram costuradas num só corpo. Observe antes de avançar.'}));
 pieces.push(object('peca','Banco de manutenção',14,29,{asset:'banco',pegada:'2x1'}));
 events.push(object('interacao','Banco de manutenção',14,30,{acao:'warehouseRest',texto:'Recuperar a equipe antes de voltar ao confronto.'}));
 // Set equipment in service alcoves after the existing IDs and outside the stairs.
 cargo('Armário da manutenção',5,21,2,3,52,'armario');
 cargo('Palete de peças',31,7,3,2,27,'carga');
 for(let u=16;u<36;u++)feature.guards.push({u,v:15,side:'v'});
 for(let v=20;v<28;v++)feature.guards.push({u:15,v,side:'u'});
 for(const [name,u,v]of [['salao',24,20],['recebimento',14,30],['plataforma',20,12],['ramal-oeste',8,23]])feature.shots.push({name,u,v,zoom:1,kind:'jogo'});
 const raw=()=>({type:'map',version:'1.10',orientation:'isometric',width:W,height:H,tilewidth:64,tileheight:32,infinite:false,nextobjectid:next,properties:props({nome:'Vila Operária · Galpão',regras:'overworld-1',bioma:'parque',cena_jogo:id,regiao:'distrito-industrial',parte:'D',trajetoria:'ambas',rampa_comprimento:2,forest:JSON.stringify(feature)}),tilesets:[{firstgid:1,source:'../tiles/rascunho.tsj'},{...ts,firstgid:101,name:'galpao-alturas',tiles:[{id:0,type:'altura',properties:props({nivel:1,rampa:'v-'})}]}],layers:[{name:'chao',type:'tilelayer',width:W,height:H,data:mat.map(m=>gids[m])},{name:'altura',type:'tilelayer',width:W,height:H,data:height.map((l,i)=>ramps[i]||(17+l))},{name:'pecas',type:'objectgroup',objects:pieces},{name:'eventos',type:'objectgroup',objects:events}]});
 const map=parseTiled(raw(),{'rascunho.tsj':ts}),seen=reachable(map,map.spawn);
 for(let v=0;v<H;v++)for(let u=0;u<W;u++)if(walkable(map,u,v)&&!seen[ix(u,v)])throw Error('Unreachable '+u+','+v);
 return {id,raw:raw(),feature};
}
export function generateWarehouse(){
 const p=industrialWarehouse(),map=parseTiled(p.raw,{'rascunho.tsj':ts});
 const region=[...['A','B','C'].map(part=>{const area=industrialPart(part);return {id:area.id,part,map:parseTiled(area.raw,{'rascunho.tsj':ts})};}),{id:p.id,part:'D',map}];
 const links=[...['A','B'].map((part,i)=>({from:{area:'kronasta-industrial-'+part.toLowerCase(),u:36,v:0,direction:'v-'},to:{area:'kronasta-industrial-'+['b','c'][i],u:36,v:39,direction:'v+'}})),{from:{area:'kronasta-industrial-b',u:26,v:11,direction:'v-'},to:{area:p.id,u:10,v:35,direction:'v+'}}];
 const result=auditZeroBreak(map,{region,links,adjacencies:[['A','B'],['B','C'],['B','D']],guards:p.feature.guards,requiredRoute:[map.spawn,...map.events]});console.log(p.id+'\n'+result.lines.join('\n'));if(!result.ok)throw Error('Warehouse rejected');
 console.log('Cota base +1: '+(map.cells.filter(c=>c.level>1).length/map.cells.length*100).toFixed(1)+'% acima da base. Ligação B↔D conferida nos testes warehouse.');
 fs.writeFileSync(root+'art/overworld/mapas/'+p.id+'.tmj',JSON.stringify(p.raw,null,1)+'\n');
 fs.writeFileSync(root+'godot/assets/overworld/maps/'+p.id+'.json',JSON.stringify(compile(p.raw,p.id)));
 writeCapturePlan(compile(p.raw,p.id),p.feature,'documentation/overworld/industrial');
 fs.writeFileSync(root+'documentation/overworld/industrial/relatorios/'+p.id+'-auditoria.json',JSON.stringify(result,null,2)+'\n');
 const path=root+'godot/assets/overworld/maps/index.json',index=JSON.parse(fs.readFileSync(path));
 if(!index.areas.some(a=>a.id===p.id))index.areas.push({id:p.id,name:'Vila Operária · Galpão',scene:p.id,biome:'parque'});
 index.scenes[p.id]=p.id;fs.writeFileSync(path,JSON.stringify(index,null,2)+'\n');
}
if(process.argv[1]===fileURLToPath(import.meta.url))generateWarehouse();
