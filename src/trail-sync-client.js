let trailRewards=[],trailRewardOwner=null,legacyArchiveNotice=false;
const trailSyncMessages={guest:'Progresso salvo neste aparelho. Entre para levar suas Trilhas com você.',saving:'Salvando suas Trilhas…',saved:'Trilhas salvas na sua conta.',pending:'Há resultados aguardando envio.',offline:'Sem sincronizar agora. Seu progresso continua neste aparelho; tentaremos novamente.',conflict:'O progresso precisa ser conferido. Os resultados continuam neste aparelho. Tente sincronizar novamente.',storage:'O navegador não permitiu salvar. Mantenha esta aba aberta e libere o armazenamento para evitar perda de progresso.',claimed:'O progresso de visitante já foi vinculado a outra conta.'};
const trailSyncLine=document.createElement('div');trailSyncLine.className='trail-sync-line';
trailSyncLine.innerHTML='<p id="trailSyncStatus" role="status" aria-live="polite"></p><button class="secondary" id="trailSyncRetry" hidden>Sincronizar novamente</button>';
$('trailMastery').after(trailSyncLine);
const trailSync=createTrailSync({trails,storage:localStorage,uuid:()=>crypto.randomUUID(),
 send:async body=>{const owner=playerAccount?.profile?.id,data=(await accountRequest('trails',body)).trails;if(owner===playerAccount?.profile?.id){trailRewards=data.rewards||[];legacyArchiveNotice||=!!data.legacyArchived;}return data;},
 withLock:fn=>typeof navigator!=='undefined'&&navigator.locks?navigator.locks.request('pipa-trail-import',fn):fn(),
 onChange:p=>{trailProgress=p;reflectCoins();if(!$('trails').hidden&&!mode)renderTrails();},
 onStatus:status=>{$('trailSyncStatus').textContent=trailSyncMessages[status]+(status==='saved'&&legacyArchiveNotice?' Dados antigos deste aparelho foram preservados como histórico; novos prêmios exigem vitória no servidor.':'');$('trailSyncRetry').hidden=!['offline','conflict','storage','pending'].includes(status);}
});
function onTrailAccountChange(){const owner=playerAccount?.profile?.id||null;if(owner!==trailRewardOwner){trailRewards=[];legacyArchiveNotice=false;trailRewardOwner=owner;}trailSync.setUser(playerAccount?.profile?.id||null);}
$('trailSyncRetry').onclick=()=>trailSync.retry();
$('trailSyncStatus').textContent=trailSyncMessages.guest;
addEventListener('online',()=>trailSync.retry());
addEventListener('storage',event=>{if(event.key?.startsWith('pipaTrailAccountV1:')||event.key==='pipaTrailsV1')trailSync.changed();});
setInterval(()=>{if(typeof document!=='undefined'&&!document.hidden)trailSync.sync();},30000);
onTrailAccountChange();

function acceptTrailSnapshot(data,owner){if(owner!==playerAccount?.profile?.id)return;trailRewards=data.rewards||trailRewards;trailSync.accept(data,owner);}
