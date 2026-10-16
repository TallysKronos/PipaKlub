export function createFrameHealth(){
  let start=null,count=0,slowWindows=0;
  function sample(now,active=true){
    if(!active){start=null;count=0;slowWindows=0;return null;}
    if(start===null){start=now;return null;}
    count++;
    if(now-start<1000)return null;
    const fps=Math.round(count*1000/(now-start));
    slowWindows=fps<40?slowWindows+1:0;
    start=now;count=0;
    return {fps,needsLight:slowWindows>=2};
  }
  return {sample};
}
