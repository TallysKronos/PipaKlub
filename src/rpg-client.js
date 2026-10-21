// Authenticated progression and encounters. The client never chooses drops or grants XP.
let rpgEpoch=0,rpgOwner=null,classBusy=false,wildBusy=false,wildDistance=0,wildThreshold=1900,wildGrace=0,wildReturn=null,wildResultEpoch=0;
let wildReturnAction=null;
const beforeRpgCloseModal=closeModal;closeModal=function(){if(wildReturnAction){const action=wildReturnAction;wildReturnAction=null;action();return;}return beforeRpgCloseModal();};$('close').onclick=()=>closeModal();
homeActions.classes=()=>homeActions.collection();
homeActions.park=()=>{hideJourney();closeHomeMenu();openWorld('park-trail');};
homeActions.wildGuide=()=>dialogue('Parque dos Ventos','Procure Pipamons no capim alto. O caminho de terra e o banco são seguros. Vitória desenvolve seu parceiro e pode render a rabiola da espécie. A primeira vitória garante uma rabiola; depois, no máximo sete vitórias seguidas ficam sem rabiola. Você pode fugir sem perder seu parceiro.','Voltar à exploração',hideJourney,{later:true});
homeActions.wildRest=()=>{wildGrace=Date.now()+12000;wildDistance=0;dialogue('Um lugar para respirar','Aqui não há encontros. Seus parceiros estão protegidos. Se perder um duelo selvagem, você volta ao apoio do parque; XP e rabiolas só são concedidos na vitória.','Continuar explorando',hideJourney,{later:true});};
function stepWildExploration(before,time){
 const id=worldRuntime.id;if(!id.startsWith('park-')||wildBusy||!worldWalkActive())return;
 const actor=worldState().actor,moved=Math.hypot(actor.x-before.x,actor.y-before.y);if(!moved)return;
 const rectangles=worldScene().tiled.layers.Walkable,inside=r=>actor.x>=r.x&&actor.x<=r.x+r.w&&actor.y>=r.y&&actor.y<=r.y+r.h;
 if(rectangles.some(r=>r.properties.safe_area&&inside(r)))return;if(Date.now()<wildGrace)return;
 if(!rectangles.some(r=>r.properties.encounter_zone===id&&inside(r)))return;
 wildDistance+=moved;if(wildDistance>=wildThreshold){wildDistance=0;wildThreshold=1900+Math.random()*1000;startWildEncounter(id);}
}
async function startWildEncounter(zone){
 if(wildBusy||mode||!playerAccount||worldRuntime.id!==zone)return;wildBusy=true;const owner=playerAccount.profile.id,epoch=rpgEpoch;worldClearWalking();worldState().actor.path=[];wildReturn={scene:zone,...campaignCheckpoint()};
 const gate=gameLoading.start('wild','O vento trouxe um encontro',{retry:()=>startWildEncounter(zone),back:()=>{gate.cancel();wildGrace=Date.now()+12000;}});
 try{const d=await request('wild',{zone});if(owner!==playerAccount?.profile.id||epoch!==rpgEpoch){gate.cancel();return;}token=d.token;await Promise.all(d.state.players.map(p=>art.load(p.soul||art.basic(p.color))));enter(d.state,d.me,'online',d.code);$('roomChip').hidden=true;await gate.done();}
 catch(e){gate.fail(e.message);}finally{wildBusy=false;}
}
async function recoverWildEncounter(){
 if(!playerAccount||mode)return;const owner=playerAccount.profile.id,epoch=rpgEpoch;
 try{const d=await accountRequest('wild',{});if(owner!==playerAccount?.profile.id||epoch!==rpgEpoch||mode)return;const pending=d.wild.pending;if(!pending)return;
  const seat=roomSessions.read(pending.code,owner);dialogue('Seu encontro está pendente',seat?'Você pode retomar a mesma batalha. O encontro e o sorteio de recompensa permanecem os mesmos.':'O encontro anterior ficou sem conexão. Encerre-o sem recompensas para continuar explorando.',seat?'Retomar encontro':'Encerrar sem recompensa',async()=>{try{if(seat){const data=await request('resume',{code:pending.code,token:seat.token});token=data.token;wildReturn={scene:pending.zone};hideJourney();enter(data.state,data.me,'online',data.code);}else{const data=await accountRequest('wild-abandon',{matchId:pending.matchId});playerAccount=data.account;reflectAccount();hideJourney();wildGrace=Date.now()+12000;}}catch(e){toast(e.message);}},{later:true});
 }catch(e){toast(e.message);}
}
homeActions.wildResume=recoverWildEncounter;
const fleeWildButton=uiElement('button','Fugir do encontro · F','wild-flee');fleeWildButton.id='wildFlee';fleeWildButton.hidden=true;document.body.append(fleeWildButton);
async function fleeWild(){if(wildBusy||mode!=='online'||!state?.wild||showResult)return;wildBusy=true;try{const d=await request('flee',{code:room,token});state=d.state;keys={};resetPointer();showResult=true;showWildResult(state,state.players.find(p=>p.id===me));}catch(e){toast(e.message);}finally{wildBusy=false;}}
fleeWildButton.onclick=fleeWild;addEventListener('keydown',e=>{if(e.key.toLowerCase()==='f'&&!e.repeat&&mode==='online'&&state?.wild&&!showResult&&!e.target?.closest('input,textarea')){e.preventDefault();fleeWild();}});
const pauseFlee=uiElement('button','Fugir do encontro · sem recompensa');pauseFlee.id='wildPauseFlee';pauseFlee.hidden=true;$('pauseTools').append(pauseFlee);pauseFlee.onclick=()=>{closeSheet();fleeWild();};
const beforeWildEnter=enter;enter=function(...args){const result=beforeWildEnter(...args);pauseFlee.hidden=fleeWildButton.hidden=!args[0]?.wild;return result;};
const beforeWildLeave=leave;leave=function(...args){pauseFlee.hidden=fleeWildButton.hidden=true;return beforeWildLeave(...args);};
function showWildResult(s,mine){
 fleeWildButton.hidden=true;const epoch=++wildResultEpoch,owner=playerAccount?.profile.id,won=(mine?.rounds||0)>=s.roundsToWin;let confirmed=null;
 modal(won?'Encontro vencido!':'Fim do encontro','<p id="wildResultStatus" role="status">Conferindo o resultado no servidor…</p><div id="wildReward"></div>','Voltar ao parque','Parque dos Ventos');
 const returnToPark=()=>{wildResultEpoch++;wildReturnAction=null;beforeRpgCloseModal();if(mode)leave();const lost=confirmed?.status==='lost'||!confirmed&&mine?.hp<=0,scene=lost?'park-trail':wildReturn?.scene||s.wild.zone;openWorld(scene);if(lost){const current=worldState();current.actor=current.navigation.create();}else if(wildReturn?.x!=null&&wildReturn.scene===scene){const current=worldState();current.navigation.target(current.actor,wildReturn,true);}wildGrace=Date.now()+12000;wildDistance=0;};
 wildReturnAction=returnToPark;$('dialogAction').onclick=returnToPark;
 let attempts=0;async function check(){if(epoch!==wildResultEpoch||owner!==playerAccount?.profile.id)return;try{const d=await accountRequest('wild',{matchId:s.id});if(epoch!==wildResultEpoch)return;const r=d.wild.result;if(!r){$('wildResultStatus').textContent='Salvando resultado… Você pode voltar; o servidor continuará tentando.';if(++attempts<15)setTimeout(check,1200);return;}confirmed=r;playerAccount=d.account;reflectAccount();$('wildResultStatus').textContent=r.status==='won'?'✓ Vitória confirmada.':r.status==='fled'?'Você fugiu. Seu parceiro e seus itens estão protegidos.':r.status==='lost'?'Seu parceiro está bem. Você voltará ao apoio do parque.':'Encontro encerrado sem recompensas.';const root=$('wildReward');root.replaceChildren();for(const item of r.classItems||[])root.append(uiElement('p','Item de classe recebido: '+(classItemNames[item]||item)+'!','class-item-reward'));root.append(uiElement('p','+'+r.pipamonXp+' XP do parceiro · +'+r.tamerXp+' XP do tamer'));if(r.tailId){const entry=ART_CONFIG.dex.entries.find(e=>e.model===r.modelId),card=uiElement('div',undefined,'wild-tail'),item=ART_CONFIG.items.find(i=>i.pipamon===entry?.id);if(item){const im=document.createElement('img');im.src=item.url;im.alt=item.name;card.append(im);}card.append(uiElement('b','Rabiola de '+(entry?.name||r.modelId)+' recebida!'),uiElement('p',r.firstTail?'Sua primeira rabiola. Leve ao professor para invocar.':'Leve ao professor para tentar uma invocação.'));root.append(card);}}
 catch(e){if(epoch===wildResultEpoch){$('wildResultStatus').textContent=e.message;if(++attempts<15)setTimeout(check,1800);}}}check();
}
const rpgAccountChange=onCourtyardAccount;onCourtyardAccount=async function(){const owner=playerAccount?.profile.id||null,changed=owner!==rpgOwner;if(changed){rpgOwner=owner;rpgEpoch++;classBusy=false;wildBusy=false;wildDistance=0;wildGrace=Date.now()+10000;wildResultEpoch++;if(typeof resetClassConstellation==='function')resetClassConstellation();fleeWildButton.hidden=true;}await rpgAccountChange();if(changed&&owner&&owner===playerAccount?.profile.id&&!mode)await recoverWildEncounter();};
