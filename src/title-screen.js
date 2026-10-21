// Presentation only: starting never creates an account, starts combat or resets a save.
export function createRuinsArt(document,assets,id='title'){
 const art=document.createElement('div');art.className='ruins-art';art.setAttribute('aria-hidden','true');
 art.innerHTML=`<img class="ruins-background" alt=""><div class="ruins-guardian"><svg class="ruins-life" viewBox="0 0 1536 1024"><defs><filter id="ruins-life-${id}" x="-5%" y="-5%" width="110%" height="110%" color-interpolation-filters="sRGB"><feTurbulence type="fractalNoise" baseFrequency=".004 .009" numOctaves="1" seed="8" result="wind"><animate attributeName="baseFrequency" values=".004 .009;.006 .012;.004 .009" dur="6s" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in="SourceGraphic" in2="wind" scale="12" xChannelSelector="R" yChannelSelector="G"><animate attributeName="scale" values="6;20;6" dur="6s" repeatCount="indefinite"/></feDisplacementMap></filter></defs></svg><img class="ruins-presence" alt="" style="--life-filter:url(#ruins-life-${id})"><i class="ruins-eye"></i><i class="ruins-heart"></i></div><div class="ruins-shade"></div><div class="ruins-fog ruins-fog-back"></div><div class="ruins-fog ruins-fog-front"></div><svg class="ruins-thread" viewBox="0 0 1600 900" preserveAspectRatio="none"><path d="M-40 810 C170 650 395 925 610 760 S1050 650 1250 448"/></svg><div class="ruins-motes"></div>`;
 const background=art.querySelector('.ruins-background'),presence=art.querySelector('.ruins-presence');
 if(assets?.background?.url)background.src=assets.background.url;if(assets?.presence?.url)presence.src=assets.presence.url;
 background.addEventListener('error',()=>art.classList.add('ruins-background-failed'));
 presence.addEventListener('error',()=>{presence.hidden=true;art.querySelector('.ruins-guardian').hidden=true;});
 for(let i=0;i<12;i++){const mote=document.createElement('i');mote.style.cssText=`--x:${(i*31+7)%100}%;--y:${(i*17+39)%100}%;--delay:${-i*1.7}s;--duration:${12+i%5*3}s`;art.querySelector('.ruins-motes').append(mote);}
 return art;
}

export function shouldShowRuinsTitle(location,seen=false){
 const query=new URLSearchParams(location.search||'');
 if(location.hash||['sala','code','token','token_hash','access_token','refresh_token','type','error'].some(key=>query.has(key)))return false;
 if(query.get('title')==='0')return false;
 if(query.get('title')==='1')return true;
 return !seen&&/(?:^|\/)(?:index\.html)?$/.test(location.pathname||'/');
}

export function createRuinsTitle({document,host,location,assets,storage,requestFrame,cancelFrame,onStart=()=>{},force=false}){
 const storageKey='soulmonsters-title-v1';let seen=false;try{seen=storage?.getItem(storageKey)==='seen';}catch{}
 if(!force&&!shouldShowRuinsTitle(location,seen))return null;
 const screen=document.createElement('dialog');
 // Progressive enhancement: browsers without native modal support keep the normal entry usable.
 if(typeof screen.showModal!=='function')return null;
 screen.id='ruinsTitle';screen.className='ruins-title';screen.setAttribute('aria-labelledby','ruinsTitleName');
 screen.innerHTML=`
 <div class="ruins-identity"><svg class="ruins-emblem" aria-hidden="true" viewBox="0 0 80 80"><path d="M40 6 67 37 40 67 13 37Z"/><path d="M40 16 58 37 40 57 22 37Z"/><path d="M40 67C26 73 52 72 40 79"/></svg><h1 id="ruinsTitleName"><span class="ruins-brand">Soulmonsters</span><span class="ruins-subtitle">Elo das Ruínas</span></h1><p class="ruins-whisper">Antes das ruínas, já existia um elo.</p></div>
 <div class="ruins-start-area"><button class="ruins-start" id="ruinsStart" type="button"><span class="ruins-start-mark" aria-hidden="true">◇</span><span>Pressione Start</span><span class="ruins-start-mark" aria-hidden="true">◇</span></button><p class="ruins-input-hint">Enter · toque · botão Start do controle</p></div>
 <button class="ruins-motion" type="button" aria-pressed="false">Pausar animação</button><small class="ruins-edition">Demo em desenvolvimento</small>`;
 const art=createRuinsArt(document,assets);screen.prepend(art);
 const startButton=screen.querySelector('.ruins-start'),motionButton=screen.querySelector('.ruins-motion');
 let started=false,finished=false,raf=0,paused=false,padHeld=false,hidden=!!document.hidden,closeTimer;
 const reduced=host.matchMedia?.('(prefers-reduced-motion: reduce)');
 const updateMotion=()=>{const stopped=paused||hidden||!!reduced?.matches;screen.classList.toggle('ruins-paused',stopped);const svg=art.querySelector('.ruins-life');if(stopped)svg.pauseAnimations?.();else svg.unpauseAnimations?.();motionButton.setAttribute('aria-pressed',String(paused));motionButton.textContent=paused?'Retomar animação':'Pausar animação';motionButton.hidden=!!reduced?.matches;};
 const stopPad=()=>{if(raf){cancelFrame?.(raf);raf=0;}};
 function finish(){if(finished)return;finished=true;stopPad();host.clearTimeout?.(closeTimer);screen.close();document.body.classList.remove('in-title');host.removeEventListener('keydown',onKey,true);document.removeEventListener('visibilitychange',onVisibility);screen.removeEventListener('cancel',onCancel);reduced?.removeEventListener?.('change',updateMotion);screen.remove();onStart();
  const focusOrder=['#kaelOpening #openingNext','#courtyard #homeMenuButton','#ruinsContinue','#accountButton','.menu button'];
  for(const selector of focusOrder){const next=[...document.querySelectorAll(selector)].find(el=>!el.disabled&&!el.closest('[hidden],[inert]')&&el.getClientRects?.().length);if(next){next.focus({preventScroll:true});break;}}
 }
 function start(){if(started)return;started=true;startButton.disabled=true;try{storage?.setItem(storageKey,'seen');}catch{}screen.classList.add('ruins-leaving');if(reduced?.matches)finish();else closeTimer=host.setTimeout(finish,650);}
 function onKey(event){if(!screen.open||event.key==='Tab'||event.ctrlKey||event.metaKey||event.altKey||/^F\d+$/.test(event.key))return;event.stopImmediatePropagation();event.preventDefault();if(['Enter',' ','Spacebar'].includes(event.key)&&!event.repeat){if(event.target===motionButton)motionButton.click();else start();}}
 function onCancel(event){event.preventDefault();}
 function pollPad(){raf=0;if(!screen.open||finished||hidden)return;const pads=host.navigator?.getGamepads?.()||[],down=[...pads].some(p=>p?.connected&&(p.buttons[9]?.pressed||p.buttons[0]?.pressed));if(down&&!padHeld)start();padHeld=down;if(!finished)raf=requestFrame?.(pollPad)||0;}
 function onVisibility(){hidden=!!document.hidden;updateMotion();if(hidden)stopPad();else if(!raf&&!finished)raf=requestFrame?.(pollPad)||0;}
 motionButton.onclick=()=>{paused=!paused;updateMotion();};startButton.onclick=start;screen.addEventListener('cancel',onCancel);
 host.addEventListener('keydown',onKey,true);document.addEventListener('visibilitychange',onVisibility);reduced?.addEventListener?.('change',updateMotion);
 document.body.append(screen);document.body.classList.add('in-title');updateMotion();screen.showModal();startButton.focus({preventScroll:true});raf=requestFrame?.(pollPad)||0;
 return {start,finish,get element(){return screen;},get started(){return started;}};
}
