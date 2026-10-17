// Ritual sessions live only in memory: leaving/reloading cannot restart attempts.
let summonOpen=false,summonBusy=false,summonRitual=null,summonTail=null,summonPath=[],summonPending=null,summonDrawing=null;
const summonSession=crypto.randomUUID();
const summonEntry=uiElement('section',undefined,'summon-entry');
summonEntry.innerHTML='<div class="eyebrow">O ateliê do Sr. Assis</div><h3>Uma rabiola. Uma nova história.</h3><p>Traga uma rabiola e desenhe a constelação do seu Pipamon.</p><button class="primary" id="visitSummoner">Visitar o invocador ✦</button>';
$('collectionMain').insertBefore(summonEntry,$('inventoryList'));
const summonRoom=uiElement('section',undefined,'summon-room');summonRoom.id='summonRoom';summonRoom.hidden=true;
summonRoom.innerHTML='<button class="secondary" id="leaveSummoner">← Voltar à coleção</button><div class="summon-npc"><canvas id="summonAssis" width="130" height="150" aria-label="Sr. Assis, invocador"></canvas><div><div class="eyebrow">Sr. Assis · Invocador</div><h3>O chamado da rabiola</h3><p id="summonSpeech">Cada rabiola guarda uma ligação. O feitiço certo desperta quem está do outro lado.</p></div></div><p id="summonNotice" class="summon-warning">A rabiola é consumida ao iniciar. Você tem 3 tentativas. Sair, fechar ou recarregar durante o ritual deixa uma rabiola danificada, que só pode ser descartada.</p><div id="summonTailList" class="summon-tail-list"></div><div id="summonRitual" hidden><div class="summon-ritual-header"><h3 id="summonTarget"></h3><span id="summonTries"></span></div><div id="summonBoard" class="summon-board" aria-label="Constelação de nove estrelas"><svg viewBox="0 0 300 300" aria-hidden="true"><polyline id="summonGuide" class="summon-guide"/><polyline id="summonStroke" class="summon-stroke"/></svg></div><p id="summonPatternHint"></p><button class="secondary" id="summonShowPattern">Consultar feitiço</button><button class="secondary" id="summonClear">Limpar desenho</button><button class="primary" id="summonSubmit">Lançar feitiço</button></div><div id="summonReveal" class="summon-reveal" hidden></div><p id="summonMessage" role="status" aria-live="polite"></p>';
$('accountCollection').append(summonRoom);
const summonReload=uiElement('button','Atualizar rabiolas','secondary');summonReload.type='button';summonReload.onclick=()=>{if(!summonRitual&&!summonBusy)loadSummonTails().catch(e=>{$('summonMessage').textContent=e.message;});};summonRoom.insertBefore(summonReload,$('summonTailList'));
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
 $('summonTailList').replaceChildren();
 if(data.active&&!summonRitual)$('summonMessage').textContent='Um ritual anterior ainda está encerrando. Ao interromper a conexão, a rabiola fica danificada em até 45 segundos. Atualize a lista após esse prazo.';
 for(const tail of data.tails){
  const card=uiElement('article',undefined,'summon-tail '+(tail.status==='damaged'?'damaged':'')),image=uiElement('div',undefined,'summon-tail-art');image.innerHTML=art.markup(tail.color,tail.soul);
  const source=({drop:'Drop',purchase:'Compra',event:'Evento'})[tail.source];
  card.append(image,uiElement('b','Rabiola de '+tail.name),uiElement('small',source+' · '+(tail.status==='damaged'?'Danificada · sem uso':'Pronta para o ritual')));
  const button=uiElement('button',tail.status==='damaged'?'Descartar rabiola':'Escolher rabiola','secondary');button.type='button';button.disabled=!!summonRitual||!!data.active||summonBusy;
  button.onclick=async()=>{
   if(tail.status==='damaged'){try{await summonCall('discard',{tailId:tail.id});await loadSummonTails();}catch(e){$('summonMessage').textContent=e.message;}return;}
   summonTail=tail;$('summonTarget').textContent=tail.name;$('summonPatternHint').textContent='Feitiço: '+tail.pattern.join(' → ');
   $('summonGuide').setAttribute('points',summonPoints(tail.pattern));$('summonGuide').style.display='';
   $('summonRitual').hidden=false;$('summonBoard').hidden=true;$('summonShowPattern').hidden=true;$('summonClear').hidden=true;$('summonSubmit').hidden=true;
   $('summonTries').textContent='3 tentativas nesta sessão';
   $('summonStart').hidden=false;$('summonStart').textContent='Usar rabiola e iniciar ritual';$('summonStart').focus();
  };card.append(button);$('summonTailList').append(card);
 }
 if(!data.tails.length)$('summonTailList').append(uiElement('p','Você ainda não tem rabiolas disponíveis. Elas podem chegar por drops, compras ou eventos.'));
}
const summonStart=uiElement('button','Usar rabiola e iniciar ritual','primary');summonStart.id='summonStart';summonStart.hidden=true;$('summonRitual').append(summonStart);
summonStart.onclick=async()=>{
 if(summonBusy||!summonTail)return;summonBusy=true;summonStart.disabled=true;
 try{
  const run=await summonCall('start',{tailId:summonTail.id});
  // Closing while the start request was in flight must still damage this item.
  if(!summonOpen){await summonCall('abandon',{ritualId:run.id});return;}
  summonRitual=run;summonPath=[];summonPending=null;
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
 $('summonRitual').hidden=true;$('leaveSummoner').textContent='← Voltar à coleção';
 const reveal=$('summonReveal');reveal.hidden=false;reveal.replaceChildren();
 if(run.status==='succeeded'){
  const sprite=uiElement('div',undefined,'summon-new-pipamon');sprite.innerHTML=art.markup(run.color,run.soul);reveal.append(sprite,uiElement('h3',run.name+' atendeu ao chamado!'),uiElement('p','Este Pipamon agora faz parte da sua coleção.'));
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
 $('leaveSummoner').textContent='← Voltar à coleção';$('summonSpeech').textContent='Cada rabiola guarda uma ligação. O feitiço certo desperta quem está do outro lado.';
 summonReload.hidden=false;
 try{await loadSummonTails();await art.load('sr-assis-poses');if(summonOpen){const c=$('summonAssis');art.draw(c.getContext('2d'),'sr-assis-poses','welcome',0,0,c.width,c.height,true);}}catch(e){$('summonMessage').textContent=e.message;}
}
function leaveSummoner(){
 const run=summonRitual;summonOpen=false;summonRitual=null;summonTail=null;summonPending=null;summonDrawing=null;summonRoom.hidden=true;$('collectionMain').hidden=false;
 if(run?.status==='active')summonCall('abandon',{ritualId:run.id}).catch(()=>{});
}
$('visitSummoner').onclick=openSummoner;$('leaveSummoner').onclick=leaveSummoner;
setInterval(async()=>{if(!summonOpen||summonRitual?.status!=='active')return;const id=summonRitual.id;try{const run=await summonCall('touch');if(summonRitual?.id===id&&run.status!=='active')updateSummonRun(run);}catch{}},12000);
addEventListener('pagehide',()=>{if(summonRitual?.status==='active'&&typeof navigator!=='undefined')navigator.sendBeacon('/account/summon',new Blob([JSON.stringify({action:'abandon',ritualId:summonRitual.id,sessionId:summonSession})],{type:'application/json'}));});
