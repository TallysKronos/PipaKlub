export function createArtAssets(config){
 const images=new Map(),loading=new Map(),atlases=config.atlases;
 const creatureNames=['carcara','mata-verde','azulao','raio-de-sol'];
 const reduced=typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion:reduce)').matches;
 function load(name,retry=false){
  if(images.has(name))return Promise.resolve(true);
  if(loading.has(name)&&!retry)return loading.get(name);
  if(typeof Image==='undefined')return Promise.resolve(false);
  const pending=new Promise(resolve=>{const image=new Image();image.decoding='async';image.onload=()=>{images.set(name,image);resolve(true);};image.onerror=()=>resolve(false);image.src=atlases[name].meta.url;});loading.set(name,pending);return pending;
 }
 function draw(context,name,frame,x,y,width,height,fit=false){
  const image=images.get(name),def=atlases[name]?.frames[frame];if(!image||!def)return false;
  const f=def.frame,b=def.contentBounds,r=fit?{x:f.x+b.x,y:f.y+b.y,w:b.w,h:b.h}:f;
  const scale=Math.min(width/r.w,height/r.h),w=r.w*scale,h=r.h*scale;
  const smoothing=context.imageSmoothingEnabled;context.imageSmoothingEnabled=false;
  context.drawImage(image,r.x,r.y,r.w,r.h,x+(width-w)/2,y+(height-h)/2,w,h);context.imageSmoothingEnabled=smoothing;return true;
 }
 function creature(context,color,time,x=-56,y=-44,size=112){
  const name=creatureNames[color]||creatureNames[0],seq=atlases['pipas-almaticas'].animations[name];
  return draw(context,'pipas-almaticas',seq[reduced?0:Math.floor(time/190)%seq.length],x,y,size,size);
 }
 function markup(color){color=Number.isInteger(color)&&color>=0&&color<4?color:0;return '<span class="almatic-icon" aria-hidden="true" style="background-image:url('+atlases['pipas-almaticas'].meta.url+');background-position:0 '+(color*100/3)+'%"></span>';}
 load('pipas-almaticas');
 return {load,draw,creature,markup,atlases,reduced};
}
