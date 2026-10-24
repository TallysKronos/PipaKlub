// Presentation policy: account XP is independent of each Pipamon's own level.
// "na Praça da Chegada", "no Mirante": the place names are proper nouns with their own article.
const placeIn=place=>(/^(Mirante|Parque|Morro|Quintal)\b/.test(place)?' no ':/^(Praça|Escadaria|Laje|Rua|Casa|Loja|Trilha)\b/.test(place)?' na ':' em ')+place;
export function createPlazaPolicy(){
 const paths=[{left:600,right:825,top:560,bottom:1010},{left:235,right:1000,top:560,bottom:625}];
 function point(x,y){
  if(!Number.isFinite(x)||!Number.isFinite(y))return {x:735,y:630};
  return paths.map(p=>({x:Math.max(p.left,Math.min(p.right,x)),y:Math.max(p.top,Math.min(p.bottom,y))})).sort((a,b)=>Math.hypot(x-a.x,y-a.y)-Math.hypot(x-b.x,y-b.y))[0];
 }
 function profile(p){
  const level=Math.min(100,Math.max(1,Math.floor(Number(p?.level)||1))),xp=Math.max(0,Number(p?.xp)||0),base=Number.isFinite(p?.level_base_xp)?p.level_base_xp:(level-1)**2*100,next=level===100?xp:Math.max(base+1,Number(p?.next_level_xp)||level**2*100);
  return {level,xp,next,percent:level===100?100:Math.max(0,Math.min(100,(xp-base)/(next-base)*100))};
 }
 function mission(phase,next,trail,context={}){
  if(phase==='arrival'||phase==='choose')return {title:'Seu primeiro parceiro',body:'Visite a casa do Sr. Assis e escolha quem vai voar com você.',action:'professor'};
  if(phase==='practice')return {title:'Seu primeiro voo',body:'Visite a casa do Sr. Assis para aprender a rebicar com ele e Nozinho.',action:'professor'};
  if(phase==='city'&&context.starterTutorial?.required)return {title:context.starterTutorial.modelId?'Monte sua primeira pipa':'Escolha sua rabiola',body:'Converse com o Sr. Assis para concluir seu primeiro elo na Oficina das Almas.',action:'professor'};
  if(phase==='city')return {title:'Um mundo para explorar',body:'Visite a cidade e conheça seu primeiro bairro.',action:'city'};
  if(context.demo&&context.complete)return {title:'Demo concluída',body:'Você conquistou o Morro do Sol! Conheça seu novo parceiro, revisite o bairro ou jogue online com seus amigos.',action:'demo',stage:null};
  if(context.roadCleared)return {title:context.roadFinal?'Bairro conquistado':'Caminho liberado',body:context.roadFinal?'Você venceu o campeão. Siga pela saída para explorar a cidade.':'A vitória foi confirmada. Suba e siga para a próxima área do Morro.',action:'worldAdvance',stage:null};
  if(context.complete)return {title:'Jornada concluída',body:'Você venceu os três bairros disponíveis! Revisite seus rivais ou encontre seus amigos enquanto os próximos bairros são preparados.',action:'city',stage:null};
  if(context.worldId==='morro'&&next?.trailIndex===0)return {title:context.nearStage===next.id?'Seu próximo duelo':'Encontre seu rival',body:(context.nearStage===next.id?'Converse com ':'Encontre ')+(context.rivals||'seu rival')+(context.place?placeIn(context.place):' em seu próximo encontro')+'.',action:'nextEncounter',stage:next.id};
  return {title:'Próximo desafio',body:trail?'Explore a '+trail.name+' e encontre seu próximo duelo.':'Explore a cidade dos ventos.',action:'city',stage:next?.id||null};
 }
 return {point,profile,mission};
}
