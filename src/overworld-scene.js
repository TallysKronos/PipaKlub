// Converte uma planta do overworld (Tiled isométrico, regras overworld-1) para a cena ortogonal do jogo.
// Roda no build: a física continua a mesma das Veredas (retângulos Walkable com level/elevation e escadas).
import {parseTiled,audit,at} from '../tools/mapa-studio/model.mjs';
import {parseWorldMap} from './world-map.js';
export const OVERWORLD_CELL=64,OVERWORLD_LEVEL=96;
const FRAME={grama:'grass',terra:'dirt',mato:'park-tall-grass',ponte:'bridge',piso:'sidewalk',calcada:'sidewalk',asfalto:'sidewalk'};
// Peças com arte aprovada no pacote do parque; pedra usa o arbusto até ganhar arte própria.
const PROP={arvore:'tree',pedra:'shrub',bau:'chest',banco:'bench',placa:'sign',flores:'flowers',poste:'lamp',lixeira:'bin',vaso:'planter'};
// Junta células iguais em retângulos: primeiro na linha, depois descendo enquanto a faixa inteira for igual.
function merge(w,h,keyAt){const used=new Uint8Array(w*h),out=[];
 for(let v=0;v<h;v++)for(let u=0;u<w;u++){const k=keyAt(u,v);if(k==null||used[v*w+u])continue;let u1=u;while(u1+1<w&&!used[v*w+u1+1]&&keyAt(u1+1,v)===k)u1++;
  let v1=v;for(;v1+1<h;v1++){let ok=true;for(let x=u;x<=u1&&ok;x++)ok=!used[(v1+1)*w+x]&&keyAt(x,v1+1)===k;if(!ok)break;}
  for(let y=v;y<=v1;y++)for(let x=u;x<=u1;x++)used[y*w+x]=1;out.push({key:k,u,v,w:u1-u+1,h:v1-v+1});}
 return out;}
export function overworldScene(raw,tilesets,{id,cell=OVERWORLD_CELL,levelPx=OVERWORLD_LEVEL}={}){
 const m=parseTiled(raw,tilesets),fail=text=>{throw Error(`Overworld ${id}: ${text}`);};
 const errors=audit(m).filter(i=>i.level==='fail');if(errors.length)fail(errors.map(i=>i.text).join(' '));
 // Limites do renderer atual das Veredas: escadas sobem para o fundo (v-) a partir do chão, e pontes cruzam em u.
 for(let v=0;v<m.h;v++)for(let u=0;u<m.w;u++){const c=at(m,u,v);if(c.ramp&&(c.ramp!=='v-'||c.level!==0))fail(`rampa ${c.ramp} no nível ${c.level} em ${u},${v}: no jogo, por enquanto, só rampa v- saindo do nível 0.`);
  if(c.level>1)fail(`nível ${c.level} em ${u},${v}: o jogo ainda desenha só o nível 1.`);}
 const R=(u,v,w=1,h=1)=>({x:u*cell,y:v*cell,width:w*cell,height:h*cell});
 const props=o=>Object.entries(o).map(([name,value])=>({name,type:typeof value==='boolean'?'bool':Number.isInteger(value)?'int':'string',value}));
 let next=0;const layers=['Walkable','Solids','Foreground','Interactions','Spawns','Exits'].map((name,i)=>({id:i+1,name,type:'objectgroup',objects:[]}));
 const add=(layer,name,r,p={})=>layers.find(l=>l.name===layer).objects.push({id:++next,name,...r,properties:props({level:0,...p})});
 const zone=raw.properties?.find(p=>p.name==='encontros')?.value||'park-veredas-wild';
 for(const r of merge(m.w,m.h,(u,v)=>{const c=at(m,u,v),f=FRAME[c.material];return f?`${f}|${c.level}|${c.ramp||''}`:null;})){
  const [frame,level,ramp]=r.key.split('|'),L=Number(level),p={ground_frame:ramp?'stairs':frame,level:L,safe_area:true,...(L?{elevation:L*levelPx}:{})};
  if(ramp)Object.assign(p,{connects_to:L+1,rise_to:(L+1)*levelPx});if(frame==='park-tall-grass'){p.encounter_zone=zone;delete p.safe_area;}
  if(frame==='bridge'&&r.h>r.w)fail(`a ponte em ${r.u},${r.v} cruza em v; o jogo ainda só desenha pontes que atravessam em u.`);
  add('Walkable',`${ramp?'Rampa':frame} ${r.u},${r.v}`,R(r.u,r.v,r.w,r.h),p);}
 // A água inclui o vão sob a ponte, para o tabuleiro apoiar nas duas margens.
 const water=merge(m.w,m.h,(u,v)=>['agua','ponte'].includes(at(m,u,v).material)?'w':null).map(r=>({x:r.u*cell,y:r.v*cell,w:r.w*cell,h:r.h*cell}));
 // Quem ocupa a célula (baú, NPC) é falado de uma vizinha da frente (u+ ou v+), para o Kael não ficar escondido atrás.
 const around=(u,v,fu=1,fv=1)=>R(u,v,Math.min(m.w,u+fu+1)-u,Math.min(m.h,v+fv+1)-v);
 const center=(u,v,fu=1,fv=1)=>({x:(u+fu/2)*cell,y:(v+fv/2)*cell}),chests=[],decor=[],npcs=[];
 for(const p of m.pieces){const level=at(m,p.u,p.v)?.level||0,c=center(p.u,p.v,p.fu,p.fv),type=PROP[p.asset]||p.asset;
  if(type==='tree')add('Solids',p.name,{x:c.x-20,y:c.y-16,width:40,height:24},{world_prop:'tree',level,sort_y:c.y+8});
  else if(type==='chest')add('Solids',p.name,{x:c.x-22,y:c.y-14,width:44,height:28},{level,sort_y:c.y});
  else if(p.blocks)add('Solids',p.name,{x:p.u*cell+8,y:p.v*cell+8,width:p.fu*cell-16,height:p.fv*cell-16},{level,sort_y:c.y});
  if(type==='chest')chests.push({id:`${id}-${p.id}`,name:p.name,...c,level,action:p.props.acao||'pilot_story'});else if(type!=='tree')decor.push({...c,type,w:type==='shrub'?72:90});
  if(p.interact)add('Interactions',p.name,around(p.u,p.v,p.fu,p.fv),{level,action:p.props.acao||'pilot_story',story:p.props.texto||`${p.name}: nada aqui por enquanto.`});}
 for(const e of m.events){const level=at(m,e.u,e.v)?.level||0,r=R(e.u,e.v);
  if(e.type==='entrada'){add('Spawns',e.name||'Entrada',r);if(e.props.destino)add('Exits',`Voltar · ${e.name||e.props.destino}`,r,{action:'street_scene',target:e.props.destino});}
  else if(e.type==='saida'){if(!e.props.destino)fail(`a saída "${e.name}" não tem destino.`);add('Exits',e.name||'Saída',around(e.u,e.v),{level,action:'street_scene',target:e.props.destino});}
  else{if(e.type==='npc'){const c=center(e.u,e.v);add('Solids',e.name,{x:c.x-14,y:c.y-10,width:28,height:20},{level,sort_y:c.y});}add('Interactions',e.name||e.type,around(e.u,e.v),{level,action:e.props.acao||'pilot_story',story:e.props.texto||`${e.name||e.type}.`});if(e.type==='npc')npcs.push({name:e.name,...center(e.u,e.v)});}}
 const name=m.name;
 const map={type:'map',version:'1.10',orientation:'orthogonal',renderorder:'right-down',width:m.w*cell/32,height:m.h*cell/32,tilewidth:32,tileheight:32,infinite:false,tilesets:[],layers,
  properties:props({scene_name:name,scene_id:id,veredas_region:true,prefer_safe_paths:true,actor_height:72,foot_radius:10,walk_speed:300,ground_corner_radius:32})};
 const scene=parseWorldMap(map);scene.isometric=true;scene.art={objects:[]};
 for(const place of scene.places)if(place.action==='pilot_story'&&chests.some(chest=>chest.name===place.name))place.interactionLabel='Abrir baú';
 scene.veredas={chests,water,sectors:[],decor,borderTrees:false,backRim:true};scene.overworld={id,cell,npcs};return scene;
}
