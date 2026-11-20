import {collisionDistance} from './collision-shapes.mjs';
import {heightAt} from './terrain.mjs';
export const ICONS={
cursor:'M4 3v17l4-5 4 7 3-2-4-6 7-1Z',
move:'M12 3v18M3 12h18M8 6l4-4 4 4M8 18l4 4 4-4M6 8l-4 4 4 4M18 8l4 4-4 4',
brush:'M14 4l6 6M8 15 18 3l4 4-11 11M8 15c-4-1-5 2-5 6 5 0 8-1 8-4Z',
erase:'m4 14 9-10 8 7-9 10H8l-4-4Zm5-5 8 8M12 21h10',
fill:'m5 8 8-5 8 9-9 8L3 11Zm1-6 9 10M3 12h17M21 17s-3 4 0 4 0-4 0-4',
eyedrop:'m15 3 6 6M14 5l5 5M16 8 6 18l-4 1 1-4L13 5',
floor:'M3 5h18v14H3ZM3 12h18M12 5v14M7 5v7M17 12v7',
height:'M4 14 12 4l8 10M12 4v15M5 21h14',
ramp:'M3 20v-5h5v-5h5V5h7v15ZM3 20h18',
hand:'M7 13V6a1.5 1.5 0 0 1 3 0v5-7a1.5 1.5 0 0 1 3 0v7-6a1.5 1.5 0 0 1 3 0v7-4a1.5 1.5 0 0 1 3 0v8c0 4-3 6-6 6h-1c-3 0-4-2-6-4l-3-4a2 2 0 0 1 3-2l1 1',
undo:'M8 5 3 10l5 5M3 10h11a6 6 0 0 1 0 12',
redo:'m16 5 5 5-5 5M21 10H10a6 6 0 0 0 0 12',
grid:'M3 3h7v7H3ZM14 3h7v7h-7ZM3 14h7v7H3ZM14 14h7v7h-7Z',
snap:'M4 4h16v16H4ZM8 4v16M16 4v16M4 8h16M4 16h16',
export:'M12 15V3M7 8l5-5 5 5M4 13v8h16v-8',
play:'m7 4 14 8-14 8Z',
stop:'M6 6h12v12H6Z',
copy:'M8 8h13v13H8ZM16 8V3H3v13h5',
trash:'M3 6h18M8 6V3h8v3M5 6l1 15h12l1-15M10 10v7M14 10v7',
mountain:'m2 20 7-13 4 7 3-5 6 11ZM6 13l3 2 3-2',
library:'M3 3h4v7H3ZM10 3h4v7h-4ZM17 3h4v7h-4ZM3 13h4v8H3ZM10 13h4v8h-4ZM17 13h4v8h-4Z',
search:'M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0Zm-2 5 7 7',
close:'m5 5 14 14M19 5 5 19',
eye:'M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7Zm13 0a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
lock:'M6 10h12v11H6ZM8 10V6a4 4 0 0 1 8 0v4M12 14v3',
unlock:'M6 10h12v11H6ZM8 10V6a4 4 0 0 1 8 0M12 14v3'
};
export function icon(name){const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.setAttribute('viewBox','0 0 24 24');svg.setAttribute('class','icon');svg.setAttribute('aria-hidden','true');const p=document.createElementNS(svg.namespaceURI,'path');p.setAttribute('d',ICONS[name]||ICONS.grid);svg.append(p);return svg;}
export function labelIcon(el,name,label){el.replaceChildren(icon(name));if(label){const s=document.createElement('span');s.textContent=label;el.append(s);}}
export function mountIcons(){document.querySelectorAll('[data-icon]').forEach(el=>{el.prepend(icon(el.dataset.icon));if(el.dataset.label){const s=document.createElement('span');s.textContent=el.dataset.label;el.append(s);}});}
export const LAYERS=[{id:'characters',name:'Personagens'},{id:'objects',name:'Objetos'},{id:'vegetation',name:'Vegetação'},{id:'relief',name:'Relevo'},{id:'floors',name:'Pisos'}];
export function layerFor(o){return o.id===-1||o.asset==='kael'?'characters':o.layer||'vegetation';}
export function floorBrushCells(a,start,size,level=a.levels[start]){
 if(start<0||start>=a.floors.length||a.levels[start]!==level)return [];
 const out=[],sx=start%a.width,sy=Math.floor(start/a.width),ramp=a.ramps[start];
 for(let dy=0;dy<size;dy++)for(let dx=0;dx<size;dx++){
  const x=sx+dx,y=sy+dy;if(x>=a.width||y>=a.height)continue;const i=y*a.width+x;
  if(a.levels[i]!==level)continue;
  if(ramp&&(dy!==0||a.ramps[i]!==ramp||a.levels[i]!==a.levels[start]))continue;
  out.push(i);
 }return out;
}
export function fillFloor(a,start,kind){if(start<0||start>=a.floors.length||a.floors[start]===kind)return 0;const old=a.floors[start],level=a.levels[start],ramp=a.ramps[start],row=Math.floor(start/a.width),pending=[start],seen=new Set();let count=0;while(pending.length){const i=pending.pop();if(seen.has(i)||a.floors[i]!==old||a.levels[i]!==level||(ramp&&(a.ramps[i]!==ramp||Math.floor(i/a.width)!==row)))continue;seen.add(i);a.floors[i]=kind;count++;const x=i%a.width;if(x>0)pending.push(i-1);if(x<a.width-1)pending.push(i+1);if(i>=a.width)pending.push(i-a.width);if(i<a.floors.length-a.width)pending.push(i+a.width);}return count;}
export function blockedByObjects(a,from,to){return a.objects.some(o=>o.collidable&&Math.abs(heightAt(a,o.x,o.y)-heightAt(a,to.x,to.y))<.35&&collisionDistance(o,to)<0&&collisionDistance(o,to)<collisionDistance(o,from));}
