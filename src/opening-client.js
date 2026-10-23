let openingState=null,openingOwner=null,openingEpoch=0,openingBusy=false,openingReplay=false,openingFrame=0,openingSince=0,openingLast=0,openingActor={x:540,y:570};
let openingBirthBeat=0,openingGiftOpen=false;
const openingBirthMoments=[{speaker:'Kael',text:'A Rabiola Antiga… a luz está vindo da mesa!',action:'Observar'},{speaker:'Kael',text:'Rabbito?! Mãe… meu desenho ganhou vida!',action:'Aguardar Rabbito'},{speaker:'Mãe',text:'Olha… ele está vindo até você. Acho que ele já sabe quem é o seu parceiro.',action:'Conhecer meu parceiro'}];
const openingImages=new Map();
const openingScreen=document.createElement('section');openingScreen.id='kaelOpening';openingScreen.className='kael-opening';openingScreen.hidden=true;openingScreen.setAttribute('role','dialog');openingScreen.setAttribute('aria-modal','true');openingScreen.setAttribute('aria-labelledby','openingChapter');
openingScreen.innerHTML='<div class="opening-stage"><canvas id="openingCanvas" width="1536" height="1024" aria-label="Kael em sua casa"></canvas><h1 class="opening-heading" id="openingChapter">Soulmonsters · Um fio de sorte</h1><div class="opening-gift" id="openingGift" hidden role="status"><div class="opening-item-reveal"><img id="openingGiftArt" alt="Rabiola Antiga"><strong>Você recebeu Rabiola Antiga!</strong><small>Uma lembrança da infância da sua mãe</small></div></div></div><div class="opening-dialog"><strong id="openingSpeaker"></strong><p id="openingSpeech" aria-live="polite"></p><form id="openingNameForm" class="opening-name" hidden><label for="openingName">Nome do parceiro</label><input id="openingName" type="text" maxlength="24" placeholder="Rabbito" autocomplete="off"><button class="primary" type="submit">Confirmar nome</button></form><div id="openingStatus" class="opening-status" role="status"></div><div class="opening-actions"><button id="openingPause" class="opening-pause secondary" type="button">Continuar depois</button><small id="openingHint">Enter para continuar · Esc para retomar depois</small><button type="button" class="secondary" id="openingRetry" hidden>Recarregar cena</button><button class="opening-next primary" id="openingNext" type="button">Continuar</button></div></div>';
document.body.append(openingScreen);
homeActions.story=()=>showOpening(true);
/* OPENING_ROOM_CLIENT */
function closeOpening(){gameLoading.cancel('opening');openingResetRoom();openingCastStep=-1;openingGiftOpen=false;openingScreen.hidden=true;document.body.classList.remove('in-opening');cancelAnimationFrame(openingFrame);openingFrame=0;courtyard.inert=false;syncHomeInert();}
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
function openingSetBusy(){for(const id of ['openingNext','openingPause','openingName','openingRetry'])$(id).disabled=openingBusy;$('openingNameForm').querySelector('button').disabled=openingBusy;openingRefreshRoomUI();}
async function loadOpeningArt(retry=false){gameAvatar.load(retry);
 const entries=Object.entries(ART_CONFIG.opening.images).filter(([key])=>!['bedroom','downstairs','rabbito'].includes(key));const results=await Promise.all(entries.map(([key,def])=>new Promise(resolve=>{if(openingImages.has(key)&&!retry){resolve(true);return;}const im=new Image();im.onload=()=>{openingImages.set(key,im);resolve(true)};im.onerror=()=>resolve(false);im.src=def.url;})));
 await Promise.all(['rabbito',art.basic(0),art.basic(2)].map(id=>art.load(id,retry)));
 const world=homeArt.world,extra=[...Object.keys(world.parkIsometric.images).map(id=>'park-iso-'+id),...Object.keys(world.villageIsometric.images).map(id=>'village-iso-'+id),'world-companion-rabbito'];const loaded=await Promise.all(extra.map(id=>homeLoadImage(id,retry)));return results.every(Boolean)&&loaded.every(Boolean);
}
async function showOpening(replay=false){
 if(!playerAccount||mode)return;openingReplay=replay;if(replay)openingState={step:0,partner_name:'Rabbito'};
 if(!openingState||openingState.step>=14)return;hideJourney();closeHomeMenu();cityScreen.hidden=true;openingScreen.hidden=false;document.body.classList.add('in-opening');courtyard.inert=true;openingLast=0;const i=openingState.step;openingActor=i===3||i<3?{...openingPoint('kaelTV'),direction:3,path:[]}:i===7||i===5||i===6?{x:940,y:650,direction:1,path:[]}:i>=12?{x:openingHomePlan.blocking.kaelEntry[0],y:openingHomePlan.blocking.kaelEntry[1],direction:1,path:[]}:{...openingPoint('kaelDesk'),direction:2,path:[]};renderOpening();
 const gate=gameLoading.start('opening','Um fio de sorte',{retry:()=>showOpening(replay),back:()=>{closeOpening();openHomeMenu();}});const epoch=openingEpoch;const okay=await loadOpeningArt();if(epoch!==openingEpoch||openingScreen.hidden){gate.cancel();return;}if(!okay){gate.fail('Não foi possível carregar a cena. Seu progresso está salvo.');$('openingStatus').textContent='Não foi possível carregar todas as artes. Sua cena está salva. Tente novamente.';$('openingRetry').hidden=false;}
 if(!okay)return;openingSince=performance.now();if(!openingFrame)openingFrame=requestAnimationFrame(drawOpening);await gate.done();
}
function openingGiftWasSeen(){if(openingReplay)return false;try{return localStorage.getItem('pipaGiftSeenV1:'+openingOwner)==='yes';}catch{return false;}}
function renderOpening(){
 const i=openingState?.step??0,s=KAEL_OPENING[i];if(!s){closeOpening();return;}
 openingResetRoom();openingBirthBeat=0;openingGiftOpen=i===7&&!openingGiftWasSeen();openingPrepareCast(i);openingScreen.classList.toggle('partner-moment',i>=9&&i<=10);openingScreen.classList.toggle('naming-partner',i===10);openingScreen.classList.toggle('room-playable',openingRoomStep());openingSince=performance.now();$('openingSpeaker').textContent=s.speaker;$('openingSpeech').textContent=i===11?(openingState.partner_name||'Rabbito')+'… '+s.text:s.text;
 $('openingGift').hidden=!openingGiftOpen;$('openingGiftArt').src=ART_CONFIG.opening.images.tail.url;$('openingNameForm').hidden=i!==10;$('openingNext').hidden=i===10;$('openingNext').textContent=i===13?'Ir para a rua':i===11?'Caminhar até a escada':i===8?'Colocar Rabiola Antiga':'Continuar';$('openingRetry').hidden=true;$('openingStatus').textContent='';
 $('openingPause').textContent=openingReplay?'Sair da reprise':'Continuar depois';$('openingHint').textContent=openingReplay?'Reprise · não altera sua coleção':typeof inputDevice==='string'&&inputDevice==='touch'?'Toque em Continuar para seguir':'Enter para continuar · Esc para retomar depois';
 if(i===9)openingRenderBirth();openingSetBusy();if(i===10){$('openingName').value='';$('openingName').focus({preventScroll:true});}else $('openingNext').focus({preventScroll:true});
}
async function advanceOpeningScene(){
 if(openingBusy||openingScreen.hidden||openingState?.step===10)return;
 if(openingReplay){openingState.step++;if(openingState.step>=14){closeOpening();await loadJourney();return;}}
 else if(!await openingRequest('advance'))return;
 if(openingState.step>=14){closeOpening();await loadJourney();return;}renderOpening();
}
function openingRenderBirth(){const beat=openingBirthMoments[openingBirthBeat];$('openingSpeaker').textContent=beat.speaker;$('openingSpeech').textContent=beat.text;$('openingNext').textContent=beat.action;openingSince=performance.now();}
async function nextOpening(){if(openingAvatarActivity?.state.kind==='seat'){openingAvatarActivity.leave();return;}if(openingBusy||openingCastBusy())return;if(openingGiftOpen){if(!openingReplay){try{localStorage.setItem('pipaGiftSeenV1:'+openingOwner,'yes');}catch{}}openingGiftOpen=false;$('openingGift').hidden=true;openingRoomSignature='';openingRefreshRoomUI();return;}if(openingState?.step===9&&openingBirthBeat<openingBirthMoments.length-1){openingBirthBeat++;openingRenderBirth();return;}if(openingRoomStep()){const spot=openingNearestSpot();if(spot)await openingInspect(spot.id);return;}return advanceOpeningScene();}
$('openingNext').onclick=nextOpening;
$('openingNameForm').onsubmit=async e=>{e.preventDefault();if(openingBusy||openingState?.step!==10||openingScreen.hidden)return;const name=$('openingName').value.trim()||'Rabbito';if([...name].length>24||/[\u0000-\u001f\u007f]/.test(name)){$('openingStatus').textContent='Use até 24 caracteres, sem quebras de linha.';return;}if(openingReplay){openingState.partner_name=name;openingState.step=11;}else if(!await openingRequest('name',{name}))return;renderOpening();};
$('openingPause').onclick=async()=>{if(openingBusy)return;const replay=openingReplay;closeOpening();if(replay){openingReplay=false;await loadJourney();}else dialogue('Um fio de sorte','Seu lugar na história está salvo. Continue quando estiver pronto.','Continuar a história',()=>showOpening(false));};
$('openingRetry').onclick=async()=>{if(openingBusy)return;if(openingReplay){await showOpening(true);return;}const epoch=openingEpoch;try{await readOpening();if(epoch!==openingEpoch)return;await showOpening(false);}catch(e){$('openingStatus').textContent=e.message;}};
addEventListener('keydown',e=>{if(openingScreen.hidden)return;if(e.key==='Tab'){const list=[...openingScreen.querySelectorAll('button,input')].filter(el=>!el.disabled&&!el.closest('[hidden]')),first=list[0],last=list.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}if(e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();$('openingPause').click();}else if(e.key==='Enter'&&e.target.tagName!=='INPUT'&&e.target.tagName!=='BUTTON'){e.preventDefault();e.stopImmediatePropagation();nextOpening();}},true);
function openingSprite(g,key,frame,x,y,height){
 const im=openingImages.get(key),def=ART_CONFIG.opening.actors[key],f=def?.frames[frame];if(!im||!f)return;const b=f.bounds,scale=height/b.h;g.drawImage(im,f.x,f.y,f.w,f.h,x-(b.x+b.w/2)*scale,y-(b.y+b.h)*scale,f.w*scale,f.h*scale);
}
let openingIsometricView=null;const openingVillageCache={};
function openingVillageRenderer(down){const id=down?'kael-home':'kael-bedroom';if(openingVillageCache[id])return openingVillageCache[id];const world=homeArt.world,pack={images:{...world.parkIsometric.images,...world.villageIsometric.images},rigs:world.parkIsometric.rigs},images={};for(const key of Object.keys(pack.images)){const prefix=world.villageIsometric.images[key]?'village-iso-':'park-iso-';images[key]=homeImages.get(prefix+key);if(!images[key])return null;}return openingVillageCache[id]=createVillageIsometricRenderer({village:id,opening:true},images,pack,soulgenRigs.environment);}
function drawOpening(t){
 openingFrame=0;if(openingScreen.hidden||!playerAccount)return;const i=openingState?.step??0,down=i>=12,g=$('openingCanvas').getContext('2d'),dt=openingLast?Math.min(.05,(t-openingLast)/1000):0;openingLast=t;
 openingStepCast(dt);g.clearRect(0,0,1536,1024);const renderer=openingVillageRenderer(down);if(!renderer){openingFrame=requestAnimationFrame(drawOpening);return;}
 const base=renderer.camera(null,1536,1024),tv=renderer.feature('tv'),normal={x:base.x+768/base.scale,y:base.y+512/base.scale},reveal=i===2?Math.min(1,Math.max(0,(t-openingSince)/1600)):i<2?0:1,blend=art.reduced?(i<2?0:1):reveal*reveal*(3-2*reveal),partner=i===9||i===10;
 const focus=partner?renderer.project({x:(openingActor.x+openingRabbit.x)/2,y:(openingActor.y+openingRabbit.y)/2}):!down&&tv?{x:(tv.x+tv.w/2)*(1-blend)+normal.x*blend,y:(tv.y+tv.h/2)*(1-blend)+normal.y*blend}:normal,scale=base.scale*(partner?1.25:7-6*blend);
 openingIsometricView={x:focus.x-768/scale,y:focus.y-512/scale,scale};g.save();g.translate(768,512);g.scale(scale,scale);g.translate(-focus.x,-focus.y);
 const pose=openingAvatarActivity?.pose(),cast=[{...openingActor,type:'player',avatarPose:pose,...(pose?{x:pose.x,y:pose.y}:{}),draw:p=>openingDrawKael(g,t,p)}];if(i>=5)cast.push({...openingMother,draw:p=>openingDrawMother(g,t,p)});if(i>9||(i===9&&openingBirthBeat>0))cast.push({...openingRabbit,draw:p=>openingDrawRabbit(g,t,p)});
 renderer.draw(g,openingActor,cast,{dt,animate:!art.reduced});if(openingRoomStep()&&!openingGiftOpen)drawOpeningRoomPlaces(g);if(!down&&tv)drawOpeningBroadcast(g,t,i<3,tv);
 const desk=renderer.feature('desk'),px=desk?desk.x+desk.w*.35:0,py=desk?desk.y+desk.h*.22:0;
 if(!down&&bedroomPlan.version<3&&desk&&i>=3&&(i<9||(i===9&&openingBirthBeat===0))){const project=openingImages.get('project');if(project)paintOpeningProject(g,project,i>=4?1:0,px,py,92,62);}
 if(i===9&&openingBirthBeat===0){const light=g.createRadialGradient(px+46,py+31,8,px+46,py+31,300);light.addColorStop(0,'#fffbe7');light.addColorStop(.2,'#ffe6b1bb');light.addColorStop(1,'#fff2b600');g.fillStyle=light;g.fillRect(px-300,py-300,700,700);}
 if(i===9&&openingBirthBeat===1&&!art.reduced){g.globalAlpha=Math.max(0,1-(t-openingSince)/850);g.fillStyle='#fff9dd';g.fillRect(focus.x-768/scale,focus.y-512/scale,1536/scale,1024/scale);}
 g.restore();drawOpeningWorkbench(t);openingFrame=requestAnimationFrame(drawOpening);
}
