function worldMissionContext(next){const c=worldRoadChapter();if(c)next=trails.stage(c.stage);return {worldId:worldIsMorro()?'morro':worldRuntime.id,roadCleared:['open','complete'].includes(worldRoadGateState()?.state),roadFinal:worldRoadGateState()?.state==='complete',nearStage:worldRuntime.near?.stage,rivals:next?.foes.map(f=>f.name).join(' e '),place:next&&ART_CONFIG.courtyard.places[trails.trails[next.trailIndex].id]?.places[next.index]?.[0]};}
const worldActors=createWorldActors(homeArt.world?.actors);
const worldCompanions=createWorldCompanions(homeArt.world?.companions);
const worldCompanionLoads=new Map();
function loadWorldCompanionImage(id,retry=false){const key='world-companion-'+id;if(homeImages.has(key))return Promise.resolve(true);if(worldCompanionLoads.has(id)&&!retry)return worldCompanionLoads.get(id);const pending=homeLoadImage(key,retry);worldCompanionLoads.set(id,pending);return pending;}
async function loadWorldActors(names,retry=false){return Promise.all(names.map(async name=>{const actor=worldActors.get(name);if(actor&&await homeLoadImage('world-npc-'+actor.id,retry))return true;const rival=ART_CONFIG.designs.rivals?.[name];if(rival){homeArt.images['rival-'+name]=rival;return homeLoadImage('rival-'+name,retry);}return false;}));}
async function loadWorldRivals(retry=false){await loadWorldActors(Object.keys(ART_CONFIG.designs.rivals||{}),retry);await art.load('leader-mikka',retry);}
// Explorable places share art direction, camera, actor scale and existing server encounters.
const worldScenes=homeArt.world?.scenes||{},worldRuntime={id:'quintal',owner:null,states:{},camera:null,near:null,error:'',loading:false};
// Authored campaign areas are installed below; keep the blockout for art review.
const worldMapMode=new URLSearchParams(location.search).get('overworld');
if(worldMapMode==='blockout'&&homeArt.world?.pilot)worldScenes.morro=homeArt.world.pilot;
/* WORLD_ROAD_CLIENT */
const parkStreet=worldScenes.quintal,parkAnchor=parkStreet.places.find(p=>p.action==='farm');if(parkAnchor)Object.assign(parkAnchor,{name:'Parque dos Ventos · exploração',action:'street_scene',target:'park-trail'});
for(const [id,scene]of Object.entries(worldScenes)){const navigation=createWorldNavigation(scene);worldRuntime.states[id]={navigation,actor:navigation.create()};}
const worldKeys=new Set();
function worldGrass(state,scene){
 if(!state.tallGrass){const habitats=(scene.tiled?.layers.Walkable||[]).filter(r=>r.properties.encounter_zone);state.tallGrass=createTallGrass(habitats,{project:p=>({x:p.x,y:p.y})});state.grassWind=0;}
 return state.tallGrass;
}
function worldWalkActive(){return !!playerAccount&&!gameLoading.active&&!mode&&!courtyard.hidden&&!courtyard.inert&&!worldRuntime.loading&&!worldRuntime.error&&!document.body.classList.contains('in-opening')&&gameMenu.hidden&&cityScreen.hidden&&$('journeyDialog').hidden&&$('partnerChoice').hidden&&!$('worldDiscovery')?.open&&!document.querySelector('dialog[open]');}
function worldClearWalking(){worldKeys.clear();if(typeof padState!=='undefined')padState.x=padState.y=0;}
function worldInput(){const x=(worldKeys.has('d')||worldKeys.has('arrowright')?1:0)-(worldKeys.has('a')||worldKeys.has('arrowleft')?1:0),y=(worldKeys.has('s')||worldKeys.has('arrowdown')?1:0)-(worldKeys.has('w')||worldKeys.has('arrowup')?1:0);if(x||y)return {x,y};return typeof padState!=='undefined'&&inputDevice.startsWith('gamepad')?{x:padState.x,y:padState.y}:{x:0,y:0};}
function worldIsEntrance(place){return ['street_scene','road_next','road_back','quintal','city'].includes(place.action);}
function worldEntranceHeading(place){if(place.action==='city')return 2;
 // The park is on the south edge of the new square. Returning must place the
 // player north of its portal; spawning south forces the next route through it.
 if(worldRuntime.id==='quintal'&&place.target==='park-trail')return 0;
 return place.action==='road_back'||place.action==='quintal'||place.action==='street_scene'&&worldRuntime.id!=='quintal'&&place.target!=='kael-bedroom'?0:3;}
function worldArriveAtDoor(place){
 const s=worldState(),p=s.navigation.nodes[place.node],heading=worldEntranceHeading(place),vectors=[[0,-64],[64,0],[-64,0],[0,64]],preferred=vectors[heading];
 s.navigation.target(s.actor,p,true);
 const inward=[preferred,...vectors].map(([x,y])=>({x:p.x+x,y:p.y+y})).find(q=>!s.navigation.geometry||s.navigation.geometry.segment(p,q));
 if(inward)s.navigation.target(s.actor,inward,true);s.actor.direction=[3,2,1,0][heading];worldRuntime.portalLatch=place.id;
}
function worldProfessorReminder(previous){
 if(worldRuntime.id!=='quintal'||!journey||!['arrival','choose','practice'].includes(journey.phase)||openingState?.step<14)return false;
 const state=worldState(),door=worldScene().places.find(p=>p.target==='professor-home'),point=door&&state.navigation.nodes[door.node];
 if(!point||state.actor.x<=point.x+224||state.actor.x<=previous.x)return false;
 // Stop both direct input and click routes before any farther portal can fire.
 Object.assign(state.actor,previous);state.actor.path=[];state.actor.moving=false;state.parkPending=null;
 state.actor.history=state.actor.history.filter(p=>p.x<=point.x+224);worldClearWalking();
 dialogue('Kael','eu preciso ver o professor primeiro','Continuar',()=>{hideJourney();$('courtyardCanvas').focus({preventScroll:true});},{speaker:'Kael'});
 return true;
}
function worldAutoEnter(previous){
 if(!worldWalkActive()||worldState().avatarActivity||!worldState().actor.moving)return;const state=worldState(),scene=worldScene(),actor=state.actor;
 if(worldProfessorReminder(previous))return;
 if(worldRuntime.portalLatch){const latched=scene.places.find(p=>p.id===worldRuntime.portalLatch);if(!latched||state.navigation.distance(actor,state.navigation.nodes[latched.node])>45)worldRuntime.portalLatch=null;}
 const portal=scene.places.find(p=>worldIsEntrance(p)&&p.id!==worldRuntime.portalLatch&&state.navigation.distance(actor,state.navigation.nodes[p.node])<=22&&state.navigation.distance(actor,state.navigation.nodes[p.node])<state.navigation.distance(previous,state.navigation.nodes[p.node])-.001);
 if(!portal)return;if(portal.action==='road_next'&&!['open','complete'].includes(worldRoadGateState()?.state))return;
 worldRuntime.near=portal;worldRuntime.portalLatch=portal.id;interactWorld();
 const back=worldScene().places.filter(worldIsEntrance).sort((a,b)=>worldState().navigation.distance(worldState().actor,worldState().navigation.nodes[a.node])-worldState().navigation.distance(worldState().actor,worldState().navigation.nodes[b.node]))[0];if(back&&worldState().navigation.distance(worldState().actor,worldState().navigation.nodes[back.node])<50)worldArriveAtDoor(back);
}
function drawWorldEntrance(g,place,time){
 if(!worldIsEntrance(place))return;const state=worldState(),p=state.navigation.nodes[place.node],open=place.action!=='road_next'||['open','complete'].includes(worldRoadGateState()?.state);if(!open)return;
 const near=worldRuntime.near?.id===place.id,bob=art.reduced?0:Math.sin(time/350)*2;
 g.save();g.translate(p.x,p.y-14+bob);const down=place.action==='road_back'||place.action==='quintal'||place.action==='street_scene'&&worldRuntime.id!=='quintal'&&place.target!=='kael-bedroom';g.rotate(place.action==='city'?Math.PI/2:down?Math.PI:0);g.strokeStyle=near?'#d9f5ff':'#9ddcf5';g.fillStyle=near?'#348fe5':'#317bb6';g.lineWidth=2;g.beginPath();g.moveTo(-9,3);g.lineTo(0,-5);g.lineTo(9,3);g.lineTo(0,0);g.closePath();g.fill();g.stroke();g.restore();
}
function worldState(){return worldRuntime.states[worldRuntime.id];}
function worldScene(){return worldScenes[worldRuntime.id];}
function worldPlaceLabel(place){if(worldRoadChapter()&&['road_next','road_gate'].includes(place.action))return place.name+' · '+worldRoadGateLabel(worldRoadChapter(),worldRoadGateState());if(!place.stage)return place.name;const st=trails.stage(place.stage),open=trails.unlocked(trailProgress,place.stage);const who=!st?place.name:st.boss&&!open?'Encontro final':st.foes.map(f=>f.name).join(' e ');return who+(open?(trailProgress.stars[place.stage]?' · vencido':''):' · bloqueado');}
function refreshWorldHUD(){
 if(!$('worldPlace')||!playerAccount)return;
 if(worldRuntime.owner!==playerAccount.profile.id){worldRuntime.owner=playerAccount.profile.id;worldRuntime.id='quintal';for(const state of Object.values(worldRuntime.states)){state.actor=state.navigation.create();state.avatarActivity=null;state.tallGrass?.reset();}worldRuntime.camera=null;worldRuntime.near=null;worldRuntime.error='';worldRuntime.loading=!homeImages.has('world-kit-street-quintal');renderWorldDestinations();}
 courtyard.classList.toggle('world-painted',!!worldScene().painted||!!worldScene().isometric);$('worldName').textContent=worldScene().name;courtyard.setAttribute('aria-label',worldScene().name);$('courtyardCanvas').setAttribute('aria-label',worldScene().name+'. Caminhe com setas ou WASD, clique ou toque no chão; E para interagir.');updateWorldContext();
}
function renderWorldDestinations(){
 if(!$('worldDestination'))return;
 const option=(label,value)=>{const o=uiElement('option',label);o.value=value;return o;};$('worldDestination').replaceChildren(option('Caminhar até…',''),...worldScene().places.map(p=>option(worldPlaceLabel(p),p.id)));
}
function updateWorldContext(){
 if(!$('worldPlace'))return;const state=worldState(),scene=worldScene();if(!state||!scene)return;
 const near=[...scene.places].sort((a,b)=>state.navigation.distance(state.actor,state.navigation.nodes[a.node])-state.navigation.distance(state.actor,state.navigation.nodes[b.node]))[0];
 const nearPoint=near&&state.navigation.nodes[near.node],geometry=state.navigation.geometry;
 worldRuntime.near=near&&state.navigation.distance(state.actor,nearPoint)<=82&&(!geometry||geometry.level(state.actor)===geometry.level(nearPoint)&&geometry.segment(state.actor,nearPoint))?near:null;
 const place=worldRuntime.near,button=$('worldInteract');const missionKey=worldRuntime.id+'|'+(place?.id||'')+'|'+JSON.stringify(trailProgress.stars);if(worldRuntime.missionKey!==missionKey){worldRuntime.missionKey=missionKey;updatePlazaMission();}setText('worldPlace',worldRuntime.loading?'Carregando cenário…':worldRuntime.error||place&&worldPlaceLabel(place)||(typeof inputDevice==='string'&&inputDevice==='touch'?'Toque no caminho para andar · siga a seta azul para entrar':'Setas / WASD / analógico para andar · avance na seta azul para entrar'));
 button.disabled=worldRuntime.loading||!place&&!worldRuntime.error;setText('worldInteract',worldRuntime.error?'Tentar carregar':place?.stage?'Ver desafio · E':place?.target==='park-veredas'?'Entrar nas Veredas · E':place&&worldIsEntrance(place)?'Entrar · E':place?'Interagir · E':'Aproxime-se');
}
async function loadWorldImage(id,retry=false){gameAvatar.load(retry);
 const scene=worldScenes[id];if(!scene)return false;const owner=worldRuntime.owner,epoch=worldRuntime.loadEpoch=(worldRuntime.loadEpoch||0)+1;
 const gate=gameLoading.start('world','Entrando em '+scene.name,{retry:()=>loadWorldImage(id,true),back:()=>{gate.cancel();if(id!=='quintal')openWorld('quintal');else openHomeMenu();}});
 worldRuntime.loading=true;worldRuntime.error='';updateWorldContext();
 const tasks=scene.isometric?[]:scene.tiled?[...new Set(scene.painted?scene.tiled.images.map(i=>i.sheet):Object.keys(scene.art?.kit.sheets||homeArt.world.kit.sheets)),...(worldRoadChapter(id)?[homeArt.world.kit.frames.fence.sheet]:[])].map(sheet=>()=>homeLoadImage('world-kit-'+sheet,retry)):[()=>homeLoadImage('world-'+id,retry)];
 tasks.push(()=>homeLoadImage('plaza-kael',retry));
 if(id==='park-veredas')tasks.push(()=>art.load('lacertubo',retry));
 if(scene.isometric){for(const id of Object.keys(homeArt.world.parkIsometric.images))tasks.push(()=>homeLoadImage('park-iso-'+id,retry));if(scene.village)for(const id of Object.keys(homeArt.world.villageIsometric.images))tasks.push(()=>homeLoadImage('village-iso-'+id,retry));if(!scene.village)tasks.push(()=>loadWorldActors(['Sr. Assis'],retry).then(a=>a.every(Boolean)));}
 if(id==='kael-home')tasks.push(()=>loadWorldActors(['Mãe'],retry).then(a=>a.every(Boolean)));
 if(id==='professor-home'){tasks.push(()=>loadWorldActors(['Sr. Assis'],retry).then(a=>a.every(Boolean)));if(homeArt.images['world-companion-nozinho'])tasks.push(()=>loadWorldCompanionImage('nozinho',retry));}
 if(id==='morro'||worldRoadChapter(id))tasks.push(async()=>{const flags=await loadWorldActors(Object.keys(ART_CONFIG.designs.rivals||{}),retry);return flags.every(Boolean);});
 const kite=playerAccount?.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),companion=worldCompanions.get(kite?.model);
 if(companion)tasks.push(()=>loadWorldCompanionImage(companion.id,retry));else if(kite)tasks.push(()=>art.load(kite.model.soul||art.basic(kite.model.color),retry));
 let done=0;gate.update(0,tasks.length,'Carregando cenário e personagens…');
 try{const flags=await Promise.all(tasks.map(async task=>{const okay=await task();gate.update(++done,tasks.length);return okay;}));if(owner!==worldRuntime.owner||id!==worldRuntime.id||epoch!==worldRuntime.loadEpoch){gate.cancel();return false;}worldRuntime.loading=false;worldRuntime.error=flags.every(Boolean)?'':'Algumas artes não carregaram. Tente carregar novamente.';updateWorldContext();if(worldRuntime.error){gate.fail(worldRuntime.error);return false;}await gate.done();if(typeof campaignScheduleAutosave==='function')campaignScheduleAutosave();return true;}
 catch(e){if(gate.current){worldRuntime.loading=false;worldRuntime.error='O cenário não carregou. Tente novamente.';gate.fail(worldRuntime.error);updateWorldContext();}return false;}
}
function worldArtLoaded(id,okay){if(!$('worldPlace')||worldRuntime.id!==id)return;worldRuntime.loading=false;worldRuntime.error=okay?'':'O cenário não carregou. Você pode usar o menu.';updateWorldContext();}
function openWorld(id,{arrival}={}){
 if(!worldScenes[id]||mode||!requireClubAccount('a exploração'))return;if(id.startsWith('park-')&&!['city','complete'].includes(journey?.phase)){toast('Conclua o primeiro voo com o professor antes de explorar o parque.');return;}
 if(worldRoadChapter(id)&&!worldRoad.canEnter(id,worldRoadProgress())){toast(worldRoadProgress()?'Vença o encontro anterior para abrir esta área.':'Aguarde a confirmação do progresso na conta.');return;}
 if((id==='morro'||worldRoadChapter(id))&&journey?.phase!=='complete'){homeActions.city();return;}
 hideJourney();closeHomeMenu();cityScreen.hidden=true;skyExperiment.hidden=true;closeTrails();cityBriefOpen=false;if(worldState()){worldState().actor.path=[];worldState().actor.moving=false;}worldRuntime.id=id;worldState().avatarActivity=null;worldState().tallGrass?.reset();worldState().parkRenderer?.reset();worldState().parkPending=null;worldRuntime.portalLatch=null;worldClearWalking();worldRuntime.missionKey=null;worldRuntime.camera=null;worldRuntime.near=null;worldRuntime.error='';worldRuntime.loading=false;worldSyncRoadGate();if(arrival){const state=worldState();state.actor=state.navigation.create();if(arrival==='north'){const exit=worldScene().places.find(p=>p.action==='road_next');if(exit)state.navigation.target(state.actor,state.navigation.nodes[exit.node],true);}}showCourtyard();renderWorldDestinations();refreshWorldHUD();loadWorldImage(id);if(id==='morro'||worldRoadChapter(id))loadWorldRivals();if(id==='professor-home')loadWorldActors(['Sr. Assis']);if(id==='kael-home')loadWorldActors(['Mãe']);$('courtyardCanvas').setAttribute('tabindex','-1');$('courtyardCanvas').focus({preventScroll:true});
}
function worldGo(place){
 const state=worldState();if(!state||!place)return;if(worldRoadChapter()&&place.action==='road_next'&&!['open','complete'].includes(worldRoadGateState().state)){const gate=worldScene().places.find(p=>p.action==='road_gate');if(gate)worldGo(gate);toast(worldRoadGateLabel(worldRoadChapter(),worldRoadGateState()));return;}worldWalkTo(state.navigation.nodes[place.node]);if(worldScene().isometric)state.parkPending=place.id;worldRuntime.near=null;updateWorldContext();
}
function worldWalkTo(point){const state=worldState();if(state.avatarActivity?.state.kind==='stairs')return;if(state.avatarActivity?.state.kind==='seat'){state.avatarActivity.leave(()=>worldWalkTo(point));return;}state.avatarActivity=null;state.navigation.target(state.actor,point);if(state.actor.navigationMessage)toast(state.actor.navigationMessage);}
function interactWorld(){
 if(mode||courtyard.hidden||courtyard.inert||document.getElementById('worldDiscovery')?.open)return;if(worldRuntime.error){loadWorldImage(worldRuntime.id,true);if(worldIsMorro())loadWorldRivals(true);else loadWorldActors(['Sr. Assis'],true);return;}
 const place=worldRuntime.near;if(!place)return;
 if(worldRoadInteract(place))return;
 if(place.stage){
  if(!trails.unlocked(trailProgress,place.stage)){toast('Vença o encontro anterior para abrir este desafio.');return;}
  trailPick=place.stage;presentStage(place.stage);modalReturnFocus=$('worldInteract');return;
 }
 if(place.action==='pilot_story'){const dialog=$('worldDiscovery');$('worldDiscoveryTitle').textContent=place.name;$('worldDiscoveryText').textContent=place.story;dialog.showModal();return;}
 if(place.action==='avatarSeat'){const state=worldState();if(state.avatarActivity?.state.kind==='seat'){state.avatarActivity.leave();}else{state.actor.path=[];worldClearWalking();state.avatarActivity=createHomeSeatActivity(state.actor,p=>{state.navigation.target(state.actor,p,true);state.avatarActivity=null;updateWorldContext();});}return;}
 if(place.action==='wildGuide'){homeActions.wildGuide();return;}if(place.action==='wildRest'){homeActions.wildRest();return;}
 if(place.action==='street_scene'){
  const state=worldState();if(state.avatarActivity?.state.kind==='stairs')return;const from=worldRuntime.id;
  const go=()=>{state.avatarActivity=null;openWorld(place.target,{arrival:'door'});const back=worldScene().places.find(p=>p.action==='street_scene'&&p.target===from);const landing=((from==='kael-home'&&place.target==='kael-bedroom')||(from==='kael-bedroom'&&place.target==='kael-home'))&&homeStairLanding(place.target);if(landing){const arrived=worldState();arrived.navigation.target(arrived.actor,landing,true);arrived.actor.avatarDir=landing.avatarDir;worldRuntime.portalLatch=back?.id;}else if(back)worldArriveAtDoor(back);updateWorldContext();};
  if((from==='kael-home'&&place.target==='kael-bedroom')||(from==='kael-bedroom'&&place.target==='kael-home')){state.actor.path=[];worldClearWalking();state.avatarActivity=createHomeStairActivity(from,state.actor,go);return;}
  go();return;
 }
 if(place.action==='quintal'){openWorld('quintal');return;}if(place.action==='pilot_boundary'){toast('Entre as casas, você avista o Parque dos Ventos. O caminho até lá faz parte da próxima etapa do bairro.');return;}homeActions[place.action]?.();
}
function worldShadow(g,x,y,r=16){g.fillStyle='#17394235';g.beginPath();g.ellipse(x,y-2,r,5,0,0,Math.PI*2);g.fill();}
function drawWorldHuman(g,actor,time){
 gameAvatar.setOwner(playerAccount?.profile?.id);const pose=actor.avatarPose,action=pose?.action||(actor.moving?'andar':'parado');
 if(gameAvatar.draw(g,{x:actor.x,y:actor.y-(pose?.lift||0),height:worldScene().actorSize||65,action,dir:pose?.dir||actor.avatarDir||['se','sw','se','ne'][actor.direction??0],time:pose?.time??(actor.moving?actor.avatarWalkTime??time:time)}))return;
 const image=homeImages.get('plaza-kael');if(!image)return;const moving=actor.moving,f=homeArt.plaza.actor.frames[actor.direction+(moving&&Math.floor(time/170)%2?4:0)],b=f.bounds,scale=(worldScene().actorSize||65)/380;worldShadow(g,actor.x,actor.y);g.drawImage(image,f.x,f.y,f.w,f.h,actor.x-(b.x+b.w/2)*scale,actor.y-(b.y+b.h)*scale,f.w*scale,f.h*scale);
}

function drawWorldRival(g,place,time){
 const stage=trails.stage(place.stage);if(!stage||stage.boss&&!trails.unlocked(trailProgress,stage.id))return;
 const node=worldState().navigation.nodes[place.node],height=worldScene().actorSize*1.12;
 stage.foes.forEach((foe,i)=>{const x=node.x+58+i*46,y=node.y-3;worldShadow(g,x,y,13);
  const direction=worldActors.facing(x,y,worldState().actor),chibi=worldActors.draw(g,homeImages,foe.name,x,y,height,{direction,time});
  if(!chibi){const image=homeImages.get('rival-'+foe.name);if(image){const width=height*image.width/image.height;g.drawImage(image,x-width/2,y-height,width,height);}else if(stage.boss)art.draw(g,'leader-mikka','0',x-height*.4,y-height,height*.8,height,true);else return;}
  g.font='bold 13px Nunito, sans-serif';g.textAlign='center';g.lineWidth=4;g.strokeStyle='#fff1d6';g.strokeText(foe.name,x,y-height-8);g.fillStyle='#294b43';g.fillText(foe.name,x,y-height-8);
 });
}
function drawWorldScene(g,time,dt){
 if(!homeArt.world){drawPlazaScene(g,time,dt);return;}
 if(!playerAccount)return;refreshWorldOwner();const state=worldState(),scene=worldScene(),canvas=$('courtyardCanvas'),stage=$('courtyardStage'),width=Math.round(stage.clientWidth)||canvas.width,height=Math.round(stage.clientHeight)||canvas.height;
 if(canvas.width!==width||canvas.height!==height){canvas.width=width;canvas.height=height;}
 // Explicit player movement stays active when ambient animations are paused or reduced.
 const moving=!homeMotionPaused&&!art.reduced;worldSyncRoadGate();worldPrimeCompanionTrail(scene,state);const walkEnabled=worldWalkActive(),manual=walkEnabled?worldInput():{x:0,y:0},before={x:state.actor.x,y:state.actor.y};if(walkEnabled){if(state.avatarActivity?.state.kind==='seat'&&(manual.x||manual.y))state.avatarActivity.leave();if(state.avatarActivity){state.avatarActivity.tick(dt);state.actor.moving=false;if(scene!==worldScene())return;}else if(manual.x||manual.y){state.parkPending=null;const input=scene.isometric?isometricInput(manual):manual;state.navigation.move(state.actor,input,dt);}else state.navigation.step(state.actor,dt);worldAutoEnter(before);if(scene!==worldScene())return;if(typeof stepWildExploration==='function')stepWildExploration(before,time);}else{state.actor.moving=false;worldClearWalking();}
 advanceAvatarWalk(state.actor,state.actor.x-before.x,state.actor.y-before.y,scene.isometric?160:(scene.actorSize||65)*.55);if(scene.isometric){const delta=toIso({x:state.actor.x-before.x,y:state.actor.y-before.y});if(Math.hypot(delta.x,delta.y)>.01){state.actor.direction=screenDirection(delta.x,delta.y);state.actor.avatarDir=avatarModel.facingIso(delta.x,delta.y,state.actor.avatarDir);}drawParkWorld(g,time,dt,state,scene,width,height,walkEnabled,moving);updateWorldContext();if(state.parkPending&&worldRuntime.near?.id===state.parkPending){state.parkPending=null;state.actor.path=[];interactWorld();}return;}
 const target=state.navigation.camera(state.actor,width,height),previous=worldRuntime.camera,blend=art.reduced||!previous?1:1-Math.exp(-dt*9),camera=previous?{x:previous.x+(target.x-previous.x)*blend,y:previous.y+(target.y-previous.y)*blend,scale:target.scale}:target;worldRuntime.camera=camera;
 g.save();g.scale(camera.scale,camera.scale);g.translate(-camera.x,-camera.y);const image=homeImages.get('world-'+worldRuntime.id);if(scene.painted)drawWorldPaintedGround(g,scene,homeImages);else if(scene.art)drawWorldArtGround(g,scene,homeImages);else if(scene.tiled)drawWorldBlockout(g,scene);else if(image)g.drawImage(image,0,0,scene.width,scene.height);else{g.fillStyle='#d1d8a6';g.fillRect(0,0,scene.width,scene.height);}
 for(const place of scene.places)drawWorldEntrance(g,place,time);
 const partnerSize=Math.round(scene.actorSize*.66),equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),follower=state.navigation.follower(state.actor,scene.actorSize*.74),resident=worldPartnerStart(scene,state,follower),actors=[{id:'player',x:state.actor.x,level:state.actor.level,y:state.actor.y,draw:()=>drawWorldHuman(g,state.actor,time)}];
 const companion=worldCompanions.get(equipped?.model),companionKey=playerAccount.profile.id+'|'+(equipped?.id||'');
 if(state.companionKey!==companionKey){state.companionKey=companionKey;state.companionMotion=null;}
 const companionMotion=worldCompanionMotion(state.companionMotion,resident,state.actor.direction);state.companionMotion=companionMotion;
 if(companion&&!homeImages.has('world-companion-'+companion.id))loadWorldCompanionImage(companion.id);
 if(equipped&&!['arrival','choose'].includes(journey?.phase))actors.push({level:state.navigation.geometry?.level(resident)??0,y:resident.y,draw:()=>{worldShadow(g,resident.x,resident.y,partnerSize*.25);if(typeof drawPipamonGlow==='function')drawPipamonGlow(g,eng.pipamons.progress(equipped.pipamon_xp).level,time,resident.x,resident.y-partnerSize*.5,partnerSize*.5,true,!moving);if(!worldCompanions.draw(g,homeImages,equipped.model,resident.x,resident.y,partnerSize,{direction:companionMotion.direction,moving:companionMotion.moving,time}))art.creature(g,equipped.model.color,time,resident.x-partnerSize/2,resident.y-partnerSize,partnerSize,{soul:equipped.model.soul,facing:companionMotion.direction===1?-1:1,animate:companionMotion.moving||moving,input:{x:companionMotion.moving?1:0}})}});
 if(worldIsMorro())for(const place of scene.places)if(place.stage)actors.push({level:state.navigation.geometry?.level(state.navigation.nodes[place.node])??0,y:state.navigation.nodes[place.node].y-3,draw:()=>drawWorldRival(g,place,time)});
 if(state.roadGateClosed)actors.push({level:0,y:state.roadGate.y+state.roadGate.h,draw:()=>drawWorldRoadGate(g)});
 if(worldRuntime.id==='kael-home')actors.push({id:'mother',x:656,y:560,level:0,draw:()=>{worldShadow(g,656,560);worldActors.draw(g,homeImages,'Mãe',656,560,scene.actorSize,{direction:worldActors.facing(656,560,state.actor),time});}});
 if(worldRuntime.id==='professor-home'){
  const p=scene.tiled?.properties||{},px=p.professor_x??365,py=p.professor_y??600,nx=p.nozinho_x??429,ny=p.nozinho_y??619;
  actors.push({id:'sr-assis',x:px,y:py,level:state.navigation.geometry?.level({x:px,y:py})??0,draw:()=>{worldShadow(g,px,py);if(!worldActors.draw(g,homeImages,'Sr. Assis',px,py,scene.actorSize*1.08,{direction:worldActors.facing(px,py,state.actor),time}))art.draw(g,'sr-assis-poses','welcome',px-36,py-100,73,100,true)}});
  if(worldCompanions.get({soul:'nozinho'})&&!homeImages.has('world-companion-nozinho'))loadWorldCompanionImage('nozinho');
  actors.push({x:nx,y:ny,level:state.navigation.geometry?.level({x:nx,y:ny})??0,draw:()=>{worldShadow(g,nx,ny,10);if(!worldCompanions.draw(g,homeImages,{soul:'nozinho'},nx,ny,scene.actorSize*.44,{direction:worldActors.facing(nx,ny,state.actor),time})){const seq=art.atlases.nozinho?.animations?.idle;if(seq)art.draw(g,'nozinho',seq[moving?Math.floor(time/180)%seq.length:0],nx-19,ny-38,38,38,true)}}});
 }
 const grass=worldGrass(state,scene);
 if(walkEnabled){grass.update(dt,state.actor,equipped?resident:null,{reduced:art.reduced});if(moving)state.grassWind+=Math.min(dt,.1);}
 for(const tuft of grass.tufts)actors.push({x:tuft.x,y:tuft.y,level:state.navigation.geometry?.level(tuft)??0,draw:()=>drawTallGrass(g,tuft,{project:p=>p,wind:state.grassWind,paused:!moving})});
 for(const entry of worldRenderQueue(scene,actors)){if(entry.kind==='actor')entry.draw();else drawWorldObject(g,entry,homeImages);}drawTallGrassParticles(g,grass.particles);g.restore();updateWorldContext();
}
function drawParkWorld(g,time,dt,state,scene,width,height,walkEnabled,moving){
 const pack=scene.village?{images:{...homeArt.world.parkIsometric.images,...homeArt.world.villageIsometric.images},rigs:homeArt.world.parkIsometric.rigs}:homeArt.world.parkIsometric,prefix=id=>scene.village&&homeArt.world.villageIsometric.images[id]?'village-iso-':'park-iso-';if(!state.parkRenderer){if(!Object.keys(pack.images).every(id=>homeImages.has(prefix(id)+id))){g.fillStyle='#7ba45b';g.fillRect(0,0,width,height);return;}const images=Object.fromEntries(Object.keys(pack.images).map(id=>[id,homeImages.get(prefix(id)+id)]));state.parkRenderer=(scene.village?createVillageIsometricRenderer:createParkIsometricRenderer)(scene,images,pack,soulgenRigs.environment);}
 const renderer=state.parkRenderer,target=renderer.camera(state.actor,width,height),previous=worldRuntime.camera,blend=art.reduced||!previous?1:1-Math.exp(-dt*7),camera=previous?{...target,x:previous.x+(target.x-previous.x)*blend,y:previous.y+(target.y-previous.y)*blend}:target;worldRuntime.camera=camera;
 const equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),follow=state.navigation.follower(state.actor,scene.actorSize*.74),resident=worldPartnerStart(scene,state,follow),avatarPose=state.avatarActivity?.pose(),entries=[{...state.actor,...(avatarPose?{x:avatarPose.x,y:avatarPose.y}:{}),type:'player',avatarPose,draw:p=>drawWorldHuman(g,{...state.actor,...p,avatarPose},time)}];
 if(scene.tiled.properties.boss_maze)entries.push({x:1264,y:280,type:'guardian',draw:p=>{worldShadow(g,p.x,p.y,46);art.creature(g,2,time,p.x-100,p.y-145,200,{soul:'lacertubo',facing:-1,animate:!reduceMotion});g.fillStyle='#173d39';g.font='bold 14px Nunito,sans-serif';g.textAlign='center';g.fillText('Lacertubo · Nv. 15',p.x,p.y-135);}});
 const projected=renderer.project(resident),key=playerAccount.profile.id+'|'+(equipped?.id||'');if(state.companionKey!==key){state.companionKey=key;state.companionMotion=null;}const motion=worldCompanionMotion(state.companionMotion,projected,state.actor.direction);state.companionMotion=motion;
 if(equipped){const c=worldCompanions.get(equipped.model);if(c&&!homeImages.has('world-companion-'+c.id))loadWorldCompanionImage(c.id);entries.push({...resident,type:'companion',draw:p=>{const size=scene.actorSize*.66;worldShadow(g,p.x,p.y,size*.25);if(!worldCompanions.draw(g,homeImages,equipped.model,p.x,p.y,size,{direction:motion.direction,moving:motion.moving,time}))art.creature(g,equipped.model.color,time,p.x-size/2,p.y-size,size,{soul:equipped.model.soul,facing:motion.direction===1?-1:1,animate:motion.moving||moving});}});}
 if(scene.art?.objects.some(o=>o.sprite?.frame==='park-gazebo'))entries.push({x:310,y:420,type:'npc',overlay:true,draw:p=>{worldShadow(g,p.x,p.y);worldActors.draw(g,homeImages,'Sr. Assis',p.x,p.y,scene.actorSize,{direction:worldActors.facing(310,420,state.actor),time});g.font='bold 12px Nunito,sans-serif';g.textAlign='center';g.fillStyle='#173d39';g.fillText('Sr. Assis',p.x,p.y-scene.actorSize-8);}});
 if(scene.village==='kael-home'){const [mx,my]=HOME_LAYOUT.blocking.mother,d=renderer.project({x:state.actor.x-mx,y:state.actor.y-my});entries.push({x:mx,y:my,action:'pilot_story',draw:p=>{worldShadow(g,p.x,p.y);worldActors.draw(g,homeImages,'Mãe',p.x,p.y,scene.actorSize,{direction:screenDirection(d.x,d.y),time});}});}
 if(scene.village==='professor-home'){const plan=serviceLayout('professor-home'),[x,y]=plan.npc,[nx,ny]=plan.companion,d=renderer.project({x:state.actor.x-x,y:state.actor.y-y});entries.push({x,y,action:'professor',draw:p=>{worldShadow(g,p.x,p.y);worldActors.draw(g,homeImages,'Sr. Assis',p.x,p.y,scene.actorSize*1.08,{direction:screenDirection(d.x,d.y),time});}});entries.push({x:nx,y:ny,draw:p=>{worldShadow(g,p.x,p.y,10);worldCompanions.draw(g,homeImages,{soul:'nozinho'},p.x,p.y,scene.actorSize*.44,{direction:0,time});}});}
 g.fillStyle=scene.village?(scene.village==='quintal'?'#a4c171':'#486960'):'#7ba45b';g.fillRect(0,0,width,height);g.save();g.scale(camera.scale,camera.scale);g.translate(-camera.x,-camera.y);
 renderer.draw(g,state.actor,entries,{time,dt,active:walkEnabled,animate:moving,partner:equipped?resident:null,entrances:scene.places.filter(worldIsEntrance).map(place=>({...place,...state.navigation.nodes[place.node],draw:()=>drawWorldEntrance(g,place,time)}))});g.restore();
}
homeActions.parkMap=()=>{const dialog=$('worldDiscovery'),maze=worldScene().tiled.properties.boss_maze,clearing=worldScene().tiled.properties.scene_id==='park-clearing';$('worldDiscoveryTitle').textContent=worldScene().name;$('worldDiscoveryText').textContent=maze?'Você está além dos muros da cidade. Contorne as cercas vivas até o pátio no nordeste. Lacertubo aguarda lá: parceiro nível 15 recomendado. A saída sul retorna à Clareira do Papel.':clearing?'Explore o capim alto da Clareira do Papel. A saída sul volta ao Jardim das Pipas; o caminho nordeste leva às Veredas do Encanamento e ao guardião.':'Explore o capim alto para encontrar Soulmonsters. O coreto e os bancos oferecem apoio. A saída sul leva à Rua dos Ventos; a saída nordeste leva à Clareira do Papel.';dialog.querySelector('[data-park-map]')?.remove();const image=worldState().parkRenderer?.mapImage;if(image){const c=document.createElement('canvas');c.dataset.parkMap='';c.width=438;c.height=282;c.style.width='100%';c.setAttribute('aria-label',maze?'Mapa das Veredas: trilhas em zigue-zague e guardião no nordeste.':'Mapa do parque: entrada sul, coreto a oeste e habitats ao norte e a leste.');c.getContext('2d').drawImage(image,0,0,438,282);dialog.insertBefore(c,dialog.querySelector('form'));dialog.addEventListener('close',()=>c.remove(),{once:true});}dialog.showModal();};
function refreshWorldOwner(){if(worldRuntime.owner!==playerAccount?.profile.id)refreshWorldHUD();}
addEventListener('keydown',event=>{const key=event.key.toLowerCase();if(!['w','a','s','d','arrowup','arrowdown','arrowleft','arrowright'].includes(key)||!worldWalkActive()||event.ctrlKey||event.metaKey||event.altKey||['INPUT','TEXTAREA','SELECT'].includes(event.target?.tagName))return;event.preventDefault();worldKeys.add(key);});
addEventListener('keyup',event=>worldKeys.delete(event.key.toLowerCase()));addEventListener('blur',worldClearWalking);document.addEventListener('visibilitychange',()=>{if(document.hidden)worldClearWalking();});
function initWorld(){
 if(!homeArt.world)return;courtyard.classList.add('world-ready');$('homeDestinations').replaceChildren();
 const worldOriginalLeave=leave;leave=function(...args){const result=worldOriginalLeave(...args);if(['legacy','blockout','pilot'].includes(worldMapMode))history.replaceState(null,'',location.pathname+'?overworld='+worldMapMode);return result;};
 const panel=uiElement('section',undefined,'world-context plaza-paper');panel.setAttribute('aria-label','Exploração do lugar');panel.innerHTML='<div class="world-location"><b id="worldName"></b><span id="worldPlace" role="status"></span></div><div class="world-controls"><label class="sr-only" for="worldDestination">Escolher destino do passeio</label><select id="worldDestination"></select><button id="worldInteract">Interagir · E</button></div>';
 const discovery=uiElement('dialog',undefined,'world-discovery plaza-paper');discovery.id='worldDiscovery';discovery.setAttribute('aria-labelledby','worldDiscoveryTitle');discovery.innerHTML='<h2 id="worldDiscoveryTitle"></h2><p id="worldDiscoveryText"></p><form method="dialog"><button autofocus>Continuar explorando</button></form>';document.body.append(discovery);
 courtyard.append(panel);$('worldInteract').onclick=interactWorld;$('worldDestination').onchange=()=>{const place=worldScene().places.find(p=>p.id===$('worldDestination').value);if(place)worldGo(place);$('worldDestination').value='';$('courtyardCanvas').focus({preventScroll:true});};
 $('courtyardStage').addEventListener('click',event=>{if(event.target.closest('button,select')||courtyard.inert||mode||!playerAccount||!$('journeyDialog').hidden||!$('partnerChoice').hidden)return;const r=$('courtyardCanvas').getBoundingClientRect(),camera=worldRuntime.camera;if(!camera)return;const point={x:(event.clientX-r.left)*$('courtyardCanvas').width/r.width/camera.scale+camera.x,y:(event.clientY-r.top)*$('courtyardCanvas').height/r.height/camera.scale+camera.y};
  if(worldScene().isometric){const hit=worldState().parkRenderer?.pick(point),id=typeof hit==='string'?hit:null,action=hit?.action||{map:'parkMap',assis:'wildGuide',rest:'wildRest','rest-east':'wildRest'}[id],place=action&&worldScene().places.find(p=>p.action===action&&(!hit?.target||p.target===hit.target)&&(action!=='wildRest'||(id==='rest-east'?p.name==='Descansar no banco leste':p.name!=='Descansar no banco leste')));if(place){worldGo(place);return;}worldState().parkPending=null;worldWalkTo(worldState().parkRenderer?.unproject(point)||fromIso(point));}else worldWalkTo(point);});
 const oldSelectCity=selectCity;selectCity=function(i){oldSelectCity(i);if(i===0)$('cityExplore').onclick=()=>openWorld('morro');};
 const oldTrails=homeActions.trails;homeActions.trails=()=>journey?.phase==='complete'&&firstOpenStage()?.trailIndex===0?openWorld('morro'):oldTrails();homeActions.farm=()=>{hideJourney();closeHomeMenu();openClubDestination('farm')};homeActions.quintal=()=>openWorld('quintal');homeActions.nextEncounter=()=>{const next=trails.stages.find(st=>trails.unlocked(trailProgress,st.id)&&!trailProgress.stars[st.id]);const destination=worldRoadEnabled&&worldRoadChapters.find(c=>c.stage===next?.id);if(destination&&destination.id!==worldRuntime.id){openWorld(destination.id);return;}const place=worldScene().places.find(p=>p.stage===next?.id);if(place){if(worldRuntime.near?.id===place.id)interactWorld();else worldGo(place);}else homeActions.city();};
 const oldReturn=returnToDistrict;returnToDistrict=function(id,won=false){const stage=trails.stage(id);if(!worldIsMorro()||stage?.trailIndex!==0||worldRuntime.owner!==playerAccount?.profile.id)return oldReturn(id,won);closeModal();if(mode)leave();const next=trails.nextStage(id);trailPick=won&&next&&trails.unlocked(trailProgress,next.id)?next.id:id;openWorld(worldRuntime.id);};
 homeActions.worldAdvance=()=>{const exit=worldScene().places.find(p=>p.action==='road_next');if(exit)worldGo(exit);};
 homeActions.motion=()=>{$('homeMotion').click();closeHomeMenu()};homeMenuGroups.optionsGroup.splice(3,0,['motion','Pausar / retomar passeio']);
 addEventListener('keydown',event=>{if(event.key.toLowerCase()==='e'&&!event.ctrlKey&&!event.altKey&&!event.metaKey&&!['INPUT','TEXTAREA','SELECT'].includes(event.target?.tagName)&&!courtyard.hidden&&!courtyard.inert&&$('journeyDialog').hidden&&$('partnerChoice').hidden){event.preventDefault();interactWorld();}});
 renderWorldDestinations();if(playerAccount)refreshWorldHUD();
}
initWorld();

/* CAMPAIGN_CLIENT */
/* RPG_CLIENT */
