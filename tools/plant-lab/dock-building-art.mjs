import {pack} from './autotile.mjs';
import {png} from './png.mjs';

// Both roof pitches share the 64×32 ground axes and a front-corner anchor.
export function dockBuilding(name, kind, colors){
  const warehouse=kind==='warehouse', width=warehouse?324:196, height=warehouse?245:177;
  const data=new Uint32Array(width*height);
  const anchor=[width/2,height-5];
  const origin=[anchor[0],anchor[1]];
  const project=([u,v,z])=>[origin[0]+(u-v)*32,origin[1]+(u+v)*16-z];
  const fill=(points,color)=>{
    const corners=points.map(project),pixel=pack(color);
    const minY=Math.max(0,Math.floor(Math.min(...corners.map(p=>p[1]))));
    const maxY=Math.min(height,Math.ceil(Math.max(...corners.map(p=>p[1]))));
    for(let y=minY;y<maxY;y++){
      const edges=[];
      for(let i=0;i<corners.length;i++){
        const [x0,y0]=corners[i], [x1,y1]=corners[(i+1)%corners.length];
        if((y0>y+.5)===(y1>y+.5))continue;
        edges.push(x0+(x1-x0)*(y+.5-y0)/(y1-y0));
      }
      edges.sort((a,b)=>a-b);
      if(edges.length===2)data.fill(pixel,y*width+Math.max(0,Math.ceil(edges[0]-.5)),y*width+Math.min(width,Math.ceil(edges[1]-.5)));
    }
  };
  const u=warehouse?4.65:2.75,v=warehouse?4.65:2.75;
  const base=warehouse?0:14, eaves=warehouse?83:50, ridge=eaves+(warehouse?32:25);
  const front=(a,b,z0,z1,color)=>fill([[a,0,z0],[b,0,z0],[b,0,z1],[a,0,z1]],color);
  const side=(a,b,z0,z1,color)=>fill([[0,a,z0],[0,b,z0],[0,b,z1],[0,a,z1]],color);
  const outline='#293038';
  if(base){
    for(const [x,y] of [[-u+.18,0],[-.18,0],[0,-v+.18],[0,-.18]]){
      fill([[x-.14,y,0],[x+.09,y,0],[x+.09,y,base],[x-.14,y,base]],'#4a352a');
    }
  }
  front(-u,0,base,eaves,outline);
  side(-v,0,base,eaves,outline);
  front(-u+.025,-.025,base+2,eaves-1,colors.front);
  side(-v+.025,-.025,base+2,eaves-1,colors.side);
  for(let z=base+6;z<eaves;z+=6){
    front(-u+.04,-.04,z,z+1,colors.trim);
    side(-v+.04,-.04,z,z+1,colors.trim);
  }
  for(const x of warehouse?[-3.67,-1.8]:[-1.42]){
    const opening=warehouse?1.45:.62;
    front(x-opening/2,x+opening/2,base+1,eaves-10,outline);
    front(x-opening/2+.06,x+opening/2-.06,base+2,eaves-14,warehouse?'#54656a':'#52615e');
    if(warehouse)for(let z=base+6;z<eaves-14;z+=5)front(x-opening/2+.06,x+opening/2-.06,z,z+1,'#253742');
  }
  for(const x of warehouse?[-3.35,-2.1,-.9]:[-2.13,-.55]){
    side(x-.28,x+.28,eaves-26,eaves-12,outline);
    side(x-.22,x+.22,eaves-24,eaves-14,'#75b9b6');
    side(x-.22,x+.22,eaves-21,eaves-19,'#345861');
  }
  fill([[-u,0,eaves],[-u/2,0,ridge],[0,0,eaves]],colors.side);
  const over=.13;
  fill([[-u-over,-v-over,eaves],[-u/2,-v-over,ridge],[-u/2,over,ridge],[-u-over,over,eaves]],colors.roofDark);
  fill([[-u/2,-v-over,ridge],[over,-v-over,eaves],[over,over,eaves],[-u/2,over,ridge]],colors.roof);
  for(let y=-v;y<0;y+=warehouse?.19:.24){
    fill([[-u/2,y,ridge],[over,y,eaves],[over,y+.035,eaves],[-u/2,y+.035,ridge]],colors.roofDark);
  }
  fill([[-u/2,-v-over,ridge+1],[-u/2+.045,-v-over,ridge-2],[-u/2+.045,over,ridge-2],[-u/2,over,ridge+1]],colors.highlight);
  fill([[-u-over,over,eaves],[-u/2,over,ridge],[over,over,eaves],[over,over,eaves-4],[-u/2,over,ridge-4],[-u-over,over,eaves-4]],outline);
  return {name,width,height,anchor,pixels:png({width,height,data})};
}
