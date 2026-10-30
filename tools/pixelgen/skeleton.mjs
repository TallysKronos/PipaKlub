// Pose-only rig: integer joints guide drawing; no raster rotation or resampling.
export const JOINTS=['topo','queixo','pescoco','ombroTras','cotoveloTras','maoTras','ombroFrente','cotoveloFrente','maoFrente','quadril','joelhoTras','peTras','joelhoFrente','peFrente'];
export const PARENTS={quadril:null,pescoco:'quadril',queixo:'pescoco',topo:'queixo',ombroTras:'pescoco',cotoveloTras:'ombroTras',maoTras:'cotoveloTras',ombroFrente:'pescoco',cotoveloFrente:'ombroFrente',maoFrente:'cotoveloFrente',joelhoTras:'quadril',peTras:'joelhoTras',joelhoFrente:'quadril',peFrente:'joelhoFrente'};
export const CHAINS=[['ombroTras','cotoveloTras','maoTras'],['ombroFrente','cotoveloFrente','maoFrente'],['quadril','joelhoTras','peTras'],['quadril','joelhoFrente','peFrente']];
export const ANCHORS={cabelo:'topo',gola:'pescoco',cinto:'quadril',acessorioTras:'maoTras',acessorioFrente:'maoFrente'};
const copy=p=>Object.fromEntries(Object.entries(p).map(([k,v])=>[k,[...v]]));
const distance=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
const mid=(a,b)=>a.map((v,i)=>Math.round((v+b[i])/2));
export function validateSupport(value,pose){
 if(value==null)return undefined;
 if(!Array.isArray(value)||value.length>2||value.some(k=>!['peTras','peFrente'].includes(k)||(pose&&!pose[k]))||new Set(value).size!==value.length)throw Error('Apoio inválido: use peTras e/ou peFrente com posição marcada.');
 return [...value];
}
export function completeSkeleton(pose){
 if(!pose?.quadril||!pose.queixo)throw Error('Marque quadril e queixo antes de completar o esqueleto.');
 const out=copy(pose);
 out.pescoco??=pose.ombroTras&&pose.ombroFrente?mid(pose.ombroTras,pose.ombroFrente):mid(pose.queixo,pose.quadril);
 for(const [root,joint,end]of CHAINS)if(out[root]&&out[end])out[joint]??=mid(out[root],out[end]);
 return out;
}
// Analytic two-bone IK. Unreachable targets stop at reach; keep the previous bend side.
export function solveChain(root,joint,end,target){
 const a=distance(root,joint),b=distance(joint,end);if(a<.1||b<.1)throw Error('Osso sem comprimento: separe as juntas.');
 const dx=target[0]-root[0],dy=target[1]-root[1],requested=Math.hypot(dx,dy);
 const d=Math.max(Math.abs(a-b)+.001,Math.min(a+b-.001,requested)),angle=requested?Math.atan2(dy,dx):Math.atan2(end[1]-root[1],end[0]-root[0]);
 const cross=(end[0]-root[0])*(joint[1]-root[1])-(end[1]-root[1])*(joint[0]-root[0]);
 const bend=cross<0?-1:1,along=(a*a-b*b+d*d)/(2*d),height=Math.sqrt(Math.max(0,a*a-along*along)),ux=Math.cos(angle),uy=Math.sin(angle);
 return {joint:[Math.round(root[0]+ux*along-uy*height*bend),Math.round(root[1]+uy*along+ux*height*bend)],end:[Math.round(root[0]+ux*d),Math.round(root[1]+uy*d)]};
}
export function moveSkeletonJoint(original,key,target,{width,height,support=[]}={}){
 const pose=completeSkeleton(original);if(!pose[key])throw Error('Junta inexistente.');
 if(!Array.isArray(target)||target.length!==2||target.some(n=>!Number.isFinite(n)))throw Error('Destino inválido.');
 support=validateSupport(support)||[];
 const chain=CHAINS.find(c=>c[2]===key);
 if(chain){if(support.includes(key))throw Error('Solte o apoio desse pé antes de movê-lo.');const result=solveChain(...chain.map(k=>pose[k]),target);pose[chain[1]]=result.joint;pose[key]=result.end;}
 else if(key==='quadril'){
  const dx=Math.round(target[0])-pose[key][0],dy=Math.round(target[1])-pose[key][1];
  for(const pt of Object.values(pose)){pt[0]+=dx;pt[1]+=dy;}
 }else{
  const parent=PARENTS[key],origin=pose[parent];if(!origin)throw Error('Falta a junta pai.');
  const angle=Math.atan2(target[1]-origin[1],target[0]-origin[0])-Math.atan2(pose[key][1]-origin[1],pose[key][0]-origin[0]);
  const descendants=k=>{for(let p=k;p;p=PARENTS[p])if(p===key)return true;return false;};
  for(const k of Object.keys(pose))if(descendants(k)){const [x,y]=pose[k],dx=x-origin[0],dy=y-origin[1];pose[k]=[Math.round(origin[0]+dx*Math.cos(angle)-dy*Math.sin(angle)),Math.round(origin[1]+dx*Math.sin(angle)+dy*Math.cos(angle))];}
 }
 for(const foot of support){
  const c=CHAINS.find(c=>c[2]===foot),target=original[foot];if(!target)throw Error('Pé de apoio sem posição.');
  const result=solveChain(...c.map(k=>pose[k]),target);
  if(distance(result.end,target)>1)throw Error('Apoio fora do alcance: aproxime o quadril ou solte o pé.');
  pose[c[1]]=result.joint;pose[foot]=[...target];
 }
 for(const v of Object.values(pose))if(v[0]<0||v[1]<0||v[0]>=width||v[1]>=height)throw Error('Movimento ultrapassa a célula; a pose foi preservada.');
 return pose;
}
export function skeletonReport(p){
 const errors=[],warnings=[],frames=[];
 for(const f of p.frames){if(!f.pose)continue;const bones={};for(const [joint,parent]of Object.entries(PARENTS))if(parent&&f.pose[joint]&&f.pose[parent]){const length=distance(f.pose[joint],f.pose[parent]);bones[joint]=length;if(length===0)warnings.push(`${f.name}: osso ${parent} → ${joint} sem comprimento.`);}
  frames.push({name:f.name,bones,support:f.support||[],anchors:Object.fromEntries(Object.entries(ANCHORS).filter(([,j])=>f.pose[j]).map(([a,j])=>[a,[...f.pose[j]]]))});
 }
 for(const seq of p.sequences||[]){const reference=p.frames[seq.start];if(!reference?.pose)continue;
  for(let i=seq.start+1;i<=seq.end;i++){const f=p.frames[i],previous=p.frames[i-1];for(const foot of f.support||[])if(previous.support?.includes(foot)&&previous.pose?.[foot]&&f.pose?.[foot]&&distance(previous.pose[foot],f.pose[foot])>1)warnings.push(`${f.name}: ${foot} mudou de posição durante o apoio; confira chão e câmera.`);
   for(const [joint,parent]of Object.entries(PARENTS)){if(!parent||!reference.pose[joint]||!reference.pose[parent]||!f.pose?.[joint]||!f.pose[parent])continue;const a=distance(reference.pose[joint],reference.pose[parent]),b=distance(f.pose[joint],f.pose[parent]);if(Math.abs(a-b)>Math.max(2,a*.2))warnings.push(`${f.name}: comprimento de ${parent} → ${joint} varia; confira perspectiva.`);}
  }
 }
 return {errors,warnings,frames,note:'Esqueleto guia a pose; os pixels e as juntas ainda precisam de desenho e revisão em 1×.'};
}
export function paintSkeleton(ctx,pose,scale,offsetX=0,support=[]){
 if(!pose)return;ctx.save();ctx.lineWidth=2;ctx.setLineDash?.([]);
 const pos=k=>[offsetX+(pose[k][0]+.5)*scale,(pose[k][1]+.5)*scale];
 for(const [joint,parent]of Object.entries(PARENTS))if(parent&&pose[parent]&&pose[joint]){ctx.strokeStyle=joint.includes('Tras')?'#69a9dd':'#ffd879';ctx.beginPath();ctx.moveTo(...pos(parent));ctx.lineTo(...pos(joint));ctx.stroke();}
 for(const key of Object.keys(pose)){const [x,y]=pos(key),r=Math.max(2,Math.min(4,scale/3));ctx.fillStyle='#142032';ctx.fillRect(x-r-1,y-r-1,r*2+2,r*2+2);ctx.fillStyle=support.includes(key)?'#75f5a7':'#fff0c5';ctx.fillRect(x-r,y-r,r*2,r*2);}
 ctx.restore();
}
function facing(p,index){return p.frames[index].name.match(/-(SO|NO|NE|SE|S|O|N|E)-\d+(?:-copia)*$/)?.[1]||(p.sequences||[]).find(s=>index>=s.start&&index<=s.end)?.name.match(/-(SO|NO|NE|SE|S|O|N|E)$/)?.[1]||null;}
export function skeletonTemplate(p,index=0){const f=p.frames[index];return {kind:'pixelgen-skeleton',version:1,width:p.width,height:p.height,body:p.style?.body,direction:facing(p,index),pose:completeSkeleton(f.pose),support:[...(f.support||[])],parents:PARENTS,anchors:ANCHORS};}
export function applySkeletonTemplate(p,index,template){
 if(template?.kind!=='pixelgen-skeleton'||template.version!==1||template.width!==p.width||template.height!==p.height||template.body!==p.style?.body)throw Error('Esqueleto incompatível com célula ou tipo de corpo.');
 if(template.direction!==facing(p,index))throw Error('Use um esqueleto da mesma direção.');
 const pose=completeSkeleton(template.pose);for(const [key,v]of Object.entries(pose))if(!JOINTS.includes(key)||v.length!==2||v.some(n=>!Number.isInteger(n))||v[0]<0||v[1]<0||v[0]>=p.width||v[1]>=p.height)throw Error('Esqueleto contém junta inválida.');
 const support=validateSupport(template.support)||[];p.frames[index].pose=pose;p.frames[index].support=support;
}
