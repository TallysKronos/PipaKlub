import {terrainHeight} from './terrain-field.mjs';import {waterAt} from './water.mjs';import {waterfallGeometry,isWaterfall} from './waterfalls.mjs';import {validRamp,moveOnTerrain} from './terrain.mjs';
export function auditMap(a){
 const issues=[],add=(severity,code,message,x,y,objectId)=>issues.push({severity,code,message,x,y,...(objectId?{objectId}:{})});
 const inside=p=>p.x>=0&&p.y>=0&&p.x<a.width*32&&p.y<a.height*32;
 if(!inside(a.player)||waterAt(a,a.player.x,a.player.y))add('error','spawn','Kael começa fora do chão caminhável.',a.player.x,a.player.y);
 for(let i=0;i<a.ramps.length;i++)if(a.ramps[i]&&!validRamp(a,i))add('error','ramp','Rampa sem os dois patamares compatíveis.',i%a.width*32+16,Math.floor(i/a.width)*32+16);
 for(const o of a.objects){
  if(isWaterfall(o.asset)){if(!waterfallGeometry(a,o))add('error','waterfall','Cachoeira sem desnível ou água compatível na origem e no destino.',o.x,o.y,o.id);continue;}
  if(o.decorative)continue;
  if(!inside(o))add('warning','object','Objeto com a raiz fora do mapa. Marque como decoração se for intencional.',o.x,o.y,o.id);
  else if(o.collidable&&waterAt(a,o.x,o.y))add('warning','object-water','Objeto com colisão apoiado na água; confira a intenção.',o.x,o.y,o.id);
 }
 for(const e of a.events??[])if(e.type==='npc'&&e.route.length){let from=e;for(const to of [...e.route,e]){const end=moveOnTerrain(a,from,{x:to.x-from.x,y:to.y-from.y});if(Math.hypot(end.x-to.x,end.y-to.y)>1){add('warning','npc-route','A rota do NPC atravessa água ou um barranco. Ajuste os pontos antes de publicar.',from.x,from.y);break;}from=to;}}
 // Reachability is advisory: isolated islands can be intentional or reached by events.
 const seen=new Set(),pending=[],start=Math.floor(a.player.y/32)*a.width+Math.floor(a.player.x/32);
 if(inside(a.player)&&!waterAt(a,a.player.x,a.player.y)){seen.add(start);pending.push(start);}
 while(pending.length){const i=pending.pop(),p={x:i%a.width*32+16,y:Math.floor(i/a.width)*32+16};for(const [dx,dy]of [[32,0],[-32,0],[0,32],[0,-32]]){const q={x:p.x+dx,y:p.y+dy};if(!inside(q)||waterAt(a,q.x,q.y))continue;const j=Math.floor(q.y/32)*a.width+Math.floor(q.x/32);if(seen.has(j))continue;const end=moveOnTerrain(a,p,{x:dx,y:dy});if(Math.hypot(end.x-q.x,end.y-q.y)<1){seen.add(j);pending.push(j);}}}
 const groups=new Set();for(let i=0;i<a.levels.length;i++){const p={x:i%a.width*32+16,y:Math.floor(i/a.width)*32+16};if(seen.has(i)||waterAt(a,p.x,p.y))continue;const key=a.levels[i];if(!groups.has(key)){groups.add(key);add('warning','route','Há chão na cota '+key+' sem rota direta desde Kael. Pode ser uma ilha ou acesso por evento intencional.',p.x,p.y);}}
 return {issues,errors:issues.filter(i=>i.severity==='error').length,warnings:issues.filter(i=>i.severity==='warning').length,reachable:seen.size};
}
