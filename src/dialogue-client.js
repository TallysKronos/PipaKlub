// A shared illustrated dialogue surface. Existing story callbacks own progression.
const dialogueArt=ART_CONFIG.dialogue,dialoguePortraitLoads=new Map();
let motherConversationVersion=0,openingMotherTalking=false;
function dialoguePortraitURL(speaker){
 const key=dialogueArt.speakers[speaker];if(key)return dialogueArt.images[key].url;
 if(speaker.startsWith('Locutor'))return dialogueArt.images.announcer.url;
 return ART_CONFIG.designs.rivals[speaker]?.url||null;
}
function loadDialoguePortrait(url){if(!url)return Promise.resolve(false);if(!dialoguePortraitLoads.has(url))dialoguePortraitLoads.set(url,new Promise(resolve=>{const image=new Image();image.onload=()=>resolve(true);image.onerror=()=>{dialoguePortraitLoads.delete(url);resolve(false);};image.src=url;}));return dialoguePortraitLoads.get(url);}
function emphasizeDialogueCopy(box){
 const copy=box.querySelector('#journeySpeech,#openingSpeech'),phrase='seu próprio desenho';if(!copy||copy.querySelector('strong')||!copy.textContent.includes(phrase))return;
 const [prefix,suffix]=copy.textContent.split(phrase),strong=uiElement('strong',phrase);copy.replaceChildren();
 copy.append(prefix);
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
$('journeyDialog').setAttribute('role','dialog');$('journeyDialog').setAttribute('aria-modal','true');$('journeySpeech').tabIndex=0;
const syncJourneyDialogue=decorateRPGDialogue($('journeyDialog'),{speaker:()=>$('journeyDialog').dataset.speaker||'Sr. Assis'});
decorateRPGDialogue($('flightCoach'),{speaker:'Sr. Assis',coach:true});
const syncOpeningDialogue=decorateRPGDialogue(document.querySelector('#kaelOpening .opening-dialog'),{speaker:()=>$('openingSpeaker').textContent.trim(),opening:true});
const beforeIllustratedDialogue=dialogue;dialogue=function(...args){
 motherConversationVersion++;$('journeyContinue').hidden=false;$('journeyDialog').dataset.dismissible='false';$('journeyDialog').querySelector('[data-mother-collection]')?.remove();
 const value=beforeIllustratedDialogue(...args);syncJourneyDialogue();return value;
};
function motherMemory(){return 'Eu guardei aquela rabiola por tantos anos… Fico feliz que ela tenha encontrado o seu lugar.';}
function openMotherConversation(text='Meu filho… você acabou de dar vida ao seu próprio desenho. Ainda nem acredito!',remembered=false){
 if(mode||!playerAccount)return;worldClearWalking();const actor=worldState()?.actor;if(actor){actor.path=[];actor.moving=false;}
 dialogue('Conversar com a mãe',text,'Sobre a Rabiola Antiga…',()=>openMotherConversation(motherMemory(),true),{speaker:'Mãe',later:true});
 $('journeyDialog').dataset.dismissible='true';$('journeyContinue').hidden=remembered;
 const version=motherConversationVersion,actions=$('journeyDialog').querySelector('.journey-actions'),collection=uiElement('button','Quero mostrar meus Pipamons.','secondary');
 collection.type='button';collection.dataset.motherCollection='';collection.onclick=()=>{if(version!==motherConversationVersion)return;hideJourney();homeActions.collection();};
 actions.prepend($('journeyContinue'),collection);$('journeyLater').textContent='Até mais, mãe.';
 $('journeyLater').onclick=()=>{hideJourney();$('courtyardCanvas').focus({preventScroll:true});};syncJourneyDialogue();(remembered?collection:$('journeyContinue')).focus({preventScroll:true});
}
function openOpeningDialogue(speaker,text){
 openingMotherTalking=true;openingClearWalking();$('openingSpeaker').textContent=speaker;$('openingSpeech').textContent=text;$('openingNext').hidden=false;$('openingNext').disabled=false;$('openingNext').textContent='Continuar';syncOpeningDialogue();$('openingNext').focus({preventScroll:true});
}
function openOpeningMotherConversation(){openOpeningDialogue('Mãe','Eu guardei aquela rabiola por tantos anos… Cuide bem dele, Kael.');}
const beforeIllustratedOpeningNext=nextOpening;nextOpening=async function(...args){if(openingMotherTalking){openingMotherTalking=false;openingRoomSignature='';openingRefreshRoomUI();syncOpeningDialogue();$('openingCanvas').focus?.({preventScroll:true});return;}return beforeIllustratedOpeningNext(...args);};$('openingNext').onclick=nextOpening;
const beforeIllustratedOpeningReset=openingResetRoom;openingResetRoom=function(...args){openingMotherTalking=false;return beforeIllustratedOpeningReset(...args);};
addEventListener('keydown',event=>{
 const box=$('journeyDialog');if(box.hidden||!box.classList.contains('rpg-dialogue')||event.ctrlKey||event.altKey||event.metaKey||event.target.closest?.('input,textarea,select'))return;
 const choices=[...box.querySelectorAll('.journey-actions button')].filter(b=>!b.hidden&&!b.disabled);
 if(event.key==='Enter'&&event.repeat){event.preventDefault();event.stopImmediatePropagation();return;}
 const copy=$('journeySpeech');
 if(event.key==='Tab'&&choices.length){const focusables=copy.scrollHeight>copy.clientHeight+1?[copy,...choices]:choices,first=focusables[0],last=focusables.at(-1);if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus({preventScroll:true});}else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus({preventScroll:true});}event.stopImmediatePropagation();return;}
 if(event.key==='Escape'){
  event.preventDefault();event.stopImmediatePropagation();if(box.dataset.dismissible==='true'||!$('journeyLater').hidden&&$('journeyLater').onclick===hideJourney){hideJourney();$('courtyardCanvas').focus({preventScroll:true});}return;
 }
 if(['ArrowUp','ArrowDown'].includes(event.key)&&choices.length&&event.target!==copy){event.preventDefault();event.stopImmediatePropagation();const i=choices.indexOf(document.activeElement),step=event.key==='ArrowDown'?1:-1;choices[(i<0?(step>0?0:choices.length-1):(i+step+choices.length)%choices.length)].focus({preventScroll:true});}
 if(event.key==='Enter'&&event.target.tagName!=='BUTTON'&&event.target!==copy){event.preventDefault();event.stopImmediatePropagation();choices[0]?.click();}
},true);
