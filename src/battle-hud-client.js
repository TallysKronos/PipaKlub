// Presentation only: never changes combat rules, inputs or server rewards.
function battleArt(parent,frame,kind='back'){
 const node=document.createElement('span');node.className='hud-art hud-art-'+frame+' hud-art-'+kind;node.setAttribute('aria-hidden','true');parent.append(node);return node;
}
// Each painted frame owns a measured inner content box, independent of its artwork.
for(const selector of ['.hud-player','.hud-clock','.hud-board','#normalLineHUD','.hud-skill','.hud-basics']){
 const panel=document.querySelector(selector);let content;
 if(selector==='.hud-player'){content=panel.querySelector('.hud-player-info');content.classList.add('hud-panel-content');}
 else{content=document.createElement('div');content.className='hud-panel-content';for(const child of [...panel.childNodes])if(child.id!=='roundPips')content.append(child);panel.prepend(content);}
 content.dataset.hudRegion=selector;
}
document.querySelector('.hud-board .hud-panel-content').insertBefore($('flightStatus'),$('leaderboard'));
$('leaderboard').setAttribute('data-hud-scroll','true');
for(const button of document.querySelectorAll('.combat-deck button')){const label=document.createElement('span');label.className='hud-button-content';while(button.firstChild)label.append(button.firstChild);button.append(label);}
const battleDeck=document.querySelector('.combat-deck'),deckTabs=document.createElement('nav');deckTabs.className='hud-deck-tabs';deckTabs.setAttribute('aria-label','Painéis de combate');battleDeck.dataset.panel='line';
for(const [id,label,selector] of [['line','Rebicada','#normalLineHUD'],['partner','Parceiro','.hud-skill'],['flight','Voo','.hud-basics']]){const button=document.createElement('button');button.type='button';button.dataset.hudTab=id;button.textContent=label;button.setAttribute('aria-pressed',String(id==='line'));const panel=document.querySelector(selector);if(!panel.id)panel.id='hud-panel-'+id;button.setAttribute('aria-controls',panel.id);button.onclick=()=>{resetNormalLine();battleDeck.dataset.panel=id;for(const tab of deckTabs.querySelectorAll('button'))tab.setAttribute('aria-pressed',String(tab===button));};deckTabs.append(button);}
battleDeck.before(deckTabs);
for(const [selector,frame] of [['.hud-player','nameplate'],['.hud-clock','clock'],['.hud-board','ranking'],['#normalLineHUD','ranking'],['.combat-deck .hud-skill','ranking'],['.hud-basics','ranking']]){
 const parent=document.querySelector(selector);parent.classList.add('hud-painted');battleArt(parent,frame);
}
battleArt($('playerPortrait'),'portrait','overlay');
for(const id of ['hp','energy']){const fill=$(id);fill.classList.add('hud-art-'+(id==='hp'?'hp-fill':'energy-fill'));battleArt(fill.parentElement,id==='hp'?'hp-track':'energy-track','track');}
for(const button of document.querySelectorAll('.combat-deck button')){
 button.classList.add('hud-painted-button');for(const state of ['normal','hover','pressed','disabled'])battleArt(button,'button-'+state,'button-'+state);
}
const lineManeuverIcon=battleArt($('normalLineUse'),'puxao','icon');
battleArt(document.querySelector('.hud-basics [data-key=" "]'),'attack','icon');battleArt(document.querySelector('.hud-basics [data-key="dodge"]'),'dodge','icon');
const partnerAbilityFrame=battleArt(document.querySelector('.hud-skill'),'slot','ability-frame'),partnerAbilityIcon=battleArt(document.querySelector('.hud-skill'),'guard','ability-icon');
$('pauseButton').textContent='';battleArt($('pauseButton'),'pause','pause-icon');
for(const [id,icon] of [['quality','settings'],['sound','sound']]){$(id).textContent='';battleArt($(id),icon,'tool-icon');}
let battleArtRequested=false;
function ensureBattleArt(){if(battleArtRequested)return;battleArtRequested=true;document.body.classList.add('hud-art-loading');let loaded=0;const sheets=Object.values(ART_CONFIG.hud.sheets);for(const sheet of sheets){const image=new Image();image.onload=()=>{if(++loaded===sheets.length){document.body.dataset.hudArtReady='true';document.body.classList.remove('hud-art-loading');}};image.onerror=()=>{document.body.classList.remove('hud-art-loading');document.body.classList.add('hud-art-unavailable');};image.src=sheet.url;}}
function updateBattleHUD(p){
 if(!mode||!p)return;
 ensureBattleArt();
 const entry=ART_CONFIG.dex.entries.find(e=>p.soul?e.id===p.soul:e.atlas===art.basic(p.color));
 setText('partnerName',entry?.name||'Parceiro almático');
 setText('battleMode',state.trail?'Trilha · '+state.trail.split('-')[0]:state.daily?'Céu do dia':mode==='practice'?'Voo de treino':state.rules==='capture'?'Vale pipa':'Duelo de pipas');
 setText('roundInfo',state.phase==='waiting'?(state.quick?'Buscando rivais':'Aguardando rival'):state.mode==='rounds'?(matchMedia('(max-width:900px), (max-height:500px)').matches?'R':'Rodada ')+state.round+' · '+state.roundsToWin+' vitórias':'Partida por tempo');
 $('hud').dataset.danger=String(p.hp<=30&&!p.respawn);$('hud').dataset.phase=state.phase||'live';
 const key=(state.mode||'time')+'|'+(state.roundsToWin||3)+'|'+(p.rounds||0);
 if($('roundPips').dataset.key!==key){$('roundPips').dataset.key=key;$('roundPips').replaceChildren();if(state.mode==='rounds'){for(let n=0;n<(state.roundsToWin||3);n++){const pip=document.createElement('i');pip.className='hud-art-round-'+(n<(p.rounds||0)?'won won':'empty');pip.setAttribute('aria-hidden','true');$('roundPips').append(pip);}$('roundPips').setAttribute('aria-label',(p.rounds||0)+' de '+(state.roundsToWin||3)+' rodadas vencidas');}}
 const maneuver=normalLineChoice().id;if(lineManeuverIcon.dataset.maneuver!==maneuver){lineManeuverIcon.dataset.maneuver=maneuver;lineManeuverIcon.className='hud-art hud-art-'+maneuver+' hud-art-icon';}
 const blocked=!!(p.respawn||pausedAt||state.phase&&state.phase!=='live'),ready=!(p.skillCooldown>0)&&p.energy>=25&&!blocked;
 const slot=ready?'slot-ready':'slot';partnerAbilityFrame.className='hud-art hud-art-'+slot+' hud-art-ability-frame';partnerAbilityIcon.className='hud-art hud-art-'+['critical','dodge','guard','line'][p.color]+' hud-art-ability-icon';
 for(const b of document.querySelectorAll('.skill-actions button')){b.title=eng.type(p).description;b.disabled=!ready;}
 $('skillName').title=eng.type(p).description;
 const skill=blocked?'Aguarde a partida':p.skillTime>0?'Habilidade ativa':p.skillCooldown>0?'Recarga · '+p.skillCooldown.toFixed(1)+' s':p.energy<25?'Precisa de 25 de energia':'Pronta · 25 energia';setText('skillStatus',skill);
 setText('flightStatus',mode==='online'?(realtime?'Tempo real':'Conexão compatível')+' · '+ping+' ms':'Treino local · WASD / arrastar');
 const dodge=!(p.dodgeCooldown>0)&&p.energy>=eng.DODGE.cost&&!blocked;
 const button=document.querySelector('.hud-basics [data-key="dodge"]');button.title=p.dodgeCooldown>0?'Recarga · '+p.dodgeCooldown.toFixed(1)+' s':'Esquiva · Shift · 18 energia';button.disabled=!dodge;
 document.querySelector('.hud-basics [data-key=" "]').disabled=blocked||p.energy<12;
 for(const [id,value] of [['hp',p.hp],['energy',p.energy]]){const meter=$(id).parentElement;meter.setAttribute('role','meter');meter.setAttribute('aria-label',id==='hp'?'Durabilidade da linha':'Energia');meter.setAttribute('aria-valuemin','0');meter.setAttribute('aria-valuemax','100');meter.setAttribute('aria-valuenow',String(Math.max(0,Math.round(value))));}
}
