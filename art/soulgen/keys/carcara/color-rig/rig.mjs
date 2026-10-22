// Animate the generated full-colour cutouts directly. No palette swap, per-frame
// raster rotation, integer snapping or misregistered expression overlays.
// Facial variants share the exact original body alpha and all nonfacial pixels.
export const parts = {
  body: { source: [96,87,280,361], rect: [35,24,26,34] },
  wingFar: { source: [920,172,251,227], rect: [21,33,18,18], pivot: [37,41] },
  wingNear: { source: [490,136,291,273], rect: [54,32,23,21], pivot: [56,41] },
  tail: { source: [98,539,299,286], rect: [45,54,24,20], pivot: [48,56] },
};
export const clips = {
  idle: { label: 'Repouso', seconds: 3.2, loop: true },
  flight: { label: 'Voo', seconds: 1.2, loop: true },
  skill: { label: 'Golpe', seconds: 2, loop: false, hitTime: .74 },
  hurt: { label: 'Dano', seconds: 1.1, loop: false },
  victory: { label: 'Vitória', seconds: 2.4, loop: false },
};
const tau = Math.PI * 2;
const rest = { x:0,y:0,lean:0,near:0,far:0,tail:0 };
const smooth = t => t*t*(3-2*t);
export function expression(name,seconds) {
  if(name==='skill' && seconds>=.22 && seconds<1.65)return 'fierce';
  if(name==='hurt' && seconds>=.03 && seconds<.72)return 'hurt';
  if(name==='victory' && seconds>=.25 && seconds<2.08)return 'happy';
  return 'normal';
}
function timeline(frames,t) {
  if(t<=frames[0].t)return Object.fromEntries(Object.keys(rest).map(k=>[k,frames[0][k]??0]));
  if(t>=frames.at(-1).t)return Object.fromEntries(Object.keys(rest).map(k=>[k,frames.at(-1)[k]??0]));
  const i=frames.findIndex(f=>f.t>t),a={...rest,...frames[i-1]},b={...rest,...frames[i]};
  const u=smooth((t-a.t)/(b.t-a.t));
  return Object.fromEntries(Object.keys(rest).map(k=>[k,a[k]+(b[k]-a[k])*u]));
}
export function pose(name,seconds) {
  const c=clips[name];if(!c)throw new Error('Unknown clip '+name);
  const t=c.loop ? ((seconds%c.seconds)+c.seconds)%c.seconds : Math.max(0,Math.min(seconds,c.seconds));
  const phase=t/c.seconds*tau;
  if(name==='idle') return {x:0,y:-.7*Math.sin(phase),lean:.8*Math.sin(phase),
    near:3*Math.sin(phase),far:-2.5*Math.sin(phase),tail:4*Math.sin(phase)};
  if(name==='flight')return {x:0,y:-1.3*Math.sin(phase),lean:-5,
    near:25*Math.sin(phase),far:-21*Math.sin(phase),tail:7*Math.sin(phase)};
  if(name==='skill') return timeline([
    {t:0},{t:.4,x:3,y:1,lean:9,near:-23,far:19,tail:-7},
    {t:.74,x:-8,y:-2,lean:-16,near:26,far:-22,tail:14},
    {t:1.1,x:-6,y:-1,lean:-10,near:17,far:-14,tail:8},
    {t:1.65,x:-1,y:0,lean:0,near:2,far:-2,tail:-3},{t:2}
  ],t);
  if(name==='hurt')return timeline([
    {t:0},{t:.1,x:3,y:1,lean:8,near:14,far:-12,tail:-9},
    {t:.23,x:1,lean:-3,near:7,far:-7,tail:6},
    {t:.4,x:2,lean:2,near:3,far:-3,tail:-4},{t:.72,x:.5,tail:2},{t:1.1}
  ],t);
  return timeline([
    {t:0},{t:.55,y:-4,lean:-2,near:-20,far:17,tail:5},
    {t:1.05,y:-5,near:-9,far:8,tail:-5},
    {t:1.55,y:-3,lean:2,near:-18,far:15,tail:5},{t:2.4}
  ],t);
}
export function render(ctx,image,name,seconds,options={}) {
  const p=pose(name,seconds), {width,height}=ctx.canvas;
  ctx.clearRect(0,0,width,height);
  ctx.save();
  const scale=options.scale??Math.min(width,height)/96;
  ctx.translate(width/2,height/2);ctx.scale(scale,scale);ctx.translate(-48,-48);
  ctx.translate(48+p.x,42+p.y);ctx.rotate(p.lean*Math.PI/180);ctx.translate(-48,-42);
  ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
  const faceBody=options.faces?.[expression(name,seconds)];
  const paint=(name,angle=0)=>{
    const item=parts[name];ctx.save();
    if(item.pivot){const [x,y]=item.pivot;ctx.translate(x,y);ctx.rotate(angle*Math.PI/180);ctx.translate(-x,-y);}
    if(name==='body' && faceBody){ctx.drawImage(faceBody,0,0,faceBody.width,faceBody.height,...item.rect);}
    else ctx.drawImage(image,...item.source,...item.rect);
    ctx.restore();
  };
  paint('tail',p.tail);paint('wingFar',p.far);paint('body');paint('wingNear',p.near);
  ctx.restore();
}
