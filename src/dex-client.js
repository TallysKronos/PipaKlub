// Public field guide. Browsing never grants or equips inventory items.
const dexEntries=ART_CONFIG.dex.entries,dexOverlay=$('pipaDex');
let dexEntry=dexEntries[0],dexState='idle',dexElapsed=0,dexLast=0,dexFrame=0,dexOpen=false,dexPlaying=!art.reduced,dexVersion=0;
const dexLabels={idle:'Repouso',flight:'Voo',skill:'Habilidade',hurt:'Dano',victory:'Vitória',greet:'Saudação',happy:'Alegria'};
function dexStates(entry){return entry.sequence?['idle']:Object.keys(art.atlases[entry.atlas].animations);}
function dexSequence(){const a=art.atlases[dexEntry.atlas];return a.animations[dexEntry.sequence||dexState];}
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
 dexEntry=entry;dexState='idle';dexElapsed=0;dexLast=0;$('dexDetails').hidden=false;
 $('dexNumber').textContent='REGISTRO '+String(dexEntries.indexOf(entry)+1).padStart(3,'0');
 $('dexName').textContent=entry.name;$('dexSubtitle').textContent=entry.title;
 $('dexGroup').textContent=entry.group==='event'?'Especial de evento':entry.group==='companion'?'Companheiro':'Almática de rua';
 const owned=!!playerAccount?.inventory.some(k=>k.model_id===entry.model);
 $('dexOwnership').textContent=owned?'Na sua coleção':entry.group==='companion'?'Ao lado do Sr. Assis':playerAccount?'Ainda não está na sua coleção':'Entre na conta para acompanhar sua coleção';
 $('dexHabitat').textContent=entry.habitat;$('dexLegend').textContent=entry.legend||'Uma história original do Pipa Club';
 $('dexStory').replaceChildren(...entry.story.map(text=>uiElement('p',text)));
 $('dexNote').textContent='“'+entry.note+'”';$('dexObtain').textContent=entry.obtain;
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
