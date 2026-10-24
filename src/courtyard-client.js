// Signed-in scene navigation. Authentication and ownership remain server-side.
const homeArt=ART_CONFIG.courtyard,homeFarm=createFarm(),firstFlight=createFirstFlight(eng);
let journeyOwner=null,journeyEpoch=0,journey=null,journeyBusy=false,journeyLoading=false,journeyError='',homeSignature='',homeLast=0,homeDrawAt=0,homeGroupAt=0,homeReplay=false,homePartner=0,firstFlightRun=null,flightSaved=false,flightTalking=false,cityPick=0,homeInvitationHandled=false;
const homeImages=new Map(),homeImageLoads=new Map();
const partners=[{id:'basica',name:'Carcará',color:0,personality:'Destemido e atento',description:'Um rebique preciso para quem gosta de encontrar o momento certo.'},{id:'mata',name:'Mata Verde',color:1,personality:'Rápido e inquieto',description:'Mude de posição com um impulso de velocidade.'},{id:'azulao',name:'Azulão',color:2,personality:'Calmo e protetor',description:'Uma proteção para respirar e preparar seu próximo movimento.'},{id:'raio',name:'Raio de sol',color:3,personality:'Curioso e engenhoso',description:'Alcance cruzamentos com uma faixa de corte ampliada.'}];
const courtyard=document.createElement('section');courtyard.id='courtyard';courtyard.className='courtyard';courtyard.hidden=true;courtyard.setAttribute('aria-label','Rua dos Ventos');
courtyard.innerHTML=`<div class="courtyard-stage" id="courtyardStage"><canvas id="courtyardCanvas" width="1536" height="864" aria-label="Seus Pipamons passeando na Rua dos Ventos"></canvas><div id="homeDestinations">
<button class="scene-destination" data-home-action="collection" style="left:19%;top:43%"><span>Meus parceiros</span></button>
<button class="scene-destination" data-home-action="city" style="left:51%;top:39%"><span>Explorar a cidade</span></button>
<button class="scene-destination" data-home-action="shop" style="left:86%;top:40%"><span>Banca de linhas</span></button>
<button class="scene-destination" data-home-action="summon" style="left:84%;top:61%"><span>Oficina das Almas</span></button>
<button class="scene-destination" data-home-action="friends" style="left:91%;top:84%"><span>Encontro dos amigos</span></button>
<button class="scene-destination" data-home-action="professor" style="left:22%;top:70%"><span>Sr. Assis</span></button></div></div>
<div class="home-hud"><div class="home-identity"><b id="homePlayerName"></b><small id="homePartnerName"></small></div><div class="home-objective"><small>Seu próximo voo</small><b id="homeObjective"></b></div><button class="home-command" id="homeMenuButton">Menu · Esc</button></div>
<div class="home-footer"><span id="homeResidents"></span><button class="home-command" id="homeMotion">Pausar passeio</button></div>
<section class="journey-dialog" id="journeyDialog" aria-labelledby="journeyTitle" hidden><div class="eyebrow">Sr. Assis</div><h2 id="journeyTitle"></h2><p id="journeySpeech"></p><p class="journey-status" id="journeyStatus" role="status"></p><div class="journey-actions"><button class="secondary" id="journeyLater" hidden>Continuar explorando</button><button id="journeyContinue">Continuar</button></div></section>
<section class="partner-choice" id="partnerChoice" aria-labelledby="partnerTitle" hidden>
<header class="starter-heading"><span class="starter-eyebrow">SR. ASSIS · UM NOVO ELO</span><h2 id="partnerTitle">Quem vai encontrar o vento com você?</h2><p id="partnerIntro"></p></header>
<div class="partner-options" id="partnerOptions"></div>
<aside class="starter-advice"><canvas id="starterProfessor" width="160" height="160" aria-hidden="true"></canvas><div><b>Sr. Assis</b><p id="partnerConnection" aria-live="polite"></p></div><span class="starter-advice-kite" aria-hidden="true"></span></aside>
<p class="starter-base-note">Atributos base · Nv. 1 · Os bônus da sua montagem entram no nascimento.</p>
<div class="journey-actions"><button class="secondary" id="partnerBack">Voltar ao professor</button><button class="primary" id="partnerConfirm">Escolher este parceiro</button></div>
<p class="journey-status" id="partnerStatus" role="status"></p></section>`;
document.body.append(courtyard);
const gameMenu=document.createElement('section');gameMenu.id='gameMenu';gameMenu.className='game-menu';gameMenu.hidden=true;gameMenu.setAttribute('role','dialog');gameMenu.setAttribute('aria-modal','true');gameMenu.setAttribute('aria-label','Menu do clube');
gameMenu.innerHTML='<div class="game-menu-panel"><h2 id="homeMenuTitle">Rua dos Ventos</h2><nav id="homeMenuLinks" aria-label="Destinos do clube"></nav><small class="keyboard-hint">Mouse ou Tab para selecionar · Enter para entrar · Esc para voltar</small></div>';document.body.append(gameMenu);
const cityScreen=document.createElement('section');cityScreen.id='cityScreen';cityScreen.className='city-screen';cityScreen.hidden=true;cityScreen.setAttribute('aria-label','Mapa da cidade');
cityScreen.innerHTML='<div class="city-stage"><div class="city-world" id="cityWorld"></div></div><div class="home-hud"><div class="home-identity"><b>A cidade dos ventos</b><small>Encontre seu próximo desafio.</small></div><button class="home-command" id="cityBack">Voltar ao passeio · Esc</button></div><section class="city-brief" aria-live="polite"><canvas id="cityBadge" width="90" height="100" aria-label="Insígnia do bairro"></canvas><div class="eyebrow" id="cityChapter"></div><h2 id="cityName"></h2><p id="cityDescription"></p><p id="cityRecord"></p><div class="journey-actions"><button id="cityExplore">Entrar no bairro</button></div></section>';document.body.append(cityScreen);
const flightCoach=document.createElement('section');flightCoach.className='flight-coach';flightCoach.id='flightCoach';flightCoach.hidden=true;flightCoach.setAttribute('aria-label','Treino com o Nozinho');
flightCoach.innerHTML='<div class="eyebrow" id="flightStep"></div><h2 id="flightTitle"></h2><p id="flightHint"></p><p class="journey-status" id="flightStatus" role="status"></p><div class="journey-actions"><button class="secondary" id="flightExit">Voltar ao passeio</button><button class="secondary" id="flightSkip">Pular treino</button><button class="primary" id="flightNext" hidden>Continuar</button></div>';document.body.append(flightCoach);
for(const destination of courtyard.querySelectorAll('.scene-destination')){destination.style.setProperty('--destination-x',destination.style.left);destination.style.setProperty('--destination-y',destination.style.top);destination.setAttribute('aria-label',destination.textContent.trim());}
let homeMotionPaused=art.reduced;
function homeLoadImage(key,retry=false){
 if(homeImages.has(key))return Promise.resolve(true);if(homeImageLoads.has(key)&&!retry)return homeImageLoads.get(key);
 const p=new Promise(resolve=>{const image=new Image();image.onload=()=>{homeImages.set(key,image);resolve(true)};image.onerror=()=>{homeImageLoads.delete(key);resolve(false)};image.src=homeArt.images[key].url});homeImageLoads.set(key,p);return p;
}
async function loadHomeArt(retry=false){
 const modular=homeArt.world?.scenes.quintal?.art,scene=homeArt.world?'world-quintal':homeArt.plaza?'plaza-plaza':'home',epoch=journeyEpoch,ground=homeArt.world?.scenes.quintal?.painted?homeArt.world.scenes.quintal.tiled.images.map(i=>'world-kit-'+i.sheet):modular?Object.keys(modular.kit.sheets).map(id=>'world-kit-'+id):[scene];await Promise.all([...ground,'city','badges',...(homeArt.plaza?['plaza-kael']:[]),...(homeArt.world?['world-npc-sr-assis']:[])].map(k=>homeLoadImage(k,retry)));await Promise.all(['sr-assis-poses','nozinho',...partners.map(p=>art.basic(p.color))].filter(Boolean).map(id=>art.load(id,retry)));
 if(epoch!==journeyEpoch)return;const okay=ground.every(key=>homeImages.has(key));$('courtyardStage').style.backgroundImage=homeArt.world?.scenes.quintal?.painted||modular?'none':okay?'url("'+homeArt.images[scene].url+'")':'';if(!okay){journeyError='O cenário não carregou. Use o menu ou tente carregar novamente.';$('homeResidents').textContent=journeyError;}if(homeArt.world)worldArtLoaded('quintal',okay);drawCityBadge();drawCityMarkers();
}
function syncHomeInert(){
 const blocked=document.body.classList.contains('in-opening')||!gameMenu.hidden||!cityScreen.hidden||!skyExperiment.hidden||[accountModal,dexOverlay,schoolHub,$('trails'),$('modal'),...document.querySelectorAll('.sheet')].some(el=>!el.hidden&&el.style.display!=='none'&&(el.classList.contains('sheet')||el.style.display==='flex'));
 if(courtyard.inert!==blocked)courtyard.inert=blocked;
}
new MutationObserver(syncHomeInert).observe(document.body,{subtree:true,attributes:true,attributeFilter:['hidden','style']});
function showCourtyard(){
 const show=!!playerAccount&&!mode&&(!param||homeInvitationHandled);courtyard.hidden=!show;document.body.classList.toggle('game-shell',!!playerAccount);if(show){updateHomeIdentity();syncHomeInert();}
}
// A room URL must always leave a visible route to join or cancel after a reload.
// Missing credentials show the invitation; existing tab credentials resume the same seat.
function offerRoomInvitation(){
 if(!playerAccount||mode||!param||homeInvitationHandled)return false;
 homeInvitationHandled=true;showCourtyard();openSheet('friendsSheet');return true;
}
async function recoverRoomInvitation(){
 if(!param||mode||homeInvitationHandled)return;
 const owner=playerAccount?.profile.id||null,saved=roomSessions.read(param,owner);
 if(!saved){offerRoomInvitation();return;}
 homeInvitationHandled=true;showCourtyard();busy=true;
 try{const d=await request('resume',{code:param,token:saved.token});if(playerAccount?.profile.id!==owner)return;token=d.token;trailStage=d.state.trail||null;enter(d.state,d.me,'online',d.code);if(d.state.trail){$('roomChip').hidden=true;if(d.state.soloPaused)openPause();}toast('Conexão recuperada. Você voltou à mesma partida.');}
 catch(e){if(playerAccount?.profile.id!==owner)return;if([401,404,409].includes(e.status))roomSessions.remove(param);openSheet('friendsSheet');toast(e.status===401||e.status===404?'Esta sessão terminou. Você pode entrar em uma nova sala.':'Não foi possível retomar. Tente entrar novamente.');}
 finally{busy=false;}
}
function updateHomeIdentity(){
 if(!playerAccount)return;const p=playerAccount.profile,k=playerAccount.inventory.find(k=>k.id===p.equipped_kite_id);$('homePlayerName').textContent=p.nickname;$('homePartnerName').textContent=journey?.phase==='arrival'||journey?.phase==='choose'?'Um parceiro está esperando por você':k?'Parceiro equipado · '+(k.personal_name||k.model.name):'Seu lugar no clube';
 const signature=p.id+'|'+playerAccount.inventory.map(k=>k.id+':'+k.model_id).join('|');if(signature!==homeSignature){homeSignature=signature;homeFarm.setCollection(playerAccount.inventory);}
 $('homeResidents').textContent=homeFarm.residents.length+' espécies no seu quintal'+(homeFarm.pages>1?' · passeios em grupos':'');
 $('homeMotion').textContent=homeMotionPaused?'Retomar passeio':'Pausar passeio';
 const next=firstOpenStage();$('homeObjective').textContent=journeyLoading?'Preparando seu lugar no clube…':journey?.phase==='arrival'||journey?.phase==='choose'?'Conheça seu primeiro parceiro':journey?.phase==='practice'?'Seu primeiro voo com o Nozinho':journey?.phase==='city'?(journey.starterTutorial?.required?(journey.starterTutorial.modelId?'Monte sua pipa com o Sr. Assis':'Escolha uma rabiola com o Sr. Assis'):'Seu parceiro está pronto. Visite a cidade.'):next?'Visite '+trails.trails[next.trailIndex].name:'Explore a cidade e cuide dos seus parceiros';
 refreshPlazaHUD();
}
async function onCourtyardAccount(){
 const owner=playerAccount?.profile?.id||null;showCourtyard();if(owner===journeyOwner){if(owner)updateHomeIdentity();return;}
 resetOpening(owner);journeyOwner=owner;journeyEpoch++;journey=null;journeyError='';journeyBusy=false;homeReplay=false;journeyLoading=false;homeSignature='';homeFarm.setCollection([]);cityScreen.hidden=true;gameMenu.hidden=true;hideJourney();if(firstFlightRun){firstFlightRun=null;flightCoach.hidden=true;leave();}
 if(typeof resetCampaignClient==='function')resetCampaignClient();for(const key of ['entry','world','opening','campaign','city','club'])gameLoading.cancel(key);if(!owner)return;
 const entry=gameLoading.start('entry','Retomando sua aventura',{retry:()=>loadHomeEntry(owner),back:()=>{entry.cancel();openHomeMenu();}});
 await loadHomeEntry(owner,entry);
}
async function loadHomeEntry(owner,entry){
 entry=entry||gameLoading.start('entry','Retomando sua aventura',{retry:()=>loadHomeEntry(owner)});
 try{const artReady=loadHomeArt();if(param)await recoverRoomInvitation();if(owner===journeyOwner)await loadJourney();const ready=await artReady;if(owner!==journeyOwner){entry.cancel();return;}if(journeyError){entry.fail(journeyError);return;}if(openingState?.step>=14&&!mode&&homeArt.world){await loadWorldImage(worldRuntime.id);entry.cancel();return;}if(!ready&&openingState?.step>=14){entry.fail('O cenário não carregou. Tente novamente.');return;}await entry.done();}
 catch(e){if(owner===journeyOwner)entry.fail(e.message);else entry.cancel();}
}
async function loadJourney(){
 if(!journeyOwner)return;const epoch=journeyEpoch,owner=journeyOwner;journeyLoading=true;updateHomeIdentity();
 try{const d=await accountRequest('journey',{action:'read'});if(epoch!==journeyEpoch||owner!==playerAccount?.profile?.id)return;journey=d.journey;await readOpening();if(epoch!==journeyEpoch||owner!==playerAccount?.profile?.id)return;journeyError='';if(accountModal.style.display==='flex')closeAccount();showCourtyard();if(!mode&&!param)renderJourney();if(typeof campaignResumeOnce==='function')await campaignResumeOnce(owner);}
 catch(e){if(epoch!==journeyEpoch)return;journey=null;journeyError=e.message;if(!mode)renderJourney();}
 finally{if(epoch===journeyEpoch){journeyLoading=false;updateHomeIdentity();}}
}
async function saveJourney(action,body={}){
 if(journeyBusy||!journeyOwner)return null;const epoch=journeyEpoch,owner=journeyOwner;journeyBusy=true;setJourneyBusy(true);
 try{const d=await accountRequest('journey',{action,...body});if(epoch!==journeyEpoch||owner!==playerAccount?.profile?.id)return null;journey=d.journey;journeyError='';if(d.account){playerAccount=d.account;reflectAccount();}updateHomeIdentity();return d;}
 catch(e){if(epoch===journeyEpoch){journeyError=e.message;for(const id of ['journeyStatus','partnerStatus','flightStatus'])$(id).textContent=e.message;}return null;}
 finally{if(epoch===journeyEpoch){journeyBusy=false;setJourneyBusy(false);}}
}
function setJourneyBusy(busy){for(const id of ['journeyContinue','partnerConfirm','partnerBack','flightNext','flightSkip'])$(id).disabled=busy;}
function hideJourney(){courtyard.classList.remove('starter-selecting');$('journeyDialog').hidden=true;$('partnerChoice').hidden=true;$('homeDestinations').inert=false;}
function dialogue(title,text,action,fn,{later=false}={}){
 hideJourney();$('journeyTitle').textContent=title;$('journeySpeech').textContent=text;$('journeyStatus').textContent='';$('journeyContinue').textContent=action;$('journeyContinue').onclick=fn;$('journeyDialog').hidden=false;$('journeyLater').textContent='Continuar explorando';$('journeyLater').hidden=!later;$('journeyLater').onclick=hideJourney;$('homeDestinations').inert=!later;$('journeyContinue').focus({preventScroll:true});
}
function renderJourney(){
 if(mode||!playerAccount)return;if(openingState?.step<14&&!homeReplay){showOpening(false);return;}if(journeyError&&!journey){dialogue('Vamos recuperar seu próximo passo',journeyError,'Tentar novamente',loadJourney,{later:true});return;}
 if(homeArt.world?.street&&worldRuntime.id!=='professor-home'&&!homeReplay){hideJourney();return;}
 if(homeReplay||journey?.phase==='arrival')dialogue('Seu lugar no céu','Chegou numa boa hora. Sou o Sr. Assis, e este é o Nozinho. Antes de visitar a cidade, vamos encontrar um parceiro e sentir o vento.','Conhecer os parceiros',async()=>{if(homeReplay||await saveJourney('welcome'))choosePartner()});
 else if(journey?.phase==='choose')choosePartner();
 else if(journey?.phase==='practice')dialogue('Vamos voar juntos?',openingState?.partner_id?'Sua mãe me contou sobre o desenho e a Rabiola Antiga… Nunca vi um nascimento assim. '+(openingState.partner_name||'Rabbito')+' parece confiar em você. Vamos descobrir juntos como ele encontra o vento? Nozinho vai ajudar, sem perdas nem consumo de itens.':'Seu parceiro está com você. Nozinho vai ajudar a praticar movimento, rebique, energia e habilidade. Aqui não há perdas nem consumo de itens.','Avançar',()=>startFirstFlight());
 else if(journey?.phase==='city'&&journey.starterTutorial?.required)renderStarterTutorial();
 else if(journey?.phase==='city')dialogue('Um corte, uma nova história','Nozinho está bem! Seus parceiros esperam por você na rua. Quando quiser um novo desafio, siga pela rua e conheça o Morro do Sol.','Explorar a cidade',openCity,{later:true});
 else hideJourney();
}
const starterPresentation=[
 {tone:'coral',label:'Precisão',advice:'O Carcará recompensa um cruzamento bem calculado. Ative o Puxão preciso e procure o próximo acerto: ele vai desgastar mais a linha rival.'},
 {tone:'leaf',label:'Agilidade',advice:'Mata Verde gosta de espaço para manobrar. Seu Dash lateral ajuda a sair de uma situação apertada e buscar um novo ângulo.'},
 {tone:'sky',label:'Proteção',advice:'Azulão sabe a hora de resistir. Use Linha firme quando o ataque estiver chegando e aproveite a proteção para se reposicionar.'},
 {tone:'sun',label:'Técnica',advice:'Raio de sol favorece quem observa a linha rival. Com Foco, a faixa de cruzamento aumenta por alguns instantes. Escolha bem a hora de atacar.'}
];
function starterSelectionLabel(p){return (homeReplay?'Treinar com ':journey?.starterTutorial?.required&&journey.phase==='city'?'Escolher rabiola de ':'Escolher ')+p.name;}
function selectStarter(index){
 homePartner=index;const p=partners[index];
 for(const [i,card]of [...$('partnerOptions').children].entries())card.setAttribute('aria-pressed',String(i===index));
 $('partnerConnection').textContent=starterPresentation[index].advice;$('partnerConfirm').textContent=starterSelectionLabel(p);
}
function starterStats(){
 const base=eng.pipamons.stats(1),limit=eng.pipamons.stats(eng.pipamons.maxLevel),list=uiElement('div',undefined,'starter-stats');
 for(const [key,label,format]of [['attack','Ataque',v=>v.toLocaleString('pt-BR',{maximumFractionDigits:2})+'×'],['speed','Voo',v=>Math.round(v).toLocaleString('pt-BR')],['defense','Defesa',v=>v.toLocaleString('pt-BR',{maximumFractionDigits:2})+'×']]){
  const row=uiElement('div',undefined,'starter-stat');row.dataset.stat=key;
  const track=uiElement('span',undefined,'starter-stat-track'),fill=uiElement('i');fill.style.width=Math.min(100,base[key]/limit[key]*100)+'%';track.append(fill);track.setAttribute('aria-hidden','true');
  row.title=label+': '+format(base[key])+(key==='speed'?' unidades por segundo':' do multiplicador base');row.append(uiElement('span',label),track,uiElement('strong',format(base[key])));list.append(row);
 }
 return list;
}
function choosePartner(){
 hideJourney();$('partnerChoice').dataset.choice=homeReplay?'replay':'partner';$('partnerTitle').textContent='Quem vai encontrar o vento com você?';$('partnerChoice').hidden=false;courtyard.classList.add('starter-selecting');$('homeDestinations').inert=true;homePartner=0;
 $('partnerIntro').textContent=homeReplay?'Conheça os quatro estilos e experimente um parceiro neste treino. Sua coleção permanece a mesma.':'Quatro parceiros, quatro jeitos de sentir o vento. Conheça cada um antes de escolher.';
 $('partnerOptions').replaceChildren(...partners.map((p,i)=>{
  const info=starterPresentation[i],skill=eng.type({color:p.color}),card=document.createElement('button');card.className='partner-option starter-card';card.type='button';card.dataset.tone=info.tone;card.setAttribute('aria-pressed',String(i===homePartner));card.setAttribute('aria-label',p.name+' · '+info.label+' · '+skill.skill);
  const scene=uiElement('div',undefined,'starter-card-scene'),painting=document.createElement('canvas');painting.width=300;painting.height=300;painting.dataset.partner=i;painting.setAttribute('aria-hidden','true');
  const mark=uiElement('span',undefined,'starter-mark');mark.setAttribute('aria-hidden','true');mark.innerHTML='<svg viewBox="0 0 32 40"><path d="M16 3 28 16 16 29 4 16Z"/><path d="M16 3v26M4 16h24M16 29v5l5 3-4 2"/></svg>';
  scene.append(uiElement('span',String(i+1).padStart(2,'0'),'starter-card-number'),painting,mark);
  const copy=uiElement('div',undefined,'starter-card-copy'),skillLabel=uiElement('div',undefined,'starter-skill');skillLabel.append(uiElement('span',info.label),uiElement('strong',skill.skill));
  copy.append(uiElement('b',p.name,'starter-name'),uiElement('small',p.personality,'starter-personality'),starterStats(),skillLabel);
  card.append(scene,copy);card.onclick=()=>selectStarter(i);return card;
 }));
 const canvas=$('starterProfessor');art.load('sr-assis-expressions').then(()=>{const g=canvas.getContext('2d');g.clearRect(0,0,160,160);art.draw(g,'sr-assis-expressions','speaking',0,0,160,160,true);});
 selectStarter(0);$('partnerStatus').textContent='';$('partnerOptions').querySelector('button').focus({preventScroll:true});
}
$('partnerBack').onclick=()=>{if(journey?.starterTutorial?.required&&journey.phase==='city'){renderStarterTutorial();return;}hideJourney();dialogue('Sem pressa para escolher','Conhecer seu parceiro é o primeiro passo. Você pode comparar todos antes de confirmar.','Ver parceiros',choosePartner)};
$('partnerConfirm').onclick=async()=>{const chosen=partners[homePartner];if(homeReplay){hideJourney();startFirstFlight();return;}if(journey?.starterTutorial?.required&&journey.phase==='city'){if(await saveJourney('starter-choose',{modelId:chosen.id}))renderStarterTutorial();return;}if(await saveJourney('choose',{modelId:chosen.id})){dialogue('Você e '+chosen.name,chosen.name+' agora faz parte da sua coleção. Vamos dar o primeiro voo juntos? O Nozinho está esperando, e este treino não consome itens nem coloca seu parceiro em risco.','Voar com '+chosen.name,startFirstFlight);}};
function renderStarterTutorial(){
 const tutorial=journey?.starterTutorial;if(!tutorial?.required)return;
 if(!tutorial.modelId){
  dialogue('Agora, suas próprias mãos','Muito bem! Você e seu parceiro já encontraram o vento. Agora escolha uma das quatro rabiolas. Vou lhe dar apenas a rabiola: será você quem montará a pipa e dará vida ao seu novo Soulmonster.','Avançar',chooseStarterTail);
 }else{
  const chosen=partners.find(p=>p.id===tutorial.modelId);
  dialogue('Uma rabiola, um novo elo','A rabiola de '+(chosen?.name||'seu starter')+' está guardada para você. Na bancada vamos montar as varetas, amarrar a linha e cortar o papel. A rabiola entra por último. Seu tutorial termina quando seu parceiro nascer.','Avançar',openStarterWorkshop);
 }
}
function chooseStarterTail(){
 choosePartner();$('partnerTitle').textContent='Qual será o seu próximo elo?';
 $('partnerIntro').textContent='Escolha uma rabiola. Depois, suas mãos vão montar a pipa e despertar seu novo parceiro na Oficina.';
 $('partnerChoice').dataset.choice='tail';
 for(const [i,card] of [...$('partnerOptions').children].entries()){
  const tail=uiElement('span',undefined,'starter-tail-token');tail.append(summonTailArt(partners[i].id),uiElement('span','Rabiola'));card.querySelector('.starter-card-scene').append(tail);
 }
 selectStarter(homePartner);
}
async function openStarterWorkshop(){
 const owner=journeyOwner,epoch=journeyEpoch,tutorial=journey?.starterTutorial;if(!tutorial?.tailId||mode)return;
 try{
  await openClubDestination('collection');if(owner!==journeyOwner||epoch!==journeyEpoch)return;
  await openSummoner();if(owner!==journeyOwner||epoch!==journeyEpoch||!summonOpen)return;
  if(summonData.active&&summonData.active.tailId!==tutorial.tailId)throw new Error('Retome sua montagem em andamento antes de abrir a pipa do tutorial.');
  const tail=summonData.tails.find(t=>t.id===tutorial.tailId);
  if(tail?.status==='damaged')await workshopCall('restore',{tailId:tutorial.tailId});
  const job=summonData.active||await workshopCall('start',{tailId:tutorial.tailId,targetModelId:tutorial.modelId});
  if(owner!==journeyOwner||epoch!==journeyEpoch||!summonOpen)return;
  summonRitual=job;summonData.active=job;workshopPending=null;journey.starterTutorial.jobId=job.id;renderWorkshop();await workshopLoadArt();
 }catch(e){if(owner===journeyOwner&&epoch===journeyEpoch){$('summonMessage').textContent=e.message;toast(e.message);}}
}
function starterTutorialCompleteDialogue(){
 dialogue('Seu primeiro elo está pronto','Você aprendeu a voar e construiu seu próprio parceiro. Ele já está na sua coleção! Nosso primeiro treino termina aqui. Quando quiser, explore a rua e procure novos desafios.','Avançar',hideJourney);
}
function startFirstFlight(){
 if(mode||!playerAccount||journeyLoading||journeyBusy)return;hideJourney();closeHomeMenu();
 const equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),p=homeReplay?partners[homePartner]:{color:equipped?.model.color??0,soul:equipped?.model.soul};
 firstFlightRun=firstFlight.create({...p,lesson:homeReplay?0:journey?.lesson||0,name:playerAccount.profile.nickname,partnerName:homeReplay?null:equipped?.personal_name},Date.now());flightSaved=false;flightTalking=true;enter(firstFlightRun.state,'you','practice');document.body.classList.add('in-first-flight');flightCoach.hidden=false;renderFlightCoach();art.load('nozinho');setText('liveLabel','Sr. Assis e Nozinho');setText('arenaMode','Primeiro voo · treino sem perdas');$('flightNext').focus({preventScroll:true});
}
function firstFlightInstruction(index){
 const device=typeof inputDevice==='string'?inputDevice:'keyboard';
 if(index===3){
  const r=firstFlightRun,p=r?.state.players[0]||{color:selected},pad=device.startsWith('gamepad'),ps=device==='gamepad-ps',touch=device==='touch',action=r?.exercise||'skill';
  if(action==='dodge')return 'Esquiva: '+(pad?'pressione '+(ps?'○':'B'):touch?'toque no botão Esquiva':'pressione Shift ou use o botão Esquiva')+'. Você avança um pouco e evita ataques durante o desvio. Não é a habilidade do parceiro.';
  if(action==='line')return 'Rebicada da linha: segure e solte '+(pad?(ps?'□':'X'):touch?'o botão Rebicada':'R ou o botão Rebicada')+'. Observe a trajetória até a manobra terminar. Ela usa energia e tem sua própria recarga; não substitui o ataque.';
  return 'Habilidade do parceiro · '+eng.type(p).skill+': '+eng.type(p).description+' '+(pad?'Use '+(ps?'L1 ou R1':'LB ou RB'):touch?'Use o botão Habilidade':'Use Q / E ou o botão Habilidade')+'. '+(p.color===1?'Observe o avanço lateral.':p.color===2?'Ative a proteção e deixe Nozinho acertar uma vez.':'Ative e acerte Nozinho enquanto o efeito está ativo.');
 }
 if(device.startsWith('gamepad')){const attack=device==='gamepad-ps'?'✕':'A',skill=device==='gamepad-ps'?'L1 ou R1':'LB ou RB';return ['Use o analógico esquerdo para levar seu parceiro até o círculo.','Chegue ao círculo. Quando a mira ficar verde, pressione '+attack+' para atacar.','Solte '+attack+' para recuperar energia. Você pode continuar voando.','Pressione '+skill+' para experimentar a habilidade do seu parceiro.','Cruze as linhas e pressione '+attack+' para atacar. Nozinho está só treinando.'][index];}
 if(device==='touch')return ['Arraste no céu até o círculo.','Chegue ao círculo e toque no céu para atacar quando a mira ficar verde.','Pare de atacar para recuperar energia. Você pode continuar voando.','Deslize rapidamente para um lado para experimentar a habilidade.','Cruze as linhas e toque para atacar. Nozinho está só treinando.'][index];
 return firstFlight.lessons[index].hint;
}
function refreshFirstFlightInstruction(){if(firstFlightRun&&!firstFlightRun.complete)$('flightHint').textContent=firstFlightInstruction(firstFlightRun.index);}
function renderFlightCoach(){
 if(!firstFlightRun)return;const r=firstFlightRun,l=firstFlight.lessons[r.index];
 $('flightStep').textContent='Sr. Assis';$('flightTitle').textContent=l.title;
 $('flightHint').textContent=r.complete?l.success:firstFlightInstruction(r.index);$('flightStatus').textContent='';
 $('flightNext').hidden=!r.complete&&!flightTalking;$('flightNext').textContent='Avançar';
 $('flightSkip').hidden=true;$('flightExit').hidden=true;
 flightCoach.classList.toggle('is-exercising',!flightTalking&&!r.complete);document.body.classList.toggle('first-flight-speaking',flightTalking||r.complete);
}
function stepFirstFlight(now){
 const r=firstFlightRun;if(!r||flightTalking)return;const exercise=r.exercise;
 firstFlight.tick(r,input(),now);
 if(exercise!==r.exercise){keys={};resetPointer();flightTalking=true;renderFlightCoach();$('flightNext').focus({preventScroll:true});}
 if(r.complete&&!flightSaved){flightSaved=true;keys={};resetPointer();renderFlightCoach();$('flightNext').focus({preventScroll:true});}
}
function drawFirstFlightGuide(){
 const r=firstFlightRun;if(!r||r.complete||r.index!==0&&r.index!==1&&r.index!==4)return;
 ctx.save();ctx.strokeStyle='#267d6b';ctx.fillStyle='#e3ffe4a0';ctx.lineWidth=3;ctx.setLineDash([6,5]);ctx.beginPath();ctx.arc(r.target.x,r.target.y,36,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.setLineDash([]);ctx.fillStyle='#164b46';ctx.font='800 17px Nunito,sans-serif';ctx.textAlign='center';ctx.lineWidth=4;ctx.strokeStyle='#fffbeccc';ctx.strokeText(r.index===0?'Voe até aqui':'Cruze e ataque',r.target.x,r.target.y-48);ctx.fillText(r.index===0?'Voe até aqui':'Cruze e ataque',r.target.x,r.target.y-48);ctx.restore();
}
$('flightNext').onclick=async()=>{const r=firstFlightRun;if(!r)return;if(flightTalking&&!r.complete){flightTalking=false;keys={};attackUntil=skillUntil=dodgeUntil=0;resetPointer();renderFlightCoach();$('sky').focus?.();return;}if(!r.complete)return;const replay=homeReplay;if(!replay&&!await saveJourney('advance',{lesson:r.index+1}))return;if(firstFlightRun!==r)return;if(r.index===4){homeReplay=false;leave();if(replay)dialogue('Bons ventos, parceiro!','Você pode voltar ao professor sempre que quiser. Sua coleção e seus prêmios continuam os mesmos.','Voltar ao passeio',hideJourney);else renderJourney();}else{firstFlight.next(r);flightSaved=false;flightTalking=true;keys={};resetPointer();renderFlightCoach();$('flightNext').focus({preventScroll:true});}};
$('flightExit').onclick=()=>{homeReplay=false;leave()};
$('flightSkip').onclick=async()=>{if(homeReplay){homeReplay=false;leave();return}if(await saveJourney('skip')){leave();renderJourney();}};
function drawCourtyard(t){
 if(courtyard.hidden||mode)return false;if(courtyard.inert){homeLast=t;return true;}if(t-homeDrawAt<1000/30)return true;homeDrawAt=t;const c=$('courtyardCanvas'),g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);
 if(!$('partnerChoice').hidden)for(const painting of $('partnerOptions').querySelectorAll('canvas[data-partner]')){const context=painting.getContext('2d');context.clearRect(0,0,painting.width,painting.height);art.creature(context,+painting.dataset.partner,t,0,0,painting.width,{animate:!art.reduced});}
 const dt=homeLast?Math.min(.1,(t-homeLast)/1000):0;homeLast=t;
 drawWorldScene(g,t,dt);
 return true;
}
$('homeMotion').onclick=()=>{homeMotionPaused=!homeMotionPaused;updateHomeIdentity()};
async function openClubDestination(page){if(mode||!playerAccount)return;hideJourney();closeHomeMenu();const gate=gameLoading.start('club','Abrindo o clube',{retry:()=>openClubDestination(page),back:()=>{gate.cancel();closeAccount();}});try{const accountReady=openAccount();const pageReady=playerAccount&&!mode?navigateClub(page):Promise.resolve();await Promise.all([accountReady,pageReady]);await gate.done();}catch(e){gate.fail(e.message);}}
const homeActions={
 feedback:()=>modal('Ajude a melhorar a demo','<p>Conte onde você estava, o que tentou fazer e o que aconteceu. O formulário pede os passos e o aparelho usado.</p><p><a class="secondary" href="https://github.com/TallysKronos/PipaKlub/issues/new?template=demo-feedback.yml" target="_blank" rel="noopener noreferrer">Abrir formulário de feedback no GitHub</a></p>','Voltar ao clube','Feedback · demo-rc.2'),
 demo:()=>openDemoFinale(),
 lab:()=>{hideJourney();closeHomeMenu();skyOpen()},
 collection:()=>openClubDestination('collection'),summon:()=>openClubDestination('summon'),trades:()=>openClubDestination('trades'),profile:()=>openClubDestination('profile'),history:()=>openClubDestination('history'),events:()=>openClubDestination('events'),
 city:()=>openCity(),
 // Trilhas open straight from the menu once the first flight is done; before that the city flow guides the player.
 trails:()=>{if(!journey||journey.phase!=='complete'){openCity();return;}hideJourney();closeHomeMenu();openTrails()},professor:()=>{if(homeArt.world?.street&&worldRuntime.id!=='professor-home'){openWorld('professor-home');}hideJourney();if(journey?.phase!=='complete')renderJourney();else dialogue('Sempre há um novo vento','Podemos repetir seu primeiro voo, praticar técnicas avançadas ou apenas cuidar dos seus parceiros.','Repetir o primeiro voo',()=>{homeReplay=true;renderJourney()},{later:true})},
 school:()=>{hideJourney();closeHomeMenu();openSchool()},practice:()=>{hideJourney();closeHomeMenu();$('practice').click()},friends:()=>{hideJourney();closeHomeMenu();openSheet('friendsSheet')},quick:()=>{hideJourney();closeHomeMenu();$('quickButton').click()},daily:()=>{hideJourney();closeHomeMenu();$('dailyButton').click()},dex:()=>{hideJourney();closeHomeMenu();openDex()},shop:()=>{hideJourney();closeHomeMenu();openClubDestination('lines').then(loadLineShop)},
 sound:()=>{$('sound').click();closeHomeMenu()},quality:()=>{$('quality').click();closeHomeMenu()},fullscreen:()=>{$('fullscreen').click();closeHomeMenu()},privacy:()=>{closeHomeMenu();if(CLARITY_ID)openConsent()},rules:()=>{closeHomeMenu();showRules()},reload:()=>{loadHomeArt(true);closeHomeMenu()},logout:async()=>{if(mode)return;try{await accountRequest('logout',{});playerAccount=null;reflectAccount();closeHomeMenu();}catch(e){toast(e.message)}},close:()=>closeHomeMenu()
};
for(const b of courtyard.querySelectorAll('[data-home-action]'))b.onclick=()=>homeActions[b.dataset.homeAction]();
const homeMenuGroups={
 // Root: six big destinations (Switch-style tiles). Trilhas and Partida rápida sit one press inside Jogar.
 root:[['playGroup','Jogar','menu-play'],['collection','Parceiros','menu-partners'],['dex','Pipa Dex','menu-dex'],['clubGroup','Clube','menu-club'],['school','Escola','menu-school'],['optionsGroup','Opções','menu-options']],
 playGroup:[['root','← Voltar'],['explorationGroup','Exploração e campanha'],['quick','Partida rápida'],['daily','Céu do dia'],['friends','Jogar com amigos'],['practice','Treino livre'],...(new URLSearchParams(location.search).has('lab')?[['lab','Laboratório · Duelo nas Alturas']]:[])],
 explorationGroup:[['playGroup','← Voltar'],['park','Parque dos Ventos'],['wildResume','Retomar encontro selvagem'],['trails','Trilhas da cidade']],
 clubGroup:[['root','← Voltar'],['farm','Fazenda dos parceiros'],['summon','Oficina das Almas'],['trades','Trocas por convite'],['shop','Banca de linhas'],['history','Meus duelos'],['events','Souls de evento'],['profile','Meu perfil'],['professor','Meu primeiro voo'],['story','Rever a abertura']],
 optionsGroup:[['root','← Voltar'],['save','Save e bancos'],['autosave','Salvamento automático'],['sound','Som'],['quality','Qualidade da imagem'],['fullscreen','Tela cheia'],...(CLARITY_ID?[['privacy','Privacidade']]:[]),['feedback','Enviar feedback da demo'],['rules','Regras'],['reload','Recarregar cenário'],['logout','Sair da conta']]
};
let homeMenuGroup='root';
function renderHomeMenu(group='root'){
 homeMenuGroup=group;$('homeMenuTitle').textContent={root:'Rua dos Ventos',playGroup:'Jogar',explorationGroup:'Exploração e campanha',clubGroup:'Vida no clube',optionsGroup:'Opções'}[group];
 const open=id=>{if(homeMenuGroups[id])renderHomeMenu(id);else{closeHomeMenu();homeActions[id]()}};
 $('homeMenuLinks').className=group==='root'?'home-tiles':'home-list';
 $('homeMenuLinks').replaceChildren(...homeMenuGroups[group].map(([id,label,icon])=>{if(id==='autosave')label='Salvamento automático: '+(campaignData?.autosave_enabled===false?'desligado':'ligado');const b=uiElement('button',icon?undefined:label);b.type='button';b.dataset.destination=id;if(icon){b.className='home-tile';const img=document.createElement('img');img.alt='';img.src=ART_CONFIG.kit?.icons?.[icon]||'';b.append(img,uiElement('strong',label));}b.onclick=()=>open(id);return b}));
 if(group==='root'){const close=uiElement('button','Voltar ao passeio','home-menu-close');close.type='button';close.onclick=closeHomeMenu;$('homeMenuLinks').append(close);}
 $('homeMenuLinks').querySelector('button').focus();
}
function openHomeMenu(){if(mode||!playerAccount)return;gameMenu.hidden=false;renderHomeMenu();syncHomeInert()}
function closeHomeMenu(){gameMenu.hidden=true;syncHomeInert();if(!courtyard.hidden)$('homeMenuButton').focus({preventScroll:true})}
$('homeMenuButton').onclick=openHomeMenu;gameMenu.onclick=e=>{if(e.target===gameMenu)closeHomeMenu()};
for(const [i,d]of homeArt.districts.entries()){const b=uiElement('button',undefined,'city-region'+(i>=3?' future':''));b.style.left=d.marker[0]+'%';b.style.top=d.marker[1]+'%';b.dataset.district=i;b.setAttribute('aria-label',d.name+(i>=3?' · em preparação':''));b.innerHTML='<span class="city-emblem" aria-hidden="true">'+(i>=3?'◇':'⚑')+'</span><small></small>';b.querySelector('small').textContent=d.name;b.onclick=()=>selectCity(i);$('cityWorld').append(b)}
function drawCityBadge(){const im=homeImages.get('badges'),f=homeArt.badges[cityPick];if(!im||!f)return;const c=$('cityBadge'),g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);g.drawImage(im,f.x,f.y,f.w,f.h,3,3,c.width-6,c.height-6)}
function drawCityMarkers(){const im=homeImages.get('badges');if(!im)return;for(const [i,b]of [...$('cityWorld').querySelectorAll('button')].entries()){let c=b.querySelector('canvas');if(!c){b.querySelector('.city-emblem').remove();c=document.createElement('canvas');c.width=80;c.height=90;c.className='city-emblem';c.setAttribute('aria-hidden','true');b.prepend(c)}const g=c.getContext('2d'),f=homeArt.badges[i];g.clearRect(0,0,80,90);g.drawImage(im,f.x,f.y,f.w,f.h,4,3,72,84)}}
function selectCity(i){
 cityPick=i;const d=homeArt.districts[i],trail=trails.trails[i],outsideDemo=trails.demo&&i>0;for(const b of $('cityWorld').querySelectorAll('button')){const index=+b.dataset.district,locked=index<3&&!trails.unlocked(trailProgress,trails.trails[index].stages[0].id);b.setAttribute('aria-pressed',String(index===i));b.classList.toggle('locked',locked);b.setAttribute('aria-label',homeArt.districts[index].name+(index>=3?' · em preparação':locked?' · bloqueado':''));}$('cityChapter').textContent=outsideDemo?'Versão completa · em breve':'Bairro '+String(i+1).padStart(2,'0');$('cityName').textContent=d.name;$('cityDescription').textContent=outsideDemo?'A demo inclui a abertura, o Morro do Sol e o online. Este bairro faz parte da versão completa.':i<3?'Explore cinco lugares deste bairro. Vença cada encontro para abrir caminho e descobrir quem espera no desafio final.':'Este bairro faz parte da expansão da cidade e ainda está em preparação.';
 const next=trail?.stages.find(s=>trails.unlocked(trailProgress,s.id)&&!trailProgress.stars[s.id])||trail?.stages.at(-1),unlocked=i<3&&trails.unlocked(trailProgress,trail.stages[0].id);$('cityExplore').hidden=i>=3||outsideDemo;$('cityExplore').disabled=!unlocked;$('cityExplore').textContent=unlocked?(trail.stages.every(s=>trailProgress.stars[s.id])?'Revisitar '+d.name:'Explorar '+d.name):'Conclua o bairro anterior';$('cityRecord').textContent=outsideDemo?'Fora do conteúdo desta demo. Seu progresso e seus parceiros continuam salvos.':i<3?trail.stages.filter(s=>trailProgress.stars[s.id]).length+' de 5 lugares vencidos · '+(districtLeaderKnown(trail)?'Encontro final: '+d.leader:'Caminhos por descobrir'):'Novos encontros e disputa de títulos chegam na expansão. Nenhum progresso foi concedido.';
 $('cityExplore').onclick=()=>{if(!unlocked)return;cityScreen.hidden=true;cityBriefOpen=true;$('trails').dataset.district=String(i);trailPick=next.id;openTrails();syncHomeInert()};drawCityBadge();
}
async function openCity(){
 if(mode||!playerAccount)return;if(journey?.starterTutorial?.required&&journey.phase==='city'){renderStarterTutorial();return;}if(!journey||['arrival','choose'].includes(journey.phase)){renderJourney();return;}if(journey.phase==='practice'&&journey.starterTutorial?.required){dialogue('Vamos sentir o vento','Antes de criar seu próximo parceiro, vamos terminar o treino com Nozinho. Seu progresso está guardado.','Avançar',startFirstFlight);return;}if(journey.phase==='practice'){dialogue('Vamos terminar seu primeiro voo?','Você pode treinar com o Nozinho ou pular a prática e conhecer a cidade. Nenhuma recompensa é concedida ao pular.','Continuar o treino',startFirstFlight,{later:true});$('journeyLater').hidden=false;$('journeyLater').textContent='Pular e visitar a cidade';$('journeyLater').onclick=async()=>{if(await saveJourney('skip'))openCity()};return;}
 if(journey.phase==='city'&&!await saveJourney('finish'))return;const gate=gameLoading.start('city','Explorando a cidade',{retry:()=>openCity(),back:()=>{gate.cancel();cityScreen.hidden=true;showCourtyard();}});try{if(!await homeLoadImage('city',true))throw new Error('O mapa não carregou. Tente novamente.');hideJourney();closeHomeMenu();cityScreen.hidden=false;$('cityWorld').style.backgroundImage='url("'+homeArt.images.city.url+'")';await trailSync.sync();if(cityScreen.hidden){gate.cancel();return;}selectCity(Math.min(2,firstOpenStage().trailIndex));syncHomeInert();await gate.done();$('cityBack').focus();}catch(e){gate.fail(e.message);}
}
$('cityBack').onclick=()=>{cityScreen.hidden=true;showCourtyard();$('homeMenuButton').focus()};
let cityBriefOpen=false;
const cityOriginalCloseTrails=closeTrails;closeTrails=function(){cityOriginalCloseTrails();if(cityBriefOpen&&!mode){cityBriefOpen=false;cityScreen.hidden=false;selectCity(cityPick);syncHomeInert()}};$('trailsClose').onclick=closeTrails;
const courtyardOriginalEnter=enter;enter=function(...args){cityBriefOpen=false;courtyard.hidden=true;cityScreen.hidden=true;gameMenu.hidden=true;hideJourney();return courtyardOriginalEnter(...args)};
const courtyardOriginalLeave=leave;leave=function(...args){firstFlightRun=null;flightCoach.hidden=true;document.body.classList.remove('in-first-flight','first-flight-speaking');homeInvitationHandled=true;const value=courtyardOriginalLeave(...args);showCourtyard();return value};
const courtyardCloseAccount=closeAccount;closeAccount=function(){courtyardCloseAccount();syncHomeInert();if(!courtyard.hidden)$('homeMenuButton').focus()};$('closeAccount').onclick=closeAccount;clubBack.textContent='← Voltar ao passeio';clubBack.onclick=closeAccount;clubBack.classList.add('same-as-close');
addEventListener('keydown',e=>{
 if(!playerAccount||mode)return;const panel=!gameMenu.hidden?gameMenu:!cityScreen.hidden?cityScreen:!$('partnerChoice').hidden?$('partnerChoice'):!$('journeyDialog').hidden?$('journeyDialog'):null;
 if(e.key==='Escape'){
  if(!gameMenu.hidden){e.preventDefault();e.stopImmediatePropagation();if(homeMenuGroup!=='root')renderHomeMenu(homeMenuGroup==='explorationGroup'?'playGroup':'root');else closeHomeMenu();return;}
  if(!cityScreen.hidden){e.preventDefault();e.stopImmediatePropagation();$('cityBack').click();return;}
  if(!courtyard.hidden&&!courtyard.inert&&!(typeof dexOpen!=='undefined'&&dexOpen)){e.preventDefault();e.stopImmediatePropagation();openHomeMenu();return;}
 }
 if(panel&&e.key==='Tab'){const buttons=[...panel.querySelectorAll('button')].filter(b=>!b.hidden&&!b.disabled&&b.getClientRects().length),first=buttons[0],last=buttons.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last?.focus()}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first?.focus()}}
 if(!gameMenu.hidden&&['ArrowDown','ArrowUp'].includes(e.key)){const buttons=[...$('homeMenuLinks').querySelectorAll('button')],i=buttons.indexOf(document.activeElement);e.preventDefault();buttons[(i+(e.key==='ArrowDown'?1:-1)+buttons.length)%buttons.length].focus()}
 if(!cityScreen.hidden&&['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();const step={ArrowLeft:-1,ArrowRight:1,ArrowUp:-4,ArrowDown:4}[e.key];selectCity(Math.max(0,Math.min(11,cityPick+step)));$('cityWorld').querySelector('[data-district="'+cityPick+'"]').focus()}
 if(!cityScreen.hidden&&e.key==='Enter'&&e.target?.closest?.('.city-region')){e.preventDefault();e.stopImmediatePropagation();if(!$('cityExplore').hidden&&!$('cityExplore').disabled)$('cityExplore').click()}
 if(gameMenu.hidden&&!$('partnerChoice').hidden&&['ArrowLeft','ArrowRight'].includes(e.key)){e.preventDefault();const next=(homePartner+(e.key==='ArrowRight'?1:-1)+partners.length)%partners.length,b=$('partnerOptions').children[next];b.click();b.focus()}
},true);
addEventListener('online',()=>{if(journeyError&&!journey)loadJourney()});
/* OPENING_CLIENT */
onCourtyardAccount();

addEventListener('keydown',e=>{
 if(!firstFlightRun||!(flightTalking||firstFlightRun.complete)||pausedAt||!$('pauseSheet').hidden)return;
 if(['Enter',' '].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat&&!$('flightNext').disabled)$('flightNext').click();}
 else if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','w','a','s','d','q','e','r','Shift'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();}
},true);
