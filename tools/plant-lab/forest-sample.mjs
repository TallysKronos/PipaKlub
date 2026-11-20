import {clone,validateLayout,PLANTS} from './model.mjs';
export function forestSample(source,{keepObjects=true}={}){
 const a=clone(source),w=a.width,h=a.height;if(w<22||h<12)throw Error('A amostra precisa de um mapa com pelo menos 22 × 12 células.');
 a.floors.fill('grass');a.levels.fill(0);a.ramps.fill(null);a.cliffs.fill('earth');a.autotiling=true;
 const set=(x,y,z,material='earth')=>{a.levels[y*w+x]=z;a.cliffs[y*w+x]=material;};
 const path=(x,y)=>{a.floors[y*w+x]='dirt';};
 for(let y=3;y<=6;y++)for(let x=2;x<=9;x++)if(!((y===3||y===6)&&(x===2||x===9)))set(x,y,1);
 for(let y=2;y<=3;y++)for(let x=4;x<=7;x++)set(x,y,2);
 for(let y=2;y<=5;y++)for(let x=16;x<=21;x++)if(!((y===2||y===5)&&(x===16||x===21)))set(x,y,2,'rock');
 for(let y=6;y<=7;y++)for(let x=17;x<=20;x++)set(x,y,1,'rock');
 for(let x=0;x<w;x++){const cy=10+Math.round(Math.sin(x*.3));for(let y=cy-1;y<=cy+1;y++)if(y>=0&&y<h)path(x,y);}
 for(const x of [5,6]){for(let y=2;y<=10;y++)path(x,y);set(x,4,1);a.ramps[4*w+x]='n';set(x,7,0);a.ramps[7*w+x]='n';}
 for(const x of [18,19]){for(let y=3;y<=10;y++)path(x,y);set(x,6,1,'rock');a.ramps[6*w+x]='n';set(x,8,0,'rock');a.ramps[8*w+x]='n';}
 for(const [x,y]of [[17,3],[20,3],[17,4],[20,4]])a.floors[y*w+x]='stone';
 if(!keepObjects){
 const specs=[[2,65,61],[3,110,63],[0,184,51],[4,288,65],[1,343,61],[2,402,65],[3,467,66],[0,704,69],[4,734,159],[2,480,163],[3,444,207],[1,324,230],[5,108,208],[2,84,279],[0,252,283],[3,323,289],[4,482,284],[2,706,305],[1,739,368],[3,663,426],[4,595,448],[0,527,462],[2,461,435],[3,395,457],[4,319,438],[1,251,462],[3,111,444],[2,66,420],[0,92,365],[1,425,264],[5,669,208],[2,708,241]];
 a.player={x:370,y:351};a.objects=specs.map(([asset,x,y],i)=>{const candidates=[];for(let dy=-56;dy<=56;dy+=8)for(let dx=-56;dx<=56;dx+=8){const px=x+dx,py=y+dy;if(px<20||py<30||px>w*32-20||py>h*32-20)continue;const cell=Math.floor(py/32)*w+Math.floor(px/32);if(a.floors[cell]==='grass'&&!a.ramps[cell]&&Math.hypot(px-a.player.x,py-a.player.y)>42)candidates.push({x:px,y:py,d:dx*dx+dy*dy});}const p=candidates.sort((a,b)=>a.d-b.d)[0]??{x,y};return {id:i+1,asset:PLANTS[asset].id,x:p.x,y:p.y,flip:i%3===0,layer:'vegetation',collidable:false};});
 }
 return validateLayout(a);
}

