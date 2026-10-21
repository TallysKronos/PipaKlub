const loadingScreen=document.createElement('dialog');loadingScreen.id='gameLoading';loadingScreen.className='game-loading';loadingScreen.setAttribute('aria-labelledby','loadingTitle');loadingScreen.setAttribute('aria-describedby','loadingDetail');
loadingScreen.innerHTML='<div class="loading-sky" aria-hidden="true"><span></span><span></span></div><section class="loading-card"><div class="loading-emblem" aria-hidden="true"><i></i><b>◇</b></div><p class="loading-brand">SOULMONSTERS</p><h2 id="loadingTitle">Preparando sua aventura</h2><p id="loadingDetail" role="status" aria-live="polite"></p><div id="loadingProgress" role="progressbar" aria-label="Recursos carregados"><span id="loadingFill"></span></div><p class="loading-tip">Cada fio guarda uma nova história.</p><div class="loading-actions"><button id="loadingRetry" hidden>Tentar novamente</button><button id="loadingBack" hidden>Voltar</button></div></section>';
document.body.append(loadingScreen);
let loadingView={active:false},loadingFocus=null;
const gameLoading=createLoadingGate({paint:fn=>typeof navigator==='undefined'||!navigator.userAgent?Promise.resolve().then(fn):requestAnimationFrame(()=>requestAnimationFrame(fn)),change:view=>{
 const get=id=>document.getElementById(id),wasActive=loadingView.active;loadingView=view;document.body.classList.toggle('game-is-loading',view.active);
 if(view.active){if(!wasActive){loadingFocus=document.activeElement;if(typeof loadingScreen.showModal==='function')loadingScreen.showModal();else loadingScreen.setAttribute('open','');}
  get('loadingTitle').textContent=view.title;get('loadingDetail').textContent=view.detail;get('loadingRetry').hidden=!view.failed||!view.retry;get('loadingBack').hidden=!view.failed||!view.back;loadingScreen.classList.toggle('loading-error',!!view.failed);
  const bar=get('loadingProgress');if(view.total){bar.setAttribute('aria-valuemax',String(view.total));bar.setAttribute('aria-valuenow',String(view.completed));get('loadingFill').style.width=Math.round(view.completed/view.total*100)+'%';bar.classList.remove('indeterminate');}
  else{bar.removeAttribute('aria-valuenow');bar.classList.add('indeterminate');get('loadingFill').style.width='';}
  if(view.failed)(!get('loadingRetry').hidden?get('loadingRetry'):get('loadingBack')).focus?.({preventScroll:true});
 }else if(wasActive){if(typeof loadingScreen.close==='function')loadingScreen.close();else loadingScreen.removeAttribute('open');if(loadingFocus?.isConnected&&!loadingFocus.closest?.('[hidden],[inert]'))loadingFocus.focus?.({preventScroll:true});}
}});
document.getElementById('loadingRetry').onclick=()=>loadingView.retry?.();
document.getElementById('loadingBack').onclick=()=>loadingView.back?.();
loadingScreen.addEventListener('cancel',e=>{e.preventDefault();if(loadingView.failed)loadingView.back?.();});
addEventListener('keydown',e=>{if(!gameLoading.active)return;if(e.target?.closest?.('#gameLoading'))return;e.preventDefault();e.stopImmediatePropagation();},true);
const bootLoading=gameLoading.start('boot','Preparando sua aventura',{detail:'Conferindo a conexão e seu lugar na história…',back:()=>{gameLoading.cancel('boot');}});
