// Deterministic native-grid conversion. No DOM, network, or image smoothing.
import {duration,validateSequences} from './animation.mjs';
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export function settings(input={}){
 const n=(k,d,a,b)=>clamp(Math.round(input[k]!==''&&Number.isFinite(Number(input[k]))?Number(input[k]):d),a,b);
 return {cols:n('cols',1,1,16),rows:n('rows',1,1,16),width:n('width',48,8,256),height:n('height',64,8,256),
 colors:n('colors',32,2,255),alpha:n('alpha',128,1,255),margin:n('margin',2,0,32),specks:n('specks',0,0,16),
 tolerance:n('tolerance',28,1,150),background:['alpha','border'].includes(input.background)?input.background:'auto',
 sample:input.sample==='nearest'?'nearest':'dominant',align:input.align==='center'?'center':'feet',
 x:n('x',0,0,16384),y:n('y',0,0,16384),cropWidth:n('cropWidth',16384,1,16384),cropHeight:n('cropHeight',16384,1,16384)};
}
export function cleanSource(source,opt){
 const {width:w,height:h}=source;
 if(!Number.isInteger(w)||!Number.isInteger(h)||w<1||h<1||w*h>16777216||source.data.length!==w*h*4)throw Error('Imagem inválida ou maior que 16 megapixels.');
 const data=new Uint8ClampedArray(source.data),mask=new Uint8Array(w*h);
 let transparent=0;for(let i=0;i<mask.length;i++){mask[i]=data[i*4+3]>=opt.alpha?1:0;if(!mask[i])transparent++;}
 const remove=opt.background==='border'||(opt.background==='auto'&&transparent/mask.length<.01);
 if(remove){
  const corners=[0,w-1,(h-1)*w,w*h-1].map(i=>[data[i*4],data[i*4+1],data[i*4+2]]);
  const bg=[0,1,2].map(c=>corners.map(v=>v[c]).sort((a,b)=>a-b)[1]);
  const seen=new Uint8Array(w*h),queue=new Int32Array(w*h);let head=0,tail=0;
  const add=i=>{if(seen[i])return;seen[i]=1;let d=0;for(let c=0;c<3;c++)d+=(data[i*4+c]-bg[c])**2;
   if(!mask[i]||d<=opt.tolerance**2){queue[tail++]=i;mask[i]=0;}};
  for(let x=0;x<w;x++){add(x);add((h-1)*w+x);}for(let y=0;y<h;y++){add(y*w);add(y*w+w-1);}
  while(head<tail){const i=queue[head++],x=i%w,y=Math.floor(i/w);if(x)add(i-1);if(x<w-1)add(i+1);if(y)add(i-w);if(y<h-1)add(i+w);}
 }
 for(let i=0;i<mask.length;i++){data[i*4+3]=mask[i]?255:0;if(!mask[i])data.fill(0,i*4,i*4+3);}
 return {data,mask,width:w,height:h};
}
function boundsOf(mask,w,rect){
 let left=rect.x+rect.w,top=rect.y+rect.h,right=-1,bottom=-1;
 for(let y=rect.y;y<rect.y+rect.h;y++)for(let x=rect.x;x<rect.x+rect.w;x++)if(mask[y*w+x]){left=Math.min(left,x);top=Math.min(top,y);right=Math.max(right,x);bottom=Math.max(bottom,y);}
 return right<0?null:{x:left,y:top,w:right-left+1,h:bottom-top+1};
}
function pixelSample(source,x0,y0,x1,y1,mode){
 const {width:w,height:h,data,mask}=source;
 if(mode==='nearest'){
  const x=clamp(Math.floor((x0+x1)/2),0,w-1),y=clamp(Math.floor((y0+y1)/2),0,h-1),i=y*w+x;
  return mask[i]?[data[i*4],data[i*4+1],data[i*4+2],255]:[0,0,0,0];
 }
 const groups=new Map();let used=0,total=0;
 // Sample a regular footprint; cost is bounded even for large source cells.
 const nx=Math.min(8,Math.max(1,Math.ceil(x1-x0))),ny=Math.min(8,Math.max(1,Math.ceil(y1-y0)));
 for(let sy=0;sy<ny;sy++)for(let sx=0;sx<nx;sx++){
  const x=clamp(Math.floor(x0+(sx+.5)*(x1-x0)/nx),0,w-1),y=clamp(Math.floor(y0+(sy+.5)*(y1-y0)/ny),0,h-1),i=y*w+x;total++;
  if(!mask[i])continue;used++;
  const r=data[i*4],g=data[i*4+1],b=data[i*4+2],key=(r>>3)*1024+(g>>3)*32+(b>>3);
  const v=groups.get(key)||[0,0,0,0];v[0]++;v[1]+=r;v[2]+=g;v[3]+=b;groups.set(key,v);
 }
 if(used/total<.4)return [0,0,0,0];
 let best=null;for(const v of groups.values())if(!best||v[0]>best[0])best=v;
 return [Math.round(best[1]/best[0]),Math.round(best[2]/best[0]),Math.round(best[3]/best[0]),255];
}
function removeSpecks(data,w,h,limit){
 if(!limit)return;
 const seen=new Uint8Array(w*h),queue=new Int32Array(w*h);
 for(let i=0;i<w*h;i++){
  if(seen[i]||!data[i*4+3])continue;let head=0,tail=1;queue[0]=i;seen[i]=1;
  while(head<tail){const p=queue[head++],x=p%w,y=Math.floor(p/w);
   for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const a=x+dx,b=y+dy;if(a<0||a>=w||b<0||b>=h)continue;const q=b*w+a;
    if(!seen[q]&&data[q*4+3]){seen[q]=1;queue[tail++]=q;}}}
  if(tail<=limit)for(let q=0;q<tail;q++)data.fill(0,queue[q]*4,queue[q]*4+4);
 }
}
export function makePalette(images,count){
 const hist=new Map();for(const image of images)for(let i=0;i<image.length;i+=4)if(image[i+3]){
  const key=(image[i]<<16)|(image[i+1]<<8)|image[i+2];hist.set(key,(hist.get(key)||0)+1);}
 if(!hist.size)return [[0,0,0,0]];
 let boxes=[Array.from(hist,([key,n])=>({rgb:[key>>16,(key>>8)&255,key&255],n}))];
 const summary=box=>{const min=[255,255,255],max=[0,0,0];let n=0;
  for(const c of box){n+=c.n;for(let k=0;k<3;k++){min[k]=Math.min(min[k],c.rgb[k]);max[k]=Math.max(max[k],c.rgb[k]);}}
  const ranges=max.map((v,k)=>v-min[k]);return {n,axis:ranges.indexOf(Math.max(...ranges)),score:Math.max(...ranges)*Math.sqrt(n)};};
 while(boxes.length<count){let at=-1,score=-1;
  boxes.forEach((b,i)=>{const s=summary(b);if(b.length>1&&s.score>score){score=s.score;at=i;}});if(at<0)break;
  const box=boxes.splice(at,1)[0],s=summary(box);box.sort((a,b)=>a.rgb[s.axis]-b.rgb[s.axis]);
  let weight=0,cut=1;for(let i=0;i<box.length-1;i++){weight+=box[i].n;cut=i+1;if(weight>=s.n/2)break;}
  boxes.push(box.slice(0,cut),box.slice(cut));
 }
 const palette=boxes.map(b=>{const sum=[0,0,0];let n=0;for(const c of b){n+=c.n;for(let k=0;k<3;k++)sum[k]+=c.rgb[k]*c.n;}return [...sum.map(v=>Math.round(v/n)),255];});
 palette.sort((a,b)=>(a[0]*.299+a[1]*.587+a[2]*.114)-(b[0]*.299+b[1]*.587+b[2]*.114));
 return [[0,0,0,0],...palette.filter((p,i)=>!palette.slice(0,i).some(q=>p.slice(0,3).every((v,k)=>v===q[k])))];
}
export function convert(source,input={}){
 const opt=settings(input),frames=[];
 if(opt.width*opt.height*opt.cols*opt.rows>1048576)throw Error('Use até 1 milhão de pixels nativos por projeto. Reduza os quadros ou a resolução.');
 const clean=cleanSource(source,opt);
 const x=Math.min(opt.x,source.width-1),y=Math.min(opt.y,source.height-1),cw=Math.min(opt.cropWidth,source.width-x),ch=Math.min(opt.cropHeight,source.height-y);
 if(cw<opt.cols||ch<opt.rows)throw Error('O recorte é menor que a grade.');
 if(opt.margin*2>=Math.min(opt.width,opt.height))throw Error('Reduza a margem do quadro.');
 for(let row=0;row<opt.rows;row++)for(let col=0;col<opt.cols;col++){
  const left=x+Math.floor(col*cw/opt.cols),top=y+Math.floor(row*ch/opt.rows);
  const rect={x:left,y:top,w:x+Math.floor((col+1)*cw/opt.cols)-left,h:y+Math.floor((row+1)*ch/opt.rows)-top};
  frames.push({row,col,rect,bounds:boundsOf(clean.mask,source.width,rect)});
 }
 const rgba=frames.map(f=>{
  const data=new Uint8ClampedArray(opt.width*opt.height*4);if(!f.bounds)return data;
  // All frames in a row share one scale; each row can represent a different character.
  const group=frames.filter(q=>q.row===f.row&&q.bounds),maxW=Math.max(...group.map(q=>q.bounds.w)),maxH=Math.max(...group.map(q=>q.bounds.h));
  const scale=Math.min((opt.width-opt.margin*2)/maxW,(opt.height-opt.margin*2)/maxH);
  const w=Math.max(1,Math.round(f.bounds.w*scale)),h=Math.max(1,Math.round(f.bounds.h*scale));
  const ox=Math.floor((opt.width-w)/2),oy=opt.align==='feet'?opt.height-opt.margin-h:Math.floor((opt.height-h)/2);
  for(let py=0;py<h;py++)for(let px=0;px<w;px++){
   const v=pixelSample(clean,f.bounds.x+px*f.bounds.w/w,f.bounds.y+py*f.bounds.h/h,
    f.bounds.x+(px+1)*f.bounds.w/w,f.bounds.y+(py+1)*f.bounds.h/h,opt.sample);
   data.set(v,((oy+py)*opt.width+ox+px)*4);
  }
  removeSpecks(data,opt.width,opt.height,opt.specks);return data;
 });
 const palette=makePalette(rgba,opt.colors),cache=new Map();
 const indexed=rgba.map((data,i)=>{const indices=new Uint8Array(opt.width*opt.height);
  for(let p=0;p<indices.length;p++)if(data[p*4+3]){
   const rgb=[data[p*4],data[p*4+1],data[p*4+2]],key=(rgb[0]<<16)|(rgb[1]<<8)|rgb[2];
   if(!cache.has(key)){let best=1,dist=Infinity;for(let c=1;c<palette.length;c++){
    const d=(rgb[0]-palette[c][0])**2*.299+(rgb[1]-palette[c][1])**2*.587+(rgb[2]-palette[c][2])**2*.114;if(d<dist){dist=d;best=c;}}
    cache.set(key,best);}indices[p]=cache.get(key);
  }
  return {name:`linha-${frames[i].row+1}-${['frente','esquerda','direita','costas'][frames[i].col]||'quadro-'+(frames[i].col+1)}`,
   row:frames[i].row,col:frames[i].col,indices,sourceRect:frames[i].rect,sourceBounds:frames[i].bounds};});
 return {kind:'pixelgen',version:1,width:opt.width,height:opt.height,cols:opt.cols,rows:opt.rows,palette,frames:indexed,settings:opt};
}
export function pixels(project,frame){
 const data=new Uint8ClampedArray(project.width*project.height*4);
 for(let i=0;i<frame.indices.length;i++)data.set(project.palette[frame.indices[i]],i*4);return data;
}
export function audit(project){
 const colors=new Set(),warnings=[];let edge=0,empty=0;
 for(const f of project.frames){let count=0;for(let i=0;i<f.indices.length;i++)if(f.indices[i]){count++;colors.add(f.indices[i]);
  const x=i%project.width,y=Math.floor(i/project.width);if(!x||!y||x===project.width-1||y===project.height-1)edge++;}
  if(!count)empty++;}
 if(empty)warnings.push(`${empty} quadro(s) vazio(s): confira recorte e transparência.`);
 if(edge)warnings.push(`${edge} pixel(s) na borda: confira cortes e margem.`);
 return {colors:colors.size,frames:project.frames.length,empty,edge,alpha:'0 / 255',warnings};
}
export function serialize(project){const {source,...native}=project;return {...native,frames:project.frames.map(f=>({...f,indices:Array.from(f.indices)}))};}
export function validateProject(p){
 if(p?.kind!=='pixelgen'||p.version!==1)throw Error('Projeto Pixelgen inválido ou versão não suportada.');
 for(const key of ['width','height'])if(!Number.isInteger(p[key])||p[key]<1||p[key]>256)throw Error('Dimensões de projeto inválidas.');
 if(!Number.isInteger(p.cols)||!Number.isInteger(p.rows)||p.cols<1||p.rows<1||p.cols>16||p.rows>16)throw Error('Grade inválida.');
 if(p.width*p.height*p.cols*p.rows>1048576)throw Error('Projeto excede 1 milhão de pixels nativos.');
 if(!Array.isArray(p.frames)||!p.frames.length||p.frames.length>p.cols*p.rows||p.frames.length>256)throw Error('Número de quadros inválido.');
 if(!Array.isArray(p.palette)||p.palette.length<1||p.palette.length>256||p.palette.some((c,i)=>!Array.isArray(c)||c.length!==4||c.some(v=>!Number.isInteger(v)||v<0||v>255)||c[3]!== (i?255:0)))throw Error('Paleta inválida.');
 const frames=p.frames.map((f,i)=>{
  if(!Array.isArray(f.indices)||f.indices.length!==p.width*p.height||f.indices.some(v=>!Number.isInteger(v)||v<0||v>=p.palette.length))throw Error('Pixels de quadro inválidos.');
  return {...f,name:String(f.name||`quadro-${i+1}`).slice(0,80),duration:duration(f),row:Math.floor(i/p.cols),col:i%p.cols,indices:Uint8Array.from(f.indices)};
 });const {source,...native}=p;return {...native,name:String(p.name||'Projeto').slice(0,80),frames,sequences:validateSequences(p.sequences,frames.length)};
}
