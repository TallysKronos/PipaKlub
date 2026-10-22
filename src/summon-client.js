// Keep club entry points; construction now uses /account/workshop, never a spell path.
let summonOpen=false,summonBusy=false,summonRitual=null,summonTarget=null,summonTail=null;
let summonData={tails:[],seen:[]},workshopDraft=workshopInput(),workshopPending=null,workshopFrame=0,workshopClock=0,workshopLast=0,workshopEpoch=0;
const summonDisplayName=p=>(typeof ART_CONFIG!=='undefined'?ART_CONFIG.dex.entries.find(e=>e.model===p.modelId)?.name:null)||p.name;
const summonEntry=uiElement('section',undefined,'summon-entry');
summonEntry.innerHTML='<h3>Oficina das Almas</h3><p>Monte a armação, firme os nós e encontre o equilíbrio do seu parceiro.</p><button class="primary" id="visitSummoner">Visitar a Oficina das Almas</button>';
$('collectionMain').insertBefore(summonEntry,$('inventoryList'));
const summonRoom=uiElement('section',undefined,'summon-room workshop-room');summonRoom.id='summonRoom';summonRoom.hidden=true;
summonRoom.innerHTML=`<button class="secondary" id="leaveSummoner">← Voltar ao clube</button>
 <header class="workshop-heading"><div><div class="eyebrow">Sr. Assis · artesão de elos</div><p id="summonSpeech">Aqui damos forma ao vento. Qual alma vamos despertar hoje?</p></div><span class="workshop-seal" aria-hidden="true">◇</span></header>
 <p id="summonMessage" role="status" aria-live="polite"></p>
 <section id="summonMenu"><h3>Cada parceiro começa com um cuidado.</h3><p>Escolha um molde conhecido e uma rabiola compatível. Os componentes básicos são fornecidos pelo ateliê nesta versão.</p><button id="summonInvoke" class="primary">Escolher molde</button><button id="workshopResume" class="secondary" hidden>Retomar montagem</button><button id="summonDamagedMenu" class="secondary">Restaurar rabiolas antigas</button></section>
 <section id="summonCatalog" hidden><button id="summonCatalogBack" class="secondary">← Oficina</button><h3>Qual parceiro vamos construir?</h3><p>Explore para conhecer espécies e trazer novas rabiolas ao ateliê.</p><div id="summonSeenGrid" class="summon-seen-grid"></div></section>
 <section id="summonPreparation" hidden><button id="summonPreparationBack" class="secondary">← Moldes</button><div class="summon-pair"><article id="summonChosenPipamon" class="summon-chosen"></article><div><h4>A alma que dará vida à montagem</h4><div id="summonTailList" class="summon-tail-list"></div></div></div><p id="summonSelectedTail">Selecione uma rabiola.</p><p class="workshop-supplies">Kit do ateliê: varetas de bambu, papel de seda e linha. Sem custo de materiais nesta versão. A rabiola fica reservada; sair não danifica a alma.</p><button id="summonStart" class="primary" disabled>Levar à bancada</button></section>
 <section id="summonDamaged" hidden><button id="summonDamagedBack" class="secondary">← Oficina</button><h3>Todo elo merece outra chance.</h3><p>O Sr. Assis restaura gratuitamente rabiolas danificadas pelo ritual antigo.</p><div id="summonDamagedList" class="summon-tail-list"></div></section>
 <section id="workshopBuild" hidden><nav id="workshopSteps" class="workshop-steps" aria-label="Progresso da montagem"></nav><div class="workshop-layout"><div class="workshop-scene"><canvas id="workshopCanvas" width="960" height="640" aria-label="Bancada animada de construção do Soulmonster"></canvas><button class="workshop-motion secondary" id="workshopMotion" aria-pressed="false">Reduzir movimento</button><p id="workshopArtStatus" role="status"></p></div><aside class="workshop-controls"><div id="workshopTool" class="eyebrow"></div><h3 id="workshopTitle" tabindex="-1"></h3><p id="workshopHint"></p><div id="workshopInputs"></div><div class="workshop-readout"><span id="workshopReadout"></span><small>Qualidade de montagem · sem bônus de combate</small></div><button id="workshopConfirm" class="primary"></button><button id="workshopRedo" class="secondary">Refazer esta etapa</button><p class="workshop-help">Pode sair e retomar. Cada etapa confirmada fica salva na sua conta.</p></aside></div></section>
 <section id="summonReveal" class="workshop-result" hidden><div class="eyebrow">O despertar</div><h3 id="workshopResultTitle"></h3><p>Rabiola unida, corpo construído e parceiro confirmado na coleção.</p><button id="summonViewPartner" class="primary">Ver meu novo parceiro</button><button id="workshopAgain" class="secondary">Voltar à oficina</button></section>`;
$('accountCollection').append(summonRoom);
const workshopAssets=typeof ART_CONFIG!=='undefined'?ART_CONFIG.workshop:null;
let workshopReduced=typeof art!=='undefined'&&!!art.reduced;
const workshopImages={};let workshopDraw=null;
$('workshopMotion').setAttribute('aria-pressed',String(workshopReduced));$('workshopMotion').textContent=workshopReduced?'Ativar movimento':'Reduzir movimento';
const workshopLastResult=uiElement('button','Rever último despertar','secondary');workshopLastResult.hidden=true;$('summonMenu').append(workshopLastResult);
workshopLastResult.onclick=async()=>{if(!summonData.latest)return;summonRitual=summonData.latest;workshopDraft=workshopInput();renderWorkshop();const entry=ART_CONFIG.dex.entries.find(e=>e.model===summonRitual.modelId);if(entry)await art.load(entry.atlas);await workshopLoadArt();};
function summonTailArt(modelId,small=false){
 const entry=typeof ART_CONFIG!=='undefined'?ART_CONFIG.dex.entries.find(e=>e.model===modelId):null,item=entry&&ART_CONFIG.items?.find(i=>i.pipamon===entry.id&&i.kind==='rabiola');
 if(!item&&modelId==='rabbito'&&workshopImages.parts?.naturalWidth){const canvas=document.createElement('canvas');canvas.width=226;canvas.height=137;canvas.className='summon-ribbon-image';canvas.setAttribute('role','img');canvas.setAttribute('aria-label','Rabiola de Rabbito');canvas.getContext('2d').drawImage(workshopImages.parts,...workshopAssets.rects.tail,0,0,226,137);return canvas;}
 if(!item)return uiElement('span','〰','summon-ribbon-fallback');
 const image=document.createElement('img');image.src=item.url;image.alt=item.name;image.loading='lazy';image.className=small?'summon-item-badge':'summon-ribbon-image';return image;
}
async function workshopLoadArt(retry=false){
 if(!workshopAssets)return;
 const results=await Promise.all(Object.entries(workshopAssets.images).map(async([id,def])=>{
  if(workshopImages[id]?.naturalWidth&&!retry)return true;
  const image=new Image();image.decoding='async';workshopImages[id]=image;
  return new Promise(resolve=>{image.onload=()=>resolve(true);image.onerror=()=>resolve(false);image.src=def.url;});
 }));
 $('workshopArtStatus').textContent=results.every(Boolean)?'':'Parte da arte não carregou. A montagem está preservada.';
 if(!results.every(Boolean)){const retryButton=uiElement('button','Recarregar arte','secondary');retryButton.onclick=()=>workshopLoadArt(true);$('workshopArtStatus').append(retryButton);}
 workshopDraw=createWorkshopRenderer({bench:workshopImages.bench,parts:workshopImages.parts,rects:workshopAssets.rects,reduced:()=>workshopReduced,drawCreature:(g,job,time,x,y,size,state)=>{
  const entry=ART_CONFIG.dex.entries.find(e=>e.model===(job.modelId||job.targetModelId));
  if(entry){const atlas=art.atlases[entry.atlas],sequence=atlas?.animations[state]||atlas?.animations.idle;if(sequence?.length){art.draw(g,entry.atlas,sequence[Math.floor(time*5)%sequence.length],x,y,size,size);return;}}
  art.creature(g,job.color,time*1000,x,y,size,{soul:job.soul,animate:!workshopReduced});
 }});workshopAnimate();
}
function workshopAnimate(){
 if(workshopFrame||!summonOpen||!summonRitual||!workshopDraw)return;
 const tick=t=>{workshopFrame=0;if(!summonOpen||!summonRitual)return;if(document.hidden){workshopLast=0;return;}
  workshopClock+=workshopLast?Math.min((t-workshopLast)/1000,.05):0;workshopLast=t;
  workshopDraw($('workshopCanvas').getContext('2d'),summonRitual,workshopDraft,workshopClock);workshopFrame=requestAnimationFrame(tick);
 };workshopFrame=requestAnimationFrame(tick);
}
document.addEventListener('visibilitychange',()=>{workshopLast=0;if(!document.hidden)workshopAnimate();});
$('workshopMotion').onclick=()=>{workshopReduced=!workshopReduced;$('workshopMotion').setAttribute('aria-pressed',String(workshopReduced));$('workshopMotion').textContent=workshopReduced?'Ativar movimento':'Reduzir movimento';};
function showSummonStage(stage){
 for(const [id,key] of [['summonMenu','npc'],['summonCatalog','catalog'],['summonPreparation','preparation'],['summonDamaged','damaged'],['workshopBuild','build']])$(id).hidden=stage!==key;$('summonReveal').hidden=true;
}
async function workshopCall(action,extra={}){return (await accountRequest('workshop',{action,...extra})).workshop;}
async function loadSummonTails(){
 const owner=playerAccount?.profile?.id,epoch=workshopEpoch,data=await workshopCall('inventory');if(!summonOpen||epoch!==workshopEpoch||owner!==playerAccount?.profile?.id)return;
 summonData={...data,seen:(data.seen||[]).map(p=>({...p,name:summonDisplayName(p)})),tails:(data.tails||[]).map(t=>({...t,name:summonDisplayName(t)}))};
 renderSummonCatalog();renderSummonDamaged();$('workshopResume').hidden=!data.active;workshopLastResult.hidden=!data.latest;
 if(data.active){summonRitual=data.active;workshopDraft=workshopInput();renderWorkshop();const e=ART_CONFIG.dex.entries.find(e=>e.model===data.active.modelId);if(e)await art.load(e.atlas);}
}
function renderSummonCatalog(){
 $('summonSeenGrid').replaceChildren(...summonData.seen.map(p=>{const available=p.availableTailIds?.length>0,card=uiElement('button',undefined,'summon-seen-card '+(available?'available':'locked'));card.type='button';const image=uiElement('div',undefined,'summon-seen-art');image.innerHTML=art.markup(p.color,p.soul);card.append(image,uiElement('b',p.name),uiElement('small',available?'Rabiola disponível':'Falta uma rabiola compatível'));card.onclick=()=>prepareSummon(p);return card;}));
 if(!summonData.seen.length)$('summonSeenGrid').append(uiElement('p','Conheça os Soulmonsters na exploração ou na Dex para descobrir seus moldes.'));
}
function prepareSummon(p){
 summonTarget=p;summonTail=null;showSummonStage('preparation');$('summonStart').disabled=true;const image=uiElement('div',undefined,'summon-chosen-art');image.innerHTML=art.markup(p.color,p.soul);$('summonChosenPipamon').replaceChildren(image,uiElement('h3',p.name),uiElement('small','Molde escolhido'));
 $('summonTailList').replaceChildren(...summonData.tails.filter(t=>t.status==='ready').map(t=>{const compatible=p.availableTailIds.includes(t.id),card=uiElement('article',undefined,'summon-tail'),button=uiElement('button',compatible?'Selecionar rabiola':'Incompatível','secondary');button.type='button';button.disabled=!compatible||!!summonData.active;button.onclick=()=>{summonTail=t;$('summonStart').disabled=false;$('summonSelectedTail').textContent='Selecionada: rabiola de '+t.name;for(const c of $('summonTailList').children)c.classList.toggle('selected',c===card);};card.append(summonTailArt(t.modelId),uiElement('b',t.name),button);return card;}));
 if(!$('summonTailList').children.length)$('summonTailList').append(uiElement('p','Ainda não há rabiolas prontas na mochila.'));
}
function renderSummonDamaged(){
 $('summonDamagedList').replaceChildren(...summonData.tails.filter(t=>t.status==='damaged').map(t=>{const card=uiElement('article',undefined,'summon-tail'),button=uiElement('button','Restaurar gratuitamente','secondary');button.onclick=async()=>{button.disabled=true;try{await workshopCall('restore',{tailId:t.id});await loadSummonTails();$('summonMessage').textContent='Rabiola restaurada.';}catch(e){$('summonMessage').textContent=e.message;button.disabled=false;}};card.append(summonTailArt(t.modelId),uiElement('b',t.name),button);return card;}));
 if(!$('summonDamagedList').children.length)$('summonDamagedList').append(uiElement('p','Nenhuma rabiola precisa de restauração.'));
}
function workshopReadout(){const stage=summonRitual.stage;$('workshopConfirm').disabled=summonBusy||(!workshopPending&&!workshopReady(stage,workshopDraft));$('workshopReadout').textContent=stage===0?workshopDraft.joints.length+'/4 encaixes':stage===2?workshopDraft.cuts.length+'/4 partes do contorno':workshopQuality(stage,workshopDraft)+'% · '+(stage===1?'firmeza':stage===3?'estabilidade':'sincronia');}
function renderWorkshop(){
 if(!summonRitual)return;const stage=summonRitual.stage,done=summonRitual.status==='completed';showSummonStage('build');
 $('workshopSteps').replaceChildren(...WORKSHOP_STAGES.map((s,i)=>{const node=uiElement('span',(i<stage?'✓ ':String(i+1)+' ')+s.name);if(i===stage)node.setAttribute('aria-current','step');return node;}));
 $('workshopRedo').hidden=done;$('workshopConfirm').hidden=done;$('workshopInputs').replaceChildren();
 if(done){$('workshopTitle').textContent='Um novo elo ganhou vida.';$('workshopHint').textContent='Seu parceiro foi confirmado na coleção. A montagem não altera os atributos de combate.';$('workshopTool').textContent='Montagem concluída';$('workshopReadout').textContent='Qualidade '+summonRitual.quality+'/100';$('summonReveal').hidden=false;$('workshopResultTitle').textContent=summonDisplayName(summonRitual)+' despertou!';}
 else{
  const step=WORKSHOP_STAGES[stage];$('workshopTitle').textContent=step.title;$('workshopHint').textContent=step.hint;$('workshopTool').textContent=step.tool;$('workshopConfirm').textContent=workshopPending?'Reenviar confirmação':step.action;
  if(stage===0||stage===2){const field=stage===0?'joints':'cuts',group=uiElement('div',undefined,'workshop-points');for(let i=0;i<4;i++){const button=uiElement('button',(stage===0?'Encaixar vareta ':'Recortar parte ')+(i+1),'secondary');button.disabled=!!workshopPending||summonBusy||i!==workshopDraft[field].length;button.onclick=()=>{workshopDraft[field].push(i);renderWorkshop();($('workshopInputs').querySelector('button:not([disabled])')||$('workshopConfirm')).focus({preventScroll:true});};group.append(button);}$('workshopInputs').append(group);}
  else{const fields=stage===1?[['tension','Tensão do nó',65]]:stage===3?[['balance','Ponto de amarração',50]]:[['wind','Direção do vento',50],['soulTension','Tensão da linha',50]];
   for(const [key,label,target]of fields){const row=uiElement('label',undefined,'workshop-range'),range=document.createElement('input'),out=uiElement('output',String(workshopDraft[key]));range.type='range';range.min='0';range.max='100';range.step='1';range.value=workshopDraft[key];range.disabled=!!workshopPending||summonBusy;range.setAttribute('aria-label',label);range.oninput=()=>{workshopDraft[key]=Number(range.value);out.textContent=range.value;workshopReadout();};row.append(uiElement('span',label+' · alvo '+target),range,out);$('workshopInputs').append(row);}
   const help=uiElement('button','Ajustar com o Sr. Assis','secondary');help.disabled=!!workshopPending||summonBusy;help.onclick=()=>{for(const [key,,target]of fields)workshopDraft[key]=target;renderWorkshop();$('workshopConfirm').focus({preventScroll:true});};$('workshopInputs').append(help);
   if(stage===1){const timed=uiElement('button','Apertar no ritmo da linha','secondary');timed.disabled=!!workshopPending||summonBusy;timed.onclick=()=>{workshopDraft.tension=Math.round(50+Math.sin(workshopClock*2.2)*45);renderWorkshop();};$('workshopInputs').append(timed);}
  }workshopReadout();
 }$('workshopRedo').disabled=summonBusy||!!workshopPending;workshopAnimate();
}
$('workshopRedo').onclick=()=>{workshopDraft=workshopInput();renderWorkshop();};
// Direct manipulation and equivalent keyboard buttons share the same ordered input.
function workshopPoint(event){
 if(!summonRitual||summonBusy||workshopPending||![0,2].includes(summonRitual.stage))return;
 const canvas=$('workshopCanvas'),r=canvas.getBoundingClientRect(),x=(event.clientX-r.left)/r.width*960-480,y=(event.clientY-r.top)/r.height*640-400;
 const field=summonRitual.stage===0?'joints':'cuts',i=workshopDraft[field].length;
 const rabbit=summonRitual.modelId==='rabbito',points=rabbit?[[-65,-155],[28,-155],[50,8],[-48,70]]:[[0,-100],[105,0],[0,100],[-105,0]];
 if(i<4&&Math.hypot(x-points[i][0],y-points[i][1])<30){workshopDraft[field].push(i);renderWorkshop();}
}
$('workshopCanvas').onpointerdown=event=>{if(event.button!==0)return;workshopPoint(event);};
$('workshopCanvas').onpointermove=event=>{if(event.buttons===1)workshopPoint(event);};
$('workshopConfirm').onclick=async()=>{
 if(summonBusy||!summonRitual||(!workshopPending&&!workshopReady(summonRitual.stage,workshopDraft)))return;
 workshopPending??={jobId:summonRitual.id,stage:summonRitual.stage,payload:workshopPayload(summonRitual.stage,workshopDraft),requestId:crypto.randomUUID()};
 const pending=workshopPending,epoch=workshopEpoch,owner=playerAccount?.profile?.id;summonBusy=true;renderWorkshop();$('summonMessage').textContent='Confirmando etapa na sua conta…';
 try{const job=await workshopCall('advance',pending);if(epoch!==workshopEpoch||!summonOpen||owner!==playerAccount?.profile?.id)return;summonRitual=job;workshopPending=null;workshopDraft=workshopInput();$('summonMessage').textContent=job.status==='completed'?'Seu parceiro está na coleção.':'Etapa salva. Pode continuar ou retomar depois.';renderWorkshop();$('workshopTitle').focus({preventScroll:true});if(job.status==='completed')await refreshAccount();}
 catch(e){if(epoch===workshopEpoch&&summonOpen)$('summonMessage').textContent=e.message+' Sua montagem está preservada. Reenvie a confirmação ou reabra a oficina para consultar o resultado.';}
 finally{summonBusy=false;if(epoch===workshopEpoch&&summonOpen)renderWorkshop();}
};
$('summonStart').onclick=async()=>{
 if(summonBusy||!summonTarget||!summonTail)return;const epoch=workshopEpoch;summonBusy=true;$('summonStart').disabled=true;
 try{const job=await workshopCall('start',{tailId:summonTail.id,targetModelId:summonTarget.modelId});if(epoch!==workshopEpoch||!summonOpen)return;summonRitual=job;workshopDraft=workshopInput();summonData.active=job;workshopPending=null;renderWorkshop();const entry=ART_CONFIG.dex.entries.find(e=>e.model===job.modelId);if(entry)await art.load(entry.atlas);await workshopLoadArt();}
 catch(e){if(epoch===workshopEpoch)$('summonMessage').textContent=e.message;}
 finally{summonBusy=false;if(epoch===workshopEpoch&&summonOpen){$('summonStart').disabled=false;if(summonRitual)renderWorkshop();}}
};
$('summonInvoke').onclick=()=>showSummonStage('catalog');$('summonCatalogBack').onclick=()=>showSummonStage('npc');$('summonPreparationBack').onclick=()=>showSummonStage('catalog');$('summonDamagedMenu').onclick=()=>showSummonStage('damaged');$('summonDamagedBack').onclick=()=>showSummonStage('npc');$('workshopResume').onclick=()=>{summonRitual=summonData.active;renderWorkshop();workshopLoadArt();};
$('workshopAgain').onclick=async()=>{summonRitual=null;workshopPending=null;showSummonStage('npc');await loadSummonTails();};
$('summonViewPartner').onclick=async()=>{const id=summonRitual?.kiteId;if(!id)return;await refreshAccount();leaveSummoner();inventorySelection=id;navigateClub('collection');const kite=playerAccount?.inventory.find(k=>k.id===id);if(kite){await selectInventory(kite);$('inventoryEquip').focus({preventScroll:true});}};
async function openSummoner(){
 if(!playerAccount||mode)return;keys={};summonOpen=true;workshopEpoch++;summonRitual=null;workshopPending=null;workshopLast=0;showSummonStage('npc');summonRoom.hidden=false;$('collectionMain').hidden=true;$('summonMessage').textContent='Carregando moldes e rabiolas…';
 try{await loadSummonTails();if(summonOpen){$('summonMessage').textContent='';await workshopLoadArt();}}
 catch(e){if(summonOpen){$('summonMessage').textContent=e.message+' Tente conectar novamente. Sua montagem permanece na conta.';const retry=uiElement('button','Tentar novamente','secondary');retry.onclick=openSummoner;$('summonMessage').append(retry);}}
}
function leaveSummoner(){summonOpen=false;workshopEpoch++;summonRitual=null;workshopPending=null;summonTail=null;workshopLast=0;if(workshopFrame)cancelAnimationFrame(workshopFrame);workshopFrame=0;summonRoom.hidden=true;$('collectionMain').hidden=false;}
$('leaveSummoner').onclick=leaveSummoner;$('visitSummoner').onclick=openSummoner;
