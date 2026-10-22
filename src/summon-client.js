// Keep club entry points; construction now uses /account/workshop, never a spell path.
let summonOpen=false,summonBusy=false,summonRitual=null,summonTarget=null,summonTail=null;
let workshopReveal=null,workshopRevealTool='estilete',workshopRevealCursor=null,workshopRevealTimer=null,workshopRevealPrev=null,workshopRevealTries=0;
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
 <section id="workshopBuild" hidden><div class="workshop-hud"><button class="secondary" id="workshopExit">← Sair da bancada</button><nav id="workshopSteps" class="workshop-steps" aria-label="Progresso da montagem"></nav></div><div class="workshop-layout"><div class="workshop-scene"><canvas id="workshopCanvas" width="960" height="640" aria-label="Bancada animada de construção do Soulmonster"></canvas><button class="workshop-motion secondary" id="workshopMotion" aria-pressed="false">Reduzir movimento</button><p id="workshopArtStatus" role="status"></p></div><aside class="workshop-controls"><div id="workshopTool" class="eyebrow"></div><h3 id="workshopTitle" tabindex="-1"></h3><p id="workshopHint"></p><div id="workshopInputs"></div><div class="workshop-readout"><span id="workshopReadout"></span><small>Qualidade de montagem · sem bônus de combate</small></div><button id="workshopConfirm" class="primary"></button><button id="workshopRedo" class="secondary">Refazer esta etapa</button><p class="workshop-help">Pode sair e retomar. Cada etapa confirmada fica salva na sua conta.</p></aside></div></section>
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
  workshopRevealTick();const g=$('workshopCanvas').getContext('2d');workshopDraw(g,summonRitual,workshopDraft,workshopClock);workshopRevealOverlay(g);workshopFrame=requestAnimationFrame(tick);
 };workshopFrame=requestAnimationFrame(tick);
}
document.addEventListener('visibilitychange',()=>{workshopLast=0;if(!document.hidden)workshopAnimate();});
$('workshopMotion').onclick=()=>{workshopReduced=!workshopReduced;$('workshopMotion').setAttribute('aria-pressed',String(workshopReduced));$('workshopMotion').textContent=workshopReduced?'Ativar movimento':'Reduzir movimento';};
function showSummonStage(stage){
 for(const [id,key] of [['summonMenu','npc'],['summonCatalog','catalog'],['summonPreparation','preparation'],['summonDamaged','damaged'],['workshopBuild','build']])$(id).hidden=stage!==key;$('summonReveal').hidden=true;
 // A montagem ocupa a tela inteira, como uma cena de jogo; menus e catálogo continuam no clube.
 summonRoom.classList.toggle('is-building',stage==='build');
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
function workshopReadout(){const stage=summonRitual.stage;$('workshopConfirm').disabled=summonBusy||(!workshopPending&&!workshopReady(stage,workshopDraft));$('workshopReadout').textContent=stage===0?workshopDraft.joints.length+'/4 encaixes':stage===2?workshopRevealReadout():workshopQuality(stage,workshopDraft)+'% · '+(stage===1?'firmeza':stage===3?'estabilidade':'sincronia');}
function renderWorkshop(){
 if(!summonRitual)return;const stage=summonRitual.stage,done=summonRitual.status==='completed';showSummonStage('build');if(stage!==2||done)workshopReveal=null;summonRoom.classList.toggle('is-revealing',stage===2&&!done);
 $('workshopSteps').replaceChildren(...WORKSHOP_STAGES.map((s,i)=>{const node=uiElement('span',(i<stage?'✓ ':String(i+1)+' ')+s.name);if(i===stage)node.setAttribute('aria-current','step');return node;}));
 $('workshopRedo').hidden=done;$('workshopConfirm').hidden=done;$('workshopInputs').replaceChildren();
 if(done){$('workshopTitle').textContent='Um novo elo ganhou vida.';$('workshopHint').textContent='Seu parceiro foi confirmado na coleção. A montagem não altera os atributos de combate.';$('workshopTool').textContent='Montagem concluída';$('workshopReadout').textContent='Qualidade '+summonRitual.quality+'/100';$('summonReveal').hidden=false;$('workshopResultTitle').textContent=summonDisplayName(summonRitual)+' despertou!';}
 else{
  const step=WORKSHOP_STAGES[stage];$('workshopTitle').textContent=step.title;$('workshopHint').textContent=step.hint;$('workshopTool').textContent=step.tool;$('workshopConfirm').textContent=workshopPending?'Reenviar confirmação':step.action;
  if(stage===2)workshopRevealControls();
  else if(stage===0){const field='joints',group=uiElement('div',undefined,'workshop-points');for(let i=0;i<4;i++){const button=uiElement('button','Encaixar vareta '+(i+1),'secondary');button.disabled=!!workshopPending||summonBusy||i!==workshopDraft[field].length;button.onclick=()=>{workshopDraft[field].push(i);renderWorkshop();($('workshopInputs').querySelector('button:not([disabled])')||$('workshopConfirm')).focus({preventScroll:true});};group.append(button);}$('workshopInputs').append(group);}
  else{const fields=stage===1?[['tension','Tensão do nó',65]]:stage===3?[['balance','Ponto de amarração',50]]:[['wind','Direção do vento',50],['soulTension','Tensão da linha',50]];
   for(const [key,label,target]of fields){const row=uiElement('label',undefined,'workshop-range'),range=document.createElement('input'),out=uiElement('output',String(workshopDraft[key]));range.type='range';range.min='0';range.max='100';range.step='1';range.value=workshopDraft[key];range.disabled=!!workshopPending||summonBusy;range.setAttribute('aria-label',label);range.oninput=()=>{workshopDraft[key]=Number(range.value);out.textContent=range.value;workshopReadout();};row.append(uiElement('span',label+' · alvo '+target),range,out);$('workshopInputs').append(row);}
   const help=uiElement('button','Ajustar com o Sr. Assis','secondary');help.disabled=!!workshopPending||summonBusy;help.onclick=()=>{for(const [key,,target]of fields)workshopDraft[key]=target;renderWorkshop();$('workshopConfirm').focus({preventScroll:true});};$('workshopInputs').append(help);
   if(stage===1){const timed=uiElement('button','Apertar no ritmo da linha','secondary');timed.disabled=!!workshopPending||summonBusy;timed.onclick=()=>{workshopDraft.tension=Math.round(50+Math.sin(workshopClock*2.2)*45);renderWorkshop();};$('workshopInputs').append(timed);}
  }workshopReadout();
 }$('workshopRedo').disabled=summonBusy||!!workshopPending;$('workshopExit').disabled=summonBusy;workshopAnimate();
}
// Sair da bancada volta ao ateliê sem perder nada: as etapas confirmadas estão na conta e a montagem pode ser retomada.
$('workshopExit').onclick=()=>{if(summonBusy)return;if(summonRitual&&summonRitual.status!=='completed')summonData.active=summonRitual;summonRitual=null;workshopReveal=null;workshopPending=null;showSummonStage('npc');$('workshopResume').hidden=!summonData.active;$('summonMessage').textContent=summonData.active?'Montagem guardada. Retome quando quiser.':'';$('summonInvoke').focus({preventScroll:true});};
$('workshopRedo').onclick=()=>{workshopDraft=workshopInput();if(summonRitual?.stage===2)workshopRevealBegin();renderWorkshop();};
// Etapa do papel: escavação da marca da alma (PIP-58). Tempo de bancada pausa com a aba oculta, como o resto da animação.
function workshopRevealActive(){return !!(summonRitual&&summonRitual.status!=='completed'&&summonRitual.stage===2&&workshopReveal&&!workshopPending&&!summonBusy);}
function workshopRevealLive(){return workshopRevealActive()&&workshopRevealTimer&&workshopClock>=workshopRevealTimer.start&&!workshopRevealTimer.over&&!workshopReveal.failed;}
function workshopRevealBegin(){
 const rabbit=summonRitual.modelId==='rabbito'||summonRitual.targetModelId==='rabbito',id=String(summonRitual.id||'');let seed=++workshopRevealTries;for(const ch of id)seed=(seed*31+ch.charCodeAt(0))>>>0;
 workshopReveal=createReveal(revealMask(workshopImages.parts,workshopAssets?.rects,rabbit),seed);workshopReveal.job=summonRitual.id;workshopReveal.fallback=rabbit&&!workshopImages.parts?.naturalWidth;workshopRevealTool='estilete';workshopRevealCursor=null;
 workshopRevealTimer={start:workshopClock+REVEAL_COUNTDOWN,end:workshopClock+REVEAL_COUNTDOWN+REVEAL_SECONDS,over:false,shown:-1};
 workshopDraft.cuts=[];workshopDraft.revealScore=null;workshopDraft.reveal=workshopReveal;
}
function workshopRevealSettle(){
 const r=revealScore(workshopReveal);
 if(r.failed){workshopReveal.failed=true;workshopDraft.cuts=[];workshopDraft.revealScore=null;$('summonMessage').textContent='A marca rasgou demais e a folha cedeu. Recomece a folha: nesta versão o papel é do ateliê e a rabiola continua guardada.';workshopRevealControls();return;}
 else if(r.done||workshopRevealTimer.over){workshopDraft.cuts=[0,1,2,3];workshopDraft.revealScore=r.score;}
 workshopReadout();
}
function workshopRevealStrike(x,y){
 if(!workshopRevealLive())return;revealStrike(workshopReveal,workshopRevealTool,x,y);
 if(workshopRevealTool==='estilete')workshopReveal.flashes.push({x,y,at:workshopClock});workshopRevealSettle();
}
function workshopRevealPointer(event,down){
 if(!workshopRevealActive())return false;const c=$('workshopCanvas'),r=c.getBoundingClientRect(),p={x:(event.clientX-r.left)/r.width*960-480,y:(event.clientY-r.top)/r.height*640-400};
 workshopRevealCursor=p;if(event.type==='pointerdown'){c.setPointerCapture?.(event.pointerId);workshopRevealPrev=null;}
 if(event.type==='pointerdown'&&workshopRevealTool==='estilete')workshopRevealStrike(p.x,p.y);
 else if(workshopRevealTool==='tesourinha'&&(event.type==='pointerdown'||down))workshopRevealSnip(p);
 return true;
}
// Interpolada a cada 4 px: a nota não depende da frequência de eventos do aparelho.
function workshopRevealSnip(p){const a=workshopRevealPrev;if(!a){workshopRevealStrike(p.x,p.y);workshopRevealPrev=p;return;}const n=Math.floor(Math.hypot(p.x-a.x,p.y-a.y)/4);for(let i=1;i<=n;i++)workshopRevealStrike(a.x+(p.x-a.x)*i/n,a.y+(p.y-a.y)*i/n);if(n)workshopRevealPrev=p;}
function workshopRevealLight(){if(!workshopRevealLive()||workshopReveal.lights<=0)return;workshopReveal.lights--;workshopReveal.lightUntil=workshopClock+2.5;workshopRevealControls();workshopReadout();}
function workshopRevealTick(){
 if(!workshopRevealActive())return;
 // A arte das peças pode chegar depois de retomar a montagem: refaz a folha com a silhueta certa antes do primeiro golpe.
 if(workshopReveal.fallback&&workshopImages.parts?.naturalWidth&&!workshopReveal.strikes){workshopRevealTries--;workshopRevealBegin();workshopRevealControls();}
 workshopDraft.reveal=workshopReveal;
 workshopDraft.revealView={tool:workshopRevealTool,cursor:workshopRevealCursor,lit:workshopClock<workshopRevealTimer.start||workshopClock<workshopReveal.lightUntil};
 if(!workshopRevealTimer.over&&workshopClock>=workshopRevealTimer.end){workshopRevealTimer.over=true;$('summonMessage').textContent='Tempo esgotado: a etapa fica com o que foi revelado.';workshopRevealSettle();workshopRevealControls();}
 const left=Math.max(0,Math.ceil(workshopRevealTimer.end-Math.max(workshopClock,workshopRevealTimer.start)));
 if(left!==workshopRevealTimer.shown){workshopRevealTimer.shown=left;const t=$('workshopRevealClock');if(t){t.textContent=left+'s';t.classList.toggle('low',left<=15);}}
}
function workshopRevealOverlay(g){
 if(!workshopRevealActive()||workshopClock>=workshopRevealTimer.start)return;
 g.save();g.fillStyle='#fff8e9';g.strokeStyle='#294b53';g.lineWidth=8;g.font='bold 120px Lilita One, sans-serif';g.textAlign='center';g.textBaseline='middle';
 const n=String(Math.ceil(workshopRevealTimer.start-workshopClock));g.strokeText(n,480,300);g.fillText(n,480,300);g.restore();
}
function workshopRevealReadout(){
 if(!workshopReveal)return '';const r=revealScore(workshopReveal);
 const bars=$('workshopRevealBars');if(bars){bars.querySelector('[data-bar=shown] i').style.width=Math.round(r.revealed*100)+'%';bars.querySelector('[data-bar=tear] i').style.width=Math.round(Math.min(1,r.damage/REVEAL_FAIL)*100)+'%';bars.querySelector('[data-bar=shown] b').textContent=Math.round(r.revealed*100)+'%';bars.querySelector('[data-bar=tear] b').textContent=Math.round(r.damage*100)+'%';}
 return workshopReveal.failed?'A folha cedeu':'Nota '+r.score+(r.damage>.3&&!workshopReveal.failed?' · a marca está rasgando: use a tesourinha':'');
}
function workshopRevealControls(){
 if(!workshopReveal||workshopReveal.job!==summonRitual.id)workshopRevealBegin();const live=!workshopReveal.failed&&!workshopRevealTimer.over;$('workshopInputs').replaceChildren();
 const head=uiElement('div',undefined,'workshop-reveal-head');const clock=uiElement('b',Math.ceil(REVEAL_SECONDS)+'s');clock.id='workshopRevealClock';head.append(clock,uiElement('span','Tempo de bancada · pausa se você sair da aba'));
 const tools=uiElement('div',undefined,'workshop-tools');tools.setAttribute('role','group');tools.setAttribute('aria-label','Ferramentas');
 for(const [id,label] of [['estilete','Estilete'],['tesourinha','Tesourinha']]){const b=uiElement('button',label,'secondary');b.setAttribute('aria-pressed',String(workshopRevealTool===id));b.disabled=!live||!!workshopPending||summonBusy;b.onclick=()=>{workshopRevealTool=id;workshopRevealControls();$('workshopCanvas').focus({preventScroll:true});};tools.append(b);}
 const light=uiElement('button','Luz do molde ('+workshopReveal.lights+')','secondary');light.disabled=!live||workshopReveal.lights<=0||!!workshopPending||summonBusy;light.onclick=()=>{workshopRevealLight();$('workshopCanvas').focus({preventScroll:true});};tools.append(light);
 const bars=uiElement('div',undefined,'workshop-reveal-bars');bars.id='workshopRevealBars';bars.innerHTML='<div data-bar="shown"><span>Marca revelada</span><i></i><b>0%</b></div><div data-bar="tear"><span>Rasgo · cede em 50%</span><i></i><b>0%</b></div>';
 for(const row of bars.children){const track=document.createElement('em');track.append(row.querySelector('i'));row.insertBefore(track,row.querySelector('b'));}
 const keys=uiElement('p','Mouse ou toque na bancada · Setas movem a ferramenta, Espaço usa, 1 e 2 trocam, L acende a Luz.','workshop-help');
 $('workshopInputs').append(head,tools,bars,keys);if(workshopReveal.failed){const again=uiElement('button','Recomeçar a folha','primary');again.onclick=()=>{workshopDraft=workshopInput();workshopRevealBegin();renderWorkshop();};$('workshopInputs').append(again);}
 workshopRevealTimer.shown=-1;workshopReadout();
}
$('workshopCanvas').tabIndex=0;
$('workshopCanvas').addEventListener('keydown',event=>{
 if(!workshopRevealActive())return;const k=event.key,step=event.shiftKey?3:8,mv={ArrowUp:[0,-step],ArrowDown:[0,step],ArrowLeft:[-step,0],ArrowRight:[step,0]}[k];
 if(mv||k===' ')event.preventDefault();
 if(k==='1'||k==='2'){workshopRevealTool=k==='1'?'estilete':'tesourinha';workshopRevealControls();}
 if(k.toLowerCase()==='l')workshopRevealLight();
 const at=workshopRevealCursor||{x:0,y:-20};
 if(mv){workshopRevealCursor={x:at.x+mv[0],y:at.y+mv[1]};if(workshopRevealTool==='tesourinha'&&workshopRevealPrev)workshopRevealSnip(workshopRevealCursor);}
 if(k===' '&&!event.repeat){workshopRevealCursor=at;if(workshopRevealTool==='estilete')workshopRevealStrike(at.x,at.y);else{workshopRevealPrev=null;workshopRevealSnip(at);}}
});
$('workshopCanvas').addEventListener('keyup',event=>{if(event.key===' ')workshopRevealPrev=null;});
// Direct manipulation and equivalent keyboard buttons share the same ordered input.
function workshopPoint(event){
 if(!summonRitual||summonBusy||workshopPending||![0,2].includes(summonRitual.stage))return;
 const canvas=$('workshopCanvas'),r=canvas.getBoundingClientRect(),x=(event.clientX-r.left)/r.width*960-480,y=(event.clientY-r.top)/r.height*640-400;
 const field=summonRitual.stage===0?'joints':'cuts',i=workshopDraft[field].length;
 const rabbit=summonRitual.modelId==='rabbito',points=rabbit?[[-65,-155],[28,-155],[50,8],[-48,70]]:[[0,-100],[105,0],[0,100],[-105,0]];
 if(i<4&&Math.hypot(x-points[i][0],y-points[i][1])<30){workshopDraft[field].push(i);renderWorkshop();}
}
$('workshopCanvas').onpointerdown=event=>{if(event.button!==0)return;if(workshopRevealPointer(event,true))return;workshopPoint(event);};
$('workshopCanvas').onpointermove=event=>{if(workshopRevealPointer(event,event.buttons===1&&!event.type.endsWith('down')))return;if(event.buttons===1)workshopPoint(event);};
$('workshopCanvas').onpointerup=$('workshopCanvas').onpointercancel=()=>{workshopRevealPrev=null;};
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
function leaveSummoner(){summonRoom.classList.remove('is-building','is-revealing');summonOpen=false;workshopEpoch++;summonRitual=null;workshopPending=null;summonTail=null;workshopLast=0;if(workshopFrame)cancelAnimationFrame(workshopFrame);workshopFrame=0;summonRoom.hidden=true;$('collectionMain').hidden=false;}
$('leaveSummoner').onclick=leaveSummoner;$('visitSummoner').onclick=openSummoner;
