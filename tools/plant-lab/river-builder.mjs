import {clone,validateLayout} from './model.mjs';import {focusAllows,protectedChange} from './level-focus.mjs';import {waterfallGeometry} from './waterfalls.mjs';
export function buildRiver(a,from,to,{width=1,depth=1,seed=1,focus=null}={}){
 if(from<0||to<0)return {valid:false,message:'Escolha a nascente e o poço.'};const sx=from%a.width,sy=Math.floor(from/a.width),tx=to%a.width,ty=Math.floor(to/a.width);
 if(ty-sy<4)return {valid:false,message:'O poço precisa ficar ao menos quatro tiles ao sul da nascente.'};if(a.levels[to]>a.levels[from])return {valid:false,message:'O destino não pode estar acima da nascente.'};
 const next=clone(a),cells=new Set(),pool=Math.max(0,a.levels[to]-depth),radius=width+2,falls=[];next.waterDepth=next.waterDepth??Array(a.levels.length).fill(0);next.flow=next.flow??Array(a.levels.length).fill(null);
 if(tx-radius<1||ty-radius<1||tx+radius>=a.width-1||ty+radius>=a.height-1)return {valid:false,message:'Afaste o poço da borda do mapa para fechar as margens.'};
 const paint=(x,y,h)=>{if(x<0||y<0||x>=a.width||y>=a.height)return;const i=y*a.width+x;if(!focusAllows(a,i,focus))throw Error('O rio alcança outro andar protegido.');cells.add(i);next.floors[i]='water';next.levels[i]=h;next.ramps[i]=null;if(next.stairs)next.stairs[i]=false;next.waterDepth[i]=Math.min(3,Math.max(1,depth));next.flow[i]='s';};
 try{
  for(let y=ty-radius;y<=ty+radius;y++)for(let x=tx-radius;x<=tx+radius;x++)if(((x-tx)/(radius+.5))**2+((y-ty)/(radius+.5))**2<=1)paint(x,y,pool);
  let previous=Math.max(pool,a.levels[from]-depth),lastX=sx;
  for(let y=sy;y<=ty;y++){
   const t=(y-sy)/(ty-sy),bend=Math.sin(t*Math.PI)*Math.sin(Number(seed)*1.7)*1.5;let x=Math.round(sx+(tx-sx)*t+bend);x=Math.max(width+1,Math.min(a.width-width-2,x));
   const original=a.levels[y*a.width+x],h=y>=ty-radius?pool:Math.max(pool,Math.min(previous,original-depth));if(h<previous)x=lastX;
   for(let dx=-Math.ceil(width/2);dx<=Math.ceil(width/2);dx++)paint(x+dx,y,h);
   if(h<previous)falls.push({x:x*32+16,y:y*32});previous=h;lastX=x;
  }
  next.ramps.forEach((r,i)=>{if(r&&cells.has(i))next.ramps[i]=null;});
  for(const point of falls){const asset=width===1?'cachoeira-fina':width===2?'cachoeira-dupla':'cachoeira-ampla',o={id:next.nextId++,asset,...point,flip:false,layer:'objects',collidable:false};if(waterfallGeometry(next,o))next.objects.push(o);}
  const issue=protectedChange(a,next,focus);if(issue)return {valid:false,message:issue};return {valid:true,next:validateLayout(next),cells:[...cells],changed:true,message:'Rio e poço rebaixado · '+(next.objects.length-a.objects.length)+' queda(s) encaixada(s)'};
 }catch(error){return {valid:false,message:error.message};}
}
