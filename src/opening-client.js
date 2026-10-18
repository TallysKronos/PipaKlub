let openingState=null,openingOwner=null,openingEpoch=0,openingBusy=false,openingReplay=false,openingFrame=0,openingSince=0,openingLast=0,openingActor={x:540,y:570};
const openingImages=new Map();
const openingScreen=document.createElement('section');openingScreen.id='kaelOpening';openingScreen.className='kael-opening';openingScreen.hidden=true;openingScreen.setAttribute('role','dialog');openingScreen.setAttribute('aria-modal','true');openingScreen.setAttribute('aria-labelledby','openingChapter');
openingScreen.innerHTML='<div class="opening-stage"><canvas id="openingCanvas" width="1536" height="1024" aria-label="Kael em sua casa"></canvas><h1 class="opening-heading" id="openingChapter">PipaKlub · Um fio de sorte</h1><div class="opening-gift" id="openingGift" hidden>Rabiola Antiga<small>Uma lembrança da infância da sua mãe</small></div></div><div class="opening-dialog"><strong id="openingSpeaker"></strong><p id="openingSpeech" aria-live="polite"></p><form id="openingNameForm" class="opening-name" hidden><label for="openingName">Nome do parceiro</label><input id="openingName" type="text" maxlength="24" placeholder="Rabbito" autocomplete="off"><button class="primary" type="submit">Confirmar nome</button></form><div id="openingStatus" class="opening-status" role="status"></div><div class="opening-actions"><button id="openingPause" class="opening-pause secondary" type="button">Continuar depois</button><small id="openingHint">Enter para continuar · Esc para retomar depois</small><button type="button" class="secondary" id="openingRetry" hidden>Recarregar cena</button><button class="opening-next primary" id="openingNext" type="button">Continuar</button></div></div>';
document.body.append(openingScreen);
homeActions.story=()=>showOpening(true);
function closeOpening(){openingScreen.hidden=true;document.body.classList.remove('in-opening');cancelAnimationFrame(openingFrame);openingFrame=0;courtyard.inert=false;syncHomeInert();}
function resetOpening(owner){openingEpoch++;openingOwner=owner;openingState=null;openingBusy=false;openingReplay=false;closeOpening();}
async function readOpening(){
 const epoch=openingEpoch,owner=openingOwner;if(!owner)return;
 const d=await accountRequest('opening',{action:'read'});
 if(epoch===openingEpoch&&owner===playerAccount?.profile?.id){openingState=d.opening;if(d.account){playerAccount=d.account;reflectAccount();}}
}
async function openingRequest(action,extra={}){
 if(openingBusy||!openingOwner)return false;const epoch=openingEpoch,owner=openingOwner;openingBusy=true;openingSetBusy();$('openingStatus').textContent='Salvando…';
 try{const d=await accountRequest('opening',{action,step:openingState?.step,...extra});if(epoch!==openingEpoch||owner!==playerAccount?.profile?.id)return false;openingState=d.opening;if(d.account){playerAccount=d.account;reflectAccount();}if(d.journey)journey=d.journey;$('openingStatus').textContent='';return true;}
 catch(e){if(epoch===openingEpoch){$('openingStatus').textContent=e.message;$('openingRetry').hidden=false;}return false;}
 finally{if(epoch===openingEpoch){openingBusy=false;openingSetBusy();}}
}
function openingSetBusy(){for(const id of ['openingNext','openingPause','openingName','openingRetry'])$(id).disabled=openingBusy;$('openingNameForm').querySelector('button').disabled=openingBusy;}
async function loadOpeningArt(retry=false){
 const entries=Object.entries(ART_CONFIG.opening.images);const results=await Promise.all(entries.map(([key,def])=>new Promise(resolve=>{if(openingImages.has(key)&&!retry){resolve(true);return;}const im=new Image();im.onload=()=>{openingImages.set(key,im);resolve(true)};im.onerror=()=>resolve(false);im.src=def.url;})));
 await Promise.all(['rabbito',art.basic(0),art.basic(2)].map(id=>art.load(id,retry)));
 return results.every(Boolean);
}
async function showOpening(replay=false){
 if(!playerAccount||mode)return;openingReplay=replay;if(replay)openingState={step:0,partner_name:'Rabbito'};
 if(!openingState||openingState.step>=14)return;hideJourney();closeHomeMenu();cityScreen.hidden=true;openingScreen.hidden=false;document.body.classList.add('in-opening');courtyard.inert=true;openingLast=0;openingActor={x:540,y:570};renderOpening();
 const epoch=openingEpoch;const okay=await loadOpeningArt();if(epoch!==openingEpoch||openingScreen.hidden)return;if(!okay){$('openingStatus').textContent='Não foi possível carregar todas as artes. Sua cena está salva. Tente novamente.';$('openingRetry').hidden=false;}
 if(!openingFrame)openingFrame=requestAnimationFrame(drawOpening);
}
function renderOpening(){
 const i=openingState?.step??0,s=KAEL_OPENING[i];if(!s){closeOpening();return;}
 openingSince=performance.now();$('openingSpeaker').textContent=s.speaker;$('openingSpeech').textContent=i===11?(openingState.partner_name||'Rabbito')+'… '+s.text:s.text;
 $('openingGift').hidden=i!==7;$('openingNameForm').hidden=i!==10;$('openingNext').hidden=i===10;$('openingNext').textContent=i===13?'Ir para o quintal':i===11?'Descer com a mãe':'Continuar';$('openingRetry').hidden=true;$('openingStatus').textContent='';
 $('openingPause').textContent=openingReplay?'Sair da reprise':'Continuar depois';$('openingHint').textContent=openingReplay?'Reprise · não altera sua coleção':'Enter para continuar · Esc para retomar depois';
 if(i===10){$('openingName').value='';$('openingName').focus({preventScroll:true});}else $('openingNext').focus({preventScroll:true});openingSetBusy();
}
async function nextOpening(){
 if(openingBusy||openingScreen.hidden||openingState?.step===10)return;
 if(openingReplay){openingState.step++;if(openingState.step>=14){closeOpening();await loadJourney();return;}}
 else if(!await openingRequest('advance'))return;
 if(openingState.step>=14){closeOpening();await loadJourney();return;}renderOpening();
}
$('openingNext').onclick=nextOpening;
$('openingNameForm').onsubmit=async e=>{e.preventDefault();if(openingBusy)return;const name=$('openingName').value.trim()||'Rabbito';if([...name].length>24||/[\u0000-\u001f\u007f]/.test(name)){$('openingStatus').textContent='Use até 24 caracteres, sem quebras de linha.';return;}if(openingReplay){openingState.partner_name=name;openingState.step=11;}else if(!await openingRequest('name',{name}))return;renderOpening();};
$('openingPause').onclick=async()=>{if(openingBusy)return;const replay=openingReplay;closeOpening();if(replay){openingReplay=false;await loadJourney();}else dialogue('Um fio de sorte','Seu lugar na história está salvo. Continue quando estiver pronto.','Continuar a história',()=>showOpening(false));};
$('openingRetry').onclick=async()=>{if(openingBusy)return;if(openingReplay){await showOpening(true);return;}const epoch=openingEpoch;try{await readOpening();if(epoch!==openingEpoch)return;await showOpening(false);}catch(e){$('openingStatus').textContent=e.message;}};
addEventListener('keydown',e=>{if(openingScreen.hidden)return;if(e.key==='Tab'){const list=[...openingScreen.querySelectorAll('button,input')].filter(el=>!el.disabled&&!el.closest('[hidden]')),first=list[0],last=list.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}if(e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();$('openingPause').click();}else if(e.key==='Enter'&&e.target.tagName!=='INPUT'&&e.target.tagName!=='BUTTON'){e.preventDefault();e.stopImmediatePropagation();nextOpening();}},true);
function openingSprite(g,key,frame,x,y,height){
 const im=openingImages.get(key),def=ART_CONFIG.opening.actors[key],f=def?.frames[frame];if(!im||!f)return;const b=f.bounds,scale=height/b.h;g.drawImage(im,f.x,f.y,f.w,f.h,x-(b.x+b.w/2)*scale,y-(b.y+b.h)*scale,f.w*scale,f.h*scale);
}
function drawOpening(t){
 openingFrame=0;if(openingScreen.hidden||!playerAccount)return;const i=openingState?.step??0,down=i>=12,room=down?'downstairs':'bedroom',g=$('openingCanvas').getContext('2d'),im=openingImages.get(room),dt=openingLast?Math.min(.05,(t-openingLast)/1000):0;openingLast=t;g.clearRect(0,0,1536,1024);if(im)g.drawImage(im,0,0,1536,1024);
 // Film blocking uses measured clear-floor paths; actors never cross furniture.
 const blocking=ART_CONFIG.opening.rooms[room].blocking,[tx,ty]=down?blocking.kael:i<3?blocking.kaelTV:blocking.kaelDesk,target={x:tx,y:ty};const dx=target.x-openingActor.x,dy=target.y-openingActor.y,d=Math.hypot(dx,dy),moving=d>2;if(art.reduced||d<2)Object.assign(openingActor,target);else{const v=Math.min(d,dt*280);openingActor.x+=dx/d*v;openingActor.y+=dy/d*v;}
 const kael=openingImages.get('kael'),f=homeArt.plaza.actor.frames[(moving?(dx>0?2:1):down?0:i<3?3:2)+(moving&&Math.floor(t/170)%2?4:0)];if(kael&&f){const b=f.bounds,s=120/b.h;g.drawImage(kael,f.x,f.y,f.w,f.h,openingActor.x-(b.x+b.w/2)*s,openingActor.y-(b.y+b.h)*s,f.w*s,f.h*s);}
 if(i>=5){const elapsed=art.reduced?1:Math.min(1,(t-openingSince)/1000);const motherY=i===5?blocking.motherEntry[1]+(blocking.mother[1]-blocking.motherEntry[1])*elapsed:blocking.mother[1];openingSprite(g,'mother',i===6||i===7?1:0,blocking.mother[0],motherY,135);}
 if(!down&&i<3){
  // The same live broadcast appears inside the CRT and in an accessible close-up.
  g.fillStyle='#203d4b';g.fillRect(473,178,88,59);g.strokeStyle='#bde3c6';g.lineWidth=2;g.beginPath();g.moveTo(480,228);g.lineTo(505,195);g.lineTo(550,223);g.stroke();
  g.fillStyle='#162e3beF';g.fillRect(885,60,545,290);g.strokeStyle='#c9ad74';g.lineWidth=4;g.strokeRect(885,60,545,290);g.fillStyle='#fff0c6';g.font='bold 24px sans-serif';g.textAlign='center';g.fillText('FINAL REGIONAL · AO VIVO',1157,100);art.creature(g,0,t,925,110,145,{facing:1});art.creature(g,2,t,1245,110,145,{facing:-1});g.font='23px sans-serif';g.fillText('Jamile',995,285);g.fillText('Gollia',1310,285);g.font='18px sans-serif';g.fillText('A campeã está perdendo terreno…',1157,325);
 }
 if(!down&&i>=3&&i<9){g.save();g.strokeStyle='#3b7988';g.lineWidth=3;g.translate(1140,280);g.beginPath();g.moveTo(-20,12);g.lineTo(-32,-25);g.lineTo(-8,-8);g.lineTo(13,-28);g.lineTo(20,12);g.lineTo(0,25);g.closePath();g.stroke();g.restore();}
 if(i===7||i===8){const tail=openingImages.get('tail');if(tail)g.drawImage(tail,1110,255,85,85);}
 if(i>=9){const age=Math.max(0,t-openingSince),birth=i===9&&!art.reduced,pulse=birth?Math.min(1,age/1200):1;g.save();if(birth){g.globalAlpha=.35*pulse;const light=g.createRadialGradient(1150,385,5,1150,385,750);light.addColorStop(0,'#fff2b6');light.addColorStop(1,'#fff2b600');g.fillStyle=light;g.fillRect(0,0,1536,1024);g.globalAlpha=1;}
  const [x,y]=blocking.rabbito,size=down?125:150;art.creature(g,0,art.reduced?0:t,x-size/2,y-size,size,{soul:'rabbito',facing:-1});
  if(birth)for(let n=0;n<20;n++){const a=n*2.399,rad=45+(age/12+n*17)%200;g.fillStyle='#ffe6a0';g.globalAlpha=.7;g.beginPath();g.arc(x+Math.cos(a)*rad,y-70+Math.sin(a)*rad,2+n%3,0,Math.PI*2);g.fill();}g.restore();
 }
 openingFrame=requestAnimationFrame(drawOpening);
}
