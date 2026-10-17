// Poll only while the authenticated collection is visible; server owns all state.
let currentTrade=null,tradeBusy=false,tradeSelection='';
const tradePanel=document.createElement('section');
tradePanel.innerHTML='<h3>Trocas por convite · 1 por 1</h3><p>Convide um amigo. Cada um oferece uma colecionável e confirma as duas ofertas. Alterar uma oferta desfaz ambas as confirmações. A sala expira em 10 minutos.</p><button class="secondary" id="tradeCreate">Criar convite</button><label for="tradeCode">Código do convite</label><input id="tradeCode" maxlength="12" autocomplete="off"><button class="secondary" id="tradeJoin">Entrar</button><div id="tradeState" role="status" aria-live="polite"></div><div id="tradeActions"></div><button class="secondary" id="tradeHistory">Histórico de trocas</button><div id="tradeHistoryList"></div>';
$('collectionMain').insertBefore(tradePanel,$('inventoryList'));
async function tradeAction(action,extra={}){
 if(tradeBusy||!playerAccount)return;tradeBusy=true;renderTrade();
 try{const d=await accountRequest('trade',{action,code:currentTrade?.code,revision:currentTrade?.revision,...extra});
  if(action==='history'){$('tradeHistoryList').replaceChildren(...d.trade.map(t=>uiElement('p',t.code+' · '+tradeStatus(t.status)+' · '+new Date(t.created_at).toLocaleString()+(t.receipt?' · '+t.receipt.hostName+': '+t.receipt.hostKite.name+' ↔ '+t.receipt.guestName+': '+t.receipt.guestKite.name:''))));}
  else {const before=currentTrade?.status;if(action!=='read')tradeSelection='';currentTrade=d.trade;renderTrade();if(currentTrade?.status==='completed'&&before!=='completed')await refreshAccount();}
 }catch(e){$('accountMessage').textContent=e.message;}
 finally{tradeBusy=false;renderTrade();}
}
function tradeStatus(status){return ({open:'Em negociação',completed:'Concluída',cancelled:'Cancelada',expired:'Expirada'})[status]||status;}
function renderTrade(){
 const t=currentTrade,open=t?.status==='open';$('tradeCreate').disabled=tradeBusy||open;$('tradeJoin').disabled=tradeBusy||open;
 const state=$('tradeState');state.replaceChildren();const actions=$('tradeActions');actions.replaceChildren();
 if(!t)return;
 state.append(uiElement('p','Convite '+t.code+' · '+tradeStatus(t.status)));
 if(!open)return;
 state.append(uiElement('p','Expira às '+new Date(t.expiresAt).toLocaleTimeString()));
 state.append(uiElement('p',(t.hostName||'Anfitrião')+': '+(t.hostKite?.name||'Sem oferta')+(t.hostConfirmed?' · Confirmado':'')));
 state.append(uiElement('p',(t.guestName||'Aguardando amigo')+': '+(t.guestKite?.name||'Sem oferta')+(t.guestConfirmed?' · Confirmado':'')));
 const select=document.createElement('select');select.setAttribute('aria-label','Sua pipa para troca');
 const blank=document.createElement('option');blank.value='';blank.textContent='Escolha uma colecionável';select.append(blank);
 for(const k of playerAccount?.inventory||[]){if(k.permanent||k.model.acquisition==='event')continue;const o=document.createElement('option');o.value=k.id;o.textContent=k.model.name+' · '+k.id.slice(0,8);select.append(o);}
 select.value=tradeSelection||(t.isHost?t.hostKite:t.guestKite)?.id||'';
 select.onchange=()=>{tradeSelection=select.value;};
 select.disabled=tradeBusy;actions.append(select);
 const button=(label,action,disabled=false)=>{const b=uiElement('button',label,'secondary');b.type='button';b.disabled=tradeBusy||disabled;b.onclick=action;actions.append(b);};
 button('Oferecer pipa',()=>tradeAction('offer',{kiteId:select.value}),false);
 button('Confirmar as duas ofertas',()=>tradeAction('confirm'),!t.hostKite||!t.guestKite||(t.isHost?t.hostConfirmed:t.guestConfirmed));
 button('Cancelar troca',()=>tradeAction('cancel'));
}
$('tradeCreate').onclick=()=>tradeAction('create',{code:null});
$('tradeJoin').onclick=()=>tradeAction('join',{code:$('tradeCode').value.trim().toUpperCase()});
$('tradeHistory').onclick=()=>tradeAction('history');
setInterval(()=>{if(playerAccount&&accountModal.style.display==='flex')tradeAction('read',{code:currentTrade?.status==='open'?currentTrade.code:null});else if(!playerAccount){currentTrade=null;tradeSelection='';$('tradeHistoryList').replaceChildren();renderTrade();}},3000);
