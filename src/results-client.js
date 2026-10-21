let resultContext=null,resultTimer=null,resultVersion=0,storyVersion=0;
const resultDate=value=>new Intl.DateTimeFormat('pt-BR',{dateStyle:'short',timeStyle:'short'}).format(new Date(value));
function uiElement(tag,text,className){const el=document.createElement(tag);if(text!==undefined)el.textContent=text;if(className)el.className=className;return el;}
function stopMatchResult(){resultContext=null;resultVersion++;clearTimeout(resultTimer);}
function showMatchResult(s,ranking=[]){if(!s.trail)track(s.quick?'quick_match_end':mode==='online'?'online_match_end':'practice_end');
 stopMatchResult();
 const mine=s.players?.find(p=>p.id===me),authenticated=mode==='online'&&!!playerAccount;
 const rounds=s.mode==='rounds',rows=ranking.map((q,i)=>'<div class="result-rank'+(q.id===me?' me':'')+'"><span><i class="result-dot" style="background:'+playerColor(q)+'"></i>'+(i+1)+'. '+playerTag(q)+' '+escapeHTML(q.name)+(q.id===me?' · você':'')+'</span><b>'+(rounds?(q.rounds||0)+' ★ · ':'')+q.score+' pts</b></div>').join('');
 if(s.wild){showWildResult(s,mine);return;}
 if(s.daily){showDailyResult(s,mine);return;}
 if(s.trail&&mode==='online'){showOnlineTrailResult(s,ranking,mine);return;}
 if(s.trail&&mode==='practice'){showTrailResult(s,ranking,mine);return;}
 const place=ranking.findIndex(q=>q.id===me)+1,cuts=mine?.cuts||0;
 modal(place===1?'O céu é seu!':'Cada duelo deixa uma história.',
  (place?'<p class="result-place">Você ficou em '+place+'º de '+ranking.length+'</p>':'')+'<p>'+(rounds?'Rodadas vencidas: '+(mine?.rounds||0)+' · ':'')+'Seus cortes: '+cuts+'.</p><div id="matchRewardSummary" class="match-rewards" aria-live="polite"></div>'+rows+'<button class="primary" id="rematchButton">'+(s.quick?'Nova partida rápida ▶':mode==='online'?'Revanche com a turma ↻':'Jogar de novo ↻')+'</button>','Voltar ao menu','Resultado do duelo');
 $('rematchButton').onclick=rematch;$('dialogAction').className='secondary';$('rematchButton').focus({preventScroll:true});
 if(!authenticated){$('matchRewardSummary').append(uiElement('p',mode==='practice'?'O treino não altera XP nem a coleção.':'Como visitante, você participa da disputa sem salvar XP ou conquistar pipas. Entre na sua conta para guardar seu progresso.'));return;}
 beginMatchResult(s.id);
}
function beginMatchResult(matchId){
 stopMatchResult();resultContext={matchId,version:resultVersion,attempts:0};
 $('matchRewardSummary').replaceChildren(uiElement('p','Conferindo suas conquistas…','save-status'));
 loadMatchResult();
}
async function loadMatchResult(){
 const ctx=resultContext;if(!ctx)return;clearTimeout(resultTimer);
 try{
  const data=await accountRequest('match-result',{matchId:ctx.matchId});if(resultContext!==ctx)return;
  renderMatchResult(data);
  if(data.status==='saved'){refreshRewards();return;}
  if(data.status!=='playing'&&data.status!=='unconfirmed'&&++ctx.attempts<12)resultTimer=setTimeout(loadMatchResult,Math.min(6000,1000+ctx.attempts*500));
 }catch(e){if(resultContext!==ctx)return;const root=$('matchRewardSummary');root.replaceChildren(uiElement('p','Não conseguimos consultar seu resultado agora. Seus dados confirmados continuam na conta.','save-status'),uiElement('p',e.message));addResultRetry(root);}
}
function addResultRetry(root){const retry=uiElement('button','Conferir novamente','secondary');retry.type='button';retry.onclick=()=>{if(resultContext)resultContext.attempts=0;loadMatchResult();};root.append(retry);}
function renderMatchResult({result,status}){
 const root=$('matchRewardSummary'),totals=result.totals,saved=status==='saved';root.replaceChildren();
 const messages={saved:'Resultado salvo na sua conta.',saving:'Salvando o resultado… Os valores abaixo já foram confirmados.',playing:'Partida em andamento. Estes são seus resultados confirmados até agora.',unconfirmed:'O encerramento desta partida ainda não foi confirmado. Estes são os registros disponíveis na sua conta.'};
 root.append(uiElement('p',messages[status]||messages.unconfirmed,'save-status'+(saved?' saved':'')));
 const stats=uiElement('div',undefined,'reward-stats');
 for(const [value,label] of [[`+${totals.xp}`,saved?'XP recebido':'XP confirmado'],[totals.cuts,'Cortes entre contas'],[totals.captured,'Pipas conquistadas'],[totals.lost,'Pipas perdidas']]){const item=uiElement('div');item.append(uiElement('b',String(value)),uiElement('span',label));stats.append(item);}root.append(stats);
 if(result.match.rules==='casual')root.append(uiElement('p','Disputa casual: sua coleção ficou protegida.','history-note'));
 if(totals.cuts&&totals.xp<totals.cuts*25)root.append(uiElement('p','O limite de XP contra o mesmo adversário foi aplicado.','history-note'));
 root.append(uiElement('h3','Seus encontros no céu'));
 if(!result.events.length)root.append(uiElement('p','Nenhum corte entre contas foi registrado nesta partida. Cortes contra visitantes não geram XP.','history-note'));
 const list=uiElement('ol',undefined,'history-list');
 for(const e of result.events){const won=e.outcome==='cut',li=uiElement('li');
  li.append(uiElement('b',won?'Você cortou '+e.opponent:e.opponent+' cortou sua linha'));
  li.append(uiElement('span',e.captured?(won?'Conquistou ':'Perdeu ')+e.kiteName:won?'+'+e.xp+' XP · coleção protegida':'Sua pipa continua na coleção'));
  li.append(uiElement('small',resultDate(e.at)));list.append(li);
 }root.append(list);
 if(!saved)addResultRetry(root);
}
async function loadRecentMatches(){
 const root=$('recentMatches');if(!playerAccount){root.replaceChildren();return;}
 root.replaceChildren(uiElement('p','Buscando seus duelos…','history-note'));
 try{const {matches}=await accountRequest('history');if(!playerAccount)return;root.replaceChildren();
  if(!matches.length){root.append(uiElement('p','Sua história começa no próximo duelo.','history-note'));return;}
  for(const match of matches){const button=uiElement('button',undefined,'recent-match');button.type='button';
   button.append(uiElement('b',(match.rules==='capture'?'Vale pipa':'Casual')+' · '+match.code),uiElement('span','+'+match.xp+' XP · '+match.captured+' conquistadas · '+match.lost+' perdidas'),uiElement('small',resultDate(match.startedAt)+(match.endedAt?'':' · resultado parcial')));
   button.onclick=()=>{closeAccount();modal('A história deste duelo.','<div id="matchRewardSummary" class="match-rewards" aria-live="polite"></div>','Voltar ao lobby','Seus duelos');beginMatchResult(match.id);};root.append(button);
  }
 }catch(e){root.replaceChildren(uiElement('p',e.message,'history-note'));}
}
function closeKiteStory(){storyVersion++;$('kiteStory').hidden=true;$('collectionMain').hidden=false;}
async function openKiteStory(kite){
 const version=++storyVersion;$('collectionMain').hidden=true;$('kiteStory').hidden=false;
 const root=$('kiteStoryBody');root.replaceChildren(uiElement('p','Buscando a história desta pipa…'));$('kiteStoryBack').focus();
 try{const {history:h}=await accountRequest('kite-history',{kiteId:kite.id});if(version!==storyVersion)return;
  root.replaceChildren(uiElement('h3',h.name),uiElement('p',kite.model.acquisition==='event'?'Especial de evento. Vinculada à sua conta e protegida contra capturas.':h.permanent?'Básica permanente. Ela acompanha você em todos os duelos.':h.captureCount+' '+(h.captureCount===1?'troca de dono em duelo.':'trocas de dono em duelos.')));
  const list=uiElement('ol',undefined,'history-list');
  for(const capture of h.captures){const li=uiElement('li');li.append(uiElement('b',capture.to+' conquistou de '+capture.from),uiElement('span','Sala '+capture.room),uiElement('small',resultDate(capture.at)));list.append(li);}root.append(list);
  if(h.captureCount>h.captures.length)root.append(uiElement('p','Mostrando as 30 conquistas mais recentes.','history-note'));
  root.append(uiElement('p',(kite.model.acquisition==='event'?'Recebida como recompensa especial em ':'Recebida no inventário inicial em ')+resultDate(h.createdAt)+'.','history-note'));
 }catch(e){if(version===storyVersion)root.replaceChildren(uiElement('p',e.message,'history-note'));}
}
$('kiteStoryBack').onclick=closeKiteStory;

// Online rematch: the first player creates the next room, everyone else is pointed to it and joins.
async function rematch(){
 const button=$('rematchButton');button.disabled=true;
 if(state?.quick){closeModal();if(mode==='online'){stopMatchResult();showResult=false;leave();}quickMatch();return;}
 if(mode!=='online'){closeModal();if(trailStage)startStage(trailStage);else $('practice').click();return;}
 try{
  const d=await request('rematch',{code:room,token});
  stopMatchResult();$('modal').style.display='none';showResult=false;
  if(d.next){leave();$('code').value=d.next;await online('join');return;}
  const old=socket;socket=null;realtime=false;old?.close();
  token=d.token;enter(d.state,d.me,'online',d.code);history.replaceState(null,'','?sala='+d.code);toast('Revanche criada! Os outros jogadores entram pelo botão Revanche.');
 }catch(e){button.disabled=false;toast(e.name==='AbortError'?'A conexão demorou. Tente novamente.':e.message);}
}
