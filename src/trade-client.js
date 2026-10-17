// Poll only while the authenticated collection is visible; server owns all state.
let currentTrade=null,tradeBusy=false,tradeSelection='',tradeAnimating=false,lastCompletedTrade=null,tradeFlightTimer;
const tradePanel=document.createElement('section');
tradePanel.className='trade-panel';
tradePanel.innerHTML='<h3>Encontro nas estrelas</h3><p class="trade-intro">Uma pipa de cada lado. Dois novos caminhos pelo céu.</p><div id="tradeScene" class="trade-scene"><div class="trade-nebula" aria-hidden="true"></div><div class="trade-stars" aria-hidden="true">✦ · ˚ 　 ✧ 　　 · ✦ 　 ˚ · 　 ✧</div><div class="trade-scene-heading"><small>CLUBE DAS TROCAS · 1 POR 1</small><h4 id="tradeSceneTitle">O céu conecta vocês</h4><p id="tradeSceneHint">Convide um amigo para começar.</p></div><div id="tradeFlights" class="trade-flights"></div><div class="trade-horizon" aria-hidden="true"></div></div><button class="secondary" id="tradeReplay" hidden>Rever o encontro</button><p class="trade-intro">Escolham suas colecionáveis e confirmem as duas ofertas. Uma alteração desfaz as confirmações. O convite dura 10 minutos.</p><button class="secondary" id="tradeCreate">Criar convite</button><label for="tradeCode">Código do convite</label><input id="tradeCode" maxlength="12" autocomplete="off"><button class="secondary" id="tradeJoin">Entrar</button><div id="tradeState" role="status" aria-live="polite"></div><div id="tradeActions"></div><button class="secondary" id="tradeHistory">Histórico de trocas</button><div id="tradeHistoryList"></div>';
$('collectionMain').insertBefore(tradePanel,$('inventoryList'));
const convergence=uiElement('div',undefined,'trade-convergence');convergence.setAttribute('aria-hidden','true');$('tradeScene').append(convergence);
const shockwave=uiElement('div',undefined,'trade-shockwave');shockwave.setAttribute('aria-hidden','true');$('tradeScene').append(shockwave);
const burst=uiElement('div',undefined,'trade-burst');burst.setAttribute('aria-hidden','true');
for(let i=0;i<16;i++){
 const spark=uiElement('i',undefined,'trade-burst-spark'),angle=i*Math.PI/8;
 spark.style.setProperty('--bx',Math.round(Math.cos(angle)*140)+'px');spark.style.setProperty('--by',Math.round(Math.sin(angle)*95)+'px');spark.style.setProperty('--spin',i*27+'deg');burst.append(spark);
}
$('tradeScene').append(burst);
function tradeKiteArt(k){
 const image=uiElement('div',undefined,'trade-kite-art');
 if(!k){image.textContent='?';return image;}
 const color=Number.isInteger(k.color)?k.color:({ 'Mata verde':1,'Azulão':2,'Raio de sol':3 })[k.name]??0;
 if(typeof art!=='undefined')image.innerHTML=art.markup(color);
 else image.textContent='◇';
 return image;
}
function paintTradeScene(t,completed=false){
 const flights=$('tradeFlights');flights.replaceChildren();
 for(const side of ['host','guest']){
  const k=t?.[side+'Kite'],name=t?.[(completed?(side==='host'?'guest':'host'):side)+'Name']||(side==='host'?'Você':'Seu amigo');
  const flight=uiElement('div',undefined,'trade-flight trade-flight-'+side);
  flight.append(tradeKiteArt(k),uiElement('span',undefined,'trade-orb'));
  const comet=uiElement('span',undefined,'trade-comet');comet.setAttribute('aria-hidden','true');comet.append(uiElement('span',undefined,'trade-comet-frames'));flight.append(comet);
  const motes=uiElement('div',undefined,'trade-motes');motes.setAttribute('aria-hidden','true');
  for(let i=0;i<12;i++){
   const mote=uiElement('i',undefined,'trade-mote'),angle=i*2.4;
   mote.style.setProperty('--dx',Math.round(Math.cos(angle)*(24+i*3))+'px');mote.style.setProperty('--dy',(35+i*6)+'px');mote.style.setProperty('--delay',(i*.12)+'s');mote.style.setProperty('--size',(12+i%4*5)+'px');motes.append(mote);
  }
  flight.append(motes);
  const caption=uiElement('div',undefined,'trade-flight-caption');
  caption.append(uiElement('b',k?.name||'Escolha uma pipa'),uiElement('small',name));
  flight.append(caption);flights.append(flight);
 }
 $('tradeSceneTitle').textContent=completed?'Novos ventos, novas histórias':t?.hostKite&&t?.guestKite?'Prontas para um novo caminho':'Duas pipas, um encontro';
 $('tradeSceneHint').textContent=completed?'Troca concluída. As pipas já estão nas novas coleções.':t?.hostKite&&t?.guestKite?'Confiram as ofertas e confirmem dos dois lados.':'Cada participante oferece uma colecionável.';
}
function playTradeFlight(t,forceMotion=false){
 if(!t?.hostKite||!t?.guestKite)return;
 clearTimeout(tradeFlightTimer);lastCompletedTrade=t;tradeAnimating=true;
 const reduced=!forceMotion&&typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches;
 const scene=$('tradeScene');scene.classList.remove('is-flying','trade-landed');paintTradeScene(t);
 scene.classList.toggle('trade-motion',forceMotion);
 $('tradeSceneTitle').textContent='Um encontro entre estrelas';
 $('tradeSceneHint').textContent='Troca confirmada! As pipas seguem para seus novos donos.';
 $('tradeReplay').hidden=true;
 // A fresh layout restarts only this decorative animation, never the transfer.
 if(!reduced){void scene.offsetWidth;scene.classList.add('is-flying');}
 scene.scrollIntoView?.({behavior:reduced?'instant':'smooth',block:'center'});
 const finish=()=>{tradeAnimating=false;scene.classList.remove('is-flying');scene.classList.add('trade-landed');paintTradeScene(t,true);$('tradeReplay').textContent=reduced?'Ver com animação':'Rever o encontro';$('tradeReplay').hidden=false;renderTrade();};
 if(reduced)finish();else tradeFlightTimer=setTimeout(finish,7200);
}
async function tradeAction(action,extra={}){
 if(tradeBusy||tradeAnimating||!playerAccount)return;tradeBusy=true;renderTrade();
 try{const d=await accountRequest('trade',{action,code:currentTrade?.code,revision:currentTrade?.revision,...extra});
  if(action!=='read')$('accountMessage').textContent='';
  if(action==='history'){$('tradeHistoryList').replaceChildren(...d.trade.map(t=>{
   const row=uiElement('div',undefined,'trade-receipt');
   row.append(uiElement('p',t.code+' · '+tradeStatus(t.status)+' · '+new Date(t.created_at).toLocaleString()+(t.receipt?' · '+t.receipt.hostName+': '+t.receipt.hostKite.name+' ↔ '+t.receipt.guestName+': '+t.receipt.guestKite.name:'')));
   if(t.status==='completed'&&t.receipt){const replay=uiElement('button','Rever encontro','secondary');replay.type='button';replay.onclick=()=>{if(!tradeAnimating)playTradeFlight({...t.receipt,code:t.code,status:'completed'},true);};row.append(replay);}
   return row;
  }));}
  else {const previous=currentTrade;if(action!=='read')tradeSelection='';currentTrade=d.trade?{...(previous?.code===d.trade.code?previous:{}),...d.trade}:null;renderTrade();if(currentTrade?.status==='completed'&&previous?.status==='open'){playTradeFlight(currentTrade);await refreshAccount();}}
 }catch(e){$('accountMessage').textContent=e.message;}
 finally{tradeBusy=false;renderTrade();}
}
function tradeStatus(status){return ({open:'Em negociação',completed:'Concluída',cancelled:'Cancelada',expired:'Expirada'})[status]||status;}
function renderTrade(){
 const t=currentTrade,open=t?.status==='open';$('tradeCreate').disabled=tradeBusy||tradeAnimating||open;$('tradeJoin').disabled=tradeBusy||tradeAnimating||open;
 if(!tradeAnimating){if(open){$('tradeScene').classList.remove('trade-landed');paintTradeScene(t);$('tradeReplay').hidden=true;}else if(!lastCompletedTrade)paintTradeScene(t);}
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
$('tradeReplay').onclick=()=>playTradeFlight(lastCompletedTrade,true);
setInterval(()=>{if(playerAccount&&accountModal.style.display==='flex'&&(typeof accountPage==='undefined'||accountPage==='trades'))tradeAction('read',{code:currentTrade?.status==='open'?currentTrade.code:null});else if(!playerAccount){clearTimeout(tradeFlightTimer);tradeAnimating=false;currentTrade=null;lastCompletedTrade=null;tradeSelection='';$('tradeReplay').hidden=true;$('tradeScene').classList.remove('is-flying','trade-landed');$('tradeHistoryList').replaceChildren();renderTrade();}},3000);
paintTradeScene(null);
