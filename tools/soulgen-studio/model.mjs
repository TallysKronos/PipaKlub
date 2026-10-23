// Soulgen Studio runtime v1. Browser and game Canvas share this exact sampler.
export const CHANNELS=['x','y','rotation','scaleX','scaleY'];
export const identity=()=>({x:0,y:0,rotation:0,scaleX:1,scaleY:1});
// linear: straight; smooth: stops at each key; spline: passes through keys without stopping (Catmull-Rom/Hermite).
export const EASES=['linear','smooth','spline'];
export const clone=value=>JSON.parse(JSON.stringify(value));
const safeId=id=>typeof id==='string'&&/^[a-z][a-zA-Z0-9_-]{0,63}$/.test(id)&&!['__proto__','constructor','prototype','root'].includes(id);
const finite=value=>typeof value==='number'&&Number.isFinite(value);
function validateInternal(project){
 const errors=[],warnings=[];const fail=s=>errors.push(s);
 if(project?.schema!=='soulgen-studio'||project.version!==1)return {ok:false,errors:['Formato de projeto não reconhecido.'],warnings};
 if(typeof project.name!=='string'||project.name.length>120)fail('Nome de projeto inválido.');
 if(!finite(project.width)||!finite(project.height)||project.width<16||project.height<16||project.width>2048||project.height>2048)fail('Montagem deve ter entre 16 e 2048 unidades.');
 if(!Array.isArray(project.rootPivot)||project.rootPivot.length!==2||!project.rootPivot.every(finite))fail('Pivô global inválido.');
 if(!project.assets||Array.isArray(project.assets)||Object.keys(project.assets).length>64)fail('Biblioteca inválida ou acima de 64 imagens.');
 for(const [id,a]of Object.entries(project.assets||{})){
  if(!safeId(id)||!a||!finite(a.width)||!finite(a.height)||a.width<1||a.height<1||a.width>8192||a.height>8192)fail('Imagem inválida: '+id);
  if(typeof a?.src!=='string'||a.src.length>24e6||!(/^data:image\/png;base64,[A-Za-z0-9+/=]+$/.test(a.src)||/^\/art\/soulgen\/keys\/[a-zA-Z0-9_/-]+\.png$/.test(a.src)&&!a.src.includes('..')))fail('Fonte de imagem não permitida: '+id);
 }
 if(Object.values(project.assets||{}).reduce((n,a)=>n+(a?.src?.length||0),0)>36e6)fail('Biblioteca acima de 36 MB.');
 if(Object.values(project.assets||{}).reduce((n,a)=>n+(a?.width*a?.height||0),0)>32e6)fail('Biblioteca acima de 32 milhões de pixels.');
 const parts=project.parts;if(!Array.isArray(parts)||parts.length>48)return {ok:false,errors:[...errors,'Lista de peças inválida.'],warnings};if(!parts.length)fail('Adicione uma peça PNG para completar o rig.');
 const ids=new Set();
 for(const p of parts){
  if(!safeId(p.id)||ids.has(p.id))fail('ID de peça inválido ou repetido.');ids.add(p.id);
  if(!Object.hasOwn(project.assets||{},p.asset))fail('Imagem ausente em '+p.id);
  const a=project.assets?.[p.asset],s=p.source;
  if(!Array.isArray(s)||s.length!==4||!s.every(finite)||s[0]<0||s[1]<0||s[2]<=0||s[3]<=0||a&&(s[0]+s[2]>a.width||s[1]+s[3]>a.height))fail('Recorte fora da fonte: '+p.id);
  if(!Array.isArray(p.rect)||p.rect.length!==4||!p.rect.every(finite)||p.rect[2]<=0||p.rect[3]<=0)fail('Tamanho/posição inválidos: '+p.id);
  if(!Array.isArray(p.pivot)||p.pivot.length!==2||!p.pivot.every(finite)||!finite(p.z))fail('Pivô/profundidade inválidos: '+p.id);
  if(p.lag!=null&&(!finite(p.lag)||p.lag<0||p.lag>1))fail('Atraso deve ficar entre 0 e 1 s: '+p.id);
  for(const w of p.faceWindows||[])if(!Array.isArray(w)||w.length!==4||!w.every(finite)||w[0]<0||w[1]<0||w[2]<=0||w[3]<=0||w[0]+w[2]>p.source[2]||w[1]+w[3]>p.source[3])fail('Janela facial fora do recorte: '+p.id);
  for(const [face,ref]of Object.entries(p.faces||{}))if(!safeId(face)||!project.assets?.[ref.asset]||!Array.isArray(ref.source)||ref.source.length!==4||!ref.source.every(finite)||ref.source[0]<0||ref.source[1]<0||ref.source[2]<=0||ref.source[3]<=0||ref.source[0]+ref.source[2]>project.assets[ref.asset].width||ref.source[1]+ref.source[3]>project.assets[ref.asset].height)fail('Expressão inválida: '+p.id+'/'+face);
 }
 for(const p of parts){let at=p,seen=new Set();while(at?.parent){if(seen.has(at.id)){fail('Ciclo de parentesco em '+p.id);break;}seen.add(at.id);at=parts.find(x=>x.id===at.parent);if(!at){fail('Peça pai inexistente em '+p.id);break;}}}
 if(!project.clips||Array.isArray(project.clips)||Object.keys(project.clips).length>32)fail('Lista de animações inválida.');
 for(const [id,c]of Object.entries(project.clips||{})){
  if(!safeId(id)||!finite(c.seconds)||c.seconds<=0||c.seconds>30||typeof c.loop!=='boolean'){fail('Duração/animação inválida: '+id);continue;}
  if(c.hitTime!=null&&(!finite(c.hitTime)||c.hitTime<0||c.hitTime>c.seconds))fail('Impacto fora da ação: '+id);
  if(!Array.isArray(c.frames)||!c.frames.length||c.frames.length>2000){fail('Quadros-chave inválidos: '+id);continue;}
  let previous=-1;
  for(const f of c.frames){if(!finite(f.t)||f.t<0||f.t>c.seconds+1e-6||f.t<=previous)fail('Tempos repetidos ou fora de ordem: '+id);previous=f.t;
   if(!f.values||Array.isArray(f.values))fail('Canais ausentes: '+id);
   for(const [part,values]of Object.entries(f.values||{})){if(part!=='root'&&!ids.has(part))fail('Canal sem peça: '+part);for(const [key,v]of Object.entries(values||{}))if(!CHANNELS.includes(key)||!finite(v)||Math.abs(v)>10000||(key.startsWith('scale')&&(v<=0||v>10)))fail('Transformação inválida: '+part+'/'+key);}
   if(f.ease!=null&&!EASES.includes(f.ease))fail('Interpolação desconhecida: '+id);
  }
  if(c.loop&&JSON.stringify(c.frames[0].values)!==JSON.stringify(c.frames.at(-1).values))warnings.push(id+': início e fim diferentes; revise o encontro do ciclo.');
  for(const w of c.expressions||[])if(!finite(w.start)||!finite(w.end)||w.start<0||w.end>w.seconds&&w.seconds!=null||w.end>c.seconds||w.start>=w.end||typeof w.face!=='string'||w.face!=='normal'&&!parts.some(p=>p.faces?.[w.face]))fail('Janela de expressão inválida: '+id);
 }
 if(!Object.keys(project.clips||{}).length)fail('Crie ao menos uma animação.');
 const recommended=project.avatar?.kind==='kael-modular-v1'?['idle','walk','run','wave','hurt','victory']:['idle','flight','skill','hurt','victory'];
 for(const id of recommended)if(!project.clips?.[id])warnings.push('Animação recomendada ausente: '+id);
 return {ok:!errors.length,errors:[...new Set(errors)],warnings:[...new Set(warnings)]};
}
export function normalizeTime(clip,time){const t=finite(time)?time:0;return clip.loop?((t%clip.seconds)+clip.seconds)%clip.seconds:Math.max(0,Math.min(t,clip.seconds));}
// Values of one track at clip time t. Spline tangents come from the neighbouring keys (wrapping on loops);
// one-shot clips settle with zero tangent at their first and last key.
export function trackAt(c,id,t){
 const frames=c.frames,v=f=>({...identity(),...f.values[id]});if(t<=frames[0].t)return v(frames[0]);if(t>=frames.at(-1).t)return v(frames.at(-1));
 const i=frames.findIndex(f=>f.t>t),a=frames[i-1],b=frames[i],h=b.t-a.t,av=v(a),bv=v(b);let u=h?(t-a.t)/h:0;
 if(a.ease!=='spline'){if(a.ease==='smooth')u=u*u*(3-2*u);return Object.fromEntries(CHANNELS.map(k=>[k,av[k]+(bv[k]-av[k])*u]));}
 const n=frames.length,prev=i-2>=0?{f:frames[i-2],dt:0}:c.loop&&n>2?{f:frames[n-2],dt:-c.seconds}:null,next=i+1<n?{f:frames[i+1],dt:0}:c.loop&&n>2?{f:frames[1],dt:c.seconds}:null;
 const u2=u*u,u3=u2*u,h00=2*u3-3*u2+1,h10=u3-2*u2+u,h01=-2*u3+3*u2,h11=u3-u2;
 return Object.fromEntries(CHANNELS.map(k=>{const ma=prev?(bv[k]-v(prev.f)[k])/(b.t-(prev.f.t+prev.dt)):0,mb=next?(v(next.f)[k]-av[k])/((next.f.t+next.dt)-a.t):0;return [k,h00*av[k]+h10*h*ma+h01*bv[k]+h11*h*mb];}));
}
export function sample(project,clipId,time){
 const c=project.clips[clipId];if(!c)throw Error('Animação inexistente.');const t=normalizeTime(c,time),values={root:trackAt(c,'root',t)};
 // A part's lag delays its own channels (follow-through); the body still leads.
 for(const p of project.parts)values[p.id]=trackAt(c,p.id,p.lag?normalizeTime(c,c.loop?t-p.lag:Math.max(0,t-p.lag)):t);
 const window=(c.expressions||[]).find(w=>t>=w.start&&t<w.end);return {t,values,face:window?.face||'normal',done:!c.loop&&time>=c.seconds,hit:c.hitTime!=null&&Math.abs(t-c.hitTime)<1/60};
}
export function putKey(project,clipId,time,values,ease='smooth'){
 const c=project.clips[clipId],t=Math.round(Math.max(0,Math.min(c.seconds,time))*1000)/1000,index=c.frames.findIndex(f=>Math.abs(f.t-t)<.0005),frame={t,ease,values:clone(values)};
 if(index>=0)c.frames[index]=frame;else c.frames.push(frame);c.frames.sort((a,b)=>a.t-b.t);delete c.simplified;
}
export function multiply(a,b){return [a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]];}
export function point(m,x,y){return {x:m[0]*x+m[2]*y+m[4],y:m[1]*x+m[3]*y+m[5]};}
export function transform(v,pivot){const a=v.rotation*Math.PI/180,cos=Math.cos(a),sin=Math.sin(a),[px,py]=pivot,m=[cos*v.scaleX,sin*v.scaleX,-sin*v.scaleY,cos*v.scaleY,0,0];m[4]=px+v.x-m[0]*px-m[2]*py;m[5]=py+v.y-m[1]*px-m[3]*py;return m;}
export function matrices(project,pose){const root=transform(pose.values.root||identity(),project.rootPivot),result={};function build(p){if(result[p.id])return result[p.id];const parent=p.parent?build(project.parts.find(q=>q.id===p.parent)):root;return result[p.id]=multiply(parent,transform(pose.values[p.id]||identity(),p.pivot));}for(const p of project.parts)build(p);return result;}
export function render(ctx,project,images,pose,{clear=true,scale,offsetX=0,offsetY=0,facing=1}={}){
 if(clear)ctx.clearRect(0,0,ctx.canvas.width,ctx.canvas.height);const s=scale??Math.min(ctx.canvas.width/project.width,ctx.canvas.height/project.height),m=matrices(project,pose);
 ctx.save();ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';ctx.translate(ctx.canvas.width/2+offsetX,ctx.canvas.height/2+offsetY);ctx.scale(s*facing,s);ctx.translate(-project.width/2,-project.height/2);
 for(const p of [...project.parts].sort((a,b)=>a.z-b.z)){if(p.visible===false)continue;const face=p.faces?.[pose.face],asset=face?.asset||p.asset,source=face?.source||p.source,image=images[asset];if(!image)continue;ctx.save();ctx.transform(...m[p.id]);ctx.drawImage(image,...source,...p.rect);ctx.restore();}ctx.restore();return m;
}
export function exportPlan(project,{fps=12,cell=256,columns=8,clipIds=Object.keys(project.clips)}={}){
 const check=validate(project);if(!check.ok)throw Error(check.errors.join('\n'));if(!Number.isInteger(fps)||fps<1||fps>60||![128,256,512].includes(cell)||!Number.isInteger(columns)||columns<1||columns>16)throw Error('Configuração de exportação inválida.');
 const frames=[],animations={};for(const id of clipIds){const c=project.clips[id];if(!c)throw Error('Animação inexistente.');const count=Math.ceil(c.seconds*fps)+(c.loop?0:1),sequence=[];for(let i=0;i<count;i++){const index=frames.length,name=id+'-'+String(i).padStart(3,'0'),time=Math.min(i/fps,c.seconds);frames.push({name,clip:id,time,x:index%columns*cell,y:Math.floor(index/columns)*cell,w:cell,h:cell,duration:1000/fps});sequence.push(name);}animations[id]={frames:sequence,loop:c.loop,seconds:c.seconds,hitTime:c.hitTime??null,hitFrame:c.hitTime==null?null:Math.min(count-1,Math.round(c.hitTime*fps))};}
 const width=Math.min(columns,frames.length)*cell,height=Math.ceil(frames.length/columns)*cell;if(!frames.length||width>8192||height>8192||frames.length>2048)throw Error('Atlas muito grande. Reduza FPS, célula ou quantidade de ações.');
 const scale=cell/Math.max(project.width,project.height)*.9;return {schema:'soulgen-atlas-v1',width,height,fps,cell,frames,animations,pivot:clone(project.rootPivot),pixelPivot:{x:cell/2+(project.rootPivot[0]-project.width/2)*scale,y:cell/2+(project.rootPivot[1]-project.height/2)*scale},renderScale:scale,logicalSize:[project.width,project.height]};
}
export class History{
 constructor(limit=40){this.limit=limit;this.past=[];this.future=[];}
 push(project){this.past.push(clone(project));if(this.past.length>this.limit)this.past.shift();this.future=[];}
 undo(current){if(!this.past.length)return null;this.future.push(clone(current));return this.past.pop();}
 redo(current){if(!this.future.length)return null;this.past.push(clone(current));return this.future.pop();}
}

export function validate(project){try{return validateInternal(project);}catch{return {ok:false,errors:['Estrutura de projeto inválida. Confira peças, fontes e animações.'],warnings:[]};}}
