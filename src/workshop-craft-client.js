// Uses the existing account/session and idempotent workshop API. No parallel economy.
let workshopCraft=null,workshopCraftKey='',workshopCraftController=null,workshopCraftSaved='';
const craftClassicLoad=workshopLoadArt,craftClassicConfirm=$('workshopConfirm').onclick;
const craftNeutral='<div class="craft-neutral"><svg viewBox="0 0 100 100" aria-hidden="true"><path d="M50 5 90 45 50 91 10 45Z"/><path d="M50 5v86M10 45h80" fill="none"/><text x="50" y="57" text-anchor="middle" fill="#315959" stroke="none" font-size="30">?</text></svg><span>Rabiola</span></div>';
function workshopCraftClass(job){const model=job.modelId||job.targetModelId,entry=ART_CONFIG.dex.entries.find(e=>e.model===model);return craftClass(job.classKey||workshopAssets?.craftClasses?.[model]||entry?.rarity);}
function workshopCraftPersist(){
 if(!workshopCraft||!summonRitual)return;const save={};for(const key of ['version','kind','stage','rods','knots','cut','glue','seated','damage','grade','balance','tested','tail','synced'])save[key]=workshopCraft[key];
 const json=JSON.stringify(save),stamp=workshopCraftKey+json;if(stamp===workshopCraftSaved)return;workshopCraftSaved=stamp;try{localStorage.setItem(workshopCraftKey,json);}catch{}
}
function workshopCraftSync(){
 const s=workshopCraft;if(!s||!summonRitual)return;const ready=craftReady(s);
 if(ready&&s.stage<5){const p=craftPayload(s);if(s.stage===0)workshopDraft.joints=p.joints;if(s.stage===1)workshopDraft.tension=p.tension;if(s.stage===2){workshopDraft.cuts=p.cuts;workshopDraft.revealScore=p.reveal;}if(s.stage===3)workshopDraft.balance=p.balance;if(s.stage===4){workshopDraft.wind=p.wind;workshopDraft.soulTension=p.tension;}}
 else if(s.stage===0)workshopDraft.joints=[];else if(s.stage===2){workshopDraft.cuts=[];workshopDraft.revealScore=null;}
 const done=summonRitual.status==='completed';$('workshopConfirm').disabled=summonBusy||(!workshopPending&&!ready);$('workshopRedo').disabled=summonBusy||!!workshopPending;
 $('workshopTitle').textContent=done?summonDisplayName(summonRitual)+' despertou!':['Armação','Amarração','Corte e colagem','Equilíbrio','A união da alma'][s.stage];
 $('workshopHint').textContent=done?'A alma encontrou sua forma. Seu novo parceiro está na coleção.':ready?craftInstruction(s):(s.message||craftInstruction(s));$('workshopReadout').textContent=Math.round(craftProgress(s)*100)+'%';
 $('craftClass').textContent=CRAFT_CLASSES[s.kind].label+' · '+CRAFT_CLASSES[s.kind].shape+' · '+Math.round(craftProgress(s)*100)+'%';
 $('craftPause').textContent=s.paused?'Retomar':'Pausar';workshopCraftPersist();
}
renderWorkshop=function(){
 if(!summonRitual)return;const stage=summonRitual.stage,done=summonRitual.status==='completed';showSummonStage('build');summonRoom.classList.add('craft-mode');summonRoom.classList.remove('is-revealing');workshopReveal=null;
 const key='pipa.craft.v2.'+summonRitual.id+'.'+stage;
 if(key!==workshopCraftKey){workshopCraftKey=key;let saved=null;try{saved=JSON.parse(localStorage.getItem(key));}catch{}workshopCraft=craftRestore(saved,workshopCraftClass(summonRitual),done?5:stage);}
 $('workshopSteps').replaceChildren(...['Armação','Nós','Papel','Voo','Elo'].map((name,i)=>{const span=uiElement('span',(i<stage?'✓ ':String(i+1)+' ')+name);if(i===stage)span.setAttribute('aria-current','step');return span;}));
 const scene=$('workshopCanvas').parentElement;
 if(!$('craftTools')){const tools=uiElement('div',undefined,'craft-tools');tools.id='craftTools';tools.setAttribute('role','group');tools.setAttribute('aria-label','Ferramentas da bancada');scene.append(tools);const label=uiElement('span',undefined,'craft-class');label.id='craftClass';scene.append(label);const pause=uiElement('button','Pausar','craft-pause');pause.id='craftPause';pause.onclick=()=>{if(summonBusy)return;workshopCraft.paused=!workshopCraft.paused;craftCancel(workshopCraft);workshopCraftController.refresh();};scene.append(pause);const help=uiElement('span','1–6 ferramentas · Setas movem · Espaço pega/solta · Esc cancela','craft-key-help');scene.append(help);
  workshopCraftController=createCraftControls({canvas:$('workshopCanvas'),tools,getState:()=>workshopCraft,onChange:workshopCraftSync,isLocked:()=>!summonOpen||!summonRitual||summonBusy||!!workshopPending||summonRitual.status==='completed'});
 }
 $('workshopConfirm').hidden=done;$('workshopRedo').hidden=done;$('craftTools').hidden=done;$('craftPause').hidden=done;$('workshopConfirm').textContent=workshopPending?'Reenviar confirmação':stage===4?'Despertar':'Guardar e continuar';$('workshopRedo').textContent='Refazer etapa';
 $('summonReveal').hidden=!done;if(done)$('workshopResultTitle').textContent=summonDisplayName(summonRitual)+' despertou!';
 workshopCraftController.refresh();workshopAnimate();
};
workshopLoadArt=async function(retry=false){await craftClassicLoad(retry);workshopDraw=(g,job,input,time)=>drawCraftWorkshop(g,workshopCraft||createCraft(workshopCraftClass(job),job.stage),time,{bench:workshopImages.craftBench,reduced:workshopReduced,drawCreature:(ctx,t)=>{
 const entry=ART_CONFIG.dex.entries.find(e=>e.model===job.modelId),atlas=entry&&art.atlases[entry.atlas],seq=atlas?.animations.victory||atlas?.animations.idle;
 if(seq?.length)art.draw(ctx,entry.atlas,seq[Math.floor(t*5)%seq.length],-170,-170,340,340);else art.creature(ctx,job.color,t*1000,-170,-170,340,{soul:job.soul,animate:!workshopReduced});
 }});};
$('workshopConfirm').onclick=async()=>{if(!workshopPending&&(!workshopCraft||!craftReady(workshopCraft)))return;await craftClassicConfirm();};
$('workshopRedo').onclick=()=>{if(summonBusy||workshopPending)return;workshopCraft=createCraft(workshopCraft.kind,workshopCraft.stage);workshopDraft=workshopInput();workshopCraftController.refresh();};
// Replace legacy handlers: pointer and keyboard events must never run two games.
for(const key of ['onpointerdown','onpointermove','onpointerup','onpointercancel','onlostpointercapture','onblur'])$('workshopCanvas')[key]=null;
renderSummonCatalog=function(){
 $('summonSeenGrid').replaceChildren(...Object.entries(CRAFT_CLASSES).map(([classKey,cfg])=>{
  const candidates=summonData.seen.filter(p=>workshopCraftClass(p)===classKey),tailIds=new Set(candidates.flatMap(p=>p.availableTailIds||[])),count=summonData.tails.filter(t=>t.status==='ready'&&tailIds.has(t.id)).length;
  const card=uiElement('button',undefined,'summon-seen-card '+(count?'available':'locked'));card.type='button';card.disabled=!count;card.innerHTML=craftNeutral;card.append(uiElement('b','Gabarito '+cfg.label),uiElement('small',cfg.shape+' · '+cfg.sides+' apoios'),uiElement('small',count?count+' rabiola(s) disponível(is)':'Encontre uma alma desta classe na exploração'));card.onclick=()=>prepareSummon({classKey,candidates});return card;
 }));
 $('summonCatalog').querySelector('h3').textContent='Qual gabarito vamos construir?';
};
prepareSummon=function(p){
 summonTarget=null;summonTail=null;showSummonStage('preparation');$('summonStart').disabled=true;const kind=workshopCraftClass(p),candidates=p.candidates||[p];$('summonChosenPipamon').innerHTML=craftNeutral;$('summonChosenPipamon').append(uiElement('h3','Gabarito '+CRAFT_CLASSES[kind].label),uiElement('small','A forma viva será revelada apenas ao despertar.'));
 $('summonTailList').replaceChildren(...summonData.tails.filter(t=>t.status==='ready'&&candidates.some(c=>c.availableTailIds.includes(t.id))).map((t,i)=>{const card=uiElement('article',undefined,'summon-tail'),button=uiElement('button','Selecionar rabiola '+(i+1),'secondary');button.onclick=()=>{summonTail=t;summonTarget=candidates.find(c=>c.availableTailIds.includes(t.id));$('summonStart').disabled=false;$('summonSelectedTail').textContent='Rabiola selecionada. A rabiola entra por último.';for(const c of $('summonTailList').children)c.classList.toggle('selected',c===card);};card.innerHTML=craftNeutral;card.append(button);return card;}));
 $('summonSelectedTail').textContent='Selecione uma rabiola compatível.';
};
