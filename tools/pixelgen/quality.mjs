import {compositeAll} from './document.mjs';
import {sequencesFor,duration,playbackOrder} from './animation.mjs';
export function qualityReport(p){
 compositeAll(p);const used=new Set(),warnings=[],frames=p.frames.map((f,index)=>{
  const a=f.indices,seen=new Uint8Array(a.length);let minX=p.width,minY=p.height,maxX=-1,maxY=-1,count=0,islands=0,single=0;
  for(let i=0;i<a.length;i++)if(a[i]){used.add(a[i]);count++;const x=i%p.width,y=Math.floor(i/p.width);minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);
   if(!seen[i]){const q=[i];seen[i]=1;let head=0;while(head<q.length){const v=q[head++],vx=v%p.width,vy=Math.floor(v/p.width);for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const x=vx+dx,y=vy+dy,n=y*p.width+x;if(x>=0&&x<p.width&&y>=0&&y<p.height&&a[n]&&!seen[n]){seen[n]=1;q.push(n);}}}islands++;if(q.length===1)single++;}
  }
  const bounds=count?{x:minX,y:minY,w:maxX-minX+1,h:maxY-minY+1}:null;
  if(!count)warnings.push(`Quadro ${index+1}: vazio.`);if(single)warnings.push(`Quadro ${index+1}: ${single} pixel(s) isolado(s); confira se são detalhes intencionais.`);
  if(count&&(minX===0||minY===0||maxX===p.width-1||maxY===p.height-1))warnings.push(`Quadro ${index+1}: pixels tocam a borda.`);
  return {name:f.name,duration:duration(f),opaquePixels:count,bounds,groundY:count?maxY:null,components:islands,isolatedPixels:single};
 });
 const sequences=sequencesFor(p).map(s=>{const a=frames.slice(s.start,s.end+1),grounds=a.map(f=>f.groundY).filter(v=>v!==null),variation=grounds.length?Math.max(...grounds)-Math.min(...grounds):0;
  if(variation>2)warnings.push(`${s.name}: apoio vertical varia ${variation} px; confira saltos ou deslizamento.`);
  return {...s,totalMs:playbackOrder(s).reduce((n,i)=>n+frames[i].duration,0),groundVariation:variation};});
 return {kind:'pixelgen-quality',version:1,width:p.width,height:p.height,layers:p.layers?.length||1,colorsUsed:used.size,alpha:[0,255],frames,sequences,warnings,note:'Métricas geométricas para revisão; não validam anatomia ou qualidade do movimento.'};
}
