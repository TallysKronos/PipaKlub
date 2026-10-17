// Public field guide. Browsing never grants or equips inventory items.
const dexEntries=ART_CONFIG.dex.entries,dexOverlay=$('pipaDex');
const reportedSightings=new Set();
let dexEntry=dexEntries[0],dexState='idle',dexElapsed=0,dexLast=0,dexFrame=0,dexOpen=false,dexPlaying=!art.reduced,dexVersion=0;
const dexLabels={idle:'Repouso',flight:'Voo',skill:'Habilidade',hurt:'Dano',victory:'Vitória',greet:'Saudação',happy:'Alegria'};
function dexStates(entry){return entry.sequence?['idle']:Object.keys(art.atlases[entry.atlas].animations);}
function dexSequence(){const a=art.atlases[dexEntry.atlas];return a.animations[dexEntry.sequence||dexState];}
function renderDexItems(entry){
 const companion=entry.group==='companion',eventItem=(entry.items||[]).some(id=>ART_CONFIG.items.find(i=>i.id===id)?.source==='event');
 $('dexItemsTitle').textContent=companion?'Item do companheiro':eventItem?'Rabiola de evento':'Itens dropáveis';
 $('dexItemsHint').textContent=companion?'Nozinho acompanha o Sr. Assis e não aparece como selvagem. Sua rabiola fica registrada aqui como item associado.':'Rabiola prevista para encontros com '+entry.name+' selvagem. Os drops ainda não estão disponíveis.';
 if(eventItem)$('dexItemsHint').textContent='Receba a rabiola em um evento e leve ao Sr. Assis. É preciso conhecer este Pipamon e ainda não possuir sua Soul vinculada.';
 // Rabiolas dropped by trail bosses show where to earn them and whether this device already has them.
 const bossDrop=id=>{try{return trails.stages.find(st=>st.drop===id)||null;}catch{return null;}},owned=id=>{try{return trailRewards.some(r=>r.dropId===id);}catch{return false;}};
 if(!companion&&(entry.items||[]).some(bossDrop))$('dexItemsHint').textContent='Vença o chefe das Trilhas no duelo online para receber a rabiola na conta e usá-la no Sr. Assis. O prêmio é entregue uma vez por chefe.';
 const cards=(entry.items||[]).map(id=>ART_CONFIG.items.find(item=>item.id===id)).filter(Boolean).map(item=>{
  const card=uiElement('article',undefined,'dex-item'),stage=uiElement('div',undefined,'dex-item-art'),image=document.createElement('img');
  image.alt=item.name;image.width=209;image.height=209;image.loading='lazy';image.decoding='async';
  const fallback=uiElement('span','Imagem indisponível','dex-item-fallback');fallback.hidden=true;
  image.onerror=()=>{image.hidden=true;fallback.hidden=false;};image.onload=()=>{image.hidden=false;fallback.hidden=true;};image.src=item.url;stage.append(image,fallback);
  const info=uiElement('div',undefined,'dex-item-info');info.append(uiElement('span','Rabiola','dex-item-kind'),uiElement('h5',item.name),uiElement('p',companion?'Associada ao companheiro':item.source==='event'?'Origem: evento': 'Origem: '+entry.name+' selvagem'),uiElement('span',companion?'Item de referência':item.source==='event'?'Concessão de evento · Invocação no Sr. Assis':owned(item.id)?'Conquistada ✓':bossDrop(item.id)?'Prêmio: '+bossDrop(item.id).name+' (Trilhas)':'Drop previsto · Em breve','dex-item-status'+(owned(item.id)?' owned':'')));
  card.append(stage,info);return card;
 });
 $('dexItemsList').replaceChildren(...cards);$('dexItemsSection').hidden=cards.length===0;
}
function drawDex(){
 const canvas=$('dexCanvas'),context=canvas.getContext('2d'),a=art.atlases[dexEntry.atlas],seq=dexSequence();
 const durations=a.playback?.[dexState]?.durations||seq.map(key=>a.frames[key].duration||190),total=durations.reduce((sum,v)=>sum+v,0);
 let at=dexElapsed%total,index=0;while(index<seq.length-1&&at>=durations[index])at-=durations[index++];
 context.clearRect(0,0,360,300);art.draw(context,dexEntry.atlas,seq[index],30,0,300,300);
}
function tickDex(t){
 dexFrame=0;if(!dexOpen||!dexPlaying)return;
 if(!document.hidden)dexElapsed+=Math.min(100,Math.max(0,t-(dexLast||t)));
 dexLast=t;drawDex();dexFrame=requestAnimationFrame(tickDex);
}
function syncDexPlayback(){
 if(dexFrame)cancelAnimationFrame(dexFrame);dexFrame=0;dexLast=0;
 $('dexPlay').textContent=dexPlaying?'Pausar':'Reproduzir';$('dexPlay').setAttribute('aria-pressed',String(dexPlaying));
 if(dexPlaying&&dexOpen)dexFrame=requestAnimationFrame(tickDex);
}
async function loadDexArt(retry=false){
 const version=++dexVersion,entry=dexEntry;$('dexLoad').textContent='Carregando ilustração…';$('dexRetry').hidden=true;
 const loaded=await art.load(entry.atlas,retry);if(!dexOpen||version!==dexVersion)return;
 $('dexLoad').textContent=loaded?'':'A ilustração não carregou. A história continua disponível.';$('dexRetry').hidden=loaded;
 if(loaded)drawDex();
}
function selectDex(entry){
 if(playerAccount&&entry.model){const key=(playerAccount.profile?.id||'')+':'+entry.model;if(!reportedSightings.has(key)){reportedSightings.add(key);accountRequest('sighting',{modelId:entry.model}).catch(()=>reportedSightings.delete(key));}}
 dexEntry=entry;dexState='idle';dexElapsed=0;dexLast=0;$('dexDetails').hidden=false;
 $('dexDetails').scrollTop=0;dexOverlay.querySelector('.dex-layout').scrollTop=0;
 $('dexNumber').textContent='REGISTRO '+String(dexEntries.indexOf(entry)+1).padStart(3,'0');
 $('dexName').textContent=entry.name;$('dexSubtitle').textContent=entry.title;
 $('dexGroup').textContent=entry.group==='event'?(entry.rarity==='rara'?'Rara de evento':'Especial de evento')+(entry.collection?' · '+entry.collection:''):entry.group==='companion'?'Companheiro':'Almática de rua';
 const owned=!!playerAccount?.inventory.some(k=>k.model_id===entry.model);
 $('dexOwnership').textContent=owned?'Na sua coleção':entry.group==='companion'?'Ao lado do Sr. Assis':playerAccount?'Ainda não está na sua coleção':'Entre na conta para acompanhar sua coleção';
 $('dexHabitat').textContent=entry.habitat;$('dexLegend').textContent=entry.legend||'Uma história original do Pipa Club';
 $('dexStory').replaceChildren(...entry.story.map(text=>uiElement('p',text)));
 $('dexNote').textContent='“'+entry.note+'”';$('dexObtain').textContent=entry.obtain;
 renderDexItems(entry);
 const type=eng.types[entry.color];$('dexSkillName').textContent=entry.group==='companion'?'Laços de amizade':type.name+' · '+type.skill;
 $('dexSkillInfo').textContent=entry.group==='companion'?'Nozinho recebe novos pipeiros com o Sr. Assis e não participa dos duelos.':type.description+' Custo: 25 de energia. Recarga: 7 s.';
 const states=dexStates(entry);$('dexAnimation').replaceChildren(...states.map(state=>{const option=document.createElement('option');option.value=state;option.textContent=dexLabels[state]||state;return option;}));$('dexAnimation').value='idle';
 $('dexAnimationHint').textContent=entry.sequence?'Esta almática tem uma animação de repouso.':'Escolha um estado para ver a animação se repetir.';
 $('dexCanvas').setAttribute('aria-label',entry.name+' — '+dexLabels[dexState]);
 for(const button of $('dexList').querySelectorAll('button'))button.setAttribute('aria-pressed',String(button.dataset.dexId===entry.id));
 drawDex();syncDexPlayback();loadDexArt();
}
function filterDex(){
 const normalize=text=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 const query=normalize($('dexSearch').value.trim()),group=$('dexFilter').value;
 const entries=dexEntries.filter(e=>(group==='all'||e.group===group)&&normalize(e.name+' '+e.title+' '+(e.legend||'')).includes(query));
 $('dexCount').textContent=entries.length+' de '+dexEntries.length+' registros';
 $('dexEmpty').hidden=entries.length>0;
 $('dexList').replaceChildren(...entries.map(entry=>{
  const button=uiElement('button',undefined,'secondary dex-entry');button.type='button';button.dataset.dexId=entry.id;
  button.setAttribute('aria-pressed',String(entry.id===dexEntry.id));
  const image=uiElement('span',undefined,'dex-thumb');
  // Nozinho uses his first atlas tile; playable entries reuse collection thumbnails.
  image.innerHTML=entry.group==='companion'?'<span class="almatic-icon" aria-hidden="true" style="background-image:url('+art.atlases.nozinho.meta.url+');background-position:0 0"></span>':art.markup(entry.color,entry.group==='event'?entry.id:null);
  const text=uiElement('span');text.append(uiElement('b',entry.name),uiElement('small',entry.group==='event'?'Especial de evento':entry.group==='companion'?'Companheiro':eng.types[entry.color].name));button.append(image,text);
  button.onclick=()=>selectDex(entry);return button;
 }));
 if(entries.length)selectDex(entries.find(e=>e.id===dexEntry.id)||entries[0]);
 else{$('dexDetails').hidden=true;dexVersion++;if(dexFrame)cancelAnimationFrame(dexFrame);dexFrame=0;}
}
function openDex(){
 if(!requireClubAccount('a Pipa Dex'))return;
 if(mode){toast('Saia da partida para consultar a Pipa Dex.');return;}
 if(introductionOpen)return;
 keys={};skillUntil=0;dexOpen=true;dexOverlay.hidden=false;$('dexSearch').value='';$('dexFilter').value='all';filterDex();$('dexClose').focus();
}
function closeDex(){dexOpen=false;dexOverlay.hidden=true;dexVersion++;if(dexFrame)cancelAnimationFrame(dexFrame);dexFrame=0;$('workshop').focus();}
$('workshop').onclick=openDex;$('dexClose').onclick=closeDex;
dexOverlay.onclick=e=>{if(e.target===dexOverlay)closeDex();};
$('dexSearch').oninput=filterDex;$('dexFilter').onchange=filterDex;
$('dexAnimation').onchange=()=>{dexState=$('dexAnimation').value;dexElapsed=0;dexLast=0;$('dexCanvas').setAttribute('aria-label',dexEntry.name+' — '+dexLabels[dexState]);drawDex();};
$('dexPlay').onclick=()=>{dexPlaying=!dexPlaying;syncDexPlayback();};
$('dexReplay').onclick=()=>{dexElapsed=0;dexLast=0;drawDex();};
$('dexRetry').onclick=()=>loadDexArt(true);
addEventListener('keydown',e=>{
 if(!dexOpen)return;
 if(e.key==='Escape'){e.preventDefault();closeDex();return;}
 if(e.key==='Tab'){
  const items=[...dexOverlay.querySelectorAll('button,input,select')].filter(el=>!el.disabled&&el.getClientRects().length),first=items[0],last=items.at(-1);
  if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}
 }
});
