// Trilhas UI: trail map, stage briefing, AI duels and coin payouts. Progress uses the per-account outbox, with a guest save on this device.
const trails=createTrails(),TRAILS_KEY='pipaTrailsV1',TYPE_NAMES=['Precisa','Ágil','Guardiã','Técnica'];
let trailProgress=loadTrails(),trailStage=null,trailPick=null;
function loadTrails(){try{return trails.sanitize(JSON.parse(localStorage.getItem(TRAILS_KEY)||'null'));}catch{return trails.defaults();}}
function saveTrails(){try{localStorage.setItem(TRAILS_KEY,JSON.stringify(trailProgress));}catch{}}
function reflectCoins(){setText('coinCount',String(trailProgress.coins));if($('plazaCoins'))$('plazaCoins').textContent=Number(trailProgress.coins||0).toLocaleString('pt-BR');}
const TIP_TECHNIQUE='Truque de pipeiro: cruze com a ponta da sua linha, pertinho da sua pipa (o trecho verde, fora da sua faixa tracejada). Dali você corta, mas não pode ser cortado.';
// Kite choice inside the briefing, so guests can switch almática between attempts.
function renderStageKites(st){
 if(playerAccount){const equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id);const button=uiElement('button',equipped?'Trocar parceiro · '+equipped.model.name:'Escolher parceiro','secondary');button.onclick=()=>chooseEncounterPartner(st.id);$('stageKites').replaceChildren(button);return;}

 $('stageKites').replaceChildren(...TYPE_NAMES.map((name,i)=>{const b=document.createElement('button');b.className='stage-kite'+(selected===i?' selected':'')+(st.counter===i?' recommended':'');b.setAttribute('aria-pressed',String(selected===i));b.setAttribute('aria-label',name+(st.counter===i?' (recomendada)':''));
  b.innerHTML='<span class="foe-art">'+art.markup(i)+'</span><small></small>';b.querySelector('small').textContent=name;
  b.onclick=()=>{if(playerAccount){closeTrails();openAccount();return;}selected=i;try{localStorage.setItem('pipaColor',String(i));}catch{}choices();renderStage();};return b;}));
}
// Keep the encounter action outside the scrollable briefing.
const stageDetails=uiElement('div',undefined,'stage-details');
for(const child of [...document.querySelector('.stage-card').children])if(child.id!=='trailStart'&&!child.classList.contains('stage-foot'))stageDetails.append(child);
document.querySelector('.stage-card').prepend(stageDetails);
const starText=n=>'★'.repeat(n)+'☆'.repeat(3-n);
function firstOpenStage(){return trails.stages.find(s=>trails.unlocked(trailProgress,s.id)&&!trailProgress.stars[s.id])||trails.stages.at(-1);}
function openTrails(){
 if(!requireClubAccount('as Trilhas'))return;
 if(mode){toast('Saia da partida para abrir as trilhas.');return;}
 trailPick=trailPick&&trails.unlocked(trailProgress,trailPick)?trailPick:firstOpenStage().id;
 trailSync.sync();renderTrails();$('trails').hidden=false;$('trails').style.display='flex';$('trailStart').focus({preventScroll:true});
}
function closeTrails(){delete $('trails').dataset.district;delete $('trails').dataset.returnStage;delete $('trails').dataset.returnWon;delete $('trails').dataset.returnAdvanced;$('trails').hidden=true;$('trails').style.display='none';}
function districtLeaderKnown(trail){return trails.unlocked(trailProgress,trail.stages.at(-1).id);}
function renderTrails(){
 const restoreFocus=document.activeElement?.classList.contains('trail-node');
 const previous=$('trails').dataset.returnStage;if(previous&&$('trails').dataset.returnWon==='yes'&&$('trails').dataset.returnAdvanced!=='yes'&&trailProgress.stars[previous]){const next=trails.nextStage(previous);if(next&&next.trailIndex===trails.stage(previous).trailIndex&&trails.unlocked(trailProgress,next.id))trailPick=next.id;$('trails').dataset.returnAdvanced='yes';}
 const district=Number($('trails').dataset.district),focused=$('trails').dataset.district!==undefined&&Number.isInteger(district)&&district>=0&&district<trails.trails.length;
 const destination=focused?trails.trails[district]:null;
 $('trailsTitle').textContent=destination?destination.name:'Trilhas da cidade';document.querySelector('.trails-header .eyebrow').textContent=destination?'Seu próximo desafio':'Jornada da cidade';
 let arrival=$('districtArrival');if(!arrival){arrival=uiElement('section',undefined,'district-arrival');arrival.id='districtArrival';}
 arrival.hidden=!destination;
 if(destination){arrival.replaceChildren(uiElement('div','Explore os cinco lugares do bairro. Cada vitória abre um novo caminho. O último encontro guarda uma surpresa.'));}

 setText('trailCoins',String(trailProgress.coins));
 const bonus=Math.floor(trailProgress.mastery/2);
 setText('trailMastery','Rabiolas recebidas na conta '+trailRewards.length+'/'+trails.DROPS.length+' · Maestria '+trailProgress.mastery+'/'+trails.MASTERY_MAX+(bonus?' · a IA está +'+bonus+' nível'+(bonus>1?'s':'')+' mais esperta':' · a IA ainda está te conhecendo'));
 $('trailList').replaceChildren(...trails.trails.map(t=>{
  const card=document.createElement('section');card.className='trail';card.hidden=focused&&t!==destination;card.style.setProperty('--accent',t.accent);
  const earned=t.stages.reduce((n,s)=>n+(trailProgress.stars[s.id]||0),0);
  card.innerHTML='<header><div><b></b><small></small></div><span class="trail-stars"></span></header><div class="trail-path"></div>';
  card.querySelector('b').textContent=t.name;card.querySelector('small').textContent=t.subtitle;card.querySelector('.trail-stars').textContent='★ '+earned+'/'+t.stages.length*3;
  const map=card.querySelector('.trail-path');map.classList.add('district-places');const geography=ART_CONFIG.courtyard.places[t.id];if(geography)map.style.backgroundImage='url('+JSON.stringify(ART_CONFIG.courtyard.images['district-'+t.id].url)+')';
  map.append(...t.stages.map((s,i)=>{
   const place=geography?.places[i],node=document.createElement('button'),open=trails.unlocked(trailProgress,s.id),stars=trailProgress.stars[s.id]||0;
   if(place){node.style.left=place[1]+'%';node.style.top=place[2]+'%';}node.className='trail-node place-node'+(s.boss?' boss':'')+(open?'':' locked')+(stars?' cleared':'')+(s.id===trailPick?' picked':'');
   node.innerHTML='<span class="node-dot"></span><span class="node-stars"></span>';
   node.querySelector('.node-dot').innerHTML=!open?art.icon('locked'):s.boss?art.icon('boss'):stars?art.icon('completed'):String(i+1);node.querySelector('.node-stars').textContent=stars?starText(stars):'';
   const location=place?.[0]||'Lugar '+(i+1),label=s.boss&&!open?'Lugar desconhecido':location;node.append(uiElement('span',label,'place-label'));node.title=label;
   node.setAttribute('aria-label',label+(open?'':' (bloqueado)')+(stars?' · '+stars+' estrelas':''));node.setAttribute('aria-pressed',String(s.id===trailPick));
   node.onclick=()=>{trailPick=s.id;renderTrails();};return node;}));
  return card;}));
 const returned=$('trails').dataset.returnStage;if(destination&&returned){const won=$('trails').dataset.returnWon==='yes',confirmed=!!trailProgress.stars[returned];arrival.prepend(uiElement('p',won?(confirmed?'Lugar conquistado! Explore o mapa para seguir seu caminho.':'Conferindo o resultado: novos caminhos aparecem após a confirmação na conta.'):'Seu caminho continua aqui. Tente novamente quando estiver pronto.','district-outcome'));const hint=trails.story(returned)?.nextHint;if(won&&confirmed&&hint)arrival.append(uiElement('p',hint,'district-story-hint'));}
 $('trailList').prepend(arrival);renderStage();if(restoreFocus)$('trailList').querySelector('.trail-node.picked')?.focus({preventScroll:true});
}
function renderStage(){
 const st=trails.stage(trailPick),open=trails.unlocked(trailProgress,st.id),level=trails.aiLevel(st,trailProgress),best=trailProgress.stars[st.id]||0,trail=trails.trails[st.trailIndex];
 setText('stageTrail',trail.name+' · Encontro '+(st.index+1)+' de 5'+(st.boss?(districtLeaderKnown(trail)?' · CAMPEÃO':' · ENCONTRO FINAL'):''));const mystery=st.boss&&!districtLeaderKnown(trail),location=ART_CONFIG.courtyard.places[trail.id]?.places[st.index]?.[0];setText('stageName',mystery?'Um encontro desconhecido':location||st.name);
 renderTrailLeader(trail,st);
 $('stageFoes').replaceChildren(...(mystery?[]:st.foes).map(f=>{const row=document.createElement('div');row.className='stage-foe';row.innerHTML='<span class="foe-art">'+art.markup(f.color,f.soul)+'</span><div><b></b><small></small></div>';row.querySelector('b').textContent=f.name;row.querySelector('small').textContent=TYPE_NAMES[f.color]+(f.soul?' · Alma lendária':'');return row;}));
 if(mystery)$('stageFoes').append(uiElement('p','Uma presença misteriosa espera no fim do caminho. Vença os quatro encontros para descobrir quem é.','unrevealed-rival'));
 const fails=trailProgress.fails[st.id]||0;
 setText('stageLevel','IA nível '+level+(level>st.level?' (base '+st.level+', +'+(level-st.level)+' pela sua maestria)':level<st.level?' (pegando mais leve depois de '+fails+' derrotas)':''));
 renderStageKites(st);
 setText('stageFormat','Melhor de '+(st.rounds*2-1)+' · vence quem fizer '+st.rounds+' rodada'+(st.rounds>1?'s':''));
 setText('stageReward','🪙 '+st.coins+'–'+Math.round(st.coins*1.5)+' moedas'+(best?'':' · +'+st.coins+' na primeira vitória'));
 setText('stageBest',best?'Seu melhor: '+starText(best):'Ainda não vencida');
 const oldSummon=$('stageSummon');if(oldSummon)oldSummon.remove();
 const drop=st.drop&&ART_CONFIG.items.find(i=>i.id===st.drop);$('stageDrop').hidden=!drop||mystery;
 if(drop){$('stageDropImage').src=drop.url;$('stageDropImage').alt=drop.name;setText('stageDropName',drop.name);const claim=trailRewards.find(r=>r.stage===st.id);setText('stageDropState',claim?(claim.status==='ready'?'Recebida na conta · Pronta para invocar':'Recebida na conta · '+({used:'em ritual',consumed:'já utilizada',damaged:'danificada',discarded:'descartada'}[claim.status]||claim.status)):trailProgress.items.includes(drop.id)?'Registro antigo · Vença novamente para receber na conta':'Na primeira vitória confirmada contra o chefe');}
 if(drop&&trailRewards.some(r=>r.stage===st.id&&r.status==='ready')){const button=uiElement('button','Ir ao invocador ✦','secondary');button.id='stageSummon';button.onclick=()=>openTrailSummoner(st.drop);$('stageDrop').after(button);}
 setText('stageTip',mystery?'Cada lugar guarda um desafio. Explore o bairro, aprenda com os encontros e descubra quem espera por você.':fails>=2?TIP_TECHNIQUE:st.tip);
 $('trailStart').disabled=!open;$('trailStart').textContent=open?(best?'Repetir desafio ▶':st.boss?'Desafiar '+trail.leaderName+' ▶':(st.foes.length===1?'Enfrentar '+st.foes[0].name+' ▶':'Iniciar confronto ▶')):'Vença a etapa anterior';

}
// Scene loading is cosmetic: failure falls back to the existing arena and never grants progress.
const encounterImages=new Map(),encounterLoads=new Map();
function loadEncounterScenery(url){if(encounterImages.has(url))return Promise.resolve(true);if(encounterLoads.has(url))return encounterLoads.get(url);const ready=new Promise(resolve=>{const image=new Image();image.onload=()=>{encounterImages.set(url,image);resolve(true)};image.onerror=()=>{encounterLoads.delete(url);resolve(false)};image.src=url;});encounterLoads.set(url,ready);return ready;}
function drawEncounterScenery(context,url){const image=encounterImages.get(url);if(!image)return false;const scale=Math.max(1000/image.width,600/image.height),w=1000/scale,h=600/scale;context.drawImage(image,(image.width-w)/2,(image.height-h)/2,w,h,0,0,1000,600);return true;}
function chooseEncounterPartner(id){
 const owner=playerAccount?.profile.id;if(!owner||mode||busy||accountSaving||!trails.unlocked(trailProgress,id))return;
 const returnFocus=modalReturnFocus;modal('Seu parceiro para este duelo','<p>Escolha um parceiro da sua coleção. Você voltará para este mesmo encontro.</p><div id="encounterPartnerList" class="encounter-partner-list"></div><p id="encounterPartnerStatus" role="status"></p>','Voltar ao desafio','Preparar o voo');
 const root=$('encounterPartnerList');$('modal').classList.add('encounter-preview');modalReturnFocus=returnFocus;
 for(const kite of playerAccount.inventory){const b=uiElement('button',undefined,'encounter-partner');b.innerHTML='<span class="foe-art">'+art.markup(kite.model.color,kite.model.soul)+'</span><b>'+escapeHTML(kite.model.name)+'</b><small>'+(kite.id===playerAccount.profile.equipped_kite_id?'Equipado':'Escolher')+'</small>';b.setAttribute('aria-pressed',String(kite.id===playerAccount.profile.equipped_kite_id));b.onclick=async()=>{
  if(accountSaving||playerAccount?.profile.id!==owner)return;if(kite.id===playerAccount.profile.equipped_kite_id){presentStage(id);return;}
  accountSaving=true;for(const item of root.querySelectorAll('button'))item.disabled=true;setText('encounterPartnerStatus','Preparando seu parceiro…');
  try{const d=await accountRequest('equip',{kiteId:kite.id});if(playerAccount?.profile.id!==owner)return;playerAccount=d.account;reflectAccount();if($('encounterPartnerList')===root&&$('modal').style.display==='flex')presentStage(id);}
  catch(e){if($('encounterPartnerList')===root)setText('encounterPartnerStatus',e.message);}
  finally{accountSaving=false;if($('encounterPartnerList')===root)for(const item of root.querySelectorAll('button'))item.disabled=false;}
 };root.append(b);}
 $('dialogAction').onclick=()=>presentStage(id);root.querySelector('button')?.focus({preventScroll:true});
}
function presentStage(id){
 const st=trails.stage(id);if(busy||mode||!st||!requireClubAccount('os encontros do bairro')||!trails.unlocked(trailProgress,id))return;
 const trail=trails.trails[st.trailIndex],scene=ART_CONFIG.designs.encounters?.[id],place=ART_CONFIG.courtyard.places[trail.id]?.places[st.index]?.[0]||st.name;
 if(scene)loadEncounterScenery(scene.url);
 const illustration=scene?'<div class="encounter-landscape" role="img" aria-label="'+escapeHTML(place)+'" style="background-image:url('+escapeHTML(scene.url)+')"></div>':'';
 modal(place,illustration+'<div class="encounter-intro">'+(st.boss?trailLeaderMarkup(trail,'ready',false):'')+'<div><div class="eyebrow">'+(st.boss?'O desafio final':'Encontro '+(st.index+1)+' de 5')+'</div><h3>'+escapeHTML(st.foes.map(f=>f.name).join(' e '))+'</h3>'+(trailStoryMarkup(id)||'<p>'+(st.boss?'Você chegou ao último lugar do bairro. Agora é hora de conhecer quem guarda este desafio.':'O vento trouxe um novo desafio. Confira seu parceiro e prepare o primeiro rebique.')+'</p>')+'<p>Vence quem conquistar '+st.rounds+' rodadas. A batalha começa depois da contagem.</p></div></div>','Começar duelo ▶',place);
 const equipped=playerAccount.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id),partner=uiElement('section',undefined,'encounter-partner-summary');partner.append(uiElement('span','Seu parceiro · '+(equipped?.model.name||'Escolha um parceiro')));const change=uiElement('button','Trocar parceiro','secondary');change.onclick=()=>chooseEncounterPartner(id);partner.append(change);$('dialogBody').prepend(partner);
 $('modal').classList.add('encounter-preview');$('trails').inert=true;modalReturnFocus=$('trailStart');$('dialogAction').onclick=()=>{closeModal();startStage(id);};$('dialogAction').focus({preventScroll:true});
}
function returnToDistrict(id,won=false){
 const st=trails.stage(id);if(!st)return;closeModal();if(mode)leave();
 const next=trails.nextStage(id);trailPick=won&&next&&next.trailIndex===st.trailIndex&&trails.unlocked(trailProgress,next.id)?next.id:id;
 $('trails').dataset.district=String(st.trailIndex);$('trails').dataset.returnStage=id;$('trails').dataset.returnWon=won?'yes':'no';$('trails').dataset.returnAdvanced=trailPick!==id?'yes':'no';
 if(typeof cityPick!=='undefined'){cityPick=st.trailIndex;cityBriefOpen=true;}openTrails();
}
async function startStage(id){
 if(busy||!requireClubAccount('as Trilhas'))return;
 const st=trails.stage(id);if(!st||!trails.unlocked(trailProgress,id))return;
 busy=true;$('trailStart').disabled=true;
 try{const d=await request('trail',{...profile(),stage:id});closeTrails();token=d.token;trailStage=id;enter(d.state,d.me,'online',d.code);$('roomChip').hidden=true;$('copy').style.display='none';$('roomBox').style.display='none';setText('liveLabel',st.name);track('trail_start',{trail_stage:id});}
 catch(e){toast(e.name==='AbortError'?'A conexão demorou. Tente novamente.':e.message);}
 finally{busy=false;if(!$('trails').hidden)renderStage();}
}

function dropCard(id){const item=ART_CONFIG.items.find(i=>i.id===id);if(!item)return '';return '<div class="drop-reward"><img src="'+escapeHTML(item.url)+'" alt=""><div><small>Nova rabiola conquistada!</small><b>'+escapeHTML(item.name)+'</b></div></div>';}
// Called by the results screen when a trail duel ends.
function showTrailResult(s,ranking,mine){
 const won=(mine?.rounds||0)>=s.roundsToWin,r=trailSync.record({stage:s.trail,won,roundsLost:Math.max(0,(s.round||0)-(mine?.rounds||0))},s.id,s.trailOwner??null);
 trailProgress=trailSync.progress();reflectCoins();track(won?'trail_win':'trail_loss',{trail_stage:s.trail});
 const st=trails.stage(s.trail),next=trails.nextStage(s.trail),canNext=won&&next&&trails.unlocked(trailProgress,next.id);
 const rows=ranking.map((q,i)=>'<div class="result-rank'+(q.id===me?' me':'')+'"><span><i class="result-dot" style="background:'+playerColor(q)+'"></i>'+(i+1)+'. '+escapeHTML(q.name)+(q.id===me?' · você':'')+'</span><b>'+(q.rounds||0)+' ★</b></div>').join('');
 // Sr. Assis coaches harder the more a stage resists: the stage tip, then the line-tip trick, then the right almática.
 const counter=Number.isInteger(st.counter)&&st.counter!==selected?st.counter:null;
 const coach=won?'':r.fails>=trails.RELIEF_AFTER?(counter!==null?'A '+TYPE_NAMES[counter]+' é a melhor resposta para esta etapa. ':'')+'A IA desta etapa vai pegar mais leve até você vencer. '+TIP_TECHNIQUE:r.fails===2?TIP_TECHNIQUE:st.tip;
 const levelNote=r.levelAfter>r.levelBefore?'A IA aprendeu com você: agora ela joga no nível '+r.levelAfter+'.':r.levelAfter<r.levelBefore?'A IA vai pegar um pouco mais leve: nível '+r.levelAfter+'.':'IA desta etapa: nível '+r.levelAfter+'.';
 modal(won?(st.boss?'Chefe derrotado!':'Etapa vencida!'):'Não foi dessa vez.',
  (st.boss?trailLeaderMarkup(trails.trails[st.trailIndex],won?'victory':'ready'):'')+'<div class="trail-result"><div class="result-stars" aria-label="'+r.stars+' de 3 estrelas">'+'★'.repeat(r.stars)+'<span class="off">'+'★'.repeat(3-r.stars)+'</span></div>'+(r.drop?dropCard(r.drop):'')+(won?'<div class="coin-gain">+'+r.coins+' 🪙'+(r.firstClear?'<small>inclui bônus da primeira vitória</small>':'')+'</div>':'<p>Rodadas vencidas: '+(mine?.rounds||0)+' de '+s.roundsToWin+'. Treine o cruzamento e tente de novo.</p>')+(coach?'<p class="trail-coach"><b>Sr. Assis:</b> '+escapeHTML(coach)+'</p>':'')+trailStoryMarkup(s.trail,won?'won':'lost',{confirmed:true,firstClear:!!r.firstClear})+'<p class="trail-note">'+levelNote+' Total: '+trailProgress.coins+' moedas.</p></div>'+rows+
  '<button class="primary" id="rematchButton">'+(won?'Ver meu caminho ▶':'Tentar de novo ↻')+'</button>'+(counter!==null&&!won&&!playerAccount?'<button class="secondary" id="trailCounter">Tentar com a '+TYPE_NAMES[counter]+' ↻</button>':''),'Voltar ao mapa do bairro',st.name);
 $('rematchButton').onclick=()=>{if(won)returnToDistrict(s.trail,true);else{returnToDistrict(s.trail,false);presentStage(s.trail);}};
 if($('trailCounter'))$('trailCounter').onclick=()=>{selected=counter;try{localStorage.setItem('pipaColor',String(counter));}catch{}choices();closeModal();startStage(s.trail);};
 if(trails.story(s.trail))$('modal').classList.add('story-result');$('dialogAction').className='secondary';$('dialogAction').onclick=()=>returnToDistrict(s.trail,won);
}
$('trailsButton').onclick=openTrails;$('trailsClose').onclick=closeTrails;$('trailStart').onclick=()=>presentStage(trailPick);
$('trails').onclick=e=>{if(e.target===$('trails'))closeTrails();};
addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('trails').hidden&&$('modal').style.display!=='flex')closeTrails();});
reflectCoins();
