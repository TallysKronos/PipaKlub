// Signed-in scene navigation. Authentication and ownership remain server-side.
const homeArt=ART_CONFIG.courtyard,homeFarm=createFarm(),firstFlight=createFirstFlight(eng);
let journeyOwner=null,journeyEpoch=0,journey=null,journeyBusy=false,journeyLoading=false,journeyError='',homeSignature='',homeLast=0,homeDrawAt=0,homeGroupAt=0,homeReplay=false,homePartner=0,firstFlightRun=null,flightSaved=false,cityPick=0,homeInvitationHandled=false;
const homeImages=new Map(),homeImageLoads=new Map();
const partners=[{id:'basica',name:'Carcará',color:0,personality:'Destemido e atento',description:'Um rebique preciso para quem gosta de encontrar o momento certo.'},{id:'mata',name:'Mata Verde',color:1,personality:'Rápido e inquieto',description:'Mude de posição com um impulso de velocidade.'},{id:'azulao',name:'Azulão',color:2,personality:'Calmo e protetor',description:'Uma proteção para respirar e preparar seu próximo movimento.'},{id:'raio',name:'Raio de sol',color:3,personality:'Curioso e engenhoso',description:'Alcance cruzamentos com uma faixa de corte ampliada.'}];
const courtyard=document.createElement('section');courtyard.id='courtyard';courtyard.className='courtyard';courtyard.hidden=true;courtyard.setAttribute('aria-label','Quintal do Clube');
courtyard.innerHTML=`<div class="courtyard-stage" id="courtyardStage"><canvas id="courtyardCanvas" width="1536" height="864" aria-label="Seus Pipamons passeando no Quintal do Clube"></canvas><div id="homeDestinations">
<button class="scene-destination" data-home-action="collection" style="left:19%;top:43%"><span>Meus parceiros</span></button>
<button class="scene-destination" data-home-action="city" style="left:51%;top:39%"><span>Explorar a cidade</span></button>
<button class="scene-destination" data-home-action="shop" style="left:86%;top:40%"><span>Banca de linhas</span></button>
<button class="scene-destination" data-home-action="summon" style="left:84%;top:61%"><span>Invocação</span></button>
<button class="scene-destination" data-home-action="friends" style="left:91%;top:84%"><span>Encontro dos amigos</span></button>
<button class="scene-destination" data-home-action="professor" style="left:22%;top:70%"><span>Sr. Assis</span></button></div></div>
<div class="home-hud"><div class="home-identity"><b id="homePlayerName"></b><small id="homePartnerName"></small></div><div class="home-objective"><small>Seu próximo voo</small><b id="homeObjective"></b></div><button class="home-command" id="homeMenuButton">Menu · Esc</button></div>
<div class="home-footer"><span id="homeResidents"></span><button class="home-command" id="homeMotion">Pausar passeio</button></div>
<section class="journey-dialog" id="journeyDialog" aria-labelledby="journeyTitle" hidden><div class="eyebrow">Sr. Assis · Quintal do Clube</div><h2 id="journeyTitle"></h2><p id="journeySpeech"></p><p class="journey-status" id="journeyStatus" role="status"></p><div class="journey-actions"><button class="secondary" id="journeyLater" hidden>Ficar no quintal</button><button id="journeyContinue">Continuar</button></div></section>
<section class="partner-choice" id="partnerChoice" aria-labelledby="partnerTitle" hidden><h2 id="partnerTitle">Quem vai encontrar o vento com você?</h2><p>Conheça cada parceiro. Sua escolha será equipada e protegida na conta.</p><div class="partner-options" id="partnerOptions"></div><div class="journey-actions"><button class="secondary" id="partnerBack">Voltar ao professor</button><button id="partnerConfirm">Escolher este parceiro</button></div><p class="journey-status" id="partnerStatus" role="status"></p></section>`;
document.body.append(courtyard);
const gameMenu=document.createElement('section');gameMenu.id='gameMenu';gameMenu.className='game-menu';gameMenu.hidden=true;gameMenu.setAttribute('role','dialog');gameMenu.setAttribute('aria-modal','true');gameMenu.setAttribute('aria-label','Menu do clube');
gameMenu.innerHTML='<div class="game-menu-panel"><h2 id="homeMenuTitle">Quintal do Clube</h2><nav id="homeMenuLinks" aria-label="Destinos do clube"></nav><small class="keyboard-hint">Mouse ou Tab para selecionar · Enter para entrar · Esc para voltar</small></div>';document.body.append(gameMenu);
const cityScreen=document.createElement('section');cityScreen.id='cityScreen';cityScreen.className='city-screen';cityScreen.hidden=true;cityScreen.setAttribute('aria-label','Mapa da cidade');
cityScreen.innerHTML='<div class="city-stage"><div class="city-world" id="cityWorld"></div></div><div class="home-hud"><div class="home-identity"><b>A cidade dos ventos</b><small>Encontre seu próximo desafio.</small></div><button class="home-command" id="cityBack">Voltar ao quintal · Esc</button></div><section class="city-brief" aria-live="polite"><canvas id="cityBadge" width="90" height="100" aria-label="Insígnia do bairro"></canvas><div class="eyebrow" id="cityChapter"></div><h2 id="cityName"></h2><p id="cityDescription"></p><p id="cityRecord"></p><div class="journey-actions"><button id="cityExplore">Entrar no bairro</button></div></section>';document.body.append(cityScreen);
const flightCoach=document.createElement('section');flightCoach.className='flight-coach';flightCoach.id='flightCoach';flightCoach.hidden=true;flightCoach.setAttribute('aria-label','Treino com o Nozinho');
flightCoach.innerHTML='<div class="eyebrow" id="flightStep"></div><h2 id="flightTitle"></h2><p id="flightHint"></p><p class="journey-status" id="flightStatus" role="status"></p><div class="journey-actions"><button class="secondary" id="flightExit">Voltar ao quintal</button><button class="secondary" id="flightSkip">Pular treino</button><button id="flightNext" hidden>Continuar</button></div>';document.body.append(flightCoach);
let homeMotionPaused=art.reduced;
function homeLoadImage(key,retry=false){
 if(homeImages.has(key))return Promise.resolve(true);if(homeImageLoads.has(key)&&!retry)return homeImageLoads.get(key);
 const p=new Promise(resolve=>{const image=new Image();image.onload=()=>{homeImages.set(key,image);resolve(true)};image.onerror=()=>{homeImageLoads.delete(key);resolve(false)};image.src=homeArt.images[key].url});homeImageLoads.set(key,p);return p;
}
async function loadHomeArt(retry=false){
 const epoch=journeyEpoch;await Promise.all(['home','city','badges'].map(k=>homeLoadImage(k,retry)));await Promise.all(['sr-assis-poses','nozinho',...partners.map(p=>art.basic(p.color))].filter(Boolean).map(id=>art.load(id,retry)));
 if(epoch!==journeyEpoch)return;const image=homeImages.get('home');if(image)$('courtyardStage').style.backgroundImage='url("'+homeArt.images.home.url+'")';if(!image){journeyError='O cenário não carregou. Use o menu ou tente carregar novamente.';$('homeResidents').textContent=journeyError;}drawCityBadge();drawCityMarkers();
}
function syncHomeInert(){
 const blocked=!gameMenu.hidden||!cityScreen.hidden||!skyExperiment.hidden||[accountModal,dexOverlay,schoolHub,$('trails'),$('modal'),...document.querySelectorAll('.sheet')].some(el=>!el.hidden&&el.style.display!=='none'&&(el.classList.contains('sheet')||el.style.display==='flex'));
 if(courtyard.inert!==blocked)courtyard.inert=blocked;
}
new MutationObserver(syncHomeInert).observe(document.body,{subtree:true,attributes:true,attributeFilter:['hidden','style']});
function showCourtyard(){
 const show=!!playerAccount&&!mode&&(!param||homeInvitationHandled);courtyard.hidden=!show;document.body.classList.toggle('game-shell',!!playerAccount);if(show){updateHomeIdentity();syncHomeInert();}
}
function updateHomeIdentity(){
 if(!playerAccount)return;const p=playerAccount.profile,k=playerAccount.inventory.find(k=>k.id===p.equipped_kite_id);$('homePlayerName').textContent=p.nickname;$('homePartnerName').textContent=journey?.phase==='arrival'||journey?.phase==='choose'?'Um parceiro está esperando por você':k?'Parceiro equipado · '+k.model.name:'Seu lugar no clube';
 const signature=p.id+'|'+playerAccount.inventory.map(k=>k.id+':'+k.model_id).join('|');if(signature!==homeSignature){homeSignature=signature;homeFarm.setCollection(playerAccount.inventory);}
 $('homeResidents').textContent=homeFarm.residents.length+' espécies no seu quintal'+(homeFarm.pages>1?' · passeios em grupos':'');
 $('homeMotion').textContent=homeMotionPaused?'Retomar passeio':'Pausar passeio';
 const next=firstOpenStage();$('homeObjective').textContent=journeyLoading?'Preparando seu lugar no clube…':journey?.phase==='arrival'||journey?.phase==='choose'?'Conheça seu primeiro parceiro':journey?.phase==='practice'?'Seu primeiro voo com o Nozinho':journey?.phase==='city'?'Seu parceiro está pronto. Visite a cidade.':next?'Visite '+trails.trails[next.trailIndex].name:'Explore a cidade e cuide dos seus parceiros';
}
async function onCourtyardAccount(){
 const owner=playerAccount?.profile?.id||null;showCourtyard();if(owner===journeyOwner){if(owner)updateHomeIdentity();return;}
 journeyOwner=owner;journeyEpoch++;journey=null;journeyError='';journeyBusy=false;homeReplay=false;journeyLoading=false;homeSignature='';homeFarm.setCollection([]);cityScreen.hidden=true;gameMenu.hidden=true;hideJourney();if(firstFlightRun){firstFlightRun=null;flightCoach.hidden=true;leave();}
 if(!owner)return;loadHomeArt();await loadJourney();
}
async function loadJourney(){
 if(!journeyOwner)return;const epoch=journeyEpoch,owner=journeyOwner;journeyLoading=true;updateHomeIdentity();
 try{const d=await accountRequest('journey',{action:'read'});if(epoch!==journeyEpoch||owner!==playerAccount?.profile?.id)return;journey=d.journey;journeyError='';if(accountModal.style.display==='flex')closeAccount();showCourtyard();if(!mode&&!param)renderJourney();}
 catch(e){if(epoch!==journeyEpoch)return;journeyError=e.message;if(!mode)renderJourney();}
 finally{if(epoch===journeyEpoch){journeyLoading=false;updateHomeIdentity();}}
}
async function saveJourney(action,body={}){
 if(journeyBusy||!journeyOwner)return null;const epoch=journeyEpoch,owner=journeyOwner;journeyBusy=true;setJourneyBusy(true);
 try{const d=await accountRequest('journey',{action,...body});if(epoch!==journeyEpoch||owner!==playerAccount?.profile?.id)return null;journey=d.journey;journeyError='';if(d.account){playerAccount=d.account;reflectAccount();}updateHomeIdentity();return d;}
 catch(e){if(epoch===journeyEpoch){journeyError=e.message;for(const id of ['journeyStatus','partnerStatus','flightStatus'])$(id).textContent=e.message;}return null;}
 finally{if(epoch===journeyEpoch){journeyBusy=false;setJourneyBusy(false);}}
}
function setJourneyBusy(busy){for(const id of ['journeyContinue','partnerConfirm','partnerBack','flightNext','flightSkip'])$(id).disabled=busy;}
function hideJourney(){$('journeyDialog').hidden=true;$('partnerChoice').hidden=true;$('homeDestinations').inert=false;}
function dialogue(title,text,action,fn,{later=false}={}){
 hideJourney();$('journeyTitle').textContent=title;$('journeySpeech').textContent=text;$('journeyStatus').textContent='';$('journeyContinue').textContent=action;$('journeyContinue').onclick=fn;$('journeyDialog').hidden=false;$('journeyLater').textContent='Ficar no quintal';$('journeyLater').hidden=!later;$('journeyLater').onclick=hideJourney;$('homeDestinations').inert=!later;$('journeyContinue').focus({preventScroll:true});
}
function renderJourney(){
 if(mode||!playerAccount)return;if(journeyError&&!journey){dialogue('Vamos recuperar seu próximo passo',journeyError,'Tentar novamente',loadJourney,{later:true});return;}
 if(homeReplay||journey?.phase==='arrival')dialogue('Seu lugar no céu','Chegou numa boa hora. Sou o Sr. Assis, e este é o Nozinho. Antes de visitar a cidade, vamos encontrar um parceiro e sentir o vento.','Conhecer os parceiros',async()=>{if(homeReplay||await saveJourney('welcome'))choosePartner()});
 else if(journey?.phase==='choose')choosePartner();
 else if(journey?.phase==='practice')dialogue('Vamos voar juntos?','Seu parceiro está esperando. Nozinho vai ajudar a praticar movimento, rebique, energia e habilidade. Aqui não há perdas nem consumo de itens.','Continuar o primeiro voo',()=>startFirstFlight(),{later:true});
 else if(journey?.phase==='city')dialogue('Um corte, uma nova história','Nozinho está bem! Sua coleção fica aqui no quintal. Quando quiser um novo desafio, passe pelo portão e conheça o Morro do Sol.','Explorar a cidade',openCity,{later:true});
 else hideJourney();
}
function choosePartner(){
 hideJourney();$('partnerChoice').hidden=false;$('homeDestinations').inert=true;homePartner=0;
 $('partnerChoice').querySelector('p').textContent=homeReplay?'Experimente qualquer parceiro neste treino. Sua coleção e seu equipamento não serão alterados.':'Escolha um parceiro do conjunto inicial. Ele será equipado e ficará permanente na sua conta.';
 $('partnerOptions').replaceChildren(...partners.map((p,i)=>{const b=document.createElement('button');b.className='partner-option';b.type='button';b.setAttribute('aria-pressed',String(i===homePartner));b.setAttribute('aria-label',p.name+' · '+p.personality);const painting=document.createElement('canvas');painting.width=240;painting.height=240;painting.dataset.partner=i;painting.setAttribute('aria-hidden','true');b.append(painting);b.append(uiElement('b',p.name),uiElement('small',p.personality),uiElement('small',p.description));b.onclick=()=>{homePartner=i;for(const [j,other]of [...$('partnerOptions').children].entries())other.setAttribute('aria-pressed',String(j===i));$('partnerConfirm').textContent=(homeReplay?'Treinar com ':'Escolher ')+p.name;};return b}));
 $('partnerStatus').textContent='';$('partnerConfirm').textContent=(homeReplay?'Treinar com ':'Escolher ')+partners[homePartner].name;$('partnerOptions').querySelector('button').focus();
}
$('partnerBack').onclick=()=>{hideJourney();dialogue('Sem pressa para escolher','Conhecer seu parceiro é o primeiro passo. Você pode comparar todos antes de confirmar.','Ver parceiros',choosePartner)};
$('partnerConfirm').onclick=async()=>{if(homeReplay||await saveJourney('choose',{modelId:partners[homePartner].id})){hideJourney();startFirstFlight();}};
function startFirstFlight(){
 if(mode||!playerAccount||journeyLoading||journeyBusy)return;hideJourney();closeHomeMenu();
 const equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),p=homeReplay?partners[homePartner]:{color:equipped?.model.color??0,soul:equipped?.model.soul};
 firstFlightRun=firstFlight.create({...p,lesson:homeReplay?0:journey?.lesson||0,name:playerAccount.profile.nickname},Date.now());flightSaved=false;enter(firstFlightRun.state,'you','practice');document.body.classList.add('in-first-flight');flightCoach.hidden=false;renderFlightCoach();art.load('nozinho');setText('liveLabel','Sr. Assis e Nozinho');setText('arenaMode','Primeiro voo · treino sem perdas');$('sky').focus?.();
}
function renderFlightCoach(){if(!firstFlightRun)return;const r=firstFlightRun,l=firstFlight.lessons[r.index];$('flightStep').textContent='Sr. Assis · '+(r.index+1)+' de 5';$('flightTitle').textContent=l.title;$('flightHint').textContent=r.complete?l.success:l.hint;$('flightStatus').textContent='';$('flightNext').hidden=!r.complete;$('flightNext').textContent=r.index===4?'Voltar para o quintal':'Próximo passo';}
function stepFirstFlight(now){
 const r=firstFlightRun;if(!r)return;firstFlight.tick(r,input(),now);if(r.complete&&!flightSaved){flightSaved=true;keys={};resetPointer();renderFlightCoach();$('flightNext').focus({preventScroll:true});}
}
function drawFirstFlightGuide(){
 const r=firstFlightRun;if(!r||r.complete||r.index!==0&&r.index!==1&&r.index!==4)return;
 ctx.save();ctx.strokeStyle='#267d6b';ctx.fillStyle='#e3ffe4a0';ctx.lineWidth=3;ctx.setLineDash([6,5]);ctx.beginPath();ctx.arc(r.target.x,r.target.y,36,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.setLineDash([]);ctx.fillStyle='#164b46';ctx.font='16px sans-serif';ctx.textAlign='center';ctx.fillText(r.index===0?'Voe até aqui':'Cruze e rebique',r.target.x,r.target.y-48);ctx.restore();
}
$('flightNext').onclick=async()=>{const r=firstFlightRun;if(!r?.complete)return;const replay=homeReplay;if(!replay&&!await saveJourney('advance',{lesson:r.index+1}))return;if(firstFlightRun!==r)return;if(r.index===4){homeReplay=false;leave();if(replay)dialogue('Bons ventos, parceiro!','Você pode voltar ao professor sempre que quiser. Sua coleção e seus prêmios continuam os mesmos.','Voltar ao quintal',hideJourney);else renderJourney();}else{firstFlight.next(r);flightSaved=false;keys={};resetPointer();renderFlightCoach();$('sky').focus?.();}};
$('flightExit').onclick=()=>{homeReplay=false;leave()};
$('flightSkip').onclick=async()=>{if(homeReplay){homeReplay=false;leave();return}if(await saveJourney('skip')){leave();renderJourney();}};
function drawCourtyard(t){
 if(courtyard.hidden||mode)return false;if(courtyard.inert){homeLast=t;return true;}if(t-homeDrawAt<1000/30)return true;homeDrawAt=t;const c=$('courtyardCanvas'),g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);
 for(const painting of $('partnerOptions').querySelectorAll('canvas')){const context=painting.getContext('2d');context.clearRect(0,0,240,240);art.creature(context,+painting.dataset.partner,t,0,0,240,{animate:!art.reduced});}
 const dt=homeLast?Math.min(.1,(t-homeLast)/1000):0;homeLast=t;if(!homeMotionPaused){homeFarm.step(dt);if(homeFarm.pages>1&&t-homeGroupAt>20000){homeGroupAt=t;homeFarm.turn(homeFarm.page===homeFarm.pages-1?-homeFarm.page:1)}}
 for(const p of [...(journey?.phase==='arrival'||journey?.phase==='choose'?[]:homeFarm.visible())].sort((a,b)=>a.y-b.y)){const x=210+p.x*.73,y=160+p.y*1.25,size=90+(p.y-310)*.1;g.fillStyle='#16362b28';g.beginPath();g.ellipse(x,y-3,size*.25,7,0,0,Math.PI*2);g.fill();art.creature(g,p.color,t+p.phase,x-size/2,y-size,size,{soul:p.soul,facing:p.facing,animate:!homeMotionPaused,input:{x:!homeMotionPaused&&p.moving?p.facing:0}});}
 art.draw(g,'sr-assis-poses','welcome',240,440,160,205,true);const seq=art.atlases.nozinho.animations.idle;art.draw(g,'nozinho',seq[art.reduced?0:Math.floor(t/180)%seq.length],370,590,90,90,true);
 return true;
}
$('homeMotion').onclick=()=>{homeMotionPaused=!homeMotionPaused;updateHomeIdentity()};
async function openClubDestination(page){if(mode||!playerAccount)return;hideJourney();closeHomeMenu();const loading=openAccount();if(playerAccount&&!mode)navigateClub(page);await loading;}
const homeActions={
 lab:()=>{hideJourney();closeHomeMenu();skyOpen()},
 collection:()=>openClubDestination('collection'),summon:()=>openClubDestination('summon'),trades:()=>openClubDestination('trades'),profile:()=>openClubDestination('profile'),history:()=>openClubDestination('history'),events:()=>openClubDestination('events'),
 city:()=>openCity(),
 // Trilhas open straight from the menu once the first flight is done; before that the city flow guides the player.
 trails:()=>{if(!journey||journey.phase!=='complete'){openCity();return;}hideJourney();closeHomeMenu();openTrails()},professor:()=>{hideJourney();if(journey?.phase!=='complete')renderJourney();else dialogue('Sempre há um novo vento','Podemos repetir seu primeiro voo, praticar técnicas avançadas ou apenas cuidar dos seus parceiros.','Repetir o primeiro voo',()=>{homeReplay=true;renderJourney()},{later:true})},
 school:()=>{hideJourney();closeHomeMenu();openSchool()},practice:()=>{hideJourney();closeHomeMenu();$('practice').click()},friends:()=>{hideJourney();closeHomeMenu();openSheet('friendsSheet')},quick:()=>{hideJourney();closeHomeMenu();$('quickButton').click()},daily:()=>{hideJourney();closeHomeMenu();$('dailyButton').click()},dex:()=>{hideJourney();closeHomeMenu();openDex()},shop:()=>{hideJourney();closeHomeMenu();openClubDestination('lines').then(loadLineShop)},
 sound:()=>{$('sound').click();closeHomeMenu()},quality:()=>{$('quality').click();closeHomeMenu()},fullscreen:()=>{$('fullscreen').click();closeHomeMenu()},privacy:()=>{closeHomeMenu();if(CLARITY_ID)openConsent()},rules:()=>{closeHomeMenu();showRules()},reload:()=>{loadHomeArt(true);closeHomeMenu()},logout:async()=>{if(mode)return;try{await accountRequest('logout',{});playerAccount=null;reflectAccount();closeHomeMenu();}catch(e){toast(e.message)}},close:()=>closeHomeMenu()
};
for(const b of courtyard.querySelectorAll('[data-home-action]'))b.onclick=()=>homeActions[b.dataset.homeAction]();
const homeMenuGroups={
 // Root: six big destinations (Switch-style tiles). Trilhas and Partida rápida sit one press inside Jogar.
 root:[['playGroup','Jogar','menu-play'],['collection','Parceiros','menu-partners'],['dex','Pipa Dex','menu-dex'],['clubGroup','Clube','menu-club'],['school','Escola','menu-school'],['optionsGroup','Opções','menu-options']],
 playGroup:[['root','← Voltar'],['trails','Trilhas'],['quick','Partida rápida'],['daily','Céu do dia'],['friends','Jogar com amigos'],['practice','Treino livre'],...(new URLSearchParams(location.search).has('lab')?[['lab','Laboratório · Duelo nas Alturas']]:[])],
 clubGroup:[['root','← Voltar'],['summon','Invocação'],['trades','Trocas por convite'],['shop','Banca de linhas'],['history','Meus duelos'],['events','Souls de evento'],['profile','Meu perfil'],['professor','Meu primeiro voo']],
 optionsGroup:[['root','← Voltar'],['sound','Som'],['quality','Qualidade da imagem'],['fullscreen','Tela cheia'],...(CLARITY_ID?[['privacy','Privacidade']]:[]),['rules','Regras'],['reload','Recarregar cenário'],['logout','Sair da conta']]
};
let homeMenuGroup='root';
function renderHomeMenu(group='root'){
 homeMenuGroup=group;$('homeMenuTitle').textContent={root:'Quintal do Clube',playGroup:'Jogar',clubGroup:'Vida no clube',optionsGroup:'Opções'}[group];
 const open=id=>{if(homeMenuGroups[id])renderHomeMenu(id);else{closeHomeMenu();homeActions[id]()}};
 $('homeMenuLinks').className=group==='root'?'home-tiles':'home-list';
 $('homeMenuLinks').replaceChildren(...homeMenuGroups[group].map(([id,label,icon])=>{const b=uiElement('button',icon?undefined:label);b.type='button';b.dataset.destination=id;if(icon){b.className='home-tile';const img=document.createElement('img');img.alt='';img.src=ART_CONFIG.kit?.icons?.[icon]||'';b.append(img,uiElement('strong',label));}b.onclick=()=>open(id);return b}));
 if(group==='root'){const close=uiElement('button','Voltar ao quintal','home-menu-close');close.type='button';close.onclick=closeHomeMenu;$('homeMenuLinks').append(close);}
 $('homeMenuLinks').querySelector('button').focus();
}
function openHomeMenu(){if(mode||!playerAccount)return;gameMenu.hidden=false;renderHomeMenu();syncHomeInert()}
function closeHomeMenu(){gameMenu.hidden=true;syncHomeInert();if(!courtyard.hidden)$('homeMenuButton').focus({preventScroll:true})}
$('homeMenuButton').onclick=openHomeMenu;gameMenu.onclick=e=>{if(e.target===gameMenu)closeHomeMenu()};
for(const [i,d]of homeArt.districts.entries()){const b=uiElement('button',undefined,'city-region'+(i>=3?' future':''));b.style.left=d.marker[0]+'%';b.style.top=d.marker[1]+'%';b.dataset.district=i;b.setAttribute('aria-label',d.name+(i>=3?' · em preparação':''));b.innerHTML='<span class="city-emblem" aria-hidden="true">'+(i>=3?'◇':'⚑')+'</span><small></small>';b.querySelector('small').textContent=d.name;b.onclick=()=>selectCity(i);$('cityWorld').append(b)}
function drawCityBadge(){const im=homeImages.get('badges'),f=homeArt.badges[cityPick];if(!im||!f)return;const c=$('cityBadge'),g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);g.drawImage(im,f.x,f.y,f.w,f.h,3,3,c.width-6,c.height-6)}
function drawCityMarkers(){const im=homeImages.get('badges');if(!im)return;for(const [i,b]of [...$('cityWorld').querySelectorAll('button')].entries()){let c=b.querySelector('canvas');if(!c){b.querySelector('.city-emblem').remove();c=document.createElement('canvas');c.width=80;c.height=90;c.className='city-emblem';c.setAttribute('aria-hidden','true');b.prepend(c)}const g=c.getContext('2d'),f=homeArt.badges[i];g.clearRect(0,0,80,90);g.drawImage(im,f.x,f.y,f.w,f.h,4,3,72,84)}}
function selectCity(i){
 cityPick=i;const d=homeArt.districts[i],trail=trails.trails[i];for(const b of $('cityWorld').querySelectorAll('button')){const index=+b.dataset.district,locked=index<3&&!trails.unlocked(trailProgress,trails.trails[index].stages[0].id);b.setAttribute('aria-pressed',String(index===i));b.classList.toggle('locked',locked);b.setAttribute('aria-label',homeArt.districts[index].name+(index>=3?' · em preparação':locked?' · bloqueado':''));}$('cityChapter').textContent='Bairro '+String(i+1).padStart(2,'0');$('cityName').textContent=d.name;$('cityDescription').textContent=i<3?'Encontre '+d.leader+' e os pipeiros deste bairro. Complete os cinco desafios para seguir sua jornada.':'Este bairro faz parte da expansão da cidade e ainda está em preparação.';
 const next=trail?.stages.find(s=>trails.unlocked(trailProgress,s.id)&&!trailProgress.stars[s.id])||trail?.stages.at(-1),unlocked=i<3&&trails.unlocked(trailProgress,trail.stages[0].id);$('cityExplore').hidden=i>=3;$('cityExplore').disabled=!unlocked;$('cityExplore').textContent=unlocked?'Conhecer o bairro':'Conclua o bairro anterior';$('cityRecord').textContent=i<3?trail.stages.filter(s=>trailProgress.stars[s.id]).length+' de 5 encontros concluídos · Campeão: '+d.leader:'Novos encontros e disputa de títulos chegam na expansão. Nenhum progresso foi concedido.';
 $('cityExplore').onclick=()=>{if(!unlocked)return;cityScreen.hidden=true;cityBriefOpen=true;trailPick=next.id;openTrails();syncHomeInert()};drawCityBadge();
}
async function openCity(){
 if(mode||!playerAccount)return;if(!journey||['arrival','choose'].includes(journey.phase)){renderJourney();return;}if(journey.phase==='practice'){dialogue('Vamos terminar seu primeiro voo?','Você pode treinar com o Nozinho ou pular a prática e conhecer a cidade. Nenhuma recompensa é concedida ao pular.','Continuar o treino',startFirstFlight,{later:true});$('journeyLater').hidden=false;$('journeyLater').textContent='Pular e visitar a cidade';$('journeyLater').onclick=async()=>{if(await saveJourney('skip'))openCity()};return;}
 if(journey.phase==='city'&&!await saveJourney('finish'))return;hideJourney();closeHomeMenu();cityScreen.hidden=false;$('cityWorld').style.backgroundImage='url("'+homeArt.images.city.url+'")';await trailSync.sync();if(cityScreen.hidden)return;selectCity(Math.min(2,firstOpenStage().trailIndex));syncHomeInert();$('cityBack').focus();
}
$('cityBack').onclick=()=>{cityScreen.hidden=true;showCourtyard();$('homeMenuButton').focus()};
let cityBriefOpen=false;
const cityOriginalCloseTrails=closeTrails;closeTrails=function(){cityOriginalCloseTrails();if(cityBriefOpen&&!mode){cityBriefOpen=false;cityScreen.hidden=false;selectCity(cityPick);syncHomeInert()}};$('trailsClose').onclick=closeTrails;
const courtyardOriginalEnter=enter;enter=function(...args){cityBriefOpen=false;courtyard.hidden=true;cityScreen.hidden=true;gameMenu.hidden=true;hideJourney();return courtyardOriginalEnter(...args)};
const courtyardOriginalLeave=leave;leave=function(...args){firstFlightRun=null;flightCoach.hidden=true;document.body.classList.remove('in-first-flight');homeInvitationHandled=true;const value=courtyardOriginalLeave(...args);showCourtyard();return value};
const courtyardCloseAccount=closeAccount;closeAccount=function(){courtyardCloseAccount();syncHomeInert();if(!courtyard.hidden)$('homeMenuButton').focus()};$('closeAccount').onclick=closeAccount;clubBack.textContent='← Voltar ao quintal';clubBack.onclick=closeAccount;clubBack.classList.add('same-as-close');
addEventListener('keydown',e=>{
 if(!playerAccount||mode)return;const panel=!gameMenu.hidden?gameMenu:!cityScreen.hidden?cityScreen:!$('partnerChoice').hidden?$('partnerChoice'):!$('journeyDialog').hidden?$('journeyDialog'):null;
 if(e.key==='Escape'){
  if(!gameMenu.hidden){e.preventDefault();e.stopImmediatePropagation();if(homeMenuGroup!=='root')renderHomeMenu();else closeHomeMenu();return;}
  if(!cityScreen.hidden){e.preventDefault();e.stopImmediatePropagation();$('cityBack').click();return;}
  if(!courtyard.hidden&&!courtyard.inert){e.preventDefault();e.stopImmediatePropagation();openHomeMenu();return;}
 }
 if(panel&&e.key==='Tab'){const buttons=[...panel.querySelectorAll('button')].filter(b=>!b.hidden&&!b.disabled&&b.getClientRects().length),first=buttons[0],last=buttons.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last?.focus()}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first?.focus()}}
 if(!gameMenu.hidden&&['ArrowDown','ArrowUp'].includes(e.key)){const buttons=[...$('homeMenuLinks').querySelectorAll('button')],i=buttons.indexOf(document.activeElement);e.preventDefault();buttons[(i+(e.key==='ArrowDown'?1:-1)+buttons.length)%buttons.length].focus()}
 if(!cityScreen.hidden&&['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();const step={ArrowLeft:-1,ArrowRight:1,ArrowUp:-4,ArrowDown:4}[e.key];selectCity(Math.max(0,Math.min(11,cityPick+step)));$('cityWorld').querySelector('[data-district="'+cityPick+'"]').focus()}
 if(!cityScreen.hidden&&e.key==='Enter'&&e.target?.closest?.('.city-region')){e.preventDefault();e.stopImmediatePropagation();if(!$('cityExplore').hidden&&!$('cityExplore').disabled)$('cityExplore').click()}
 if(gameMenu.hidden&&!$('partnerChoice').hidden&&['ArrowLeft','ArrowRight'].includes(e.key)){e.preventDefault();const next=(homePartner+(e.key==='ArrowRight'?1:-1)+partners.length)%partners.length,b=$('partnerOptions').children[next];b.click();b.focus()}
},true);
addEventListener('online',()=>{if(journeyError&&!journey)loadJourney()});
onCourtyardAccount();
