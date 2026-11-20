import {pointOnLevel} from './level-focus.mjs';
import {isTree} from './nature-kit.mjs';
import {neighborMask,MASKS} from './autotile.mjs';
import {terrainHeight} from './terrain-field.mjs';
export const TREE='arvore-kronasta';
export const treeCell=(a,o)=>Math.floor(o.y/32)*a.width+Math.floor(o.x/32);
const CACHE=new WeakMap();
export function prepareTrees(a){const objects=a.objects.filter(n=>isTree(n.asset)),signature=objects.map(n=>n.asset+':'+n.x+','+n.y).join(';')+'|'+a.levels.join(',')+'|'+a.ramps.join(',');const old=CACHE.get(a);if(old?.signature===signature)return old;
 const groups=new Map(),levels=new Map(),masks=new Map();for(const o of objects){const h=o.asset+'|'+terrainHeight(a,o.x,o.y).toFixed(2);levels.set(o,h);if(!groups.has(h))groups.set(h,new Set());groups.get(h).add(treeCell(a,o));}
 for(const o of objects){const cells=groups.get(levels.get(o));masks.set(o,neighborMask(a,treeCell(a,o),(x,y)=>x>=0&&y>=0&&x<a.width&&y<a.height&&cells.has(y*a.width+x)));}
 const result={signature,masks};CACHE.set(a,result);return result;
}
export function treeMask(a,o){return (CACHE.get(a)??prepareTrees(a)).masks.get(o)??0;}
export function treeRegion(a,o){const i=MASKS.indexOf(treeMask(a,o)),v=0;return {x:i%8*64,y:(Math.floor(i/8)+v*6)*96,w:64,h:96,key:o.asset+':'+i+':'+v};}
export function paintTrees(a,cell,size,erase=false,asset=TREE,level=null){const sx=cell%a.width,sy=Math.floor(cell/a.width);let changed=0;if(cell<0)return 0;
 for(let dy=0;dy<size;dy++)for(let dx=0;dx<size;dx++){const x=sx+dx,y=sy+dy;if(x>=a.width||y>=a.height)continue;if(level!==null&&!pointOnLevel(a,{x:x*32+16,y:y*32+28},level))continue;const i=y*a.width+x,old=a.objects.find(o=>isTree(o.asset)&&treeCell(a,o)===i);
  if(erase){if(old){a.objects=a.objects.filter(o=>o!==old);changed++;}continue;}
  if(old||a.ramps[i]||a.floors[i]==='water'||a.objects.length>=1500)continue;
  a.objects.push({id:a.nextId++,asset,x:x*32+16,y:y*32+28,flip:false,layer:'vegetation',collidable:true});changed++;
 }if(changed)CACHE.delete(a);return changed;
}
export function treeSample(source){const a=structuredClone(source);a.objects=[];a.nextId=1;a.levels.fill(0);a.ramps.fill(null);a.floors.fill('grass');
 for(let y=2;y<12;y++)for(let x=2;x<14;x++)if(x<a.width&&y<a.height&&((x-7.5)/5.5)**2+((y-6.5)/4.8)**2<1&&!(x>=6&&x<=8&&y>=5&&y<=7))paintTrees(a,y*a.width+x,1);
 for(const [x,y]of [[16,3],[18,6],[16,9]])if(x<a.width&&y<a.height)paintTrees(a,y*a.width+x,1);
 if(a.width>21&&a.height>12){for(let y=9;y<=12;y++)for(let x=17;x<=21;x++)a.levels[y*a.width+x]=1;for(let x=18;x<=20;x++)paintTrees(a,10*a.width+x,1);}
 a.player={x:Math.min(a.width*32-30,470),y:Math.min(a.height*32-30,400)};return a;
}
