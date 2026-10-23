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
function openingWalkActive(){return !gameLoading.active&&!openingScreen.hidden&&openingRoomStep()&&!openingWorkbench&&!openingBusy&&!openingGiftOpen&&openingAvatarActivity?.state.kind!=='stairs';}
function openingClearWalking(){openingWalkKeys={};openingWalkIntent=null;openingActor.path=[];openingActor.moving=false;}
function openingCloseBench(){openingCraftAt=null;openingCraftSaving=false;openingWorkbench=false;bench.hidden=true;openingRoomSignature='';openingRefreshRoomUI();}
function openingResetRoom(){openingAvatarActivity=null;openingCraftAt=null;openingCraftSaving=false;openingClearWalking();openingRoomNavigation=openingState?.step===13?openingDownstairsNavigation:openingState?.step===11?openingExitNavigation:openingBedroomNavigation;openingWorkbench=false;bench.hidden=true;roomPlaces.hidden=true;openingRoomSignature='';}
function openingNearestSpot(){return openingRoomNavigation.hotspots.filter(p=>openingRoomNavigation.near(openingActor,p.id)).sort((a,b)=>Math.hypot(a.x-openingActor.x,a.y-openingActor.y)-Math.hypot(b.x-openingActor.x,b.y-openingActor.y))[0];}
function openingRefreshRoomUI(){
 roomPlaces.hidden=!openingRoomStep()||openingGiftOpen;if(openingGiftOpen){$('openingSpeaker').textContent='Presente de aniversário';$('openingNext').textContent='Guardar Rabiola Antiga';$('openingNext').disabled=openingBusy;$('openingHint').textContent='Confirmar para guardar o presente';return;}if(!openingRoomStep()){$('openingNext').disabled=openingBusy||openingCastBusy();return;}
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
 openingCraftAt=performance.now();$('openingBenchPlace').disabled=true;$('openingBenchStatus').textContent='Encaixando a vareta…';
};
async function openingFinishCraft(){
 if(openingCraftSaving||!openingWorkbench||openingState?.step!==3)return;
 const epoch=openingEpoch;openingCraftSaving=true;$('openingBenchBack').disabled=true;await advanceOpeningScene();if(epoch!==openingEpoch)return;
 if(openingState?.step===3){openingCraftAt=null;openingCraftSaving=false;$('openingBenchStatus').textContent=$('openingStatus').textContent||'Não foi possível salvar. Tente novamente.';$('openingBenchPlace').disabled=false;}
 $('openingBenchBack').disabled=false;
}
function drawOpeningWorkbench(t){
 if(!openingWorkbench)return;const im=openingImages.get('project'),g=$('openingProjectArt').getContext('2d');if(!im||!g)return;g.clearRect(0,0,1536,1024);
 const p=openingCraftAt===null?0:art.reduced?1:Math.min(1,Math.max(0,(t-openingCraftAt)/950)),ease=p*p*(3-2*p);
 paintOpeningProject(g,im,ease,0,0,1536,1024);
 if(openingCraftAt!==null&&p===1&&!openingCraftSaving)openingFinishCraft();
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
 if(!openingRoomStep()||openingWorkbench)return;
 const room=openingVillageRenderer(openingState.step>=12);
 for(const p of openingRoomNavigation.hotspots){
  const near=openingRoomNavigation.near(openingActor,p.id),q=openingProjectPoint(p),b=room?.feature(p.id);g.save();
  if(b&&p.id!=='stairs'){
   const label=({tv:'TV',drawings:'Desenhos',desk:'Bancada',mother:'Mãe',exit:'Saída',seat:'Sentar'})[p.id],w=label.length*10+24,x=b.x+b.w/2-w/2,y=b.y-28;
   g.fillStyle=near?'#efc66e':'#fff0cf';g.strokeStyle='#28555a';g.lineWidth=2;g.beginPath();g.roundRect(x,y,w,25,7);g.fill();g.stroke();g.font='bold 17px Nunito,sans-serif';g.textAlign='center';g.fillStyle='#214b50';g.fillText(label,x+w/2,y+18);
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
function openingCastBusy(){return (openingState?.step===5&&(!!openingMother.path?.length||!!openingActor.path?.length))||(openingState?.step===8&&!!openingActor.path?.length)||(openingState?.step===9&&(!!openingActor.path?.length||(openingBirthBeat>=2&&openingRabbit.x>1102)));}
function openingStageRoute(actor,nav,target){actor.path=nav.route(actor,target);}
function openingPrepareCast(i){
 const previous=openingCastStep;openingCastStep=i;
 const down=i>=12,nav=down?openingDownstairsNavigation:openingBedroomNavigation;
 if(down&&previous<12){const p=openingHomePlan.blocking;Object.assign(openingActor,{x:p.kaelEntry[0],y:p.kaelEntry[1],direction:1,path:[]});Object.assign(openingMother,{x:p.mother[0],y:p.mother[1],direction:2,path:[]});Object.assign(openingRabbit,{x:p.rabbitoEntry[0],y:p.rabbitoEntry[1],direction:1,path:[]});}
 if(i===5){Object.assign(openingMother,{...openingPoint('motherEntry'),direction:3,path:[]});openingStageRoute(openingMother,nav,openingPoint('mother'));openingStageRoute(openingActor,nav,openingPoint('kaelTalk'));}
 if([6,7,8].includes(i)&&previous<5){Object.assign(openingMother,{...openingPoint('mother'),direction:2,path:[]});}
 if(i===8)openingStageRoute(openingActor,nav,openingPoint('kaelDesk'));
 if(i===9){openingStageRoute(openingActor,nav,openingPoint('kaelBirth'));openingStageRoute(openingMother,nav,openingPoint('mother'));Object.assign(openingRabbit,{...openingPoint('rabbito'),direction:1,path:[]});}
 if([10,11].includes(i)&&previous<9){Object.assign(openingActor,{...openingPoint('kaelBirth'),direction:2,path:[]});Object.assign(openingMother,{...openingPoint('mother'),direction:2,path:[]});Object.assign(openingRabbit,{...openingPoint('rabbitoNear'),direction:1,path:[]});}
}
function openingStepCast(dt){if(openingAvatarActivity){const activity=openingAvatarActivity;if(activity.state.kind==='seat'&&Object.values(openingWalkKeys).some(Boolean))activity.leave();activity.tick(dt);openingRefreshRoomUI();return;}

 const i=openingState?.step??0,nav=i>=12?openingDownstairsNavigation:openingBedroomNavigation;
 if(openingRoomStep())openingStepRoom(dt);else openingTickActor(nav,openingActor,{},dt);
 if(i>=5)openingTickActor(nav,openingMother,{},dt);
 if(i===5&&!openingMother.path?.length){openingMother.direction=2;openingActor.direction=1;}
 if(i===9){openingActor.direction=2;openingMother.direction=2;if(openingBirthBeat>=2&&!openingRabbit.path?.length&&openingRabbit.x>1102)openingStageRoute(openingRabbit,nav,{x:1100,y:640});openingTickActor(nav,openingRabbit,{},dt);}
 if(i>=11){const d=Math.hypot(openingActor.x-openingRabbit.x,openingActor.y-openingRabbit.y);if(d>110&&!openingRabbit.path?.length){const dx=openingActor.x-openingRabbit.x,dy=openingActor.y-openingRabbit.y;const target={x:openingActor.x-dx/d*70,y:openingActor.y-dy/d*70};if(nav.safe(target))openingStageRoute(openingRabbit,nav,target);}openingTickActor(nav,openingRabbit,{},dt);}
 openingRefreshRoomUI();
}
function openingDrawKael(g,t,position=openingProjectPoint(openingActor)){gameAvatar.setOwner(playerAccount?.profile?.id);const pose=openingAvatarActivity?.pose();if(gameAvatar.draw(g,{...position,y:position.y-(pose?.lift||0),height:102,action:pose?.action||(openingActor.moving?'andar':'parado'),dir:pose?.dir||openingActor.avatarDir||'se',time:pose?.time??(openingActor.moving?openingActor.avatarWalkTime??t:t)}))return;const actor={...openingActor,...position},im=openingImages.get('kael'),f=homeArt.plaza.actor.frames[(actor.direction??3)+(actor.moving&&Math.floor(t/170)%2?4:0)];if(!im||!f)return;const b=f.bounds,s=102/b.h;g.drawImage(im,f.x,f.y,f.w,f.h,actor.x-(b.x+b.w/2)*s,actor.y-(b.y+b.h)*s,f.w*s,f.h*s);}
function openingDrawMother(g,t,position=openingProjectPoint(openingMother)){const actor={...openingMother,...position};openingSprite(g,'mother',(actor.direction??0)+(actor.moving&&Math.floor(t/170)%2?4:0),actor.x,actor.y,104);}
function openingDrawRabbit(g,t,position=openingProjectPoint(openingRabbit)){const actor={...openingRabbit,...position};if(worldCompanions.draw(g,homeImages,{soul:'rabbito'},actor.x,actor.y,66,{direction:actor.direction,moving:actor.moving,time:art.reduced?0:t}))return;art.creature(g,0,art.reduced?0:t,actor.x-55,actor.y-110,110,{soul:'rabbito',facing:actor.direction===2?1:-1,input:actor.moving?{x:-1}:{}},openingState?.step===11&&!actor.moving);}

function openingTickActor(nav,actor,input,dt){const before={x:actor.x,y:actor.y};nav.tick(actor,isometricInput(input),dt);advanceAvatarWalk(actor,actor.x-before.x,actor.y-before.y);const d=openingProjectPoint({x:actor.x-before.x,y:actor.y-before.y});if(Math.hypot(d.x,d.y)>.01){actor.direction=screenDirection(d.x,d.y);actor.avatarDir=avatarModel.facingIso(d.x,d.y,actor.avatarDir);}}
