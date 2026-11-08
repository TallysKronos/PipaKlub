import {clone,validateLayout} from './model.mjs';import {cleanRamps} from './terrain.mjs';
export function resizeMap(a,width,height){
 if(!Number.isInteger(width)||!Number.isInteger(height)||width<8||height<8||width>64||height>64)throw Error('Dimensões entre 8×8 e 64×64.');const next={...clone(a),width,height},n=width*height;
 for(const [key,fill]of [['variants',null],['floors','grass'],['levels',0],['ramps',null],['rampProfiles',null],['cliffs','earth'],['stairs',false],['waterDepth',0],['flow',null],['campaignBlocked',false]]){if(!a[key]&&!['floors','levels','ramps','cliffs'].includes(key))continue;next[key]=Array(n).fill(fill);for(let y=0;y<Math.min(height,a.height);y++)for(let x=0;x<Math.min(width,a.width);x++)next[key][y*width+x]=a[key][y*a.width+x];}
 next.objects=a.objects.filter(o=>o.x<width*32&&o.y<height*32);if(a.events)next.events=a.events.filter(e=>e.x<width*32&&e.y<height*32).map(e=>({...e,route:e.route.filter(p=>p.x<width*32&&p.y<height*32)}));next.player={x:Math.min(a.player.x,width*32-16),y:Math.min(a.player.y,height*32-16)};cleanRamps(next);if(next.stairs)next.stairs=next.stairs.map((v,i)=>!!v&&!!next.ramps[i]);
 return {next:validateLayout(next),removedObjects:a.objects.length-next.objects.length,removedEvents:(a.events?.length??0)-(next.events?.length??0)};
}
