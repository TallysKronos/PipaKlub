function openingProjectPoint(p){return bedroomProjectPoint(p);}
const bedroomPlan=ART_CONFIG.opening.rooms.bedroom;
function openingPoint(name){const p=bedroomPlan.blocking[name];return {x:p[0],y:p[1]};}
const openingBedroomNavigation=createOpeningRoom({...bedroomPlan,hotspots:bedroomPlan.hotspots.filter(p=>p.id!=='stairs')});
const openingExitNavigation=createOpeningRoom({...bedroomPlan,hotspots:bedroomPlan.hotspots.filter(p=>p.id==='stairs')});
const openingHomePlan=ART_CONFIG.opening.homeLayout;
const openingDownstairsNavigation=createOpeningRoom({...ART_CONFIG.opening.rooms.downstairs,hotspots:ART_CONFIG.opening.rooms.downstairs.hotspots.filter(h=>h.id!=='upstairs')});
let openingRoomNavigation=openingBedroomNavigation;
let openingAvatarActivity=null;
let openingWalkKeys={},openingWalkIntent=null,openingWorkbench=false,openingRoomSignature='',openingCraftAt=null,openingCraftSaving=false;
const roomPlaces=uiElement('nav',undefined,'opening-places');roomPlaces.id='openingPlaces';roomPlaces.hidden=true;roomPlaces.setAttribute('aria-label','Lugares do quarto');
for(const spot of [...openingBedroomNavigation.hotspots,...openingDownstairsNavigation.hotspots,...openingExitNavigation.hotspots]){const b=uiElement('button',({tv:'TV',drawings:'Desenhos',desk:'Mesa',mother:'Mãe',exit:'Saída para a rua',stairs:'Escada',seat:'Sentar'}[spot.id]),'opening-place');b.type='button';b.dataset.openingPlace=spot.id;b.onclick=()=>openingWalkTo(spot.id);roomPlaces.append(b);}
$('openingSpeech').after(roomPlaces);
const bench=uiElement('section',undefined,'opening-workbench');bench.id='openingWorkbench';bench.hidden=true;bench.setAttribute('aria-labelledby','openingBenchTitle');
bench.innerHTML='<div class="opening-bench-card"><h2 id="openingBenchTitle">Uma ideia feita de papel</h2><p>O corpo de papel já está pronto. Falta encaixar a última vareta na armação.</p><canvas id="openingProjectArt" width="1536" height="1024" role="img" aria-label="Projeto físico do Rabbito, feito de papel e bambu, ainda sem rabiola"></canvas><div><button type="button" class="secondary" id="openingBenchBack">Olhar o quarto</button><button type="button" class="primary" id="openingBenchPlace">Encaixar a última vareta</button></div><p id="openingBenchStatus" role="status"></p></div>';
openingScreen.querySelector('.opening-stage').append(bench);
function openingRoomStep(){return [3,7,11,13].includes(openingState?.step);}
function openingWalkActive(){return !gameLoading.active&&!openingScreen.hidden&&openingRoomStep()&&!openingWorkbench&&!openingBusy&&!openingGiftOpen&&!openingMother.path?.length&&openingAvatarActivity?.state.kind!=='stairs';}
function openingClearWalking(){openingWalkKeys={};openingWalkIntent=null;openingActor.path=[];openingActor.moving=false;}
function openingCloseBench(){openingCraftAt=null;openingCraftSaving=false;openingWorkbench=false;openingRod.grabbed=false;openingRod.pointer=null;bench.hidden=true;openingRoomSignature='';openingRefreshRoomUI();}
function openingResetRoom(){openingAvatarActivity=null;openingCraftAt=null;openingCraftSaving=false;openingClearWalking();openingRoomNavigation=openingState?.step===13?openingDownstairsNavigation:openingState?.step===11?openingExitNavigation:openingBedroomNavigation;openingWorkbench=false;bench.hidden=true;roomPlaces.hidden=true;openingRoomSignature='';}
function openingNearestSpot(){return openingRoomNavigation.hotspots.filter(p=>openingRoomNavigation.near(openingActor,p.id)).sort((a,b)=>Math.hypot(a.x-openingActor.x,a.y-openingActor.y)-Math.hypot(b.x-openingActor.x,b.y-openingActor.y))[0];}
function openingRefreshRoomUI(){
 roomPlaces.hidden=!openingHintsShown||!openingRoomStep()||openingGiftOpen;if(openingGiftOpen){$('openingSpeaker').textContent='Presente de aniversário';$('openingNext').textContent='Avançar';$('openingNext').disabled=openingBusy;$('openingHint').textContent='Avançar · guardar o presente';return;}if(!openingRoomStep()){$('openingNext').disabled=openingBusy||openingCastBusy();return;}
 const near=openingNearestSpot(),signature=[openingState.step,near?.id,openingBusy,openingWorkbench,openingAvatarActivity?.state.phase,typeof inputDevice==='string'?inputDevice:'keyboard'].join('|');if(signature===openingRoomSignature)return;openingRoomSignature=signature;
 $('openingSpeaker').textContent=openingState.step===11?'Seu parceiro vai com você':openingState.step===13?'Seu primeiro passeio juntos':openingState.step===3?'Termine seu projeto':'Uma ideia inesperada';
 $('openingHint').textContent=typeof inputDevice==='string'&&inputDevice.startsWith('gamepad')?'Analógico · A interage · B pausa':typeof inputDevice==='string'&&inputDevice==='touch'?'Toque no chão para andar · toque nos destaques para interagir':'Setas / WASD / clique para andar · E interage';
 $('openingNext').textContent=near?.id==='stairs'?'Descer a escada · E':near?.id==='exit'?'Sair para a rua · E':near?.id==='mother'?'Conversar · E':near?.id==='desk'?(openingState.step===3?'Montar Rabbito':'Ver projeto'):near?'Examinar · E':'Aproxime-se';
 $('openingNext').disabled=openingBusy||openingWorkbench||!near||openingAvatarActivity?.state.kind==='stairs';if(openingAvatarActivity?.state.kind==='seat'){$('openingNext').textContent='Levantar · E';$('openingNext').disabled=false;}
 roomPlaces.setAttribute('aria-label',openingState.step===13?'Lugares da casa':'Lugares do quarto');
 for(const b of roomPlaces.querySelectorAll('button')){b.hidden=!openingRoomNavigation.hotspots.some(p=>p.id===b.dataset.openingPlace);b.disabled=openingBusy||openingWorkbench;b.setAttribute('aria-pressed',String(b.dataset.openingPlace===near?.id));}
}
function openingWalkTo(id){if(openingAvatarActivity?.state.kind==='seat'){openingAvatarActivity.leave(()=>openingWalkTo(id));return;}
 if(!openingWalkActive())return;const p=openingRoomNavigation.hotspots.find(s=>s.id===id);if(!p)return;
 const path=openingRoomNavigation.route(openingActor,p);if(!path.length){$('openingStatus').textContent='Escolha um caminho livre no chão.';return;}
 openingActor.path=path;openingWalkIntent=id;$('openingStatus').textContent='';
 if(openingRoomNavigation.near(openingActor,id)){openingActor.path=[];openingWalkIntent=null;openingInspect(id);}
}
async function openingInspect(id){
 if(!openingWalkActive())return;
 if(!openingRoomNavigation.near(openingActor,id)){openingWalkTo(id);return;}
 openingClearWalking();const look=(openingState.step<12?bedroomPlan:openingHomePlan).hotspots.find(p=>p.id===id)?.lookAt;if(look){const d=openingProjectPoint({x:look[0]-openingActor.x,y:look[1]-openingActor.y});openingActor.direction=screenDirection(d.x,d.y);}else openingActor.direction=3;
 if(id==='seat'){openingAvatarActivity=createHomeSeatActivity(openingActor,p=>{Object.assign(openingActor,p);openingAvatarActivity=null;openingRoomSignature='';openingRefreshRoomUI();});return;}
 if(id==='stairs'){openingAvatarActivity=createHomeStairActivity('kael-bedroom',openingActor,()=>{openingAvatarActivity=null;advanceOpeningScene();});return;}
 if(id==='exit'){await advanceOpeningScene();return;}
 if(id==='mother'){openingActor.direction=2;openingMother.direction=1;$('openingSpeech').textContent='Eu guardei aquela rabiola por tantos anos… Cuide bem dele, Kael. E volte para me contar como foi o primeiro voo.';return;}
 if(id==='tv'){$('openingSpeech').textContent='A final continua na TV. Gollia pressiona, e Jamile procura uma abertura. Um dia eu ainda vou estar naquele céu.';return;}
 if(id==='drawings'){$('openingSpeech').textContent='Tantas orelhas diferentes… Esta foi a versão que eu mais gostei. Não quero copiar um Pipamon que já existe. Quero terminar o meu.';return;}
 if(id==='desk'){
  if(openingState.step===7){await advanceOpeningScene();return;}
  openingWorkbench=true;bench.hidden=false;openingRoomSignature='';openingRefreshRoomUI();drawOpeningWorkbench(performance.now());$('openingBenchStatus').textContent='';$('openingBenchPlace').disabled=false;$('openingBenchPlace').focus({preventScroll:true});
 }
}
$('openingBenchBack').onclick=()=>{openingCloseBench();$('openingNext').focus({preventScroll:true});};
$('openingBenchPlace').onclick=()=>{
 if(openingBusy||openingCraftAt!==null||!openingWorkbench||openingState?.step!==3)return;
 openingRod.grabbed=true;openingRod.x=1180;openingRod.y=550;$('openingBenchStatus').textContent='Vareta na mão. Use as setas para levar ao encaixe e Enter para soltar.';$('openingProjectArt').focus();
};
async function openingFinishCraft(){
 if(openingCraftSaving||!openingWorkbench||openingState?.step!==3)return;
 const epoch=openingEpoch;openingCraftSaving=true;$('openingBenchBack').disabled=true;await advanceOpeningScene();if(epoch!==openingEpoch)return;
 if(openingState?.step===3){openingCraftAt=null;openingCraftSaving=false;$('openingBenchStatus').textContent=$('openingStatus').textContent||'Não foi possível salvar. Tente novamente.';$('openingBenchPlace').disabled=false;}
 $('openingBenchBack').disabled=false;
}
function drawOpeningWorkbench(t){
 if(openingWorkbench)drawOpeningFirstPersonBench(t);
}
function paintOpeningProject(g,im,p,x,y,w,h){
 g.save();g.translate(x,y);g.scale(w/1536,h/1024);g.drawImage(im,0,0,1070,1024,0,0,1070,1024);g.save();g.translate(1303+(580-1303)*p,650);g.rotate(.65*p);g.scale(1+.6*p,1+.6*p);g.drawImage(im,1070,450,466,400,-233,-200,466,400);g.restore();g.restore();
}
function openingStepRoom(dt){
 if(!openingWalkActive())return;const input={x:(openingWalkKeys.d||openingWalkKeys.arrowright?1:0)-(openingWalkKeys.a||openingWalkKeys.arrowleft?1:0),y:(openingWalkKeys.s||openingWalkKeys.arrowdown?1:0)-(openingWalkKeys.w||openingWalkKeys.arrowup?1:0)};
 if(typeof padState!=='undefined'&&inputDevice.startsWith('gamepad')){input.x=padState.x;input.y=padState.y;}
 if(input.x||input.y)openingWalkIntent=null;openingTickActor(openingRoomNavigation,openingActor,input,dt);openingRefreshRoomUI();
 const entrance=openingRoomNavigation.hotspots.find(p=>['stairs','exit'].includes(p.id)&&Math.hypot(openingActor.x-p.x,openingActor.y-p.y)<42);
 if(entrance&&openingActor.moving){openingInspect(entrance.id);return;}
 if(openingWalkIntent&&!openingActor.path?.length){const id=openingWalkIntent;openingWalkIntent=null;if(openingRoomNavigation.near(openingActor,id))openingInspect(id);}
}
$('openingCanvas').addEventListener('pointerdown',e=>{
 if(!openingWalkActive()||e.button>0)return;const screen=openingRoomNavigation.canvasPoint(e.currentTarget.getBoundingClientRect(),1536,1024,e.clientX,e.clientY);if(!screen||!openingIsometricView)return;const projected={x:screen.x/openingIsometricView.scale+openingIsometricView.x,y:screen.y/openingIsometricView.scale+openingIsometricView.y},p=openingVillageRenderer(openingState.step>=12).unproject(projected),hit=openingVillageRenderer(openingState.step>=12)?.pick(projected);
 const spot=openingRoomNavigation.hotspots.find(s=>s.id===hit?.hotspot||Math.hypot(p.x-s.x,p.y-s.y)<45);
 if(spot){openingWalkTo(spot.id);return;}
 if(openingAvatarActivity?.state.kind==='seat'){openingAvatarActivity.leave(()=>{openingActor.path=openingRoomNavigation.route(openingActor,p);openingWalkIntent=null;});return;}const path=openingRoomNavigation.route(openingActor,p);if(!path.length){$('openingStatus').textContent='Aqui não dá para passar. Clique no chão livre.';return;}openingActor.path=path;openingWalkIntent=null;$('openingStatus').textContent='';
});
addEventListener('keydown',e=>{
 if(openingScreen.hidden)return;if(openingWorkbench&&e.key==='Escape'&&!openingBusy){e.preventDefault();e.stopImmediatePropagation();openingCloseBench();$('openingNext').focus({preventScroll:true});return;}
 if(openingAvatarActivity?.state.kind==='seat'&&!/INPUT|TEXTAREA|SELECT/.test(e.target?.tagName)&&['e','w','a','s','d','arrowleft','arrowright','arrowup','arrowdown'].includes(e.key.toLowerCase())){openingAvatarActivity.leave();if(e.key.toLowerCase()==='e'){e.preventDefault();e.stopImmediatePropagation();return;}}
 if(!openingWalkActive()||/INPUT|TEXTAREA/.test(e.target?.tagName))return;const k=e.key.toLowerCase();
 if(['w','a','s','d','arrowleft','arrowright','arrowup','arrowdown'].includes(k)){e.preventDefault();e.stopImmediatePropagation();openingWalkKeys[k]=true;}
 if(k==='e'&&!e.repeat){e.preventDefault();e.stopImmediatePropagation();const spot=openingNearestSpot();if(spot)openingInspect(spot.id);}
},true);
addEventListener('keyup',e=>{delete openingWalkKeys[e.key.toLowerCase()];});addEventListener('blur',openingClearWalking);document.addEventListener('visibilitychange',()=>{if(document.hidden)openingClearWalking();});
function drawOpeningRoomPlaces(g){
 if(!openingHintsShown||!openingRoomStep()||openingWorkbench)return;
 const room=openingVillageRenderer(openingState.step>=12);
 for(const p of openingRoomNavigation.hotspots){
  const near=openingRoomNavigation.near(openingActor,p.id),q=openingProjectPoint(p),b=room?.feature(p.id);g.save();
  if(b&&p.id!=='stairs'){
   const x=b.x+b.w/2,y=b.y-22;g.fillStyle=near?'#efc66e':'#fff0cf';g.strokeStyle='#28555a';g.lineWidth=2;g.beginPath();g.moveTo(x-9,y-10);g.lineTo(x+9,y-10);g.lineTo(x,y+3);g.closePath();g.fill();g.stroke();
  }else{
   g.translate(q.x,q.y);g.fillStyle='#55c8ef';g.strokeStyle='#20536b';g.lineWidth=3;g.beginPath();g.moveTo(-15,-5);g.lineTo(0,10);g.lineTo(15,-5);g.lineTo(9,-11);g.lineTo(0,-2);g.lineTo(-9,-11);g.closePath();g.fill();g.stroke();
  }
  g.restore();
 }
 if(openingActor.path?.length){const p=openingProjectPoint(openingActor.path.at(-1));g.strokeStyle='#fff1bd';g.lineWidth=3;g.beginPath();g.arc(p.x,p.y,9,0,Math.PI*2);g.stroke();}
}
function drawOpeningBroadcast(g,t,featured,box={x:473,y:178,w:88,h:59}){
 const {x,y,w,h}=box,time=art.reduced?600:t,cycle=time%2400/2400;
 g.save();g.beginPath();g.rect(x,y,w,h);g.clip();g.fillStyle='#203c58';g.fillRect(x,y,w,h);g.fillStyle='#94bac1';g.fillRect(x,y+h*.3,w,h*.7);
 const left=x+w*(.24+Math.sin(time/900)*.035),right=x+w*(.75-Math.max(0,Math.sin(time/380))*.16),ay=y+h*.69,by=y+h*.58;
 g.strokeStyle='#de9e57';g.lineWidth=.6;g.beginPath();g.moveTo(x,y+h);g.lineTo(left,ay);g.stroke();g.strokeStyle='#4776a5';g.beginPath();g.moveTo(x+w,y+h);g.lineTo(right,by);g.stroke();
 art.creature(g,0,time,left-13,ay-21,26,{facing:1,input:{x:-.4,y:0},hitFlash:cycle<.13?.15:0});art.creature(g,2,time,right-14,by-21,28,{facing:-1,input:{x:-1,y:0},skillCooldown:cycle<.2?6.8:0});
 if(!art.reduced&&cycle<.2){g.strokeStyle='#f9f3c8';g.lineWidth=.8;g.beginPath();g.moveTo(right-6,by-6);g.lineTo(left+8,ay-6);g.stroke();}
 g.fillStyle='#132733e8';g.fillRect(x,y,w,11);g.fillRect(x,y+h-10,w,10);g.fillStyle='#fff0c8';g.textAlign='center';g.font='bold 4px sans-serif';g.fillText('FINAL REGIONAL · AO VIVO',x+w/2,y+7);g.font='4px sans-serif';g.fillText('Jamile',x+19,y+h-3);g.fillText('Gollia',x+w-18,y+h-3);
 if(featured){g.fillStyle='#fff4cb';for(let k=0;k<3;k++)g.fillRect(x+w-5-k*2,y+14+k*2,1.2,1.2);}
 g.restore();
}

// All story blocking uses the same measured foot paths as player movement.
let openingCastStep=-1,openingMother={...openingPoint('motherEntry'),direction:3,path:[]},openingRabbit={x:1145,y:640,direction:1,path:[]};
function openingCastBusy(){return (openingState?.step===5&&!!openingMother.path?.length)||(openingState?.step===8&&!!openingActor.path?.length);}
function openingStageRoute(actor,nav,target){actor.path=nav.route(actor,target);}
function openingPrepareCast(i){
 const previous=openingCastStep;openingCastStep=i;
 const down=i>=12,nav=down?openingDownstairsNavigation:openingBedroomNavigation;
 if(down&&previous<12){const p=openingHomePlan.blocking;Object.assign(openingActor,{x:p.kaelEntry[0],y:p.kaelEntry[1],direction:1,path:[]});Object.assign(openingMother,{x:p.mother[0],y:p.mother[1],direction:2,path:[]});Object.assign(openingRabbit,{x:p.rabbitoEntry[0],y:p.rabbitoEntry[1],direction:1,path:[]});}
 if(i===5){Object.assign(openingActor,{...openingPoint('kaelDesk'),direction:3,path:[]});Object.assign(openingMother,{...openingPoint('motherEntry'),direction:3,path:[]});openingStageRoute(openingMother,nav,openingPoint('mother'));}
 if([6,7,8].includes(i)&&previous<5){Object.assign(openingMother,{...openingPoint('mother'),direction:2,path:[]});}
 if(i===7){if(previous<5)Object.assign(openingMother,{...openingPoint('mother'),direction:2,path:[]});if(!openingGiftOpen)openingStageRoute(openingMother,nav,openingPoint('motherEntry'));}
 if(i===8)openingStageRoute(openingActor,nav,openingPoint('kaelDesk'));
 if(i===9){openingStageRoute(openingActor,nav,openingPoint('kaelBirth'));openingMother.path=[];Object.assign(openingRabbit,{...openingPoint('rabbito'),direction:1,path:[]});}
 if([10,11].includes(i)&&previous<9){Object.assign(openingActor,{...openingPoint('kaelBirth'),direction:2,path:[]});Object.assign(openingMother,{...openingPoint('mother'),direction:2,path:[]});Object.assign(openingRabbit,{...openingPoint('rabbitoNear'),direction:1,path:[]});}
}
function openingStepCast(dt){if(openingAvatarActivity){const activity=openingAvatarActivity;if(activity.state.kind==='seat'&&Object.values(openingWalkKeys).some(Boolean))activity.leave();activity.tick(dt);openingRefreshRoomUI();return;}

 const i=openingState?.step??0,nav=i>=12?openingDownstairsNavigation:openingBedroomNavigation;
 if(openingRoomStep())openingStepRoom(dt);else openingTickActor(nav,openingActor,{},dt);
 if(i>=5)openingTickActor(nav,openingMother,{},dt);
 if(i===5&&!openingMother.path?.length){if(openingMotherArrivedAt===null)openingMotherArrivedAt=performance.now();openingMother.direction=2;openingActor.direction=1;const d=openingProjectPoint({x:openingMother.x-openingActor.x,y:openingMother.y-openingActor.y});openingActor.avatarDir=avatarModel.facingIso(d.x,d.y,openingActor.avatarDir);}
 if(i===9){openingActor.direction=2;if(openingBirthBeat>=1&&!openingRabbit.path?.length&&openingRabbit.x>1102)openingStageRoute(openingRabbit,nav,{x:1100,y:640});openingTickActor(nav,openingRabbit,{},dt);}
 if(i>=11){const d=Math.hypot(openingActor.x-openingRabbit.x,openingActor.y-openingRabbit.y);if(d>110&&!openingRabbit.path?.length){const dx=openingActor.x-openingRabbit.x,dy=openingActor.y-openingRabbit.y;const target={x:openingActor.x-dx/d*70,y:openingActor.y-dy/d*70};if(nav.safe(target))openingStageRoute(openingRabbit,nav,target);}openingTickActor(nav,openingRabbit,{},dt);}
 openingRefreshRoomUI();
}
function openingDrawStandingKael(g,t,position=openingProjectPoint(openingActor)){gameAvatar.setOwner(playerAccount?.profile?.id);const pose=openingAvatarActivity?.pose();if(gameAvatar.draw(g,{...position,y:position.y-(pose?.lift||0),height:102,action:pose?.action||(openingActor.moving?'andar':'parado'),dir:pose?.dir||openingActor.avatarDir||'se',time:pose?.time??(openingActor.moving?openingActor.avatarWalkTime??t:t)}))return;const actor={...openingActor,...position},im=openingImages.get('kael'),f=homeArt.plaza.actor.frames[(actor.direction??3)+(actor.moving&&Math.floor(t/170)%2?4:0)];if(!im||!f)return;const b=f.bounds,s=102/b.h;g.drawImage(im,f.x,f.y,f.w,f.h,actor.x-(b.x+b.w/2)*s,actor.y-(b.y+b.h)*s,f.w*s,f.h*s);}
function openingDrawKael(g,t,position=openingProjectPoint(openingActor)){
 if(openingState?.step===5&&openingMotherArrivedAt!==null&&!art.reduced){const q=(t-openingMotherArrivedAt)/350;if(q>=0&&q<1){openingDrawStandingKael(g,t,{x:position.x,y:position.y-Math.sin(q*Math.PI)*8});return;}}
 const dt=openingImpactAt===null?-1:t-openingImpactAt,fall=dt<0?0:dt<300?dt/300:dt<950?1:Math.max(0,1-(dt-950)/600);
 if(openingState?.step!==9||art.reduced||!fall){openingDrawStandingKael(g,t,position);return;}
 const eased=fall*fall*(3-2*fall);g.save();g.translate(position.x-28*eased,position.y+8*eased);g.rotate(-1.05*eased);openingDrawStandingKael(g,t,{x:0,y:0});g.restore();
}
function openingDrawMother(g,t,position=openingProjectPoint(openingMother)){const actor={...openingMother,...position};openingSprite(g,'mother',(actor.direction??0)+(actor.moving&&Math.floor(t/170)%2?4:0),actor.x,actor.y,104);}
function openingDrawRabbit(g,t,position=openingProjectPoint(openingRabbit)){const actor={...openingRabbit,...position};if(worldCompanions.draw(g,homeImages,{soul:'rabbito'},actor.x,actor.y,66,{direction:actor.direction,moving:actor.moving,time:art.reduced?0:t}))return;art.creature(g,0,art.reduced?0:t,actor.x-55,actor.y-110,110,{soul:'rabbito',facing:actor.direction===2?1:-1,input:actor.moving?{x:-1}:{}},openingState?.step===11&&!actor.moving);}

// Figma Melhorias 85:674–679: discovery first; the stage owns the camera.
let openingHintsShown=false,openingHintSince=0,openingBroadcastSide=0,openingImpactAt=null,openingMotherArrivedAt=null;
const openingRod={x:1180,y:550,grabbed:false,pointer:null};
const openingHelp=uiElement('button','Preciso de uma dica','secondary opening-help');openingHelp.type='button';openingHelp.hidden=true;openingHelp.setAttribute('aria-pressed','false');openingScreen.querySelector('.opening-stage').append(openingHelp);
const openingReplayExit=uiElement('button','Sair da reprise','secondary opening-replay-exit');openingReplayExit.type='button';openingReplayExit.hidden=true;openingScreen.querySelector('.opening-stage').append(openingReplayExit);openingReplayExit.onclick=async()=>{if(!openingReplay||openingBusy)return;closeOpening();openingReplay=false;await loadJourney();};
openingHelp.onclick=()=>{openingHintsShown=!openingHintsShown;openingHelp.setAttribute('aria-pressed',String(openingHintsShown));openingHelp.textContent=openingHintsShown?'Ocultar dicas':'Preciso de uma dica';openingRoomSignature='';openingRefreshRoomUI();};
const openingBroadcastControls=uiElement('div',undefined,'opening-broadcast-controls');openingBroadcastControls.hidden=true;openingBroadcastControls.setAttribute('aria-label','Acompanhar a final regional');
for(const [side,label]of [[0,'Acompanhar Jamile'],[1,'Acompanhar Gollia']]){const b=uiElement('button',label,'secondary');b.type='button';b.setAttribute('aria-pressed',String(side===0));b.onclick=()=>{openingBroadcastSide=side;for(const [n,button]of [...openingBroadcastControls.children].entries())button.setAttribute('aria-pressed',String(n===side));};openingBroadcastControls.append(b);}
openingScreen.querySelector('.opening-stage').append(openingBroadcastControls);
const openingNameScene=uiElement('section',undefined,'opening-naming-scene');openingNameScene.hidden=true;openingNameScene.setAttribute('aria-labelledby','openingBirthTitle');
openingNameScene.innerHTML='<div class="opening-birth-art"><span>UM ELO ACABA DE NASCER</span><canvas id="openingPartnerPortrait" width="640" height="640" role="img" aria-label="Seu novo parceiro Rabbito animado"></canvas><small>Papel, vento e uma história só de vocês.</small></div><div class="opening-birth-record"><small>SEU PRIMEIRO SOULMONSTER</small><h2 id="openingBirthTitle">Rabbito</h2><p>Do seu desenho, nasceu um parceiro.<br>Como ele vai se chamar?</p><dl id="openingBirthStats"></dl><div id="openingNameSlot"></div><p id="openingNameStatus" role="status"></p></div>';
openingScreen.querySelector('.opening-stage').append(openingNameScene);$('openingNameSlot').append($('openingNameForm'));
bench.querySelector('h2').textContent='Sua primeira criação';bench.querySelector('p').textContent='Pegue a vareta e leve até o encaixe na armação.';$('openingProjectArt').tabIndex=0;$('openingProjectArt').setAttribute('aria-label','Bancada em primeira pessoa. Pegue a vareta com o botão ou arraste; setas movem e Enter encaixa.');
const openingBenchScene=openingScreen.querySelector('.opening-stage');
function openingImmersiveScene(i){
 openingHintsShown=false;openingHintSince=performance.now();openingImpactAt=null;openingMotherArrivedAt=null;openingHelp.hidden=true;openingHelp.textContent='Preciso de uma dica';openingHelp.setAttribute('aria-pressed','false');
 openingBroadcastControls.hidden=i>1;openingNameScene.hidden=i!==10;openingReplayExit.hidden=!openingReplay;openingScreen.classList.toggle('broadcast-moment',i<2);openingRod.grabbed=false;openingRod.pointer=null;openingRod.x=1180;openingRod.y=550;
 if(i===10){const stats=eng.pipamons.stats(1);$('openingBirthStats').replaceChildren();for(const [label,value]of [['Nível','1'],['Origem','Rabiola Antiga'],['Linha',Math.round(stats.line)],['Energia',Math.round(stats.energy)],['Velocidade',Math.round(stats.speed)],['Elo','Primeiro parceiro']]){const div=document.createElement('div'),dt=document.createElement('dt'),dd=document.createElement('dd');dt.textContent=label;dd.textContent=value;div.append(dt,dd);$('openingBirthStats').append(div);}}
}
function openingImmersiveTick(t){
 openingHelp.hidden=!openingRoomStep()||openingWorkbench||openingGiftOpen||t-openingHintSince<18000;
 openingBenchScene.classList.toggle('at-workbench',openingWorkbench);
 if(openingState?.step<2)drawOpeningRegionalFinal($('openingCanvas').getContext('2d'),t);
 if(openingState?.step===10){const g=$('openingPartnerPortrait').getContext('2d');g.clearRect(0,0,640,640);art.creature(g,0,t,50,40,540,{soul:'rabbito',animate:!art.reduced});$('openingNameStatus').textContent=$('openingStatus').textContent;}
}
function drawOpeningRegionalFinal(g,t){
 const w=1536,h=1024,time=art.reduced?1200:t,cycle=time%4200/4200,press=Math.max(0,Math.sin(cycle*Math.PI*2)),focus=openingBroadcastSide;
 g.save();g.fillStyle='#8bbdc5';g.fillRect(0,0,w,h);art.background(g,ART_CONFIG.designs.scenes.morro,0,0,w,h);
 g.fillStyle='#123d4d55';g.fillRect(0,0,w,h);g.fillStyle='#fff3d4';g.fillRect(70,80,1396,106);g.fillStyle='#244f52';g.font='bold 26px Nunito,sans-serif';g.textAlign='left';g.fillText('FINAL REGIONAL',110,124);g.font='22px Nunito,sans-serif';g.fillText('Jamile  /  Carcará',110,162);g.textAlign='right';g.fillText('Gollia  /  Azulão',1426,162);g.fillStyle='#b94f39';g.font='bold 20px Nunito,sans-serif';g.fillText('● AO VIVO',1426,121);
 const a={x:440+Math.sin(time/950)*55,y:530+Math.cos(time/750)*28},b={x:1090-press*180,y:480+Math.sin(time/850)*30};
 g.strokeStyle='#e8ba69';g.lineWidth=4;g.beginPath();g.moveTo(150,960);g.quadraticCurveTo(380,760,a.x,a.y);g.stroke();g.strokeStyle='#c3dfdf';g.beginPath();g.moveTo(1380,960);g.quadraticCurveTo(1180,700,b.x,b.y);g.stroke();
 art.creature(g,0,time,a.x-190,a.y-180,380,{id:'opening-jamile',facing:1,input:{x:.5},hitFlash:press>.8?.15:0});art.creature(g,2,time,b.x-190,b.y-180,380,{id:'opening-gollia',facing:-1,input:{x:-1},skillCooldown:press>.7?6.7:0});
 if(press>.8&&!art.reduced){g.strokeStyle='#fff6bb';g.lineWidth=6;g.beginPath();g.moveTo(a.x+110,a.y);g.lineTo(b.x-100,b.y);g.stroke();}
 g.fillStyle='#153b43dd';g.beginPath();g.roundRect(focus?850:220,760,460,92,18);g.fill();g.fillStyle='#fff1cf';g.font='bold 25px Nunito,sans-serif';g.textAlign='center';g.fillText(focus?'Gollia pressiona pelas laterais':'Jamile procura uma abertura',focus?1080:450,816);g.restore();
}
function openingBenchPoint(e){const r=$('openingProjectArt').getBoundingClientRect(),s=Math.min(r.width/1536,r.height/1024),x=(e.clientX-r.left-(r.width-1536*s)/2)/s,y=(e.clientY-r.top-(r.height-1024*s)/2)/s;return {x,y};}
function openingReleaseRod(){
 if(!openingRod.grabbed)return;openingRod.grabbed=false;openingRod.pointer=null;
 if(Math.hypot(openingRod.x-620,openingRod.y-538)<105){openingCraftAt=performance.now();$('openingBenchPlace').disabled=true;$('openingBenchStatus').textContent='A armação está firme.';}
 else{openingRod.x=1180;openingRod.y=550;$('openingBenchStatus').textContent='Tente aproximar a vareta da linha clara no corpo da pipa.';}
}
const openingBenchCanvas=$('openingProjectArt');
openingBenchCanvas.addEventListener('pointerdown',e=>{if(!openingWorkbench||openingBusy||openingCraftAt!==null||e.button>0)return;const p=openingBenchPoint(e);if(Math.hypot(p.x-openingRod.x,p.y-openingRod.y)>145)return;e.preventDefault();openingRod.grabbed=true;openingRod.pointer=e.pointerId;openingBenchCanvas.setPointerCapture(e.pointerId);Object.assign(openingRod,p);});
openingBenchCanvas.addEventListener('pointermove',e=>{if(openingRod.grabbed&&openingRod.pointer===e.pointerId)Object.assign(openingRod,openingBenchPoint(e));});
openingBenchCanvas.addEventListener('pointerup',e=>{if(openingRod.pointer===e.pointerId)openingReleaseRod();});
openingBenchCanvas.addEventListener('pointercancel',()=>{openingRod.grabbed=false;openingRod.pointer=null;openingRod.x=1180;openingRod.y=550;});
openingBenchCanvas.addEventListener('keydown',e=>{if(!openingWorkbench||!openingRod.grabbed)return;const move={ArrowLeft:[-28,0],ArrowRight:[28,0],ArrowUp:[0,-28],ArrowDown:[0,28]}[e.key];if(move){e.preventDefault();openingRod.x=Math.max(120,Math.min(1400,openingRod.x+move[0]));openingRod.y=Math.max(120,Math.min(900,openingRod.y+move[1]));}if(e.key==='Enter'||e.key===' '){e.preventDefault();openingReleaseRod();}});
function drawOpeningFirstPersonBench(t){
 const im=openingImages.get('project'),g=openingBenchCanvas.getContext('2d');if(!im||!g)return;g.clearRect(0,0,1536,1024);
 const bg=openingImages.get('first-person-bench');if(bg)g.drawImage(bg,0,0,1536,1024);else{g.fillStyle='#bc8b4d';g.fillRect(0,0,1536,1024);}
 g.fillStyle='#fff0d5';g.shadowColor='#173d3a55';g.shadowBlur=25;g.beginPath();g.roundRect(190,90,770,825,16);g.fill();g.shadowBlur=0;
 g.drawImage(im,0,0,1070,1024,255,128,1070*.63,1024*.63);
 const p=openingCraftAt===null?0:art.reduced?1:Math.min(1,(t-openingCraftAt)/650),ease=p*p*(3-2*p),x=openingRod.x+(620-openingRod.x)*ease,y=openingRod.y+(538-openingRod.y)*ease;
 if(openingCraftAt===null){g.save();g.globalAlpha=.45;g.strokeStyle='#fff5cf';g.lineWidth=10;g.setLineDash([12,10]);g.beginPath();g.moveTo(570,500);g.lineTo(670,576);g.stroke();g.restore();}
 g.save();g.translate(x,y);g.rotate(.65*(openingCraftAt!==null?ease:(openingRod.grabbed ? .6 : 0)));g.drawImage(im,1070,450,466,400,-105,-90,210,180);g.restore();
 if(openingRod.grabbed){g.save();g.translate(openingRod.x+18,openingRod.y+26);g.scale(1.4,1.4);drawCraftHand(g,1);g.restore();}
 if(openingCraftAt!==null&&p===1&&!openingCraftSaving)openingFinishCraft();
}
/* OPENING_CRAFT_HAND */
function openingTickActor(nav,actor,input,dt){const before={x:actor.x,y:actor.y};nav.tick(actor,isometricInput(input),dt);advanceAvatarWalk(actor,actor.x-before.x,actor.y-before.y);const d=openingProjectPoint({x:actor.x-before.x,y:actor.y-before.y});if(Math.hypot(d.x,d.y)>.01){actor.direction=screenDirection(d.x,d.y);actor.avatarDir=avatarModel.facingIso(d.x,d.y,actor.avatarDir);}}
