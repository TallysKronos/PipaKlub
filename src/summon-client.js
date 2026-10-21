// Ritual sessions live only in memory: leaving/reloading cannot restart attempts.
let summonOpen=false,summonBusy=false,summonRitual=null,summonTail=null,summonPath=[],summonPending=null,summonDrawing=null;
let summonData={tails:[],seen:[]},summonTarget=null;
const summonRehearsed=new Set();
function needsSummonPractice(){return playerAccount?.inventory?.length===1&&!summonRehearsed.has(summonTarget?.modelId);}
function openSummonPractice(){
 const target=summonTarget;if(!target)return;let path=[];
 let panel=$('summonPractice');if(!panel){panel=uiElement('section',undefined,'summon-practice');panel.id='summonPractice';$('summonPreparation').append(panel);}
 panel.hidden=false;panel.replaceChildren(uiElement('h4','Ensaio sem consumir itens'),uiElement('p','Clique nas estrelas nesta ordem: '+target.pattern.join(' → ')+'. Você pode errar e repetir sem perder a rabiola.'));
 const board=uiElement('div',undefined,'summon-practice-grid'),status=uiElement('p','Nenhuma estrela selecionada.');status.setAttribute('role','status');
 const reset=()=>{path=[];for(const b of board.children)b.setAttribute('aria-pressed','false');status.textContent='Tente de novo: '+target.pattern.join(' → ');};
 for(let i=1;i<=9;i++){const b=uiElement('button',String(i),'secondary');b.type='button';b.setAttribute('aria-label','Estrela de ensaio '+i);b.setAttribute('aria-pressed','false');b.onclick=()=>{if(path.length>=target.pattern.length)reset();path=extendSummonPath(path,i);b.setAttribute('aria-pressed','true');status.textContent='Seu desenho: '+path.join(' → ');if(path.length===target.pattern.length){if(path.every((n,j)=>n===target.pattern[j])){summonRehearsed.add(target.modelId);status.textContent='Ensaio concluído! Nenhum item foi usado. Selecione sua rabiola e inicie quando estiver pronto.';$('summonStart').disabled=!summonTail;$('summonStart').focus({preventScroll:true});}else status.textContent+=' · O símbolo é diferente. Reinicie para tentar novamente.';}};board.append(b);}
 const again=uiElement('button','Reiniciar ensaio','secondary');again.onclick=reset;panel.append(board,status,again);board.querySelector('button').focus({preventScroll:true});
}
const summonDisplayName=p=>(typeof ART_CONFIG!=='undefined'?ART_CONFIG.dex.entries.find(e=>e.model===p.modelId)?.name:null)||p.name;
const summonSession=crypto.randomUUID();
const summonEntry=uiElement('section',undefined,'summon-entry');
summonEntry.innerHTML='<div class="eyebrow">O ateliê do Sr. Assis</div><h3>Uma rabiola. Uma nova história.</h3><p>Traga uma rabiola e desenhe a constelação do seu Pipamon.</p><button class="primary" id="visitSummoner">Visitar o invocador ✦</button>';
$('collectionMain').insertBefore(summonEntry,$('inventoryList'));
const summonRoom=uiElement('section',undefined,'summon-room');summonRoom.id='summonRoom';summonRoom.hidden=true;
summonRoom.innerHTML='<button class="secondary" id="leaveSummoner">← Menu do clube</button><div class="summon-npc"><canvas id="summonAssis" width="130" height="150" aria-label="Sr. Assis, invocador"></canvas><div><div class="eyebrow">Sr. Assis · Invocador</div><h3>O chamado da rabiola</h3><p id="summonSpeech">Cada rabiola guarda uma ligação. O feitiço certo desperta quem está do outro lado.</p></div></div><p id="summonNotice" class="summon-warning">A rabiola é consumida ao iniciar. Você tem 3 tentativas. Sair, fechar ou recarregar durante o ritual deixa uma rabiola danificada, que só pode ser descartada.</p><div id="summonTailList" class="summon-tail-list"></div><div id="summonRitual" hidden><div class="summon-ritual-header"><h3 id="summonTarget"></h3><span id="summonTries"></span></div><div id="summonBoard" class="summon-board" aria-label="Constelação de nove estrelas"><svg viewBox="0 0 300 300" aria-hidden="true"><polyline id="summonGuide" class="summon-guide"/><polyline id="summonStroke" class="summon-stroke"/></svg></div><p id="summonPatternHint"></p><button class="secondary" id="summonShowPattern">Consultar feitiço</button><button class="secondary" id="summonClear">Limpar desenho</button><button class="primary" id="summonSubmit">Lançar feitiço</button></div><div id="summonReveal" class="summon-reveal" hidden></div><p id="summonMessage" role="status" aria-live="polite"></p>';
$('accountCollection').append(summonRoom);
const summonReload=uiElement('button','Atualizar rabiolas','secondary');summonReload.type='button';summonReload.onclick=()=>{if(!summonRitual&&!summonBusy)loadSummonTails().catch(e=>{$('summonMessage').textContent=e.message;});};summonRoom.insertBefore(summonReload,$('summonTailList'));
const summonStages=uiElement('div');
summonStages.innerHTML='<nav class="summon-steps" aria-label="Etapas da invocação"><span>NPC</span><span>Pipamon</span><span>Rabiola</span><span>Ascendente</span></nav><div id="summonMenu"><h3>Como posso ajudar?</h3><p>Os Pipamon que você conhece podem ouvir seu chamado.</p><button class="primary" id="summonInvoke">Invocar Pipamon ✦</button><button class="secondary" id="summonDamagedMenu">Rabiolas danificadas</button></div><section id="summonCatalog" hidden><button class="secondary" id="summonCatalogBack">← Conversar com o NPC</button><h3>Pipamon que você já viu</h3><p class="summon-help">A rabiola no card indica que você pode invocar. O cadeado indica que falta uma rabiola compatível ou que a Soul vinculada já está na coleção.</p><div id="summonSeenGrid" class="summon-seen-grid"></div></section><section id="summonPreparation" hidden><button class="secondary" id="summonPreparationBack">← Escolher outro Pipamon</button><h3>Prepare o chamado</h3><div class="summon-pair"><article id="summonChosenPipamon" class="summon-chosen"></article><div><h4>Suas rabiolas</h4><p class="summon-help">Escolha uma rabiola compatível e depois clique em Usar.</p><div id="summonTailSlot"></div></div></div><p id="summonSelectedTail" role="status">Nenhuma rabiola selecionada.</p></section><section id="summonDamaged" hidden><button class="secondary" id="summonDamagedBack">← Conversar com o NPC</button><h3>Rabiolas danificadas</h3><div id="summonDamagedList" class="summon-tail-list"></div></section>';
summonRoom.insertBefore(summonStages,summonReload);$('summonTailSlot').append($('summonTailList'));
const ascendantTitle=uiElement('div','Ascendente · desenhe o feitiço','eyebrow');$('summonRitual').prepend(ascendantTitle);
function showSummonStage(stage){
 for(const [id,key] of [['summonMenu','npc'],['summonCatalog','catalog'],['summonPreparation','preparation'],['summonDamaged','damaged'],['summonRitual','ascendant']])$(id).hidden=stage!==key;
 $('summonNotice').hidden=!['preparation','ascendant'].includes(stage);$('summonReveal').hidden=true;
 for(const [i,node] of [...summonStages.querySelectorAll('.summon-steps span')].entries())node.classList.toggle('current',i===['npc','catalog','preparation','ascendant'].indexOf(stage));
 const card=document.querySelector('.account-card');if(card)card.scrollTop=0;
 if(stage==='ascendant')requestAnimationFrame(()=>$('summonBoard').scrollIntoView?.({block:'center'}));
}
function summonTailArt(modelId,small=false){
 const entry=typeof ART_CONFIG!=='undefined'?ART_CONFIG.dex.entries.find(e=>e.model===modelId):null;
 const item=entry&&ART_CONFIG.items?.find(i=>i.pipamon===entry.id&&i.kind==='rabiola');
 if(!item)return uiElement('span','〰','summon-ribbon-fallback');
 const image=document.createElement('img');image.src=item.url;image.alt=item.name;image.loading='lazy';image.decoding='async';image.className=small?'summon-item-badge':'summon-ribbon-image';return image;
}
for(let i=1;i<=9;i++){
 const node=uiElement('button',String(i),'summon-node');node.type='button';node.dataset.node=i;node.style.left=(50+(i-1)%3*100)/3+'%';node.style.top=(50+Math.floor((i-1)/3)*100)/3+'%';node.setAttribute('aria-label','Estrela '+i);
 node.onclick=e=>{if(e.detail===0&&!summonBusy&&!summonPending&&summonRitual?.status==='active'){summonPath=extendSummonPath(summonPath,i);paintSummonPath();}};
 $('summonBoard').append(node);
}
const summonPoints=path=>path.map(n=>[50+(n-1)%3*100,50+Math.floor((n-1)/3)*100].join(',')).join(' ');
function paintSummonPath(){
 $('summonStroke').setAttribute('points',summonPoints(summonPath));
 for(const node of $('summonBoard').querySelectorAll('button')){node.classList.toggle('on',summonPath.includes(Number(node.dataset.node)));node.disabled=summonBusy||!!summonPending;}
 $('summonClear').disabled=summonBusy||!!summonPending;$('summonSubmit').disabled=summonBusy||(!summonPath.length&&!summonPending);$('summonSubmit').textContent=summonPending?'Reenviar tentativa':'Lançar feitiço';
}
async function summonCall(action,extra={}){return (await accountRequest('summon',{action,sessionId:summonSession,ritualId:summonRitual?.id,...extra})).summon;}
async function loadSummonTails(){
 const data=await summonCall('inventory');if(!summonOpen)return;
 summonData={...data,seen:(data.seen||[]).map(p=>({...p,name:summonDisplayName(p)})),tails:data.tails.map(t=>({...t,name:summonDisplayName(t)}))};renderSummonCatalog();renderSummonDamaged();
 if(data.active&&!summonRitual)$('summonMessage').textContent='Um ritual anterior ainda está encerrando. Ao interromper a conexão, a rabiola fica danificada em até 45 segundos. Atualize a lista após esse prazo.';
 if(summonTarget&&!summonRitual){summonTarget=summonData.seen.find(p=>p.modelId===summonTarget.modelId)||null;if(summonTarget)prepareSummon(summonTarget);else showSummonStage('catalog');}
}
function renderSummonCatalog(){
 $('summonSeenGrid').replaceChildren(...(summonData.seen||[]).map(p=>{
  const available=p.availableTailIds.length>0,card=uiElement('button',undefined,'summon-seen-card '+(available?'available':'locked'));card.type='button';card.dataset.modelId=p.modelId;card.setAttribute('aria-label',p.name+' · '+(available?'Rabiola disponível':'Bloqueado'));
  const image=uiElement('div',undefined,'summon-seen-art');image.innerHTML=art.markup(p.color,p.soul);const badge=uiElement('span',undefined,'summon-availability');
  if(available){if(art.icon)badge.innerHTML=art.icon('tail-ready');else badge.append(summonTailArt(p.modelId,true));badge.setAttribute('aria-label','Rabiola disponível');}else{if(art.icon)badge.innerHTML=art.icon('locked');else badge.textContent='🔒';badge.setAttribute('aria-label','Sem rabiola compatível');}
  card.append(image,badge,uiElement('b',p.name),uiElement('small',available?'Pode invocar':'Bloqueado'));card.onclick=()=>prepareSummon(p);return card;
 }));
 if(!summonData.seen?.length)$('summonSeenGrid').append(uiElement('p','Nenhum Pipamon avistado ainda. Explore a Pipa Dex ou encontre jogadores em partidas.'));
}
function prepareSummon(p){
 $('summonPractice')?.remove();$('summonPracticeButton')?.remove();
 summonTarget=p;summonTail=null;showSummonStage('preparation');$('summonStart').hidden=false;$('summonStart').disabled=true;$('summonStart').textContent='Usar rabiola → Ascendente';$('summonSelectedTail').textContent='Nenhuma rabiola selecionada.';
 const chosen=$('summonChosenPipamon');chosen.replaceChildren();const image=uiElement('div',undefined,'summon-chosen-art');image.innerHTML=art.markup(p.color,p.soul);chosen.append(image,uiElement('h3',p.name),uiElement('small','Pipamon escolhido'));
 $('summonTailList').replaceChildren(...summonData.tails.filter(t=>t.status==='ready').map(tail=>{
  const compatible=p.availableTailIds.includes(tail.id),card=uiElement('article',undefined,'summon-tail '+(compatible?'compatible':'incompatible'));card.append(summonTailArt(tail.modelId),uiElement('b','Rabiola de '+tail.name));
  card.append(uiElement('small',compatible?'Compatível':'🔒 Não pode ser usada neste chamado'));
  const button=uiElement('button','Selecionar rabiola','secondary');button.type='button';button.disabled=!compatible||!!summonData.active||summonBusy;
  button.onclick=()=>{summonTail=tail;for(const c of $('summonTailList').children)c.classList.toggle('selected',c===card);$('summonSelectedTail').textContent='Selecionada: rabiola de '+tail.name+(needsSummonPractice()?'. Faça o ensaio gratuito antes do primeiro ritual.':'');$('summonStart').disabled=needsSummonPractice();};card.append(button);return card;
 }));
 if(!$('summonTailList').children.length)$('summonTailList').append(uiElement('p','Você não tem rabiolas prontas para usar.'));
 $('summonTarget').textContent=p.name;$('summonPatternHint').textContent='Feitiço: '+p.pattern.join(' → ');$('summonGuide').setAttribute('points',summonPoints(p.pattern));
 const practice=uiElement('button','Ensaiar feitiço sem usar rabiola','secondary');practice.id='summonPracticeButton';practice.onclick=openSummonPractice;$('summonStart').before(practice);
 if(needsSummonPractice())$('summonSelectedTail').textContent='Seu primeiro chamado: ensaie o feitiço gratuitamente antes de consumir a rabiola.';
}
function renderSummonDamaged(){
 $('summonDamagedList').replaceChildren(...summonData.tails.filter(t=>t.status==='damaged').map(t=>{
  const card=uiElement('article',undefined,'summon-tail damaged');if(art.icon)card.innerHTML=art.icon('tail-damaged');card.append(summonTailArt(t.modelId),uiElement('b','Rabiola de '+t.name),uiElement('small','Danificada · somente descarte'));
  const discard=uiElement('button','Descartar rabiola','secondary');discard.onclick=async()=>{try{await summonCall('discard',{tailId:t.id});await loadSummonTails();}catch(e){$('summonMessage').textContent=e.message;}};card.append(discard);return card;
 }));
 if(!$('summonDamagedList').children.length)$('summonDamagedList').append(uiElement('p','Nenhuma rabiola danificada.'));
}
$('summonInvoke').onclick=()=>showSummonStage('catalog');$('summonCatalogBack').onclick=()=>showSummonStage('npc');$('summonPreparationBack').onclick=()=>{summonTarget=null;summonTail=null;showSummonStage('catalog');};$('summonDamagedMenu').onclick=()=>showSummonStage('damaged');$('summonDamagedBack').onclick=()=>showSummonStage('npc');
const summonStart=uiElement('button','Usar rabiola → Ascendente','primary');summonStart.id='summonStart';summonStart.hidden=true;$('summonPreparation').append(summonStart);
summonStart.onclick=async()=>{
 if(summonBusy||!summonTail||needsSummonPractice())return;summonBusy=true;summonStart.disabled=true;
 try{
  const run=await summonCall('start',{tailId:summonTail.id,targetModelId:summonTarget.modelId});
  // Closing while the start request was in flight must still damage this item.
  if(!summonOpen){await summonCall('abandon',{ritualId:run.id});return;}
  summonRitual=run;summonPath=[];summonPending=null;
  showSummonStage('ascendant');
  $('summonStart').hidden=true;$('summonTailList').hidden=true;$('summonBoard').hidden=false;
  for(const id of ['summonShowPattern','summonClear','summonSubmit'])$(id).hidden=false;
  $('summonGuide').style.display='none';$('summonPatternHint').textContent='Desenhe ligando as estrelas. Ao soltar, o feitiço é enviado. Pelo teclado, use Tab e Espaço e depois Lançar feitiço.';
  $('summonSpeech').textContent='A rabiola foi utilizada. Concentre-se na constelação e faça o chamado!';
  $('leaveSummoner').textContent='Sair do ritual · danifica a rabiola';updateSummonRun(run);
 }catch(e){$('summonMessage').textContent=e.message;}finally{summonBusy=false;summonStart.disabled=false;paintSummonPath();}
};
function updateSummonRun(run){
 summonRitual=run;summonReload.hidden=run.status==='active';$('summonTries').textContent=run.remaining+' de 3 tentativas restantes';
 if(run.status==='active')return;
 $('summonRitual').hidden=true;$('summonNotice').hidden=true;$('leaveSummoner').textContent='← Menu do clube';
 const reveal=$('summonReveal');reveal.hidden=false;reveal.replaceChildren();
 if(run.status==='succeeded'){
  if(typeof summonDesignReveal==='function')summonDesignReveal(reveal);
  const sprite=uiElement('div',undefined,'summon-new-pipamon');sprite.innerHTML=art.markup(run.color,run.soul);reveal.append(sprite,uiElement('h3',run.name+' atendeu ao chamado!'),uiElement('p','Este Pipamon agora faz parte da sua coleção.'));
  const view=uiElement('button','Ver meu novo parceiro','primary');view.id='summonViewPartner';view.onclick=async()=>{view.disabled=true;try{await refreshAccount();leaveSummoner();inventorySelection=run.kiteId||null;navigateClub('collection');const kite=playerAccount?.inventory.find(k=>k.id===run.kiteId);if(kite){await selectInventory(kite);$('inventoryEquip').focus({preventScroll:true});}}finally{view.disabled=false;}};reveal.append(view);view.focus({preventScroll:true});
  $('summonSpeech').textContent='Um novo laço nasceu. Cuide bem dessa história!';refreshAccount();
 }else{
  reveal.append(uiElement('h3',run.status==='failed'?'O chamado se apagou.':'O ritual foi interrompido.'),uiElement('p',run.status==='failed'?'As três tentativas terminaram. A rabiola foi consumida.':'A rabiola ficou danificada e só pode ser descartada.'));
 }
 summonRitual=null;summonTail=null;summonPending=null;summonPath=[];
}
async function submitSummon(){
 if(summonBusy||summonRitual?.status!=='active'||(!summonPath.length&&!summonPending))return;
 summonPending??={path:[...summonPath],requestId:crypto.randomUUID()};summonBusy=true;paintSummonPath();
 const runId=summonRitual.id;
 try{const run=await summonCall('attempt',summonPending);if(!summonOpen||summonRitual?.id!==runId)return;
  summonPending=null;summonPath=[];updateSummonRun(run);$('summonMessage').textContent=run.status==='active'?'O símbolo não corresponde. Respire e tente novamente.':run.status==='succeeded'?'Invocação confirmada na sua coleção.':'';
 }catch(e){$('summonMessage').textContent=e.message+' Reenvie a mesma tentativa para consultar o resultado, sem gastar outra.';}
 finally{summonBusy=false;paintSummonPath();}
}
$('summonSubmit').onclick=submitSummon;$('summonClear').onclick=()=>{if(!summonPending){summonPath=[];paintSummonPath();}};
$('summonShowPattern').onclick=()=>{$('summonGuide').style.display=$('summonGuide').style.display==='none'?'':'none';$('summonPatternHint').textContent=$('summonGuide').style.display==='none'?'Desenhe a constelação.':'Feitiço: '+summonRitual.pattern.join(' → ');};
const board=$('summonBoard');
const boardPoint=e=>{const r=board.getBoundingClientRect();return {x:(e.clientX-r.left)/r.width*300,y:(e.clientY-r.top)/r.height*300};};
board.onpointerdown=e=>{if(e.button!==0||summonBusy||summonPending||summonRitual?.status!=='active')return;e.preventDefault();summonPath=[];summonDrawing={id:e.pointerId,point:boardPoint(e)};board.setPointerCapture(e.pointerId);summonPath=sampleSummonSegment([],summonDrawing.point,summonDrawing.point);paintSummonPath();};
board.onpointermove=e=>{if(summonDrawing?.id!==e.pointerId)return;const point=boardPoint(e);summonPath=sampleSummonSegment(summonPath,summonDrawing.point,point);summonDrawing.point=point;paintSummonPath();};
board.onpointerup=e=>{if(summonDrawing?.id!==e.pointerId)return;summonDrawing=null;submitSummon();};
board.onpointercancel=()=>{summonDrawing=null;summonPath=[];paintSummonPath();};
async function openSummoner(){
 if(!playerAccount||mode)return;keys={};summonOpen=true;$('collectionMain').hidden=true;summonRoom.hidden=false;$('summonReveal').hidden=true;$('summonRitual').hidden=true;$('summonTailList').hidden=false;$('summonMessage').textContent='';$('leaveSummoner').focus();
 $('leaveSummoner').textContent='← Menu do clube';$('summonSpeech').textContent='Cada rabiola guarda uma ligação. O feitiço certo desperta quem está do outro lado.';
 summonReload.hidden=false;
 summonTarget=null;summonTail=null;showSummonStage('npc');
 try{await loadSummonTails();await art.load('sr-assis-poses');if(summonOpen){const c=$('summonAssis');art.draw(c.getContext('2d'),'sr-assis-poses','welcome',0,0,c.width,c.height,true);}}catch(e){$('summonMessage').textContent=e.message;}
}
function leaveSummoner(){
 const run=summonRitual;summonOpen=false;summonRitual=null;summonTail=null;summonPending=null;summonDrawing=null;summonRoom.hidden=true;$('collectionMain').hidden=false;
 if(run?.status==='active')summonCall('abandon',{ritualId:run.id}).catch(()=>{});
}
$('visitSummoner').onclick=openSummoner;$('leaveSummoner').onclick=leaveSummoner;
setInterval(async()=>{if(!summonOpen||summonRitual?.status!=='active')return;const id=summonRitual.id;try{const run=await summonCall('touch');if(summonRitual?.id===id&&run.status!=='active')updateSummonRun(run);}catch{}},12000);
addEventListener('pagehide',()=>{if(summonRitual?.status==='active'&&typeof navigator!=='undefined')navigator.sendBeacon('/account/summon',new Blob([JSON.stringify({action:'abandon',ritualId:summonRitual.id,sessionId:summonSession})],{type:'application/json'}));});
