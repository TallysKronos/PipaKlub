let dailyViewVersion=0;
function dailyDescription(data){
 const day=eng.daily(Date.parse(data.date+'T12:00:00Z'));
 return {...day,...data};
}
function dailyCard(day){
 return '<div class="daily-sky '+day.weather+'" aria-hidden="true">'+art.icon(day.weather,'weather-icon')+'</div><p class="daily-date">'+escapeHTML(day.date)+' · renova às 00:00 UTC (21h de Brasília)</p><h3>'+escapeHTML(day.name)+'</h3><p>'+escapeHTML(day.description)+'</p>';
}
async function openDaily(){
 if(mode||!requireClubAccount('Céu do dia'))return;
 const version=++dailyViewVersion,owner=playerAccount?.profile?.id;
 modal('Céu do dia','<p role="status">Conferindo o céu e suas moedas…</p>','Voltar','Desafio diário');
 try{
  const {daily}=await accountRequest('daily',{});
  if(version!==dailyViewVersion||playerAccount?.profile?.id!==owner||$('modal').style.display!=='flex'||$('dialogTitle').textContent!=='Céu do dia')return;
  trailSync.accept(daily,owner);const day=dailyDescription(daily);
  $('dialogBody').innerHTML=dailyCard(day)+'<p>Vença duas rodadas contra o Guardião do céu, nível 4. Sua coleção fica protegida.</p><p class="daily-reward">'+(day.claimed?'✓ Bônus de hoje já recebido. Você pode jogar novamente.':'🪙 +25 moedas na primeira vitória de hoje.')+'</p><p class="history-note">Mesmo céu para todos. A condição fica fixa até o fim do duelo. Sair antes da vitória não dá bônus.</p><button id="startDaily" class="primary">Enfrentar o céu ▶</button>';
  $('startDaily').onclick=startDaily;
 }catch(e){if(version===dailyViewVersion&&$('dialogTitle').textContent==='Céu do dia')$('dialogBody').replaceChildren(uiElement('p',e.message),Object.assign(uiElement('button','Tentar novamente','secondary'),{onclick:openDaily}));}
}
async function startDaily(){
 if(busy||!requireClubAccount('Céu do dia'))return;
 busy=true;const button=$('startDaily');if(button)button.disabled=true;
 try{const d=await request('daily',profile());closeModal();token=d.token;enter(d.state,d.me,'online',d.code);$('roomChip').hidden=true;$('copy').style.display='none';$('roomBox').style.display='none';$('arenaMode').textContent='Céu do dia · '+d.state.daily.name;$('liveLabel').textContent=d.state.daily.name;$('gameTip').textContent=d.state.daily.description;}
 catch(e){toast(e.name==='AbortError'?'A conexão demorou. Tente novamente.':e.message);}
 finally{busy=false;if(button)button.disabled=false;}
}
function showDailyResult(s,mine){
 const won=(mine?.rounds||0)>=s.roundsToWin;
 modal(won?'Você conquistou este céu!':'O céu guarda uma nova chance.',dailyCard(s.daily)+'<p>'+ (won?'Duas rodadas vencidas! Conferindo o bônus na sua conta…':'Vença duas rodadas para conquistar o bônus diário. Tente novamente quando quiser.')+'</p><div id="dailyRewardStatus" role="status" aria-live="polite"></div>','Voltar ao menu','Desafio diário');
 if(!won)return;
 const owner=playerAccount?.profile?.id,match=s.id;
 let tries=0;
 async function check(){
  if(state?.id!==match||!showResult||playerAccount?.profile?.id!==owner||!$('dailyRewardStatus'))return;
  try{
   const result=await accountRequest('match-result',{matchId:match}),{daily}=await accountRequest('daily',{});
   if(state?.id!==match||!showResult||playerAccount?.profile?.id!==owner||!$('dailyRewardStatus'))return;
   trailSync.accept(daily,owner);
   $('dailyRewardStatus').textContent=result.status==='saved'?'✓ Resultado salvo. O bônus de 25 moedas é recebido uma vez por dia.' : 'Salvando seu bônus… Ele será enviado mesmo se você voltar ao menu.';
   if(result.status==='saved')refreshRewards();
   if(result.status!=='saved'&&++tries<12)setTimeout(check,1500);
   else if(result.status!=='saved'){const retry=uiElement('button','Conferir novamente','secondary');retry.onclick=()=>{tries=0;check();};$('dailyRewardStatus').append(retry);}
  }catch(e){if(state?.id===match&&$('dailyRewardStatus')){const root=$('dailyRewardStatus');root.replaceChildren(uiElement('p','O servidor continuará tentando salvar. '+e.message));const retry=uiElement('button','Conferir novamente','secondary');retry.onclick=check;root.append(retry);}}
 }
 check();
}
// Weather stays behind the readable combat layer. No extra images or animated DOM nodes.
function drawDailyWeather(t){
 const weather=state?.daily?.weather;if(!weather)return;ctx.save();
 if(weather==='fog'){ctx.fillStyle='#e6ede4aa';ctx.fillRect(0,0,1000,600);ctx.fillStyle='#fff5';ctx.fillRect(0,170,1000,70);ctx.fillRect(0,350,1000,80);}
 else if(weather==='rain'||weather==='wind'){
  ctx.strokeStyle=weather==='rain'?'#3d718850':'#ffffff80';ctx.lineWidth=weather==='rain'?2:3;ctx.beginPath();
  const n=lightMode?12:28,phase=lightMode||matchMedia('(prefers-reduced-motion: reduce)').matches?0:t;
  for(let i=0;i<n;i++){const x=(i*137+phase*(weather==='rain'?.04:.1))%1100-50,y=(i*73+phase*(weather==='rain'?.18:.015))%600;ctx.moveTo(x,y);ctx.lineTo(x+(weather==='rain'?-5:50),y+(weather==='rain'?18:-8));}ctx.stroke();
 }else{ctx.fillStyle='#fff4bc20';ctx.fillRect(0,0,1000,600);}
 ctx.restore();
}
$('dailyButton').onclick=openDaily;
