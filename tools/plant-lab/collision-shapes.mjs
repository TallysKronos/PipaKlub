export function validateCollision(raw){
 if(!raw||!['circle','rect','polygon'].includes(raw.shape))throw Error('Formato de colisão inválido.');
 const number=(v,min,max)=>Number.isFinite(v)&&v>=min&&v<=max;
 const x=raw.x??0,y=raw.y??0;if(!number(x,-128,128)||!number(y,-128,128))throw Error('Deslocamento de colisão inválido.');
 if(raw.shape==='circle'){if(!number(raw.radius,1,256))throw Error('Raio entre 1 e 256.');return {shape:'circle',x,y,radius:raw.radius};}
 if(raw.shape==='rect'){if(!number(raw.width,1,512)||!number(raw.height,1,512))throw Error('Tamanho de colisão inválido.');return {shape:'rect',x,y,width:raw.width,height:raw.height};}
 if(!Array.isArray(raw.points)||raw.points.length<3||raw.points.length>16||raw.points.some(p=>!Array.isArray(p)||p.length!==2||!p.every(n=>number(n,-256,256))))throw Error('Polígono: 3 a 16 pontos [x,y], entre -256 e 256.');
 let area=0;raw.points.forEach((p,i)=>{const q=raw.points[(i+1)%raw.points.length];area+=p[0]*q[1]-q[0]*p[1];});if(Math.abs(area)<1)throw Error('O polígono precisa ter área.');return {shape:'polygon',x,y,points:raw.points.map(p=>[...p])};
}
export function collisionDistance(o,p){
 const c=o.collision??{shape:'circle',radius:12},x=p.x-o.x-(c.x??0),y=p.y-o.y-(c.y??0);
 if(c.shape==='circle')return Math.hypot(x,y)-c.radius;
 if(c.shape==='rect'){const dx=Math.abs(x)-c.width/2,dy=Math.abs(y)-c.height/2;return Math.hypot(Math.max(0,dx),Math.max(0,dy))+Math.min(Math.max(dx,dy),0);}
 let inside=false,d=Infinity;for(let i=0,j=c.points.length-1;i<c.points.length;j=i++){
  const a=c.points[j],b=c.points[i];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])inside=!inside;
  const vx=b[0]-a[0],vy=b[1]-a[1],t=Math.max(0,Math.min(1,((x-a[0])*vx+(y-a[1])*vy)/(vx*vx+vy*vy||1)));d=Math.min(d,Math.hypot(x-a[0]-t*vx,y-a[1]-t*vy));
 }return inside?-d:d;
}
