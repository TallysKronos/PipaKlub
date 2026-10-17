// Android-style intermediate-node capture, shared by pointer and keyboard input.
export function extendSummonPath(path,node){
 if(!Number.isInteger(node)||node<1||node>9||path.includes(node))return [...path];
 const result=[...path],last=result.at(-1);
 if(last){const ax=(last-1)%3,ay=Math.floor((last-1)/3),bx=(node-1)%3,by=Math.floor((node-1)/3);
  if((ax+bx)%2===0&&(ay+by)%2===0){const mid=(ay+by)/2*3+(ax+bx)/2+1;if(!result.includes(mid)&&mid!==node)result.push(mid);}
 }
 result.push(node);return result;
}
export function sampleSummonSegment(path,a,b,radius=28){
 const dx=b.x-a.x,dy=b.y-a.y,length=dx*dx+dy*dy;
 const hits=[];
 for(let node=1;node<=9;node++){
  if(path.includes(node))continue;
  const x=50+(node-1)%3*100,y=50+Math.floor((node-1)/3)*100;
  const t=length?Math.max(0,Math.min(1,((x-a.x)*dx+(y-a.y)*dy)/length)):0;
  if(Math.hypot(a.x+t*dx-x,a.y+t*dy-y)<=radius)hits.push({node,t});
 }
 hits.sort((a,b)=>a.t-b.t);
 return hits.reduce((result,hit)=>extendSummonPath(result,hit.node),path);
}
