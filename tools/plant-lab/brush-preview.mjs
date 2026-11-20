import {focusAllows,focusLocked} from './level-focus.mjs';
import {rasterPlan,surfacePainters} from './terrain-raster.mjs';
import {floorBrushCells,fillFloor} from './studio.mjs';
import {paintFaces} from './wall-kit.mjs';

// Geometry is unchanged by material painting. Reuse its ownership/depth buffers
// and the commit renderer's samplers rather than rasterizing a second world.
export function materialPreview(a,{tool,cell,size=1,material,level=a.levels[cell],kind='top',focus=null,cellsOverride=null}){
 const invalid=message=>({valid:false,message});
 if(cell<0||cell>=a.floors.length)return invalid('Aponte para o mapa.');
 if(!focusAllows(a,cell,focus))return invalid('Andar protegido. Escolha o andar '+a.levels[cell]+' ou destrave o foco.');
 if(tool==='face'&&kind!=='face')return invalid('Aponte para a lateral do barranco.');
 if(tool!=='face'&&kind!=='top')return invalid('Aponte para o piso, acima ou abaixo do barranco.');
 const next={...a,floors:[...a.floors],cliffs:[...a.cliffs]};let cells;
 if(tool==='face'){
  paintFaces(next,cell,size,material,focusLocked(focus)?focus.level:null);cells=new Set();
  for(let dy=0;dy<size;dy++)for(let dx=0;dx<size;dx++){const x=cell%a.width+dx,y=Math.floor(cell/a.width)+dy;if(x<a.width&&y<a.height)if(focusAllows(a,y*a.width+x,focus))cells.add(y*a.width+x);}
 }else{
  if(a.levels[cell]!==level)return invalid('Pincelada protegida na cota '+level+'. Solte e clique para trocar de andar.');
  cells=new Set(cellsOverride?cellsOverride.filter(i=>a.levels[i]===level&&focusAllows(a,i,focus)):tool==='fill'?[cell]:floorBrushCells(a,cell,size,level));
  if(tool==='fill'){fillFloor(next,cell,material);cells=new Set(next.floors.flatMap((k,i)=>k!==a.floors[i]?[i]:[]));if(!cells.size)cells.add(cell);}
  else for(const i of cells)next.floors[i]=material;
 }
 const affected=new Set(cells);
 if(tool!=='face')for(const i of cells)for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const x=i%a.width+dx,y=Math.floor(i/a.width)+dy;if(x>=0&&y>=0&&x<a.width&&y<a.height)affected.add(y*a.width+x);}
 const r=rasterPlan(a),{pixel,faceColor}=surfacePainters(next,r.heights,r.width,r.worldHeight),data=new Uint32Array(r.width*r.height),mask=new Uint8Array(data.length);
 let minX=r.width,minY=r.height,maxX=-1,maxY=-1,changed=0;
 for(let n=0;n<data.length;n++){
  const i=r.owner[n];if(!affected.has(i))continue;
  const face=!!r.kind[n];if(tool==='face'&&!face)continue;
  const x=n%r.width,sy=Math.floor(n/r.width)-r.pad,y=Math.floor(r.depth[n]-(face?1:.5));
  const color=face?faceColor(i,x,y,r.zmap[n],sy):pixel(i,x,y),before=face?r.faces[n]:r.top[n];
  const selected=cells.has(i)&&(tool==='face'?face:!face);
  if(selected)mask[n]=1;
  if(color!==before){data[n]=color;changed++;}
  if(selected||color!==before){minX=Math.min(minX,x);maxX=Math.max(maxX,x);minY=Math.min(minY,sy+r.pad);maxY=Math.max(maxY,sy+r.pad);}
 }
 if(maxX<0)return invalid('Não há superfície visível neste ponto.');
 return {valid:true,message:changed?'Prévia · clique para aplicar':'Material já aplicado · escolha outro para trocar',width:r.width,height:r.height,pad:r.pad,data,mask,bounds:{x:minX,y:minY-r.pad,width:maxX-minX+1,height:maxY-minY+1},cells:[...cells],changed};
}
