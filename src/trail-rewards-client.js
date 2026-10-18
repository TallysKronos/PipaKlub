// Account rewards come exclusively from the server ledger; previews never grant inventory.
let trailResultVersion=0;
async function openTrailSummoner(dropId){
 if(!playerAccount)return;
 closeTrails();closeModal();if(mode)leave();
 await openAccount();if(!playerAccount)return;navigateClub('summon');
}
function showOnlineTrailResult(s,ranking,mine){
 const owner=playerAccount?.profile?.id,match=s.id,version=++trailResultVersion,st=trails.stage(s.trail),won=(mine?.rounds||0)>=s.roundsToWin;
 modal(won?(st.boss?'Chefe derrotado!':'Etapa vencida!'):'Não foi dessa vez.',
 (st.boss?trailLeaderMarkup(trails.trails[st.trailIndex],won?'victory':'ready'):'')+'<p>'+escapeHTML(st.name)+'</p><div id="trailOnlineReward" role="status" aria-live="polite">Conferindo o resultado na sua conta…</div>','Voltar ao mapa do bairro',st.name);
 $('dialogAction').className='secondary';$('dialogAction').onclick=()=>returnToDistrict(s.trail,won);
 let attempts=0;
 const current=()=>version===trailResultVersion&&state?.id===match&&showResult&&playerAccount?.profile?.id===owner&&!!$('trailOnlineReward');
 async function check(){
  if(!current())return;
  try{
   const data=await accountRequest('trail-result',{matchId:match});if(!current())return;
   acceptTrailSnapshot(data.trails,owner);const root=$('trailOnlineReward'),r=data.trails.result;root.replaceChildren();
   root.append(uiElement('p',data.status==='saved'?'✓ Resultado salvo na sua conta.':data.status==='abandoned'?'Partida encerrada sem resultado confirmado.':'Salvando suas conquistas… Você pode voltar ao menu; o servidor continuará tentando.','save-status'));
   if(r){
    const stars=uiElement('div','★'.repeat(r.stars)+'☆'.repeat(3-r.stars),'result-stars');stars.setAttribute('aria-label',r.stars+' de 3 estrelas');root.append(stars);
    root.append(uiElement('p',r.won?'+'+r.coins+' moedas confirmadas'+(r.firstClear?' · bônus da primeira vitória incluído':''):'Tente novamente: o progresso anterior continua na conta.','coin-gain'));
    if(r.drop){const item=ART_CONFIG.items.find(i=>i.id===r.drop),card=uiElement('div',undefined,'drop-reward');if(item){const image=document.createElement('img');image.src=item.url;image.alt=item.name;card.append(image,uiElement('b',item.name+' · recebida na conta'));}root.append(card);}
    if(data.status==='saved'){
     if(r.tailId){const summon=uiElement('button','Ir ao invocador ✦','primary');summon.id='trailGoSummoner';summon.onclick=()=>openTrailSummoner(r.drop);root.append(summon);}
     const next=r.won&&trails.nextStage(s.trail),again=uiElement('button',r.won?'Ver meu caminho ▶':'Tentar de novo ↻','secondary');again.id='rematchButton';again.onclick=()=>{if(r.won)returnToDistrict(s.trail,true);else{returnToDistrict(s.trail,false);presentStage(s.trail);}};root.append(again);return;
    }
   }
   if(data.status!=='abandoned'&&++attempts<12)setTimeout(check,1500);else addRetry(root);
  }catch(e){if(!current())return;const root=$('trailOnlineReward');root.replaceChildren(uiElement('p','Não conseguimos conferir agora. O servidor mantém a entrega pendente. '+e.message));addRetry(root);}
 }
 function addRetry(root){const retry=uiElement('button','Conferir novamente','secondary');retry.onclick=()=>{attempts=0;check();};root.append(retry);}
 check();
}
