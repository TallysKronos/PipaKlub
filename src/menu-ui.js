// Shared collection presentation. No grants, mutations of ownership, or game rules.
let inventorySelection=null,inventoryPreviewFrame=0,inventoryPreviewVersion=0,inventoryPreviewEntry=null,inventoryPreviewLast=0,inventoryPreviewElapsed=0,inventoryPreviewKite=null;
const portraitObserver=typeof IntersectionObserver==='function'?new IntersectionObserver(entries=>{for(const item of entries)if(item.isIntersecting){const node=item.target;node.style.backgroundImage='url("'+node.dataset.portraitUrl+'")';portraitObserver.unobserve(node);}},{rootMargin:'120px'}):null;
function pipamonPortrait(entry){
 const node=uiElement('span',undefined,'pipamon-portrait');node.setAttribute('aria-hidden','true');
 if(!entry)return node;
 const a=art.atlases[entry.atlas],f=a.frames[a.animations[entry.sequence||'idle'][0]].frame,[x,y,size]=ART_CONFIG.portraits[entry.id].crop,W=a.meta.size.w,H=a.meta.size.h;
 node.dataset.portrait=entry.id;node.dataset.portraitUrl=a.meta.url;
 node.style.backgroundSize=W/size*100+'% '+H/size*100+'%';node.style.backgroundPosition=(f.x+x)/(W-size)*100+'% '+(f.y+y)/(H-size)*100+'%';
 if(portraitObserver)portraitObserver.observe(node);else node.style.backgroundImage='url("'+a.meta.url+'")';return node;
}
function inventoryDexEntry(kite){return ART_CONFIG.dex.entries.find(e=>e.model===kite.model_id)||ART_CONFIG.dex.entries.find(e=>e.id===kite.model.soul)||ART_CONFIG.dex.entries.find(e=>e.color===kite.model.color&&e.group==='common');}
function inventoryVisible(){return !!playerAccount&&accountPage==='collection'&&accountModal.style.display==='flex'&&!$('collectionMain').hidden&&!document.hidden;}
function releasePipamonPortraits(root){if(portraitObserver)for(const node of root.querySelectorAll('.pipamon-portrait'))portraitObserver.unobserve(node);}
function stopInventoryPreview(){if(inventoryPreviewFrame)cancelAnimationFrame(inventoryPreviewFrame);inventoryPreviewFrame=0;inventoryPreviewLast=0;}
function drawInventoryPreview(){
 if(!inventoryPreviewEntry)return;const e=inventoryPreviewEntry,a=art.atlases[e.atlas],seq=a.animations[e.sequence||'idle'],durations=seq.map(k=>a.frames[k].duration||190),total=durations.reduce((n,d)=>n+d,0);
 let time=inventoryPreviewElapsed%total,index=0;while(index<seq.length-1&&time>=durations[index])time-=durations[index++];
 const canvas=$('inventoryCanvas'),ctx=canvas.getContext('2d');if(!ctx)return;ctx.clearRect(0,0,canvas.width,canvas.height);drawPipamonGlow(ctx,pipamonProgress(inventoryPreviewKite).level,inventoryPreviewElapsed,canvas.width/2,canvas.height/2,canvas.width*.32,false,art.reduced);art.draw(ctx,e.atlas,seq[index],40,0,canvas.width-80,canvas.height);
}
function tickInventoryPreview(t){inventoryPreviewFrame=0;if(!inventoryVisible())return;if(inventoryPreviewLast)inventoryPreviewElapsed+=Math.min(100,t-inventoryPreviewLast);inventoryPreviewLast=t;drawInventoryPreview();inventoryPreviewFrame=requestAnimationFrame(tickInventoryPreview);}
function resumeInventoryPreview(){stopInventoryPreview();if(inventoryVisible()&&!art.reduced&&inventoryPreviewEntry)inventoryPreviewFrame=requestAnimationFrame(tickInventoryPreview);}
async function selectInventory(kite){
 inventorySelection=kite.id;inventoryPreviewKite=kite;renderPipamonProgress(kite);inventoryPreviewEntry=inventoryDexEntry(kite);inventoryPreviewElapsed=0;stopInventoryPreview();
 for(const card of $('inventoryList').querySelectorAll('button'))card.setAttribute('aria-pressed',String(card.dataset.kiteId===kite.id));
 const e=inventoryPreviewEntry,t=eng.type({color:kite.model.color}),equipped=kite.id===playerAccount.profile.equipped_kite_id;
 $('inventoryDetails').hidden=false;$('inventoryDetails').scrollTop=0;$('inventoryName').textContent=(kite.personal_name||kite.model.name);$('inventorySubtitle').textContent=e?.title||t.name;
 $('inventoryOwnership').textContent=equipped?'Equipada para o próximo voo':kite.model_id==='rabbito'?'Parceiro da história · vinculado à conta':kite.model.acquisition==='event'?'Soul de evento · vinculada à conta':kite.permanent?'Básica permanente':'Colecionável · pode ser conquistada em Vale pipa';
 $('inventorySkill').textContent=t.name+' · '+t.skill;$('inventorySkillDescription').textContent=t.description;
 $('inventoryLore').replaceChildren(...(e?.story||[]).map(text=>uiElement('p',text)));
 $('inventoryCaptures').textContent=(kite.capture_count||0)+' transferências em Vale pipa · não conta vitórias da história';$('inventoryHabitat').textContent=e?.habitat||'Céus de Kronasta';
 const equip=$('inventoryEquip');equip.textContent=equipped?'Já está equipada':'Equipar Pipamon';equip.disabled=accountSaving||equipped||!!mode;
 equip.onclick=()=>equipInventory(kite);$('inventoryHistory').onclick=()=>{stopInventoryPreview();openKiteStory(kite);};
 $('inventoryCanvas').setAttribute('aria-label',(kite.personal_name||kite.model.name)+' — corpo inteiro animado');
 const version=++inventoryPreviewVersion;$('inventoryLoad').textContent='Carregando seu parceiro…';drawInventoryPreview();
 const loaded=e&&await art.load(e.atlas);if(version!==inventoryPreviewVersion)return;
 $('inventoryLoad').textContent=loaded?'':'A ilustração não carregou. Selecione o Pipamon para tentar novamente.';if(loaded){drawInventoryPreview();resumeInventoryPreview();}
}
async function equipInventory(kite){if(accountSaving||mode)return;accountSaving=true;renderAccountDialog();try{const d=await accountRequest('equip',{kiteId:kite.id});playerAccount=d.account;reflectAccount();toast('Pipa equipada. Pronta para voar!');}catch(e){$('accountMessage').textContent=e.message;}finally{accountSaving=false;renderAccountDialog();}}
function renderInventory(){
 const p=playerAccount.profile,normalize=text=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase(),q=normalize($('inventorySearch').value.trim()),filter=$('inventoryFilter').value;
 const items=playerAccount.inventory.filter(k=>normalize((k.personal_name||'')+' '+k.model.name).includes(q)&&(filter==='all'||filter==='story'&&k.model_id==='rabbito'||filter==='event'&&k.model.acquisition==='event'&&k.model_id!=='rabbito'||filter==='equipped'&&k.id===p.equipped_kite_id));
 releasePipamonPortraits($('inventoryList'));$('inventoryList').replaceChildren(...items.map(k=>{const card=uiElement('button',undefined,'inventory-card portrait-card'+(k.id===p.equipped_kite_id?' equipped':''));card.type='button';card.dataset.kiteId=k.id;card.setAttribute('aria-pressed',String(k.id===inventorySelection));card.setAttribute('aria-label',(k.personal_name||k.model.name)+(k.id===p.equipped_kite_id?' · equipada':''));card.append(pipamonPortrait(inventoryDexEntry(k)),uiElement('b',k.personal_name||k.model.name),uiElement('small','Nv. '+pipamonProgress(k).level+' · '+(k.id===p.equipped_kite_id?'Equipada · ':'')+(k.model_id==='rabbito'?'Parceiro da história':k.model.acquisition==='event'?'Especial de evento':k.permanent?'Permanente':'Colecionável')));card.onclick=()=>selectInventory(k);return card;}));
 $('inventoryEmpty').hidden=items.length>0;$('inventoryResults').textContent=items.length+' de '+playerAccount.inventory.length+' Pipamons';
 if(items.length)selectInventory(items.find(k=>k.id===inventorySelection)||items.find(k=>k.id===p.equipped_kite_id)||items[0]);else{$('inventoryDetails').hidden=true;inventoryPreviewVersion++;stopInventoryPreview();}
}
function menuSkinPanel(panel){
 if(panel.dataset.menuSkinned)return;panel.dataset.menuSkinned='true';panel.classList.add('menu-skinned');
 const layer=uiElement('span',undefined,'hud-art menu-skin-layer');layer.setAttribute('aria-hidden','true');mountHudSkin(layer,'ranking',ART_CONFIG.hud);panel.prepend(layer);
}
function skinMenuButtons(){
 for(const button of document.querySelectorAll('.menu-skinned button.primary,.menu-skinned button.secondary')){
  if(button.matches('.portrait-card,.dex-entry,.club-tile,.close')||button.closest('.combat-deck')||button.querySelector('.menu-button-skin'))continue;
  button.classList.add('menu-art-button');for(const state of ['normal','hover','pressed','disabled']){const layer=uiElement('span',undefined,'hud-art menu-button-skin menu-button-'+state);layer.setAttribute('aria-hidden','true');mountHudSkin(layer,'button-compact-'+state,ART_CONFIG.hud);button.append(layer);}
 }
}
function initializeMenuUI(){
 const main=$('collectionMain'),search=uiElement('aside',undefined,'collection-browser');
 search.innerHTML='<div class="collection-search"><label for="inventorySearch">Buscar Pipamon<input id="inventorySearch" type="search" placeholder="Nome do parceiro" autocomplete="off"></label><label class="sr" for="inventoryFilter">Filtrar coleção</label><select id="inventoryFilter"><option value="all">Todos</option><option value="equipped">Equipado</option><option value="event">Eventos</option><option value="story">História</option></select></div><p id="inventoryResults" class="collection-results" role="status"></p>';
 const layout=uiElement('div',undefined,'collection-layout');search.append($('inventoryList'));search.append(uiElement('p','Nenhum Pipamon encontrado. Tente outro nome ou filtro.','collection-empty'));search.lastChild.id='inventoryEmpty';
 const details=uiElement('article',undefined,'inventory-details');details.id='inventoryDetails';
 details.innerHTML='<header class="creature-heading"><span class="eyebrow">Seu parceiro de voo</span><h3 id="inventoryName"></h3><p id="inventorySubtitle"></p><span id="inventoryOwnership" class="collection-status"></span></header><div class="collection-stage"><canvas id="inventoryCanvas" width="720" height="600" role="img"></canvas></div><p id="inventoryLoad" role="status"></p><div class="inventory-actions"><button id="inventoryEquip" type="button" class="primary">Equipar Pipamon</button><button id="inventoryHistory" type="button" class="secondary">Histórico de conquistas</button></div><section id="inventoryProgress" class="pipamon-progress" aria-label="Nível e status do Pipamon"></section><dl class="collection-facts"><div><dt>Habitat</dt><dd id="inventoryHabitat"></dd></div><div><dt>Histórico</dt><dd id="inventoryCaptures"></dd></div></dl><section class="collection-skill"><h4 id="inventorySkill"></h4><p id="inventorySkillDescription"></p></section><section><h4>A história desta alma</h4><div id="inventoryLore" class="collection-lore"></div></section>';
 details.prepend(details.querySelector('.collection-stage'));layout.append(search,details);$('collectionCount').after(layout);for(const note of main.querySelectorAll(':scope > .collection-info'))details.append(note);
 $('inventorySearch').oninput=renderInventory;$('inventoryFilter').onchange=renderInventory;
 // Root frames stay outside each menu's scrolling content.
 const accountCard=document.querySelector('.account-card'),scroll=uiElement('div',undefined,'account-scroll');for(const child of [...accountCard.childNodes])if(child!==$('closeAccount'))scroll.append(child);accountCard.append(scroll);
 for(const panel of document.querySelectorAll('.account-card,.dex-card,.sheet-card,#modal .panel,.rpg-box,.trails-card,.design-panel'))menuSkinPanel(panel);
 const priorRender=renderAccountDialog;renderAccountDialog=function(){priorRender();accountCard.dataset.accountState=playerAccount?'member':'guest';skinMenuButtons();};
 const priorSync=syncClubMenu;syncClubMenu=function(){priorSync();accountCard.dataset.clubPage=accountPage;stopInventoryPreview();if(accountPage==='collection')resumeInventoryPreview();};
 const priorStoryBack=closeKiteStory;closeKiteStory=function(){priorStoryBack();if(accountPage==='collection')resumeInventoryPreview();};$('kiteStoryBack').onclick=closeKiteStory;
 const priorClose=closeAccount;closeAccount=function(){inventoryPreviewVersion++;stopInventoryPreview();priorClose();};$('closeAccount').onclick=closeAccount;
 const priorDex=openDex;openDex=function(){stopInventoryPreview();priorDex();skinMenuButtons();};$('workshop').onclick=openDex;
 // Only changed subtrees trigger a pass; decorations are ignored to avoid loops.
 new MutationObserver(records=>{if(records.some(r=>[...r.addedNodes].some(n=>n.nodeType===1&&!n.classList.contains('hud-art')&&!n.classList.contains('hud-slice'))||r.removedNodes.length&&!r.target.classList?.contains('hud-art')))skinMenuButtons();}).observe(document.body,{childList:true,subtree:true});
 document.addEventListener('visibilitychange',()=>{if(document.hidden)stopInventoryPreview();else resumeInventoryPreview();});
 skinMenuButtons();
}
initializeMenuUI();
