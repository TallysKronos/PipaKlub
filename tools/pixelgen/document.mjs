// Native indexed layers. indices is the visible composite; cels remain editable.
export const MAX_CEL_PIXELS=4194304;
export function compositeFrame(p,f){
 if(!f.cels)return f.indices;
 const out=new Uint8Array(p.width*p.height);
 p.layers.forEach((layer,n)=>{if(layer.visible===false)return;const cel=f.cels[n];for(let i=0;i<out.length;i++)if(cel[i])out[i]=cel[i];});
 f.indices=out;return out;
}
export function compositeAll(p){for(const f of p.frames)compositeFrame(p,f);return p;}
export function upgrade(p){
 if(!p.layers)p.layers=[{name:'Pixels',visible:true,locked:false}];
 for(const f of p.frames)if(!f.cels)f.cels=p.layers.map((_,i)=>i?new Uint8Array(p.width*p.height):f.indices.slice());
 p.version=2;return compositeAll(p);
}
export function cloneDocument(p){return {...p,style:p.style?{...p.style}:undefined,layers:p.layers?.map(l=>({...l})),settings:p.settings?{...p.settings}:undefined,sequences:p.sequences?.map(s=>({...s})),ramps:p.ramps?Object.fromEntries(Object.entries(p.ramps).map(([k,v])=>[k,[...v]])):undefined,sheet:p.sheet?structuredClone(p.sheet):undefined,frames:p.frames.map(f=>({...f,indices:f.indices.slice(),cels:f.cels?.map(c=>c.slice()),support:f.support?[...f.support]:undefined,pose:f.pose?structuredClone(f.pose):undefined}))};}
export function editable(p,layer){if(!p.layers[layer])throw Error('Selecione uma camada.');if(p.layers[layer].locked)throw Error('Desbloqueie a camada para editar.');if(p.layers[layer].visible===false)throw Error('Mostre a camada para editar.');}
export function layerPixels(p,frame,layer){return p.frames[frame].cels[layer];}
export function addLayer(p,after=p.layers.length-1,name='Nova camada'){
 if(p.layers.length>=8||(p.layers.length+1)*p.width*p.height*p.frames.length>MAX_CEL_PIXELS)throw Error('Limite: 8 camadas e 4 milhões de pixels de cels.');
 const at=after+1;p.layers.splice(at,0,{name,visible:true,locked:false});for(const f of p.frames)f.cels.splice(at,0,new Uint8Array(p.width*p.height));return at;
}
export function removeLayer(p,index){if(p.layers.length===1)throw Error('Mantenha pelo menos uma camada.');p.layers.splice(index,1);for(const f of p.frames)f.cels.splice(index,1);compositeAll(p);return Math.min(index,p.layers.length-1);}
export function moveLayer(p,index,delta){const to=index+delta;if(to<0||to>=p.layers.length)return index;[p.layers[index],p.layers[to]]=[p.layers[to],p.layers[index]];for(const f of p.frames)[f.cels[index],f.cels[to]]=[f.cels[to],f.cels[index]];compositeAll(p);return to;}
export function rect(p,r){if(!r)return {x:0,y:0,w:p.width,h:p.height};const x=Math.max(0,Math.min(p.width-1,Math.floor(r.x))),y=Math.max(0,Math.min(p.height-1,Math.floor(r.y)));return {x,y,w:Math.max(1,Math.min(p.width-x,Math.floor(r.w))),h:Math.max(1,Math.min(p.height-y,Math.floor(r.h)))};}
export function extract(p,frame,layer,selection,all=false){
 editable(p,layer);if(!selection)throw Error('Selecione a região com a ferramenta Seleção.');const area=rect(p,selection),to=addLayer(p,layer,'Parte recortada');
 for(const [index,f] of p.frames.entries()){if(!all&&index!==frame)continue;for(let y=area.y;y<area.y+area.h;y++)for(let x=area.x;x<area.x+area.w;x++){const i=y*p.width+x;f.cels[to][i]=f.cels[layer][i];f.cels[layer][i]=0;}}
 compositeAll(p);return to;
}
export function transform(p,frame,layer,selection,op,dx=0,dy=0){
 editable(p,layer);const area=rect(p,selection),cel=layerPixels(p,frame,layer),old=cel.slice();
 if(op==='move')for(let y=area.y;y<area.y+area.h;y++)for(let x=area.x;x<area.x+area.w;x++)cel[y*p.width+x]=0;
 for(let y=0;y<area.h;y++)for(let x=0;x<area.w;x++){
  const a=op==='flip-x'?area.x+area.w-1-x:area.x+x+dx,b=op==='flip-y'?area.y+area.h-1-y:area.y+y+dy;
  if(a>=0&&a<p.width&&b>=0&&b<p.height)cel[b*p.width+a]=old[(area.y+y)*p.width+area.x+x];
 }compositeFrame(p,p.frames[frame]);
}
