const trailSyncMessages={guest:'Progresso salvo neste aparelho. Entre para levar suas Trilhas com você.',saving:'Salvando suas Trilhas…',saved:'Trilhas salvas na sua conta.',pending:'Há resultados aguardando envio.',offline:'Sem sincronizar agora. Seu progresso continua neste aparelho; tentaremos novamente.',conflict:'O progresso precisa ser conferido. Os resultados continuam neste aparelho. Tente sincronizar novamente.',storage:'O navegador não permitiu salvar. Mantenha esta aba aberta e libere o armazenamento para evitar perda de progresso.',claimed:'O progresso de visitante já foi vinculado a outra conta.'};
const trailSyncLine=document.createElement('div');trailSyncLine.className='trail-sync-line';
trailSyncLine.innerHTML='<p id="trailSyncStatus" role="status" aria-live="polite"></p><button class="secondary" id="trailSyncRetry" hidden>Sincronizar novamente</button>';
$('trailMastery').after(trailSyncLine);
const trailSync=createTrailSync({trails,storage:localStorage,uuid:()=>crypto.randomUUID(),
 send:async body=>(await accountRequest('trails',body)).trails,
 withLock:fn=>typeof navigator!=='undefined'&&navigator.locks?navigator.locks.request('pipa-trail-import',fn):fn(),
 onChange:p=>{trailProgress=p;reflectCoins();if(!$('trails').hidden&&!mode)renderTrails();},
 onStatus:status=>{$('trailSyncStatus').textContent=trailSyncMessages[status];$('trailSyncRetry').hidden=!['offline','conflict','storage','pending'].includes(status);}
});
function onTrailAccountChange(){trailSync.setUser(playerAccount?.profile?.id||null);}
$('trailSyncRetry').onclick=()=>trailSync.retry();
$('trailSyncStatus').textContent=trailSyncMessages.guest;
addEventListener('online',()=>trailSync.retry());
addEventListener('storage',event=>{if(event.key?.startsWith('pipaTrailAccountV1:')||event.key==='pipaTrailsV1')trailSync.changed();});
setInterval(()=>{if(typeof document!=='undefined'&&!document.hidden)trailSync.sync();},30000);
onTrailAccountChange();
