// Condition is authoritative on the server; these views never submit durability values.
let guardUntil=0;
let careDialogueVersion=0;
const careHideJourney=hideJourney;hideJourney=function(...args){careDialogueVersion++;return careHideJourney(...args);};
addEventListener('blur',()=>{guardUntil=0;});document.addEventListener('visibilitychange',()=>{guardUntil=0;});
function kiteCondition(kite){return {line:kite?.condition?.line??100,hull:kite?.condition?.hull??100};}
function kiteBroken(kite){const c=kiteCondition(kite);return c.line<=0||c.hull<=0;}
function equippedNeedsRepair(){const k=playerAccount?.inventory.find(k=>k.id===playerAccount.profile.equipped_kite_id);return k&&kiteBroken(k);}
function queueGuard(){const p=mode&&ownKite();if(!p||!battleLive()||p.respawn||p.guardCooldown>0||p.lineMove||p.evade>0)return;guardUntil=Date.now()+180;}
const fanGuard=fanButton('guard','Guarda','battle-skill',[]);
fanGuard.querySelector('.fan-icon').remove();
fanGuard.insertAdjacentHTML('afterbegin','<svg class="fan-guard-icon" viewBox="0 0 64 64" aria-hidden="true"><path d="M32 6 53 15 50 35Q45 49 32 58 19 49 14 35L11 15Z" fill="#71d9d0" stroke="#ffe3a0" stroke-width="3"/><path d="M32 15V47M20 24 32 19 44 24" fill="none" stroke="#184952" stroke-width="4"/></svg>');
const guardKey=uiElement('span','G','guard-key');fanGuard.querySelector('.fan-glyphs').append(guardKey);
const guardNote=uiElement('small','','duel-action-cost');fanGuard.append(guardNote);fan.append(fanGuard);holdPointer(fanGuard,queueGuard);
function updateGuardButton(p,blocked){
 const remaining=p.guardCooldown||0;setRing(fanGuard,remaining,eng.GUARD.cooldown,blocked||remaining>0||!!p.lineMove||p.evade>0);
 const text=blocked?'Aguarde':p.guardTime>0?'Protegido':remaining>0?Math.ceil(remaining)+' s':'0,5 s · impacto';
 if(guardNote.textContent!==text)guardNote.textContent=text;
 fanGuard.setAttribute('aria-disabled',String(blocked||remaining>0||!!p.lineMove||p.evade>0));fanGuard.setAttribute('aria-label','Guarda · '+text+' · G ou gatilho esquerdo');
 fanGuard.classList.toggle('is-held',p.guardTime>0);guardKey.textContent=inputDevice.startsWith('gamepad')?'LT / L2':'G';
}
addEventListener('keydown',e=>{if(e.key.toLowerCase()==='g'&&!e.repeat&&!e.target?.closest('input,textarea,select,[contenteditable=true]')&&battleLive()){e.preventDefault();queueGuard();}});
for(const side of ['you','rival']){
 const panel=duelHud.querySelector('.duel-partner.duel-'+side),row=panel.querySelector('.duel-line').cloneNode(true);row.className='duel-hull';row.querySelector('span').textContent='Armação';row.querySelector('[role=meter]').setAttribute('aria-label','Integridade da armação');panel.querySelector('.duel-line').after(row);
}
const careBattleUpdate=updateCinematicBattle;
const guardianHull=duelHud.querySelector('.duel-hull').cloneNode(true);guardianHull.classList.add('guardian-hull');guardianHull.querySelector('[role=meter]').setAttribute('aria-label','Armação do guardião');guardianHud.querySelector('.guardian-vital').after(guardianHull);const guardianLineLabel=uiElement('small','LINHA','guardian-line-label');guardianHud.querySelector('.guardian-vital').before(guardianLineLabel);
function paintHull(row,q){const max=q.hullMax||eng.pipamonStats(q).line,percent=Math.max(0,Math.min(100,(q.hull??max)/max*100));row.querySelector('[role=meter]').setAttribute('aria-valuenow',String(Math.ceil(percent)));row.querySelector('i').style.width=percent+'%';row.querySelector('strong').textContent=Math.ceil(percent)+'%';row.dataset.danger=String(percent<=30);}
updateCinematicBattle=function(p){careBattleUpdate(p);if(!cinematicBattleActive())return;for(const [side,q]of [['you',p],['rival',(renderPlayers||state.players).find(q=>q.id!==me)]]){if(!q)continue;paintHull(duelHud.querySelector('.duel-partner.duel-'+side+' .duel-hull'),q);if(q.bossId)paintHull(guardianHull,q);}};
const careBattleDraw=drawGuardianBattle;
const careBodyStatus=uiElement('div','','care-body-status');careBodyStatus.setAttribute('role','meter');careBodyStatus.setAttribute('aria-label','Integridade da armação');careBodyStatus.setAttribute('aria-valuemin','0');careBodyStatus.setAttribute('aria-valuemax','100');$('hud').append(careBodyStatus);
const careHudUpdate=updateBattleHUD;updateBattleHUD=function(p){careHudUpdate(p);careBodyStatus.hidden=!p||cinematicBattleActive();if(!p||careBodyStatus.hidden)return;const max=p.hullMax||eng.pipamonStats(p).line,value=Math.max(0,Math.ceil((p.hull??max)/max*100));careBodyStatus.textContent='Armação '+value+'% · Guarda G';careBodyStatus.setAttribute('aria-valuenow',String(value));};
drawGuardianBattle=function(time){careBattleDraw(time);if(!mode||!state)return;for(const p of renderPlayers||state.players){if(!(p.guardTime>0||p.guardFlash>0)||p.respawn)continue;ctx.save();ctx.strokeStyle=p.guardFlash>0?'#ffdf8d':'#85ece5';ctx.fillStyle='#63dad322';ctx.lineWidth=p.guardFlash>0?6:3;ctx.beginPath();ctx.arc(p.x,p.y,46,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.restore();}};
const careSelectInventory=selectInventory;
selectInventory=function(kite){const result=careSelectInventory(kite),c=kiteCondition(kite),root=$('pilotPartnerSummary')||$('inventoryDetails');root.querySelector('.kite-condition')?.remove();const note=uiElement('p','Condição · Linha '+c.line+'% · Armação '+c.hull+'%'+(kiteBroken(kite)?' — precisa de reparo com o professor.':c.line<100||c.hull<100?' — o professor pode reparar gratuitamente.':' — pronta para voar.'),'kite-condition');note.dataset.broken=String(kiteBroken(kite));root.append(note);return result;};
function goProfessorForCare(){if(mode)return;pilotReturn=null;closeModal();closeHomeMenu();hideJourney();wildGrace=Date.now()+15000;wildDistance=0;if(worldRuntime.id!=='professor-home')openWorld('professor-home');showProfessorCare();}
function offerKiteRepair(){
 const healthy=playerAccount?.inventory.some(k=>!kiteBroken(k));wildGrace=Date.now()+15000;wildDistance=0;
 dialogue('Sua pipa precisa de cuidado','Seu parceiro está preservado. A linha ou a armação chegou ao limite. '+(healthy?'Você pode equipar outro parceiro na coleção ou voltar para consertar suas pipas.':'Vamos voltar ao Sr. Assis para consertar suas pipas. O reparo é gratuito.'),'Voltar ao professor',goProfessorForCare,{later:true});
 if(healthy){const b=uiElement('button','Escolher outro parceiro','secondary');b.classList.add('care-choice');b.onclick=()=>{hideJourney();homeActions.collection();};$('journeyDialog').querySelector('.journey-actions').prepend(b);}
}
async function showProfessorCare(){
 if(mode||worldRuntime.id!=='professor-home'||!playerAccount)return;const owner=playerAccount.profile.id;
 dialogue('Vamos cuidar das suas pipas','Vou conferir a linha e a armação de todos os seus parceiros.','Conferindo…',()=>{},{later:true});const view=careDialogueVersion;$('journeyContinue').disabled=true;
 try{
  const d=await accountRequest('kite-care',{action:'read'});if(view!==careDialogueVersion||owner!==playerAccount?.profile.id||worldRuntime.id!=='professor-home')return;playerAccount=d.account;reflectAccount();
  const damaged=playerAccount.inventory.filter(k=>{const c=kiteCondition(k);return c.line<100||c.hull<100;});
  if(!damaged.length){dialogue('Prontas para voar!','Todas as linhas e armações estão inteiras. Pode contar comigo quando precisar de reparos.','Obrigado, professor',hideJourney,{later:true});return;}
  const names=damaged.slice(0,4).map(k=>{const c=kiteCondition(k);return (k.personal_name||k.model.name)+': linha '+c.line+'%, armação '+c.hull+'%';}).join(' · ');
  dialogue('Uma nova chance de voar',names+(damaged.length>4?' · e mais '+(damaged.length-4)+' parceiros.':'.')+' Vou reparar todos sem cobrar moedas.','Consertar minhas pipas',async()=>{
   const repairView=careDialogueVersion;$('journeyContinue').disabled=true;$('journeyStatus').textContent='Reparando suas pipas…';
   try{const saved=await accountRequest('kite-care',{action:'repair'});if(owner!==playerAccount?.profile.id)return;playerAccount=saved.account;reflectAccount();if(repairView===careDialogueVersion)dialogue('Prontas para voar!','Linha renovada, armação inteira. Seus parceiros continuam com os mesmos níveis, bônus e histórias.','Obrigado, professor',hideJourney,{later:true});}
   catch(e){if(repairView===careDialogueVersion)$('journeyStatus').textContent=e.message;}finally{if(repairView===careDialogueVersion)$('journeyContinue').disabled=false;}
  },{later:true});
 }catch(e){if(view===careDialogueVersion){$('journeyStatus').textContent=e.message;$('journeyContinue').textContent='Tentar novamente';$('journeyContinue').onclick=showProfessorCare;}}
 finally{if(view===careDialogueVersion)$('journeyContinue').disabled=false;}
}
const careDialogue=dialogue;
dialogue=function(...args){for(const b of $('journeyDialog').querySelectorAll('.care-choice'))b.remove();$('journeyContinue').disabled=false;return careDialogue(...args);};
const careProfessor=homeActions.professor;
homeActions.professor=function(){careProfessor();if(mode||!playerAccount)return;const b=uiElement('button','Cuidar das minhas pipas','secondary');b.classList.add('care-choice');b.onclick=showProfessorCare;$('journeyDialog').querySelector('.journey-actions').prepend(b);if($('journeyDialog').hidden)showProfessorCare();};
const schoolCare=uiElement('button','Cuidar das minhas pipas','secondary');schoolCare.onclick=()=>{pilotReturn=null;closeSchool();goProfessorForCare();};schoolHub.querySelector('.school-links').append(schoolCare);
const careWildEncounter=startWildEncounter;
startWildEncounter=async function(zone){if(!mode&&equippedNeedsRepair()){worldClearWalking();offerKiteRepair();return;}return careWildEncounter(zone);};
const carePresentStage=presentStage;
presentStage=function(id){if(!mode&&equippedNeedsRepair()){pilotReturn=null;closeTrails();offerKiteRepair();return;}const result=carePresentStage(id);if($('modal').classList.contains('encounter-preview')){$('dialogBody').append(uiElement('p','Pipa por perto: ataque (Espa\u00e7o) para atingir a arma\u00e7\u00e3o. Encostar sem atacar n\u00e3o causa dano. Cortes gastam a linha. Se a arma\u00e7\u00e3o quebrar, o encontro termina. Use Guarda (G) por 0,5 s para bloquear impactos; recarga de 20 s. O professor repara suas pipas gratuitamente.','encounter-care-rule'));}return result;};
