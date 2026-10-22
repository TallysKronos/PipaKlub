// Runtime helper: timing is read from the atlas. Does not change the PNG pixels.
function createSoulAnimator(atlas,image){
 let state='idle',index=0,elapsed=0;
 const logicalSize=Math.ceil(Math.max(...Object.values(atlas.frames).flatMap(f=>[f.frame.w,f.frame.h])));
 function play(name,restart=true){if(!atlas.animations[name])throw new RangeError('Animação inexistente: '+name);if(name!==state||restart){state=name;index=0;elapsed=0;}return api;}
 function update(milliseconds){let remaining=Number.isFinite(milliseconds)?Math.max(0,Math.min(milliseconds,250)):0;elapsed+=remaining;
  for(let safe=0;safe<32;safe++){const seq=atlas.animations[state],rules=atlas.playback[state],duration=rules.durations[index];if(elapsed<duration)break;elapsed-=duration;if(index+1<seq.length)index++;else if(rules.loop)index=0;else{state=rules.returnTo||'idle';index=0;}}
  return api;
 }
 function draw(ctx,x,y,size,flip=false){const f=atlas.frames[atlas.animations[state][index]].frame,scale=size/logicalSize;
  ctx.save();ctx.imageSmoothingEnabled=false;if(flip){ctx.translate(x+size,y);ctx.scale(-1,1);x=0;y=0;}
  ctx.drawImage(image,f.x,f.y,f.w,f.h,x+(size-f.w*scale)/2,y+(size-f.h*scale)/2,f.w*scale,f.h*scale);ctx.restore();
 }
 const api={play,update,draw,get state(){return state;},get index(){return index;},get frame(){return atlas.animations[state][index];}};return api;
}
