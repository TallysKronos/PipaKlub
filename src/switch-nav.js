// Pure helpers for the controller layer: shared by the page and the tests.
export function createSwitchNav(){
 const DEADZONE=.22;
 // Standard Gamepad API button order (Xbox layout; Steam Deck and most pads report it).
 const BUTTONS={a:0,b:1,x:2,y:3,lb:4,rb:5,lt:6,rt:7,view:8,start:9,ls:10,rs:11,up:12,down:13,left:14,right:15};
 const GLYPHS={
  xbox:{actionX:'xbox-x',actionY:'xbox-y',confirm:'xbox-a',back:'xbox-b',attack:'xbox-a',dodge:'xbox-b',maneuver:'xbox-x',side:'xbox-y',skill:'xbox-lb',skillRight:'xbox-rb',pause:'xbox-menu',menu:'xbox-menu',tabLeft:'xbox-lb',tabRight:'xbox-rb',move:'stick',navigate:'dpad'},
  ps:{actionX:'ps-square',actionY:'ps-triangle',confirm:'ps-cross',back:'ps-circle',attack:'ps-cross',dodge:'ps-circle',maneuver:'ps-square',side:'ps-triangle',skill:'ps-l1',skillRight:'ps-r1',pause:'ps-options',menu:'ps-options',tabLeft:'ps-l1',tabRight:'ps-r1',move:'stick',navigate:'dpad'},
  keyboard:{actionX:'key-x',actionY:'key-y',confirm:'key-enter',back:'key-escape',attack:'key-space',dodge:'key-shift',maneuver:'key-r',side:'mouse-right',skill:'key-q',skillRight:'key-e',pause:'key-escape',menu:'key-escape',tabLeft:'key-q',tabRight:'key-e',move:'key-w',navigate:'key-tab'},
  touch:{actionX:'touch-tap',actionY:'touch-tap',confirm:'touch-tap',back:'back',attack:'touch-tap',dodge:'touch-tap',maneuver:'hold',side:'touch-tap',skill:'touch-drag',skillRight:'touch-drag',pause:'touch-tap',menu:'touch-tap',tabLeft:'touch-tap',tabRight:'touch-tap',move:'touch-drag',navigate:'touch-tap'}
 };
 // DualShock/DualSense report Sony ids; everything else (Xbox, Steam Deck, generic XInput) uses the Xbox glyphs.
 const padKind=id=>/054c|sony|playstation|dualshock|dualsense|wireless controller/i.test(id||'')?'ps':'xbox';
 const glyphSet=device=>device==='gamepad-ps'?GLYPHS.ps:device==='gamepad'||device==='gamepad-xbox'?GLYPHS.xbox:GLYPHS[device]||GLYPHS.keyboard;
 const axis=v=>Math.abs(v)<DEADZONE?0:(v-Math.sign(v)*DEADZONE)/(1-DEADZONE);
 function stick(x,y){const ax=axis(x),ay=axis(y),m=Math.hypot(ax,ay);return m>1?{x:ax/m,y:ay/m}:{x:ax,y:ay};}
 // Spatial focus: the nearest candidate in the pressed direction, favouring ones in the same row/column.
 function pick(current,candidates,dir){
  const v={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]}[dir];if(!v)return null;
  let best=null,bestScore=Infinity;
  for(const c of candidates){
   if(c===current)continue;
   const dx=c.x-current.x,dy=c.y-current.y,along=dx*v[0]+dy*v[1],across=Math.abs(dx*v[1]-dy*v[0]);
   const overlap=v[0]?Math.min(current.bottom,c.bottom)-Math.max(current.top,c.top)>0:Math.min(current.right,c.right)-Math.max(current.left,c.left)>0;
   if(along<=2)continue;
   const score=along+across*(overlap?.5:2.5);
   if(score<bestScore){bestScore=score;best=c;}
  }
  return best;
 }
 // Edge detection with key repeat for held directions (menus feel like a console, not a typewriter).
 function repeater(first=380,next=110){
  const held=new Map();
  return (key,down,now)=>{
   if(!down){held.delete(key);return false;}
   const at=held.get(key);
   if(at===undefined){held.set(key,now+first);return true;}
   if(now>=at){held.set(key,now+next);return true;}
   return false;
  };
 }
 return {DEADZONE,BUTTONS,GLYPHS,padKind,glyphSet,stick,pick,repeater};
}
