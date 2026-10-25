// Preparation is a scene in the same atelier as the live workbench.
// Existing inventory, reservation, resume and birth handlers remain authoritative.
const atelierScene=uiElement('div',undefined,'atelier-scene');
atelierScene.setAttribute('aria-hidden','true');
summonRoom.prepend(atelierScene);
const atelierTop=uiElement('div',undefined,'atelier-top');
atelierTop.innerHTML='<div><span class="atelier-kicker">Ateliê do Sr. Assis</span><h2>Oficina das Almas</h2></div><button type="button" id="atelierLeave" aria-label="Sair da Oficina">✕</button>';
summonRoom.prepend(atelierTop);
$('atelierLeave').onclick=()=>{if(!summonBusy)closeAccount();};
const atelierMentor=uiElement('div',undefined,'atelier-mentor');
const atelierPortrait=document.createElement('img');atelierPortrait.src='/oficina-v3/assis.png';atelierPortrait.alt='Sr. Assis';atelierPortrait.draggable=false;
const atelierVoice=uiElement('div',undefined,'atelier-voice');
atelierVoice.append(uiElement('b','Sr. Assis'));
const atelierSpeech=uiElement('p');atelierSpeech.id='atelierSpeech';atelierSpeech.setAttribute('aria-live','polite');atelierVoice.append(atelierSpeech);
atelierMentor.append(atelierPortrait,atelierVoice);summonRoom.append(atelierMentor);

function atelierFrame(kind='common',sealed=false){
 const n=kind==='rare'?6:kind==='uncommon'?5:4;
 const points=Array.from({length:n},(_,i)=>{const a=-Math.PI/2+i*Math.PI*2/n,r=kind==='rare'&&i%2?60:84;return Math.round(100+Math.cos(a)*r)+','+Math.round(92+Math.sin(a)*r);}).join(' ');
 const vertices=points.split(' ').map(p=>p.split(',').map(Number));
 return '<svg class="atelier-kite" viewBox="0 0 200 220" aria-hidden="true"><path class="kite-string" d="M100 174q-25 18 0 24t0 20"/><polygon class="kite-paper" points="'+points+'"/><path d="m100 8 0 168M16 92h168" stroke="#fff2ce" stroke-width="1" opacity=".6"/>'+vertices.map(([x,y])=>'<path class="kite-stick-shadow" d="M100 91L'+x+' '+y+'"/><path class="kite-stick" d="M100 91L'+x+' '+y+'"/>').join('')+'<polygon class="kite-rim" points="'+points+'"/>'+vertices.map(([x,y])=>'<g transform="translate('+x+' '+y+') rotate(25)"><rect x="-5" y="-6" width="10" height="12" rx="3" class="kite-knot"/><path d="M-4-2h8M-4 2h8" stroke="#80542e" stroke-width="1"/></g>').join('')+'<circle class="kite-knot" cx="100" cy="91" r="6"/>'+(sealed?'<path class="kite-patch" d="m124 102 16 7-7 17-17-8Z"/>':'')+'</svg>';
}
function atelierPartnerToken(modelId,tailModelId=modelId){
 const entry=ART_CONFIG.dex.entries.find(e=>e.model===modelId),token=uiElement('span',undefined,'atelier-partner-token');
 token.append(pipamonPortrait(entry));
 const badge=uiElement('span',undefined,'atelier-tail-badge');badge.title='Rabiola';badge.setAttribute('aria-hidden','true');badge.append(summonTailArt(tailModelId,true));token.append(badge);return token;
}
const atelierMenu=$('summonMenu');
atelierMenu.classList.add('atelier-table');
atelierMenu.querySelector('h3').textContent='Sua próxima pipa começa aqui';
atelierMenu.querySelector('p').textContent='Bambu, papel e uma alma à espera de encontrar sua forma.';
const welcomeKite=uiElement('div',undefined,'atelier-welcome-kite');welcomeKite.innerHTML=atelierFrame('common',true);atelierMenu.prepend(welcomeKite);
$('summonInvoke').textContent='Preparar minha pipa';
const atelierExtras=uiElement('div',undefined,'atelier-extras');atelierMenu.append(atelierExtras);atelierExtras.append($('summonDamagedMenu'),workshopLastResult);
$('summonDamagedMenu').textContent='Cuidar de rabiolas antigas';
$('summonCatalog').classList.add('atelier-table');$('summonPreparation').classList.add('atelier-table');$('summonDamaged').classList.add('atelier-table');
$('summonCatalog').querySelector('p').textContent='Escolha a armação sobre a mesa. Formas mais complexas exigem mais precisão.';
$('summonPreparation').querySelector('h4').textContent='Escolha a rabiola do seu parceiro';
$('summonPreparation').querySelector('.workshop-supplies').textContent='O ateliê fornece bambu, papel e linha. A rabiola fica reservada e entra só no final.';
$('summonStart').textContent='Sentar à bancada';
for(const id of ['summonCatalogBack','summonPreparationBack','summonDamagedBack'])$(id).classList.add('atelier-back');
const atelierMaterialsTitle=uiElement('h3','Escolha sua rabiola','atelier-materials-title');$('summonPreparationBack').after(atelierMaterialsTitle);
const atelierTailToolbar=uiElement('div',undefined,'atelier-tail-toolbar'),atelierStock=uiElement('span');atelierStock.id='atelierTailStock';
const atelierTailArrows=uiElement('div',undefined,'atelier-tail-arrows');
const atelierTailPrev=uiElement('button','‹'),atelierTailNext=uiElement('button','›');
atelierTailPrev.type=atelierTailNext.type='button';atelierTailPrev.setAttribute('aria-label','Rabiolas anteriores');atelierTailNext.setAttribute('aria-label','Próximas rabiolas');
atelierTailArrows.append(atelierTailPrev,atelierTailNext);atelierTailToolbar.append(atelierStock,atelierTailArrows);$('summonTailList').before(atelierTailToolbar);
$('summonTailList').setAttribute('role','group');$('summonTailList').setAttribute('aria-label','Rabiolas disponíveis, lista horizontal');
function atelierRefreshTailScroll(){const list=$('summonTailList'),max=list.scrollWidth-list.clientWidth;atelierTailPrev.disabled=list.scrollLeft<2;atelierTailNext.disabled=list.scrollLeft>=max-2;atelierTailArrows.hidden=max<2;}
function atelierMoveTails(sign){const list=$('summonTailList');list.scrollBy({left:sign*Math.max(120,list.clientWidth*.7),behavior:art.reduced?'instant':'smooth'});}
atelierTailPrev.onclick=()=>atelierMoveTails(-1);atelierTailNext.onclick=()=>atelierMoveTails(1);
$('summonTailList').addEventListener('scroll',atelierRefreshTailScroll,{passive:true});
new ResizeObserver(atelierRefreshTailScroll).observe($('summonTailList'));
$('summonTailList').addEventListener('wheel',event=>{const list=$('summonTailList');if(event.ctrlKey||Math.abs(event.deltaX)>Math.abs(event.deltaY)||list.scrollWidth<=list.clientWidth+2)return;const next=list.scrollLeft+event.deltaY;if(next<0&&list.scrollLeft<=0||next>list.scrollWidth-list.clientWidth&&list.scrollLeft>=list.scrollWidth-list.clientWidth-2)return;event.preventDefault();list.scrollLeft=next;},{passive:false});
$('summonTailList').addEventListener('keydown',event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;const buttons=[...$('summonTailList').querySelectorAll('button')],at=buttons.indexOf(document.activeElement);if(at<0)return;event.preventDefault();event.stopPropagation();const next=event.key==='Home'?0:event.key==='End'?buttons.length-1:Math.max(0,Math.min(buttons.length-1,at+(event.key==='ArrowRight'?1:-1)));buttons[next]?.focus({preventScroll:true});buttons[next]?.scrollIntoView({block:'nearest',inline:'nearest',behavior:art.reduced?'instant':'smooth'});});

const atelierStages=showSummonStage;
showSummonStage=function(stage){
 atelierStages(stage);summonRoom.dataset.atelierStage=stage;
 const speech={npc:'Vamos dar forma ao vento? Prepare a mesa ou retome uma pipa que ficou esperando por você.',catalog:'Pegue um gabarito. O diamante é um bom começo; as outras formas pedem uma mão mais firme.',preparation:'O retrato mostra o parceiro que você vai construir. O selo no canto mostra a rabiola, que entra só no final.',damaged:'Nenhum elo precisa ficar para trás. Vamos cuidar das rabiolas que precisam de outra chance.'};
 atelierSpeech.textContent=stage==='npc'&&summonData.active?'Sua pipa está guardada na mesa. Vamos continuar de onde você parou?':speech[stage]||'';
 if(stage!=='build')requestAnimationFrame(()=>{if(!summonOpen)return;const section=$(stage==='npc'?'summonMenu':stage==='catalog'?'summonCatalog':stage==='preparation'?'summonPreparation':'summonDamaged');section?.querySelector('button:not([disabled]):not([hidden])')?.focus({preventScroll:true});});
};

renderSummonCatalog=function(){
 $('summonSeenGrid').replaceChildren(...Object.entries(CRAFT_CLASSES).map(([classKey,cfg],i)=>{
  const candidates=summonData.seen.filter(p=>workshopCraftClass(p)===classKey),tailIds=new Set(candidates.flatMap(p=>p.availableTailIds||[])),count=summonData.tails.filter(t=>t.status==='ready'&&tailIds.has(t.id)).length;
  const piece=uiElement('button',undefined,'atelier-template '+(count?'available':'locked'));piece.type='button';piece.disabled=!count;piece.dataset.kind=classKey;
  piece.innerHTML=atelierFrame(classKey);const tag=uiElement('span',undefined,'atelier-tag');tag.append(uiElement('b',cfg.label),uiElement('span',['Diamante · 4 apoios','Pentágono · 5 apoios','Estrela de vento · 6 apoios'][i]),uiElement('small',count?count+(count>1?' rabiolas disponíveis':' rabiola disponível'):'Encontre uma rabiola desta classe'));piece.append(tag);
  piece.setAttribute('aria-label','Gabarito '+cfg.label+'. '+(count?count+' rabiolas disponíveis.':'Sem rabiola compatível. Explore para encontrar.'));
  piece.onclick=()=>prepareSummon({classKey,candidates});return piece;
 }));
 $('summonCatalog').querySelector('h3').textContent='Qual forma suas mãos vão construir?';
 $('summonInvoke').hidden=!!summonData.active;
 $('summonMenu').querySelector('h3').textContent=summonData.active?'Uma pipa espera por suas mãos':'Sua próxima pipa começa aqui';
 $('summonMenu').querySelector('p').textContent=summonData.tails.some(t=>t.status==='ready')?'Escolha a rabiola do parceiro que quer construir. O ateliê cuida dos materiais.':'Traga uma rabiola da exploração para começar. Você também pode restaurar as antigas.';
 if(summonData.active)$('summonMenu').querySelector('p').textContent='A rabiola está reservada. Retome a montagem com o progresso guardado.';
};
prepareSummon=function(p){
 summonTarget=null;summonTail=null;showSummonStage('preparation');$('summonStart').disabled=true;
 const kind=workshopCraftClass(p),candidates=p.candidates||[p];
 $('summonChosenPipamon').innerHTML=atelierFrame(kind,true);$('summonChosenPipamon').append(uiElement('h3','Gabarito '+CRAFT_CLASSES[kind].label),uiElement('small','Escolha ao lado o parceiro que quer construir.'));
 const stock=summonData.tails.filter(t=>t.status==='ready'&&candidates.some(c=>(c.availableTailIds||[]).includes(t.id))),groups=new Map();
 for(const t of stock){
  const target=candidates.find(c=>c.modelId===t.modelId&&(c.availableTailIds||[]).includes(t.id))||candidates.find(c=>(c.availableTailIds||[]).includes(t.id));
  const key=target.modelId+':'+t.modelId;if(!groups.has(key))groups.set(key,{target,tails:[]});groups.get(key).tails.push(t);
 }
 releasePipamonPortraits($('summonTailList'));
 $('summonTailList').replaceChildren(...[...groups.values()].map(({target,tails})=>{
  const t=tails[0],name=summonDisplayName(target),parcel=uiElement('button',undefined,'atelier-soul');parcel.type='button';
  const token=atelierPartnerToken(target.modelId,t.modelId);token.append(uiElement('span','×'+tails.length,'atelier-tail-count'));
  parcel.append(token,uiElement('b',name));parcel.setAttribute('aria-label','Selecionar rabiola de '+name+', '+tails.length+(tails.length===1?' disponível':' disponíveis'));parcel.setAttribute('aria-pressed','false');
  parcel.onclick=()=>{summonTail=t;summonTarget=target;$('summonStart').disabled=false;$('summonSelectedTail').textContent=name+' · '+tails.length+(tails.length===1?' rabiola disponível':' rabiolas disponíveis')+' · Usar 1 nesta montagem';atelierSpeech.textContent='Vamos construir '+name+'! Primeiro a armação; a rabiola só entra quando o corpo estiver pronto.';for(const c of $('summonTailList').children){c.classList.toggle('selected',c===parcel);c.setAttribute('aria-pressed',String(c===parcel));}};
  return parcel;
 }));
 $('atelierTailStock').textContent=stock.length+(stock.length===1?' rabiola':' rabiolas')+' · '+groups.size+(groups.size===1?' parceiro':' parceiros');
 $('summonTailList').scrollLeft=0;requestAnimationFrame(atelierRefreshTailScroll);
 $('summonSelectedTail').textContent='Escolha a rabiola do parceiro que quer construir.';
};
document.addEventListener('keydown',event=>{
 if(atelierExitDialog.open)return;
 if(event.key==='Tab'&&summonOpen&&!summonRoom.hidden&&!summonRoom.classList.contains('is-building')){const controls=[...summonRoom.querySelectorAll('button:not([disabled])')].filter(e=>e.getClientRects().length&&getComputedStyle(e).visibility!=='hidden');const first=controls[0],last=controls.at(-1);if(event.shiftKey&&document.activeElement===first){event.preventDefault();event.stopImmediatePropagation();last?.focus();}else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();event.stopImmediatePropagation();first?.focus();}return;}
 if(event.key!=='Escape'||!summonOpen||summonRoom.hidden||summonRoom.classList.contains('is-building'))return;
 event.preventDefault();event.stopImmediatePropagation();if(summonBusy)return;
 const stage=summonRoom.dataset.atelierStage;if(stage==='preparation')showSummonStage('catalog');else if(stage==='catalog'||stage==='damaged')showSummonStage('npc');else closeAccount();
},true);
const atelierExitDialog=document.createElement('dialog');atelierExitDialog.className='atelier-exit-confirm';atelierExitDialog.setAttribute('aria-labelledby','atelierExitTitle');
atelierExitDialog.innerHTML='<div class="eyebrow">OFICINA DAS ALMAS</div><h2 id="atelierExitTitle">Sair e cancelar a preparação?</h2><p>Tem certeza? Ao sair, você terá que escolher o gabarito e a rabiola novamente. Uma montagem em andamento será descartada; a rabiola volta a ficar disponível.</p><p id="atelierExitError" role="status"></p><div><button type="button" id="atelierExitStay">Continuar na Oficina</button><button type="button" id="atelierExitYes">Sim, cancelar e sair</button></div>';
document.body.append(atelierExitDialog);
let atelierExitBusy=false;const atelierCloseAccount=closeAccount;
closeAccount=function(){
 if(!summonOpen||summonRoom.hidden)return atelierCloseAccount();
 if(workshopV3Frame)return;
 if(summonRoom.dataset.atelierStage==='npc'&&!summonData.active)return atelierCloseAccount();
 if(atelierExitDialog.open||summonBusy)return;
 $('atelierExitError').textContent='';atelierExitDialog.showModal();$('atelierExitStay').focus();
};
const atelierStay=()=>{if(atelierExitBusy)return;atelierExitDialog.close();$('atelierLeave').focus();};
$('atelierExitStay').onclick=atelierStay;atelierExitDialog.addEventListener('cancel',event=>{event.preventDefault();atelierStay();});
$('atelierExitYes').onclick=async()=>{
 if(atelierExitBusy)return;atelierExitBusy=true;$('atelierExitYes').disabled=true;$('atelierExitStay').disabled=true;
 try{
  if(summonData.active){const id=summonData.active.id,read=await accountRequest('workshop-v3',{action:'read',jobId:id});await accountRequest('workshop-v3',{action:'cancel',jobId:id,seed:Number(read.workshop.seed)});}
  summonData.active=null;summonTarget=null;summonTail=null;atelierExitDialog.close();atelierCloseAccount();
 }catch(error){$('atelierExitError').textContent='Não foi possível cancelar. '+error.message+' Sua montagem continua aberta.';}
 finally{atelierExitBusy=false;$('atelierExitYes').disabled=false;$('atelierExitStay').disabled=false;}
};
