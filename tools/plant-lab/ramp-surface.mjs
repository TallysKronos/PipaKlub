// Continuous group coordinates: adjoining ramp cells share one surface, not two curbs.
export function rampSpan(a,i){const horizontal=['e','w'].includes(a.ramps[i]),step=horizontal?a.width:1,axis=horizontal?Math.floor(i/a.width):i%a.width,limit=horizontal?a.height:a.width;let left=i,right=i;const same=j=>j>=0&&j<a.levels.length&&a.ramps[j]===a.ramps[i]&&a.levels[j]===a.levels[i];while((horizontal?Math.floor(left/a.width):left%a.width)>0&&same(left-step))left-=step;while((horizontal?Math.floor(right/a.width):right%a.width)<limit-1&&same(right+step))right+=step;return {left:(horizontal?Math.floor(left/a.width):left%a.width)*32,width:((right-left)/step+1)*32,...(horizontal?{horizontal:true}:{})};}
export function rampSurface(color,x,y,width){
 const t=(y+.5)/32,blend=Math.min(1,(y+1)/5,(32-y)/5),edge=Math.min(x,width-1-x);
 // A shaded incline, with short transverse erosion marks rather than staircase risers.
 let factor=1-blend*(.13+.12*t);
 if(edge<3)factor=1-blend*([.48,.27,.08][edge]);
 else if(edge===3)factor=1+blend*.12;
 else if(y%8===4&&x>7&&x<width-8&&((x+Math.floor(y/8)*7)%23)<11)factor-=.065*blend;
 const r=Math.min(255,Math.round((color&255)*factor)),g=Math.min(255,Math.round((color>>>8&255)*factor)),b=Math.min(255,Math.round((color>>>16&255)*factor));
 return(r|g<<8|b<<16|255<<24)>>>0;
}
