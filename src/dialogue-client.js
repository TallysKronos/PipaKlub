// A shared illustrated dialogue surface. Existing story callbacks own progression.
const dialogueArt=ART_CONFIG.dialogue,dialoguePortraitLoads=new Map();
let motherConversationVersion=0,openingMotherTalking=false;
function dialoguePortraitURL(speaker){
 const key=dialogueArt.speakers[speaker];if(key)return dialogueArt.images[key].url;
 if(speaker.startsWith('Locutor'))return ART_CONFIG.opening.images.announcer.url;
 return ART_CONFIG.designs.rivals[speaker]?.url||null;
}
function loadDialoguePortrait(url){if(!url)return Promise.resolve(false);if(!dialoguePortraitLoads.has(url))dialoguePortraitLoads.set(url,new Promise(resolve=>{const image=new Image();image.onload=()=>resolve(true);image.onerror=()=>{dialoguePortraitLoads.delete(url);resolve(false);};image.src=url;}));return dialoguePortraitLoads.get(url);}
function emphasizeDialogueCopy(box){
 const copy=box.querySelector('#journeySpeech,#openingSpeech'),phrase='seu próprio desenho';if(!copy||copy.querySelector('strong')||!copy.textContent.includes(phrase))return;
 const [prefix,suffix]=copy.textContent.split(phrase),strong=uiElement('strong',phrase);copy.replaceChildren();
 if(prefix.startsWith('Meu filho')&&prefix.endsWith('ao '))copy.append(prefix.slice(0,-3),document.createElement('br'),'ao ');else copy.append(prefix);
 copy.append(strong,suffix);
}
function decorateRPGDialogue(box,{speaker,opening=false,coach=false}={}){
 if(!box)return;box.classList.add('rpg-dialogue');box.style.setProperty('--rpg-dialogue-frame','url("'+dialogueArt.images.frame.url+'")');
 let portrait=box.querySelector('.rpg-dialogue-portrait');if(!portrait){portrait=document.createElement('img');portrait.className='rpg-dialogue-portrait';portrait.alt='';portrait.setAttribute('aria-hidden','true');portrait.decoding='async';portrait.hidden=true;box.prepend(portrait);}
 let request=0,activeURL=null,failedURL=null;
 const sync=()=>{
  const who=typeof speaker==='function'?speaker():speaker||box.dataset.speaker||'Sr. Assis',url=dialoguePortraitURL(who),guidance=opening&&openingRoomStep()&&!openingMotherTalking;
  box.dataset.rpgSpeaker=who;box.classList.toggle('rpg-guidance',guidance||coach&&box.classList.contains('is-exercising'));
  if(box.hidden||opening&&openingScreen.hidden){if(activeURL!==null){request++;activeURL=null;}portrait.hidden=true;return;}
  box.classList.toggle('rpg-no-portrait',!url||guidance||failedURL===url);emphasizeDialogueCopy(box);
  if(!url||guidance){if(activeURL!==null){request++;activeURL=null;}portrait.hidden=true;}
  else if(activeURL!==url){activeURL=url;failedURL=null;portrait.hidden=true;const version=++request;loadDialoguePortrait(url).then(ok=>{if(version!==request||box.hidden||box.dataset.rpgSpeaker!==who)return;failedURL=ok?null:url;portrait.hidden=!ok;if(ok&&portrait.getAttribute('src')!==url)portrait.src=url;box.classList.toggle('rpg-no-portrait',!ok);});}
  const actions=box.querySelector('.journey-actions,.opening-actions'),buttons=actions?[...actions.querySelectorAll('button')].filter(b=>!b.hidden):[];
  box.classList.toggle('rpg-choices',buttons.length>1&&!coach&&!opening);if(actions)actions.setAttribute('aria-label','Escolhas do diálogo');
 };
 new MutationObserver(records=>{if(records.some(record=>record.target!==portrait))sync();}).observe(box,{attributes:true,attributeFilter:['hidden','data-speaker','class'],childList:true,subtree:true,characterData:true});
 if(opening)new MutationObserver(sync).observe(openingScreen,{attributes:true,attributeFilter:['hidden','class']});
 let lastHeight=0;new ResizeObserver(()=>{const h=Math.ceil(box.getBoundingClientRect().height);if(h&&h!==lastHeight){lastHeight=h;box.style.setProperty('--rpg-panel-height',h+'px');}}).observe(box);
 box.addEventListener('pointerover',e=>{const b=e.target.closest('button');if(box.classList.contains('rpg-choices')&&b&&!b.disabled&&!b.hidden&&document.activeElement!==b)b.focus({preventScroll:true});});
 sync();return sync;
}
const syncJourneyDialogue=decorateRPGDialogue($('journeyDialog'),{speaker:()=>$('journeyDialog').dataset.speaker||'Sr. Assis'});
decorateRPGDialogue($('flightCoach'),{speaker:'Sr. Assis',coach:true});
const syncOpeningDialogue=decorateRPGDialogue(document.querySelector('#kaelOpening .opening-dialog'),{speaker:()=>$('openingSpeaker').textContent.trim(),opening:true});
const beforeIllustratedDialogue=dialogue;dialogue=function(...args){
 motherConversationVersion++;$('journeyDialog').querySelector('[data-mother-collection]')?.remove();
 const value=beforeIllustratedDialogue(...args);syncJourneyDialogue();return value;
};
function motherMission(){return journey?.phase==='complete'?'Vocês já encontraram o vento juntos! Explorem a cidade, conheçam os outros pipeiros e voltem para me contar as novidades.':'Leve seu parceiro para conhecer o Sr. Assis. Ele vai ajudar vocês no primeiro voo. A casa dele fica logo adiante, na Rua dos Ventos.';}
function openMotherConversation(text='Meu filho… você acabou de dar vida ao seu próprio desenho. Ainda nem acredito!'){
 if(mode||!playerAccount)return;worldClearWalking();const actor=worldState()?.actor;if(actor){actor.path=[];actor.moving=false;}
 dialogue('Conversar com a mãe',text,'O que você quer que eu faça agora?',()=>openMotherConversation(motherMission()),{speaker:'Mãe',later:true});
 const version=motherConversationVersion,actions=$('journeyDialog').querySelector('.journey-actions'),collection=uiElement('button','Quero mostrar meus Pipamons!','secondary');
 collection.type='button';collection.dataset.motherCollection='';collection.onclick=()=>{if(version!==motherConversationVersion)return;hideJourney();homeActions.collection();};
 actions.prepend($('journeyContinue'),collection);$('journeyLater').textContent='Vou sair para explorar a cidade.';
 $('journeyLater').onclick=()=>{hideJourney();$('courtyardCanvas').focus({preventScroll:true});};syncJourneyDialogue();$('journeyContinue').focus({preventScroll:true});
}
function openOpeningMotherConversation(){
 openingMotherTalking=true;openingClearWalking();$('openingSpeaker').textContent='Mãe';$('openingSpeech').textContent='Eu guardei aquela rabiola por tantos anos… Cuide bem dele, Kael. E volte para me contar como foi o primeiro voo.';$('openingNext').hidden=false;$('openingNext').disabled=false;$('openingNext').textContent='Continuar';syncOpeningDialogue();$('openingNext').focus({preventScroll:true});
}
const beforeIllustratedOpeningNext=nextOpening;nextOpening=async function(...args){if(openingMotherTalking){openingMotherTalking=false;openingRoomSignature='';openingRefreshRoomUI();syncOpeningDialogue();$('openingCanvas').focus?.({preventScroll:true});return;}return beforeIllustratedOpeningNext(...args);};$('openingNext').onclick=nextOpening;
const beforeIllustratedOpeningReset=openingResetRoom;openingResetRoom=function(...args){openingMotherTalking=false;return beforeIllustratedOpeningReset(...args);};
addEventListener('keydown',event=>{
 const box=$('journeyDialog');if(box.hidden||!box.classList.contains('rpg-dialogue')||event.ctrlKey||event.altKey||event.metaKey||event.target.closest?.('input,textarea,select'))return;
 const choices=[...box.querySelectorAll('.journey-actions button')].filter(b=>!b.hidden&&!b.disabled);
 if(['ArrowUp','ArrowDown'].includes(event.key)&&choices.length){event.preventDefault();event.stopImmediatePropagation();const i=choices.indexOf(document.activeElement),step=event.key==='ArrowDown'?1:-1;choices[(i<0?0:(i+step+choices.length)%choices.length)].focus({preventScroll:true});}
 if(event.key==='Enter'&&event.target.tagName!=='BUTTON'&&!event.repeat){event.preventDefault();event.stopImmediatePropagation();choices[0]?.click();}
},true);
