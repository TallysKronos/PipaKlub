// Pointer and single-press keyboard interaction share the exact same geometry.
export function createCraftControls({canvas,tools,getState,onChange,isLocked=()=>false}){
 const buttons=[];
 for(const [id,name]of CRAFT_TOOLS){const b=document.createElement('button');b.type='button';b.className='craft-tool';b.innerHTML=craftIcon(id)+'<span>'+name+'</span><kbd>'+(buttons.length+1)+'</kbd>';b.setAttribute('aria-label',name);b.onclick=()=>{if(isLocked())return;craftSelect(getState(),id);refresh();canvas.focus({preventScroll:true});};buttons.push([id,b]);tools.append(b);}
 function point(e){const r=canvas.getBoundingClientRect();return {x:(e.clientX-r.left)*960/r.width,y:(e.clientY-r.top)*640/r.height};}
 function refresh(){const s=getState();for(const [id,b]of buttons){b.setAttribute('aria-pressed',String(id==='luz'?s.light:s.tool===id));b.disabled=isLocked()||s.paused;}onChange(s);}
 const down=e=>{if(e.button!==0||isLocked())return;canvas.focus({preventScroll:true});canvas.setPointerCapture?.(e.pointerId);craftDown(getState(),point(e));refresh();};
 const move=e=>{if(isLocked())return;craftMove(getState(),point(e));if(getState().drag)refresh();};
 const up=e=>{if(isLocked())return;craftUp(getState(),point(e));refresh();};
 const cancel=()=>{craftCancel(getState());refresh();};
 const lost=()=>{if(getState().drag)cancel();},hidden=()=>{if(document.hidden)cancel();};
 const key=e=>{if(isLocked())return;const s=getState(),step=e.shiftKey?3:10,m={ArrowUp:[0,-step],ArrowDown:[0,step],ArrowLeft:[-step,0],ArrowRight:[step,0]}[e.key];
  if(m||e.key===' '||e.key==='Escape'||/^[1-6]$/.test(e.key)){e.preventDefault();e.stopPropagation();}if(e.repeat&&e.key===' ')return;
  if(m)craftMove(s,{x:s.cursor.x+m[0],y:s.cursor.y+m[1]});
  if(e.key===' ')s.drag?craftUp(s,s.cursor):craftDown(s,s.cursor);
  if(e.key==='Escape')craftCancel(s);if(/^[1-6]$/.test(e.key))craftSelect(s,CRAFT_TOOLS[Number(e.key)-1][0]);refresh();
 };
 canvas.tabIndex=0;canvas.style.touchAction='none';canvas.addEventListener('pointerdown',down);canvas.addEventListener('pointermove',move);canvas.addEventListener('pointerup',up);canvas.addEventListener('pointercancel',cancel);canvas.addEventListener('lostpointercapture',lost);canvas.addEventListener('keydown',key);canvas.addEventListener('blur',cancel);document.addEventListener('visibilitychange',hidden);
 return {refresh,destroy(){for(const [event,fn]of [['pointerdown',down],['pointermove',move],['pointerup',up],['pointercancel',cancel],['lostpointercapture',lost],['keydown',key],['blur',cancel]])canvas.removeEventListener(event,fn);document.removeEventListener('visibilitychange',hidden);tools.replaceChildren();}};
}
