const $=s=>document.querySelector(s),$$=s=>[...document.querySelectorAll(s)];
const skin=id=>`<span class="pk-skin" data-skin="${id}" aria-hidden="true"></span>`;
const menu=[['play','Jogar'],['partners','Parceiros'],['dex','Pipa Dex'],['club','Clube'],['school','Escola'],['options','Opções']];
$('#menuGrid').innerHTML=menu.map(([id,label],i)=>`<button type="button" class="pk-menu${i===0?' pk-focus':''}" tabindex="${i===0?0:-1}" data-label="${label}">${skin('window')}<span class="pk-content"><img src="icons/menu-${id}.png" alt=""><strong>${label}</strong></span></button>`).join('');
function focusMenu(button){for(const el of $$('#menuGrid button')){el.classList.toggle('pk-focus',el===button);el.tabIndex=el===button?0:-1;}$('#menuStatus').textContent='Prévia do kit: '+button.dataset.label+' em destaque.';}
$('#menuGrid').addEventListener('focusin',e=>{if(e.target.matches('button'))focusMenu(e.target);});
$('#menuGrid').addEventListener('click',e=>{const b=e.target.closest('button');if(b){focusMenu(b);$('#menuStatus').textContent=b.dataset.label+' selecionado na prévia. O catálogo não abre telas do jogo.';}});
$('#menuGrid').addEventListener('keydown',e=>{
 const buttons=$$('#menuGrid button'),index=buttons.indexOf(document.activeElement),columns=getComputedStyle($('#menuGrid')).gridTemplateColumns.split(' ').length;
 const move={ArrowRight:1,ArrowLeft:-1,ArrowDown:columns,ArrowUp:-columns}[e.key];
 if(move!==undefined&&index>=0){e.preventDefault();buttons[(index+move+buttons.length)%buttons.length].focus();}
});
const states=[['Normal',''],['Ponteiro','hover'],['Pressionado','pressed'],['Foco','focus'],['Carregando','loading']];
$('#states').innerHTML=states.map(([name,state])=>`<div class="state-example"><small>${name.toUpperCase()}</small><button type="button" class="pk-button${state==='focus'?' pk-focus':''}" data-state="${state}"${state==='loading'?' aria-busy="true" disabled':''}>${skin(state==='loading'?'button-disabled':'button-secondary')}<span class="pk-content">Continuar</span></button></div>`).join('');
function resize(){
 const width=Number($('#width').value),height=Number($('#height').value);
 $('#resizeButton').style.width=width+'px';$('#resizePanel').style.width=width+'px';$('#resizePanel').style.height=height+'px';
 $('#metrics').textContent=`${width} × ${height} px · cantos do painel: 25 px`;
}
$('#width').addEventListener('input',resize);$('#height').addEventListener('input',resize);resize();
window.verifyKit=()=>{
 const panel=$('#resizePanel'),frame=panel.querySelector('.pk-skin'),old=[panel.style.width,panel.style.height],rows=[];
 for(const width of [200,280,420,640,800,1000])for(const height of [160,220,320,400]){
  panel.style.width=width+'px';panel.style.height=height+'px';const css=getComputedStyle(frame);
  rows.push({width,height,caps:[css.borderTopWidth,css.borderRightWidth,css.borderBottomWidth,css.borderLeftWidth],source:css.borderImageSource});
 }
 [panel.style.width,panel.style.height]=old;
 const errors=rows.filter(r=>r.caps.join()!==rows[0].caps.join()||!r.source.includes('window.png'));
 const result={cases:rows.length,failures:errors.length,caps:rows[0].caps};
 $('#verification').textContent=`${result.cases} tamanhos · ${result.failures} variações indevidas nos cantos. Inspeção visual ainda necessária para confirmar as emendas.`;
 return result;
};
$('#verify').addEventListener('click',window.verifyKit);
const cards=[['carcara','Carcará','Disponível',''],['mata-verde','Mata verde','Equipado','equipped'],['nevagume','Nevagume','Evento','event'],['yaguaru-memoria','Yaguarú','Bloqueado','locked']];
$('#cards').innerHTML=cards.map(([id,name,state,badge])=>`<button type="button" class="pk-card" aria-label="${name}, ${state}"${badge==='locked'?' aria-disabled="true"':''} aria-pressed="${badge==='equipped'}" data-event="${badge==='event'||badge==='locked'}">${skin('portrait-card')}<span class="pk-content"><img class="pk-card-art" src="examples/${id}.png" alt=""><strong>${name}</strong><small>${state}</small></span>${badge?`<img class="pk-badge" src="icons/badge-${badge}.svg" alt="">`:''}</button>`).join('');
$('#cards').addEventListener('click',e=>{const card=e.target.closest('button');if(card)$('#collectionStatus').textContent='Prévia de estado: '+card.getAttribute('aria-label')+'. Nenhum item da conta é alterado.';});
function selectTab(tab){
 const tabs=$$('[role=tab]');for(const t of tabs){t.setAttribute('aria-selected',String(t===tab));t.tabIndex=t===tab?0:-1;}
 $('#collectionPanel').setAttribute('aria-labelledby',tab.id);
 const label=tab.querySelector('.pk-content').textContent;
 $('#collectionStatus').textContent='Exemplos de estados para a coleção '+label+'.';
 for(const c of $$('#cards .pk-card'))c.hidden=label==='Eventos'&&c.dataset.event!=='true'||label==='Meus'&&c.getAttribute('aria-disabled')==='true';
}
for(const tab of $$('[role=tab]')){
 tab.addEventListener('click',()=>selectTab(tab));
 tab.addEventListener('keydown',e=>{const tabs=$$('[role=tab]'),i=tabs.indexOf(tab);let next;if(e.key==='ArrowRight')next=(i+1)%tabs.length;if(e.key==='ArrowLeft')next=(i+tabs.length-1)%tabs.length;if(e.key==='Home')next=0;if(e.key==='End')next=tabs.length-1;if(next!==undefined){e.preventDefault();tabs[next].focus();selectTab(tabs[next]);}});
}
// Start on Todos so all four state examples are visible at first.
selectTab($('#tab-all'));
$('#roomCode').innerHTML=Array.from({length:6},(_,i)=>`<label>${skin('input')}<input aria-label="Caractere ${i+1} do código da sala" maxlength="1" pattern="[A-Za-z0-9]" autocomplete="off" value="${'PIPA24'[i]}"></label>`).join('');
$('#roomCode').addEventListener('input',e=>{e.target.value=e.target.value.replace(/[^A-Za-z0-9]/g,'').toUpperCase();});
const actions=[['dodge','Esquiva','dodge'],['maneuver','Rebicada','maneuver'],['skill','Habilidade','skill']];
$('#fan').innerHTML=actions.map(([id,label,command])=>`<button type="button" class="pk-action" aria-label="${label}">${skin('action-paper')}<img class="pk-action-icon" src="icons/battle-${id}.png" alt="">${id==='maneuver'?'<svg class="pk-cooldown" viewBox="0 0 120 120" aria-hidden="true"><circle class="pk-cooldown-track" cx="60" cy="60" r="53"/><circle class="pk-cooldown-progress" cx="60" cy="60" r="53"/></svg>':''}<img class="pk-glyph" data-command="${command}" alt=""><span class="action-label">${label}</span></button>`).join('');
function updateCooldown(){const value=Number($('#cooldown').value);$('#fan').style.setProperty('--pk-cooldown',String(333*(1-value/100)));$('#cooldownStatus').textContent=value+'% de recarga concluída';}
$('#cooldown').addEventListener('input',updateCooldown);updateCooldown();
const maps={xbox:{confirm:'xbox-a',back:'xbox-b',dodge:'xbox-b',maneuver:'xbox-x',skill:'xbox-lb'},ps:{confirm:'ps-cross',back:'ps-circle',dodge:'ps-circle',maneuver:'ps-square',skill:'ps-l1'},keyboard:{confirm:'key-enter',back:'key-escape',dodge:'key-space',maneuver:'key-x',skill:'key-q'},touch:{confirm:'touch-tap',back:'back',dodge:'touch-tap',maneuver:'hold',skill:'touch-tap'}};
window.setKitPlatform=platform=>{
 const map=maps[platform]||maps.xbox;
 for(const img of $$('[data-command]')){img.src='glyphs/'+map[img.dataset.command]+'.svg';img.alt=map[img.dataset.command];}
};
$('#platform').addEventListener('change',e=>window.setKitPlatform(e.target.value));window.setKitPlatform('xbox');
try{
 const response=await fetch('manifest.json');if(!response.ok)throw Error('Manifesto indisponível.');const manifest=await response.json();window.kitManifest=manifest;
 $('#glyphGrid').innerHTML=Object.entries(manifest.glyphs).map(([id,g])=>`<div class="glyph-item"><img src="${g.image}" alt="${id}" loading="lazy"><span>${id}</span></div>`).join('');
 $('#assetGrid').innerHTML=Object.entries(manifest.components).map(([id,c])=>`<div class="asset-item"><div class="asset-art"><img src="${c.image}" alt="${id}" loading="lazy"></div><b>${id}</b><small>${c.width} × ${c.height} px · ${c.mode==='whole'?'proporção preservada':c.mode==='three'?'3 partes':'9 partes'}</small></div>`).join('');
}catch(e){$('#assetGrid').textContent='Abra o catálogo pelo servidor local para carregar o manifesto. Consulte README.md.';console.error(e);}
