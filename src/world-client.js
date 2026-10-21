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
for(const [id,scene]of Object.entries(worldScenes)){const navigation=createWorldNavigation(scene);worldRuntime.states[id]={navigation,actor:navigation.create()};}
function worldState(){return worldRuntime.states[worldRuntime.id];}
function worldScene(){return worldScenes[worldRuntime.id];}
function worldPlaceLabel(place){if(worldRoadChapter()&&['road_next','road_gate'].includes(place.action))return place.name+' · '+worldRoadGateLabel(worldRoadChapter(),worldRoadGateState());if(!place.stage)return place.name;const st=trails.stage(place.stage),open=trails.unlocked(trailProgress,place.stage);return place.name+(open?(trailProgress.stars[place.stage]?' · vencido':''):' · bloqueado')+(st?.boss&&!open?' · encontro desconhecido':'');}
function refreshWorldHUD(){
 if(!$('worldPlace')||!playerAccount)return;
 if(worldRuntime.owner!==playerAccount.profile.id){worldRuntime.owner=playerAccount.profile.id;worldRuntime.id='quintal';for(const state of Object.values(worldRuntime.states))state.actor=state.navigation.create();worldRuntime.camera=null;worldRuntime.near=null;worldRuntime.error='';worldRuntime.loading=!homeImages.has('world-kit-street-quintal');renderWorldDestinations();}
 courtyard.classList.toggle('world-painted',!!worldScene().painted);$('worldName').textContent=worldScene().name;courtyard.setAttribute('aria-label',worldScene().name);updateWorldContext();
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
 const place=worldRuntime.near,button=$('worldInteract');const missionKey=worldRuntime.id+'|'+(place?.id||'')+'|'+JSON.stringify(trailProgress.stars);if(worldRuntime.missionKey!==missionKey){worldRuntime.missionKey=missionKey;updatePlazaMission();}setText('worldPlace',worldRuntime.loading?'Carregando cenário…':worldRuntime.error||place&&worldPlaceLabel(place)||'Siga os caminhos e encontre um lugar');
 button.disabled=worldRuntime.loading||!place&&!worldRuntime.error;setText('worldInteract',worldRuntime.error?'Tentar carregar':place?.stage?'Ver desafio · E':place?'Interagir · E':'Aproxime-se');
}
async function loadWorldImage(id,retry=false){
 if(worldScenes[id]?.tiled){const owner=worldRuntime.owner;worldRuntime.loading=true;worldRuntime.error='';updateWorldContext();const loaded=await Promise.all([...new Set(worldScenes[id].painted?worldScenes[id].tiled.images.map(i=>i.sheet):Object.keys(worldScenes[id].art?.kit.sheets||homeArt.world.kit.sheets)),...(worldRoadChapter(id)?[homeArt.world.kit.frames.fence.sheet]:[])].map(sheet=>homeLoadImage('world-kit-'+sheet,retry)));if(worldRuntime.owner!==owner||worldRuntime.id!==id)return;worldRuntime.loading=false;worldRuntime.error=loaded.every(Boolean)?'':'Algumas artes não carregaram. Tente carregar novamente.';updateWorldContext();return;}
 const owner=worldRuntime.owner;worldRuntime.loading=true;worldRuntime.error='';updateWorldContext();const okay=await homeLoadImage('world-'+id,retry);
 if(worldRuntime.owner!==owner||worldRuntime.id!==id)return;worldRuntime.loading=false;worldRuntime.error=okay?'':'O cenário não carregou. Você pode usar o menu.';updateWorldContext();
}
function worldArtLoaded(id,okay){if(!$('worldPlace')||worldRuntime.id!==id)return;worldRuntime.loading=false;worldRuntime.error=okay?'':'O cenário não carregou. Você pode usar o menu.';updateWorldContext();}
function openWorld(id,{arrival}={}){
 if(!worldScenes[id]||mode||!requireClubAccount('a exploração'))return;
 if(worldRoadChapter(id)&&!worldRoad.canEnter(id,worldRoadProgress())){toast(worldRoadProgress()?'Vença o encontro anterior para abrir esta área.':'Aguarde a confirmação do progresso na conta.');return;}
 if((id==='morro'||worldRoadChapter(id))&&journey?.phase!=='complete'){homeActions.city();return;}
 hideJourney();closeHomeMenu();cityScreen.hidden=true;skyExperiment.hidden=true;closeTrails();cityBriefOpen=false;worldRuntime.id=id;worldRuntime.missionKey=null;worldRuntime.camera=null;worldRuntime.near=null;worldRuntime.error='';worldRuntime.loading=false;worldSyncRoadGate();if(arrival){const state=worldState();state.actor=state.navigation.create();if(arrival==='north'){const exit=worldScene().places.find(p=>p.action==='road_next');if(exit)state.navigation.target(state.actor,state.navigation.nodes[exit.node],true);}}showCourtyard();renderWorldDestinations();refreshWorldHUD();loadWorldImage(id);if(id==='morro'||worldRoadChapter(id))loadWorldRivals();if(id==='professor-home')loadWorldActors(['Sr. Assis']);if(id==='kael-home')loadWorldActors(['Mãe']);$('worldDestination').focus({preventScroll:true});
}
function worldGo(place){
 const state=worldState();if(!state||!place)return;if(worldRoadChapter()&&place.action==='road_next'&&!['open','complete'].includes(worldRoadGateState().state)){const gate=worldScene().places.find(p=>p.action==='road_gate');if(gate)worldGo(gate);toast(worldRoadGateLabel(worldRoadChapter(),worldRoadGateState()));return;}worldWalkTo(state.navigation.nodes[place.node]);worldRuntime.near=null;updateWorldContext();
}
function worldWalkTo(point){const state=worldState();state.navigation.target(state.actor,point);if(state.actor.navigationMessage)toast(state.actor.navigationMessage);}
function interactWorld(){
 if(mode||courtyard.hidden||courtyard.inert||document.getElementById('worldDiscovery')?.open)return;if(worldRuntime.error){loadWorldImage(worldRuntime.id,true);if(worldIsMorro())loadWorldRivals(true);else loadWorldActors(['Sr. Assis'],true);return;}
 const place=worldRuntime.near;if(!place)return;
 if(worldRoadInteract(place))return;
 if(place.stage){
  if(!trails.unlocked(trailProgress,place.stage)){toast('Vença o encontro anterior para abrir este desafio.');return;}
  trailPick=place.stage;presentStage(place.stage);modalReturnFocus=$('worldInteract');return;
 }
 if(place.action==='pilot_story'){const dialog=$('worldDiscovery');$('worldDiscoveryTitle').textContent=place.name;$('worldDiscoveryText').textContent=place.story;dialog.showModal();return;}
 if(place.action==='street_scene'){const from=worldRuntime.id;openWorld(place.target,{arrival:'door'});const state=worldState(),back=worldScene().places.find(p=>p.action==='street_scene'&&p.target===from);if(back)state.navigation.target(state.actor,state.navigation.nodes[back.node],true);state.actor.direction=place.target==='quintal'?0:3;updateWorldContext();return;}
 if(place.action==='quintal'){openWorld('quintal');return;}if(place.action==='pilot_boundary'){toast('Entre as casas, você avista o Parque dos Ventos. O caminho até lá faz parte da próxima etapa do bairro.');return;}homeActions[place.action]?.();
}
function worldShadow(g,x,y,r=16){g.fillStyle='#17394235';g.beginPath();g.ellipse(x,y-2,r,5,0,0,Math.PI*2);g.fill();}
function drawWorldHuman(g,actor,time){
 const image=homeImages.get('plaza-kael');if(!image)return;const moving=actor.moving,f=homeArt.plaza.actor.frames[actor.direction+(moving&&Math.floor(time/170)%2?4:0)],b=f.bounds,scale=(worldScene().actorSize||65)/380;worldShadow(g,actor.x,actor.y);g.drawImage(image,f.x,f.y,f.w,f.h,actor.x-(b.x+b.w/2)*scale,actor.y-(b.y+b.h)*scale,f.w*scale,f.h*scale);
}

function drawWorldRival(g,place,time){
 const stage=trails.stage(place.stage);if(!stage||stage.boss&&!trails.unlocked(trailProgress,stage.id))return;
 const node=worldState().navigation.nodes[place.node],height=worldScene().actorSize*1.12;
 stage.foes.forEach((foe,i)=>{const x=node.x+35+i*45,y=node.y-3;worldShadow(g,x,y,13);
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
 const moving=!homeMotionPaused&&!art.reduced;worldSyncRoadGate();worldPrimeCompanionTrail(scene,state);state.navigation.step(state.actor,dt);
 const target=state.navigation.camera(state.actor,width,height),previous=worldRuntime.camera,blend=art.reduced||!previous?1:1-Math.exp(-dt*9),camera=previous?{x:previous.x+(target.x-previous.x)*blend,y:previous.y+(target.y-previous.y)*blend,scale:target.scale}:target;worldRuntime.camera=camera;
 g.save();g.scale(camera.scale,camera.scale);g.translate(-camera.x,-camera.y);const image=homeImages.get('world-'+worldRuntime.id);if(scene.painted)drawWorldPaintedGround(g,scene,homeImages);else if(scene.art)drawWorldArtGround(g,scene,homeImages);else if(scene.tiled)drawWorldBlockout(g,scene);else if(image)g.drawImage(image,0,0,scene.width,scene.height);else{g.fillStyle='#d1d8a6';g.fillRect(0,0,scene.width,scene.height);}
 for(const place of scene.places){const p=state.navigation.nodes[place.node],open=!place.stage||trails.unlocked(trailProgress,place.stage),near=worldRuntime.near?.id===place.id;g.strokeStyle=open?'#fff0b1':'#71888c';g.fillStyle=open?'#164a6580':'#293c4655';g.lineWidth=near?3:2;g.beginPath();g.ellipse(p.x,p.y-2,near?18:12,near?8:5,0,0,Math.PI*2);g.fill();g.stroke();}
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
 for(const entry of worldRenderQueue(scene,actors)){if(entry.kind==='actor')entry.draw();else drawWorldObject(g,entry,homeImages);}g.restore();updateWorldContext();
}
function refreshWorldOwner(){if(worldRuntime.owner!==playerAccount?.profile.id)refreshWorldHUD();}
function initWorld(){
 if(!homeArt.world)return;courtyard.classList.add('world-ready');$('homeDestinations').replaceChildren();
 const worldOriginalLeave=leave;leave=function(...args){const result=worldOriginalLeave(...args);if(['legacy','blockout','pilot'].includes(worldMapMode))history.replaceState(null,'',location.pathname+'?overworld='+worldMapMode);return result;};
 const panel=uiElement('section',undefined,'world-context plaza-paper');panel.setAttribute('aria-label','Exploração do lugar');panel.innerHTML='<div class="world-location"><b id="worldName"></b><span id="worldPlace" role="status"></span></div><div class="world-controls"><label class="sr-only" for="worldDestination">Escolher destino do passeio</label><select id="worldDestination"></select><button id="worldInteract">Interagir · E</button></div>';
 const discovery=uiElement('dialog',undefined,'world-discovery plaza-paper');discovery.id='worldDiscovery';discovery.setAttribute('aria-labelledby','worldDiscoveryTitle');discovery.innerHTML='<h2 id="worldDiscoveryTitle"></h2><p id="worldDiscoveryText"></p><form method="dialog"><button autofocus>Continuar explorando</button></form>';document.body.append(discovery);
 courtyard.append(panel);$('worldInteract').onclick=interactWorld;$('worldDestination').onchange=()=>{const place=worldScene().places.find(p=>p.id===$('worldDestination').value);if(place)worldGo(place);$('worldDestination').value='';};
 $('courtyardStage').addEventListener('click',event=>{if(event.target.closest('button,select')||courtyard.inert||mode||!playerAccount||!$('journeyDialog').hidden||!$('partnerChoice').hidden)return;const r=$('courtyardCanvas').getBoundingClientRect(),camera=worldRuntime.camera;if(!camera)return;worldWalkTo({x:(event.clientX-r.left)/camera.scale+camera.x,y:(event.clientY-r.top)/camera.scale+camera.y});});
 const oldSelectCity=selectCity;selectCity=function(i){oldSelectCity(i);if(i===0)$('cityExplore').onclick=()=>openWorld('morro');};
 const oldTrails=homeActions.trails;homeActions.trails=()=>journey?.phase==='complete'&&firstOpenStage()?.trailIndex===0?openWorld('morro'):oldTrails();homeActions.farm=()=>{hideJourney();closeHomeMenu();openClubDestination('farm')};homeActions.quintal=()=>openWorld('quintal');homeActions.nextEncounter=()=>{const next=trails.stages.find(st=>trails.unlocked(trailProgress,st.id)&&!trailProgress.stars[st.id]);const destination=worldRoadEnabled&&worldRoadChapters.find(c=>c.stage===next?.id);if(destination&&destination.id!==worldRuntime.id){openWorld(destination.id);return;}const place=worldScene().places.find(p=>p.stage===next?.id);if(place){if(worldRuntime.near?.id===place.id)interactWorld();else worldGo(place);}else homeActions.city();};
 const oldReturn=returnToDistrict;returnToDistrict=function(id,won=false){const stage=trails.stage(id);if(!worldIsMorro()||stage?.trailIndex!==0||worldRuntime.owner!==playerAccount?.profile.id)return oldReturn(id,won);closeModal();if(mode)leave();const next=trails.nextStage(id);trailPick=won&&next&&trails.unlocked(trailProgress,next.id)?next.id:id;openWorld(worldRuntime.id);};
 homeActions.worldAdvance=()=>{const exit=worldScene().places.find(p=>p.action==='road_next');if(exit)worldGo(exit);};
 homeActions.motion=()=>{$('homeMotion').click();closeHomeMenu()};homeMenuGroups.optionsGroup.splice(3,0,['motion','Pausar / retomar passeio']);
 addEventListener('keydown',event=>{if(event.key.toLowerCase()==='e'&&!event.ctrlKey&&!event.altKey&&!event.metaKey&&!['INPUT','TEXTAREA','SELECT'].includes(event.target?.tagName)&&!courtyard.hidden&&!courtyard.inert&&$('journeyDialog').hidden&&$('partnerChoice').hidden){event.preventDefault();interactWorld();}});
 renderWorldDestinations();if(playerAccount)refreshWorldHUD();
}
initWorld();
