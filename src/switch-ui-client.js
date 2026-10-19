// Controller layer: gamepad in menus and battle, spatial focus, device glyphs and the command bar.
// It only drives the controls that already exist (clicks, Escape, the battle input); rules stay untouched.
const switchNav=createSwitchNav();
let inputDevice='mouse',padSynthetic=false;
const padState={x:0,y:0,cut:false,skill:0,active:false},padPrev=[],padRepeat=switchNav.repeater();
const glyphURL=id=>{const svg=ART_CONFIG.kit?.glyphs?.[id];return svg?'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(svg):'';};
function glyphImage(command,cls='kit-glyph'){const img=document.createElement('img');img.className=cls;img.alt='';img.dataset.glyph=command;img.src=glyphURL(switchNav.glyphSet(inputDevice)[command]);return img;}
function refreshGlyphs(){const set=switchNav.glyphSet(inputDevice);for(const img of document.querySelectorAll('img[data-glyph]'))img.src=glyphURL(set[img.dataset.glyph]);renderCommandBar();}
function setInputDevice(device){
 if(device===inputDevice)return;inputDevice=device;
 document.body.dataset.input=device.startsWith('gamepad')?'gamepad':device;
 refreshGlyphs();
}
addEventListener('keydown',()=>{if(!padSynthetic)setInputDevice('keyboard');},true);
addEventListener('pointerdown',e=>setInputDevice(e.pointerType==='touch'?'touch':'mouse'),true);
for(const [name,url] of Object.entries(ART_CONFIG.kit?.components||{}))document.documentElement.style.setProperty('--kit-'+name,'url("'+url+'")');

// Which layer owns the controller right now.
function battleLive(){return !!(mode&&state&&!showResult&&!pausedAt&&!skyActive&&$('pauseSheet').hidden&&$('modal').style.display!=='flex'&&!document.querySelector('.sheet:not([hidden])'));}
function visibleRect(el){const r=el.getBoundingClientRect();return r.width>1&&r.height>1&&r.bottom>0&&r.right>0&&r.top<innerHeight&&r.left<innerWidth?r:null;}
// Focusable, visible and not covered by another layer (dialogs, sheets and menus are tested by hit point).
function focusTargets(){
 const out=[];
 for(const el of document.querySelectorAll('button,a[href],input:not([type=hidden]),select,textarea,[tabindex]:not([tabindex="-1"])')){
  if(el.disabled||el.closest('[inert],[hidden],[aria-hidden=true]')||el.id==='commandBar'||el.classList.contains('pilot-command'))continue;
  const r=visibleRect(el);if(!r)continue;
  const cx=Math.min(innerWidth-1,Math.max(0,r.left+r.width/2)),cy=Math.min(innerHeight-1,Math.max(0,r.top+r.height/2)),hit=document.elementFromPoint(cx,cy);
  if(!hit||!(hit===el||el.contains(hit)||hit.contains(el)&&hit!==document.body))continue;
  out.push({el,x:r.left+r.width/2,y:r.top+r.height/2,left:r.left,right:r.right,top:r.top,bottom:r.bottom});
 }
 return out;
}
function focusPad(el){el.focus({preventScroll:true});el.scrollIntoView?.({block:'nearest',inline:'nearest'});renderCommandBar();}
const PRIMARY=['[autofocus]','#journeyContinue','#partnerConfirm','#flightNext','#trailStart','#rematchButton','#assisNext','.primary','.pk-button'];
function moveFocus(dir){
 const targets=focusTargets();if(!targets.length)return;
 const current=targets.find(t=>t.el===document.activeElement);
 // First press lands on the screen's main action when there is one, else the top-left target.
 if(!current){const first=PRIMARY.map(s=>targets.find(t=>t.el.matches(s))).find(Boolean)||targets.slice().sort((a,b)=>a.top-b.top||a.left-b.left)[0];focusPad(first.el);return;}
 const el=current.el;
 // Sliders and selects take left/right as value changes, like a console options screen.
 if((dir==='left'||dir==='right')&&el.matches('input[type=range],select')){
  const step=dir==='right'?1:-1;
  if(el.tagName==='SELECT'){const i=Math.max(0,Math.min(el.options.length-1,el.selectedIndex+step));if(i!==el.selectedIndex){el.selectedIndex=i;el.dispatchEvent(new Event('change',{bubbles:true}));}}
  else{if(step>0)el.stepUp();else el.stepDown();el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));}
  return;
 }
 const next=switchNav.pick(current,targets,dir);if(next)focusPad(next.el);
}
function confirmFocus(){
 const el=document.activeElement;
 if(!el||el===document.body||!focusTargets().some(t=>t.el===el)){moveFocus('down');return;}
 if(el.matches('input[type=text],input:not([type]),input[type=email],input[type=password],textarea')){el.select?.();return;}
 if(el.tagName==='SELECT'){moveFocus('right');return;}
 el.click();
}
function pressKey(key){padSynthetic=true;try{const target=document.activeElement&&document.activeElement!==document.body?document.activeElement:document;for(const type of ['keydown','keyup'])target.dispatchEvent(new KeyboardEvent(type,{key,bubbles:true,cancelable:true}));}finally{padSynthetic=false;}}
function goBack(){pressKey('Escape');}
// LB/RB: tabs when the screen has them, otherwise the first filter select.
function switchTab(step){
 const tabs=focusTargets().map(t=>t.el).filter(el=>el.matches('[role=tab],[data-hud-tab],[aria-pressed][data-tab],.tab-button'));
 if(tabs.length>1){const i=tabs.findIndex(el=>el.getAttribute('aria-selected')==='true'||el.getAttribute('aria-pressed')==='true'||el.classList.contains('active'));const next=tabs[(Math.max(0,i)+step+tabs.length)%tabs.length];next.click();next.focus({preventScroll:true});return;}
 const select=focusTargets().map(t=>t.el).find(el=>el.tagName==='SELECT');
 if(select){const i=(select.selectedIndex+step+select.options.length)%select.options.length;select.selectedIndex=i;select.dispatchEvent(new Event('change',{bubbles:true}));}
}
function scrollFocused(dy){let el=document.activeElement;while(el&&el!==document.body){const s=getComputedStyle(el);if(/(auto|scroll)/.test(s.overflowY)&&el.scrollHeight>el.clientHeight){el.scrollTop+=dy;return;}el=el.parentElement;}}
function startPressed(){
 if(document.body.classList.contains('in-opening')){$('openingPause').click();return;}
 if(mode){if(pausedAt||!$('pauseSheet').hidden)goBack();else openPause();return;}
 if(typeof gameMenu!=='undefined'&&playerAccount){if(gameMenu.hidden)openHomeMenu();else closeHomeMenu();}
}

function pollPads(){
 requestAnimationFrame(pollPads);
 const pads=navigator.getGamepads?.()||[];const pad=[...pads].find(p=>p&&p.connected&&p.mapping==='standard')||[...pads].find(p=>p&&p.connected);
 if(!pad){padState.active=false;padState.cut=false;padState.skill=0;padState.x=padState.y=0;return;}
 const B=switchNav.BUTTONS,down=i=>!!pad.buttons[i]?.pressed,now=performance.now();
 const pressed=i=>{const d=down(i),was=padPrev[i];padPrev[i]=d;return d&&!was;},released=i=>{const d=down(i),was=padPrev[i];padPrev[i]=d;return !d&&was;};
 const move=switchNav.stick(pad.axes[0]||0,pad.axes[1]||0),any=pad.buttons.some(b=>b.pressed)||Math.hypot(move.x,move.y)>.3;
 if(any)setInputDevice(switchNav.padKind(pad.id)==='ps'?'gamepad-ps':'gamepad-xbox');
 if(!inputDevice.startsWith('gamepad')){for(let i=0;i<pad.buttons.length;i++)padPrev[i]=down(i);return;}
 if(typeof openingWalkActive==='function'&&openingWalkActive()){
  padState.active=false;padState.x=move.x+(down(B.right)?1:0)-(down(B.left)?1:0);padState.y=move.y+(down(B.down)?1:0)-(down(B.up)?1:0);padState.cut=false;padState.skill=0;
  if(pressed(B.a)){const spot=openingNearestSpot();if(spot)openingInspect(spot.id);}
  if(pressed(B.b)||pressed(B.start))$('openingPause').click();
  for(let i=0;i<pad.buttons.length;i++)padPrev[i]=down(i);return;
 }
 const live=battleLive();padState.active=live;
 if(live){
  padState.x=move.x;padState.y=move.y;padState.cut=down(B.a);padState.skill=down(B.lb)?-1:down(B.rb)?1:0;
  if(pressed(B.b))queueDodge();
  const x=down(B.x);if(x&&!padPrev[B.x])normalLineStart();if(!x&&padPrev[B.x])resetNormalLine();padPrev[B.x]=x;
  if(pressed(B.y))$('normalLineSide').click();
  if(pressed(B.start))startPressed();
  for(const i of [B.a,B.lb,B.rb,B.view,B.up,B.down,B.left,B.right])padPrev[i]=down(i);
  return;
 }
 padState.x=padState.y=0;padState.cut=false;padState.skill=0;
 const dirs={up:down(B.up)||move.y<-.6,down:down(B.down)||move.y>.6,left:down(B.left)||move.x<-.6,right:down(B.right)||move.x>.6};
 for(const [dir,held] of Object.entries(dirs))if(padRepeat(dir,held,now))moveFocus(dir);
 if(pressed(B.a))confirmFocus();
 if(pressed(B.b))goBack();
 if(pressed(B.lb))switchTab(-1);
 if(pressed(B.rb))switchTab(1);
 if(pressed(B.start))startPressed();
 if(pressed(B.x))pressKey('x');
 if(pressed(B.y))pressKey('y');
 const scroll=switchNav.stick(0,pad.axes[3]||0).y;if(scroll)scrollFocused(scroll*18);
 for(const i of [B.view,B.up,B.down,B.left,B.right])padPrev[i]=down(i);
}
// Battle input from the pad, merged by input() in the page.
function padInput(){return padState.active?padState:null;}

// Command bar: what each button does on the current screen, in the glyphs of the last device used.
const commandBar=document.createElement('nav');commandBar.id='commandBar';commandBar.className='command-bar';commandBar.setAttribute('aria-label','Comandos');document.body.append(commandBar);
let commandKey='';
function renderCommandBar(){
 const gamepad=inputDevice.startsWith('gamepad');
 const live=mode&&!showResult&&!pausedAt&&$('pauseSheet').hidden;
 const tabs=gamepad&&focusTargets().some(t=>t.el.matches('[role=tab],[data-hud-tab],.tab-button'));
 const items=live?[]:[['confirm','Selecionar'],['back','Voltar'],...(tabs?[['tabLeft',''],['tabRight','Abas']]:[]),...(!mode&&playerAccount?[['menu','Menu']]:[])];
 const key=inputDevice+'|'+items.map(i=>i.join(':')).join(',');
 commandBar.hidden=!gamepad||!items.length;if(key===commandKey)return;commandKey=key;
 commandBar.replaceChildren(...items.map(([command,label])=>{const span=document.createElement('span');span.className='command';span.append(glyphImage(command));if(label)span.append(label);return span;}));
}
addEventListener('focusin',()=>{if(inputDevice.startsWith('gamepad'))renderCommandBar();});
setInterval(renderCommandBar,400);
addEventListener('gamepadconnected',e=>{setInputDevice(switchNav.padKind(e.gamepad.id)==='ps'?'gamepad-ps':'gamepad-xbox');toast('Controle conectado. Use o direcional para navegar.');});
requestAnimationFrame(pollPads);

// Corner battle HUD: the three bottom panels give way to a fan of round actions in the lower-right corner.
// Each action shows its pictogram, the command glyph for the current device and a recharge ring.
const fan=document.createElement('div');fan.className='action-fan';fan.id='actionFan';fan.setAttribute('role','group');fan.setAttribute('aria-label','Ações de combate');
const RING='<svg class="fan-ring" viewBox="0 0 120 120" aria-hidden="true"><circle class="fan-ring-track" cx="60" cy="60" r="53"/><circle class="fan-ring-progress" cx="60" cy="60" r="53"/></svg>';
function fanButton(action,label,icon,glyphs){
 const b=document.createElement('button');b.type='button';b.className='fan-action fan-'+action;b.dataset.action=action;b.setAttribute('aria-label',label);
 b.innerHTML='<span class="fan-base" aria-hidden="true"></span>'+RING+'<span class="fan-label"></span>';
 const img=document.createElement('img');img.className='fan-icon';img.alt='';img.src=ART_CONFIG.kit?.icons?.[icon]||'';b.insertBefore(img,b.querySelector('.fan-ring'));
 const g=document.createElement('span');g.className='fan-glyphs';for(const command of glyphs)g.append(glyphImage(command));b.append(g);
 b.querySelector('.fan-label').textContent=label;return b;
}
const fanDodge=fanButton('dodge','Esquiva','battle-dodge',['dodge']),fanLine=fanButton('maneuver','Rebicada','battle-maneuver',['maneuver']),fanSkill=fanButton('skill','Habilidade','battle-skill',['skill','skillRight']);
fan.append(fanDodge,fanLine,fanSkill);$('hud').append(fan);
const holdPointer=(b,down,up)=>{b.addEventListener('pointerdown',e=>{e.preventDefault();e.stopPropagation();down();try{b.setPointerCapture(e.pointerId);}catch{}});if(up)for(const ev of ['pointerup','pointercancel','lostpointercapture'])b.addEventListener(ev,up);b.addEventListener('click',e=>{if(e.detail===0)down();});};
holdPointer(fanDodge,()=>queueDodge());
holdPointer(fanLine,()=>normalLineStart(),()=>resetNormalLine());
// The partner skill goes where the kite is heading; a still kite uses the right.
holdPointer(fanSkill,()=>{const i=input();queueSkill((i.x||0)<-.1?'q':'e');});
function setRing(b,remaining,total,blocked){b.style.setProperty('--fan-cooldown',String(333*Math.max(0,Math.min(1,total?remaining/total:0))));b.classList.toggle('is-cooling',remaining>0);b.classList.toggle('is-blocked',!!blocked);}
function updateFan(){
 const p=mode&&ownKite();fan.hidden=!p||showResult;if(fan.hidden)return;
 const blocked=!!(p.respawn||pausedAt||state.phase&&state.phase!=='live'),d=normalLineChoice();
 setRing(fanDodge,p.dodgeCooldown||0,eng.DODGE.cooldown,blocked||p.energy<eng.DODGE.cost);
 setRing(fanLine,p.lineMove?d.cooldown:p.lineCooldown||0,d.cooldown,blocked||(!p.lineMove&&p.energy<d.cost));
 setRing(fanSkill,p.skillCooldown||0,7,blocked||p.energy<25);
 fanLine.querySelector('.fan-label').textContent=d.name+' '+(normalLineSide<0?'←':'→');
 fanLine.classList.toggle('is-held',normalLineHeld);
}
setInterval(updateFan,100);

// The maneuver choice now lives in the pause menu, next to the other match options.
const pauseLine=document.createElement('label');pauseLine.className='pause-line';pauseLine.textContent='Rebicada';
const pauseLineSelect=$('normalLineChoice').cloneNode(true);pauseLineSelect.id='pauseLineChoice';pauseLineSelect.setAttribute('aria-label','Escolher rebicada');pauseLine.append(pauseLineSelect);
$('pauseNote').after(pauseLine);
pauseLineSelect.onchange=()=>{$('normalLineChoice').value=pauseLineSelect.value;$('normalLineChoice').dispatchEvent(new Event('change'));};
new MutationObserver(()=>{const open=!$('pauseSheet').hidden;document.body.classList.toggle('is-paused',open);if(open)pauseLineSelect.value=$('normalLineChoice').value;}).observe($('pauseSheet'),{attributes:true,attributeFilter:['hidden']});
