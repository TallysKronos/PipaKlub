// PIP-50 pilot: one navigation language for the menu, dialogue, collection and battle HUD.
// The player navigates by pulling a line: a small kite on a string marks the focused option.
// Presentation only: it reuses the existing actions, never grants, unlocks or changes rules.
// `?classico` in the address keeps the previous look for side-by-side review.
const pilotUI=!/[?&]classico\b/.test(location.search);
const PILOT_KITE='<svg viewBox="0 0 40 64" aria-hidden="true"><path d="M20 2 37 20 20 40 3 20Z" fill="#f2a33a" stroke="#213d39" stroke-width="2.5" stroke-linejoin="round"/><path d="M20 2 20 40M3 20h34" stroke="#213d39" stroke-width="1.6"/><path d="M20 2 37 20 20 20Z" fill="#e2603a"/><path d="M20 40c-6 5 6 7 0 12s5 6 0 10" fill="none" stroke="#213d39" stroke-width="2"/><path d="m15 47 5 2 5-2M15 56l5 2 5-2" stroke="#e2603a" stroke-width="3" stroke-linecap="round"/></svg>';
function pilotKite(cls='pilot-kite'){const k=document.createElement('span');k.className=cls;k.setAttribute('aria-hidden','true');k.innerHTML=PILOT_KITE;return k;}
// Footer commands are also buttons, so mouse and touch use the same command system as the controller.
function pilotCommand(command,label,fn){const c=document.createElement(fn?'button':'span');c.className='pilot-command';if(fn){c.type='button';c.tabIndex=-1;c.onclick=fn;}c.append(glyphImage(command),document.createTextNode(label));return c;}
const pilotEscape=()=>pressKey('Escape');

if(pilotUI){
document.body.classList.add('pilot-ui');

// ---------------------------------------------------------------- main menu
const PILOT_NOTES={
 playGroup:'Trilhas, partida rápida, céu do dia, amigos e treino livre.',collection:'Seus Pipamons, níveis e quem voa com você.',dex:'O caderno de campo do Sr. Assis: todas as almáticas já vistas.',
 backpack:'Rabiolas e lembranças guardadas na mochila.',missions:'O próximo vento a seguir na sua jornada.',city:'Os bairros de Kronasta, seus rivais e trilhas.',
 clubGroup:'Invocação, trocas, banca de linhas, duelos e perfil.',school:'Lições de voo com o Sr. Assis, uma por vez.',optionsGroup:'Som, imagem, privacidade e conta.',
 trails:'Desafios em sequência pelos bairros. As vitórias abrem novos caminhos.',quick:'Entre com quem está esperando; bots completam a sala.',daily:'Um céu diferente a cada dia, com recompensa.',
 friends:'Crie uma sala e mande o código para a turma.',practice:'Voo livre contra bots, sem recompensa.',lab:'Experimento em teste.',
 summon:'Chame um Pipamon com uma rabiola e o ritual certo.',trades:'Troque pipas com um amigo, com confirmação dos dois lados.',shop:'Linhas novas para o seu voo, compradas com moedas.',
 history:'Seus últimos duelos e resultados.',events:'Almas especiais de evento.',profile:'Seu nome, nível e conquistas.',professor:'Repetir o primeiro voo com o Sr. Assis.',story:'Rever a abertura sem perder o progresso.',
 sound:'Ligar ou desligar o som.',quality:'Modo leve para aparelhos mais simples.',fullscreen:'Ocupar a tela inteira.',privacy:'Escolher se o jogo pode medir o uso.',rules:'Como o corte, a esquiva e a energia funcionam.',
 reload:'Recarregar as imagens do cenário.',logout:'Sair desta conta neste aparelho.'
};
const PILOT_ROOT=[['playGroup','Jogar'],['collection','Parceiros'],['dex','Pipa Dex'],['backpack','Mochila'],['missions','Missões'],['city','Mapa da cidade'],['clubGroup','Clube'],['school','Escola do Sr. Assis'],['optionsGroup','Opções']];
const PILOT_TITLES={root:'Caderno do pipeiro',playGroup:'Jogar',clubGroup:'Clube',optionsGroup:'Opções'};
if(typeof homeActions==='object'){homeActions.backpack=()=>{hideJourney();closeHomeMenu();openPlazaBag()};homeActions.missions=()=>{hideJourney();closeHomeMenu();openPlazaMissions()};}
const pilotMenu=document.createElement('div');pilotMenu.className='pilot-menu';
pilotMenu.innerHTML='<div class="pilot-menu-col"><p class="pilot-crumb" id="pilotCrumb"></p><h2 class="pilot-menu-title" id="pilotMenuTitle"></h2><nav class="pilot-menu-list" id="pilotMenuList" aria-labelledby="pilotMenuTitle"></nav><svg class="pilot-line" id="pilotLine" aria-hidden="true"><path/></svg><span class="pilot-spool" aria-hidden="true"></span></div>'+
 '<aside class="pilot-menu-side" aria-live="polite"><div class="pilot-partners"><img class="pilot-avatar" id="pilotAvatar" alt=""><canvas class="pilot-partner" id="pilotPartner" width="360" height="360" aria-hidden="true"></canvas></div><div class="pilot-note"><b id="pilotNoteName"></b><p id="pilotNoteText"></p></div></aside>'+
 '<footer class="pilot-footer" id="pilotMenuFooter"></footer>';
gameMenu.append(pilotMenu);
const menuKite=pilotKite();pilotMenu.querySelector('.pilot-menu-col').append(menuKite);
let pilotGroup='root',pilotFrom={},pilotAnim=0,pilotLineUntil=0;
const pilotItems=group=>group==='root'?PILOT_ROOT:homeMenuGroups[group].filter(([id])=>id!=='root').map(([id,label])=>[id,label]);
let pilotReturn=null;
function pilotOpen(id){if(homeMenuGroups[id]){pilotFrom[id]=document.activeElement?.dataset?.destination||id;renderHomeMenu(id);}else{const group=pilotGroup;pilotReturn=null;closeHomeMenu();homeActions[id]?.();pilotReturn={group,id};}}
// Set after the action: opening a screen may close another one first, which must not count as back.
// Back from a screen opened by the menu returns to the menu, on the option that opened it.
function pilotBack(){
 const r=pilotReturn;pilotReturn=null;if(!r)return;
 setTimeout(()=>{
  // The same Escape may already have reopened the menu on its first option: just move to the origin.
  const busy=mode||!playerAccount||courtyard.hidden||!cityScreen.hidden||document.querySelector('.overlay[style*="flex"]')||$('kaelOpening')?.hidden===false||(typeof dexOverlay!=='undefined'&&!dexOverlay.hidden)||$('trails')?.hidden===false;
  if(busy)return;if(gameMenu.hidden)openHomeMenu();if(r.group!=='root')renderHomeMenu(r.group);$('pilotMenuList').querySelector('[data-destination="'+r.id+'"]')?.focus({preventScroll:true});
 },60);
}
{const a=closeAccount;closeAccount=function(...x){const v=a.apply(this,x);pilotBack();return v};$('closeAccount').onclick=closeAccount;}
{const d=closeDex;closeDex=function(...x){const v=d.apply(this,x);pilotBack();return v};$('dexClose').onclick=closeDex;}
{const m=closeModal;closeModal=function(...x){const v=m.apply(this,x);pilotBack();return v};$('close').onclick=$('dialogAction').onclick=closeModal;}
{const s=closeSchool;closeSchool=function(...x){const v=s.apply(this,x);pilotBack();return v};$('schoolClose').onclick=closeSchool;}
function pilotFooter(){
 const f=$('pilotMenuFooter');f.replaceChildren(pilotCommand('confirm','Escolher',()=>$('pilotMenuList').querySelector('.pilot-option:focus')?.click()),pilotCommand('back',pilotGroup==='root'?'Fechar':'Voltar',pilotEscape));
}
function pilotRenderMenu(group,focusId){
 pilotGroup=group;setText('pilotMenuTitle',PILOT_TITLES[group]||'Menu');setText('pilotCrumb',group==='root'?'Quintal do Clube':'Caderno do pipeiro ›');
 const list=$('pilotMenuList');list.replaceChildren(...pilotItems(group).map(([id,label])=>{
  const b=document.createElement('button');b.type='button';b.className='pilot-option'+(homeMenuGroups[id]?' has-sub':'');b.dataset.destination=id;b.textContent=label;
  b.onclick=()=>pilotOpen(id);b.onmouseenter=()=>b.focus({preventScroll:true});b.onfocus=()=>pilotFocus(b);return b;}));
 pilotFooter();
 const target=list.querySelector('[data-destination="'+focusId+'"]')||list.querySelector('button');target?.focus({preventScroll:true});
}
function pilotFocus(b){
 setText('pilotNoteName',b.textContent);setText('pilotNoteText',PILOT_NOTES[b.dataset.destination]||'');
 const col=pilotMenu.querySelector('.pilot-menu-col').getBoundingClientRect(),r=b.getBoundingClientRect();
 menuKite.style.transform='translate('+(r.left-col.left-46)+'px,'+(r.top-col.top+r.height/2-30)+'px)';
 pilotLineUntil=performance.now()+(art.reduced?0:420);if(!pilotAnim)pilotAnim=requestAnimationFrame(pilotTick);
}
// The line runs from the spool at the bottom of the column to the kite, sagging a little.
function pilotDrawLine(){
 const col=pilotMenu.querySelector('.pilot-menu-col'),c=col.getBoundingClientRect(),k=menuKite.getBoundingClientRect(),svg=$('pilotLine');
 svg.setAttribute('width',c.width);svg.setAttribute('height',c.height);
 const x0=34,y0=c.height-30,x1=k.left-c.left+20,y1=k.top-c.top+46,mx=(x0+x1)/2-30,my=(y0+y1)/2+40;
 svg.querySelector('path').setAttribute('d','M'+x0+' '+y0+' Q'+mx+' '+my+' '+x1+' '+y1);
}
let pilotPartnerEntry=null,pilotPartnerStart=0;
function pilotTick(t){
 pilotAnim=0;if(gameMenu.hidden)return;pilotDrawLine();
 const e=pilotPartnerEntry,a=e&&art.atlases[e.atlas],c=$('pilotPartner'),g=c.getContext('2d');
 if(a&&g){const seq=a.animations[e.sequence||'idle'],f=art.reduced?0:Math.floor((t-pilotPartnerStart)/200)%seq.length;g.clearRect(0,0,c.width,c.height);art.draw(g,e.atlas,seq[f],0,0,c.width,c.height,true);}
 if(t<pilotLineUntil||(a&&!art.reduced))pilotAnim=requestAnimationFrame(pilotTick);
}
function pilotPrepareSide(){
 $('pilotAvatar').src=typeof plazaURL==='function'?plazaURL('avatar.png'):'';
 const k=playerAccount?.inventory?.find(x=>x.id===playerAccount.profile.equipped_kite_id);pilotPartnerEntry=k&&typeof inventoryDexEntry==='function'?inventoryDexEntry(k):null;
 if(pilotPartnerEntry)art.load(pilotPartnerEntry.atlas).then(()=>{pilotPartnerStart=performance.now();if(!pilotAnim)pilotAnim=requestAnimationFrame(pilotTick);});
}
const classicRenderHomeMenu=renderHomeMenu;
renderHomeMenu=function(group='root'){
 const back=group==='root'&&pilotGroup!=='root'?pilotGroup:null;
 classicRenderHomeMenu(group);if(group==='root'&&!back)pilotPrepareSide();
 pilotRenderMenu(group,back);
};
// Arrows move through the pilot list, not the hidden classic one; Escape keeps the classic behaviour.
document.addEventListener('keydown',e=>{
 if(gameMenu.hidden||!['ArrowDown','ArrowUp'].includes(e.key))return;
 const buttons=[...$('pilotMenuList').querySelectorAll('button')],i=buttons.indexOf(document.activeElement);
 e.preventDefault();e.stopPropagation();buttons[(i+(e.key==='ArrowDown'?1:-1)+buttons.length)%buttons.length]?.focus({preventScroll:true});
},true);
addEventListener('resize',()=>{if(!gameMenu.hidden&&document.activeElement?.classList.contains('pilot-option'))pilotFocus(document.activeElement);});

// ---------------------------------------------------------------- dialogue
// A nameplate tied with string, a portrait, the line of speech and a quiet advance marker.
function pilotDialogue(box,{portrait,name,next,back}){
 if(box.dataset.pilot)return;box.dataset.pilot='true';box.classList.add('pilot-dialogue');
 if(portrait){const p=document.createElement('canvas');p.className='pilot-portrait';p.width=180;p.height=180;p.setAttribute('aria-hidden','true');box.prepend(p);
  // Art loads only when the dialogue is actually shown.
  const draw=()=>{if(!box.hidden&&!p.dataset.drawn){p.dataset.drawn='true';portrait(p);}};new MutationObserver(draw).observe(box,{attributes:true,attributeFilter:['hidden']});draw();}
 if(name){const n=box.querySelector(name);n?.classList.add('pilot-nameplate');}
 const keep=(button,command)=>{if(!button)return;button.classList.add('pilot-advance');const add=()=>{if(!button.querySelector('.kit-glyph'))button.prepend(glyphImage(command));if(command==='confirm'&&!button.querySelector('.pilot-kite-mini'))button.append(pilotKite('pilot-kite-mini'));};add();new MutationObserver(add).observe(button,{childList:true});};
 keep(box.querySelector(next),'confirm');keep(box.querySelector(back),'back');
}
const assisPortrait=c=>art.load('sr-assis-expressions').then(()=>{const g=c.getContext('2d');if(!g)return;g.clearRect(0,0,c.width,c.height);art.draw(g,'sr-assis-expressions','speaking',0,0,c.width,c.height,true);});
pilotDialogue($('journeyDialog'),{portrait:assisPortrait,name:'.eyebrow',next:'#journeyContinue',back:'#journeyLater'});
if($('kaelOpening'))pilotDialogue(document.querySelector('#kaelOpening .opening-dialog'),{name:'#openingSpeaker',next:'#openingNext',back:'#openingPause'});
// Kael and his mother get their own faces when they speak in the opening.
if($('openingSpeaker')){
 const face=document.createElement('img');face.className='pilot-face';face.alt='';document.querySelector('#kaelOpening .opening-dialog').prepend(face);
 const sync=()=>{const who=$('openingSpeaker').textContent.trim();const url=who==='Kael'&&typeof plazaURL==='function'?plazaURL('avatar.png'):'';face.hidden=!url;if(url&&face.src!==url)face.src=url;};
 new MutationObserver(sync).observe($('openingSpeaker'),{childList:true,characterData:true,subtree:true});sync();
}

// ---------------------------------------------------------------- collection and Dex
// Filters become tabs (LB/RB, Q/E); search is an optional command; details follow the focus;
// confirming on the focused, already-selected card is the explicit "equip".
function pilotTabs(select,host){
 if(!select||select.dataset.pilot)return;select.dataset.pilot='true';
 const bar=document.createElement('div');bar.className='pilot-tabs';bar.setAttribute('role','tablist');
 const sync=()=>{for(const t of bar.querySelectorAll('[role=tab]')){const on=t.dataset.value===select.value;t.setAttribute('aria-selected',String(on));if(on)t.scrollIntoView?.({block:'nearest',inline:'nearest'});}};
 for(const o of select.options){const t=document.createElement('button');t.type='button';t.setAttribute('role','tab');t.dataset.value=o.value;t.textContent=o.textContent;t.onclick=()=>{select.value=o.value;select.dispatchEvent(new Event('change',{bubbles:true}));sync();};bar.append(t);}
 host.before(bar);select.closest('label,div')?.classList.add('pilot-hidden-control');sync();select.addEventListener('change',sync);
 return bar;
}
function pilotStep(bar,step){const tabs=[...bar.querySelectorAll('[role=tab]')],i=tabs.findIndex(t=>t.getAttribute('aria-selected')==='true'),n=tabs[(Math.max(0,i)+step+tabs.length)%tabs.length];n.click();}
function pilotSearch(input,label){
 if(!input)return;const wrap=input.closest('label,div');wrap?.classList.add('pilot-search','pilot-collapsed');
 return ()=>{wrap?.classList.toggle('pilot-collapsed');if(!wrap?.classList.contains('pilot-collapsed'))input.focus();};
}
function pilotCollectionFooter(host,items){const f=document.createElement('footer');f.className='pilot-footer pilot-footer-inline';f.append(...items.map(([c,l,fn])=>pilotCommand(c,l,fn)));host.append(f);return f;}
let invTabs=null,dexTabs=null,invSearch=null,dexSearch=null;
function pilotWireCollection(){
 if(!invTabs&&$('inventoryFilter')&&$('inventoryList')){invTabs=pilotTabs($('inventoryFilter'),$('inventoryList'));invSearch=pilotSearch($('inventorySearch'));pilotCollectionFooter($('inventoryList').closest('.account-card')||$('inventoryList').parentElement,[['confirm','Equipar',()=>$('inventoryEquip')?.click()],['actionX','Histórico',()=>$('inventoryHistory')?.click()],['actionY','Buscar',()=>invSearch?.()],['tabLeft','',()=>pilotStep(invTabs,-1)],['tabRight','Filtro',()=>pilotStep(invTabs,1)],['back','Voltar',()=>closeAccount()]]).classList.add('pilot-inventory-footer');
  // The footer mirrors the real equip button: same label, same disabled state.
  const equip=$('inventoryEquip'),cmd=document.querySelector('.pilot-inventory-footer .pilot-command');
  if(equip&&cmd){const sync=()=>{cmd.disabled=equip.disabled;cmd.lastChild.textContent=equip.disabled&&/equipada/i.test(equip.textContent)?'Equipada':'Equipar';};new MutationObserver(sync).observe(equip,{attributes:true,childList:true,characterData:true,subtree:true});sync();}}
 if(!dexTabs&&$('dexFilter')&&$('dexList')){dexTabs=pilotTabs($('dexFilter'),$('dexList'));dexSearch=pilotSearch($('dexSearch'));}
}
pilotWireCollection();new MutationObserver(pilotWireCollection).observe(document.body,{childList:true,subtree:true});
// Opening a collection lands on the partner that is shown (the equipped one), not on the close button.
function pilotLandOnCard(list,selector){
 const a=document.activeElement;if(!list.offsetParent||list.contains(a)&&a!==list)return;
 if(a&&a!==document.body&&!a.matches('#closeAccount,#dexClose,.club-back'))return;
 (list.querySelector(selector+'[aria-pressed=true]')||list.querySelector(selector))?.focus({preventScroll:true});
}
for(const [id,sel] of [['inventoryList','.inventory-card'],['dexList','button']]){const list=$(id);if(list)new MutationObserver(()=>setTimeout(()=>pilotLandOnCard(list,sel),0)).observe(list,{childList:true});}
// Details follow the focus; a confirm on the card that is already shown equips it.
document.addEventListener('focusin',e=>{const card=e.target.closest?.('#inventoryList .inventory-card,#dexList button');if(card&&card.getAttribute('aria-pressed')!=='true')card.click();});
document.addEventListener('click',e=>{const card=e.target.closest?.('#inventoryList .inventory-card');if(!card||e.detail!==0)return;if(card.dataset.pilotShown==='true'){const equip=$('inventoryEquip');if(equip&&!equip.disabled){e.stopPropagation();equip.click();}}card.dataset.pilotShown='true';},true);
document.addEventListener('focusout',e=>{const card=e.target.closest?.('#inventoryList .inventory-card');if(card)delete card.dataset.pilotShown;});
addEventListener('keydown',e=>{
 if(/INPUT|TEXTAREA|SELECT/.test(e.target?.tagName||''))return;const key=e.key.toLowerCase();
 const inv=$('inventoryList')?.offsetParent?invTabs:null,dex=$('dexList')?.offsetParent?dexTabs:null,bar=inv||dex;if(!bar)return;
 if(key==='q'||key==='e'){e.preventDefault();pilotStep(bar,key==='q'?-1:1);}
 if(key==='y'){e.preventDefault();(inv?invSearch:dexSearch)?.();}
 if(key==='x'&&inv){e.preventDefault();$('inventoryHistory')?.click();}
});

// ---------------------------------------------------------------- results never open under a pause
if(typeof showMatchResult==='function'){const classicResult=showMatchResult;showMatchResult=function(...args){if(!$('pauseSheet').hidden)closeSheet();return classicResult.apply(this,args);};}
}
