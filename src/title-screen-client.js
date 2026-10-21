const ruinsTitleAssets=ART_CONFIG.courtyard.images;
const ruinsSceneAssets={background:ruinsTitleAssets['title-background'],presence:ruinsTitleAssets['title-presence']};
const ruinsMenu=document.querySelector('.menu');
ruinsMenu.classList.add('ruins-menu');
ruinsMenu.prepend(createRuinsArt(document,ruinsSceneAssets,'menu'));
document.getElementById('ruinsContinue').onclick=()=>document.getElementById('accountButton').click();
const ruinsMenuMotion=document.getElementById('ruinsMenuMotion'),ruinsMenuReduced=matchMedia('(prefers-reduced-motion: reduce)');
let ruinsMenuPaused=false;
function syncRuinsMenuMotion(){
 const paused=ruinsMenuPaused||document.hidden||ruinsMenuReduced.matches||['in-title','in-match','game-shell'].some(c=>document.body.classList.contains(c));
 ruinsMenu.classList.toggle('ruins-paused',paused);
 const svg=ruinsMenu.querySelector('.ruins-life');if(paused)svg.pauseAnimations?.();else svg.unpauseAnimations?.();
 ruinsMenuMotion.setAttribute('aria-pressed',String(ruinsMenuPaused));ruinsMenuMotion.textContent=ruinsMenuPaused?'Retomar animação':'Pausar animação';ruinsMenuMotion.hidden=ruinsMenuReduced.matches;
}
ruinsMenuMotion.onclick=()=>{ruinsMenuPaused=!ruinsMenuPaused;syncRuinsMenuMotion();};
new MutationObserver(syncRuinsMenuMotion).observe(document.body,{attributes:true,attributeFilter:['class']});
document.addEventListener('visibilitychange',syncRuinsMenuMotion);ruinsMenuReduced.addEventListener?.('change',syncRuinsMenuMotion);
createRuinsTitle({document,host:globalThis,location,
 assets:ruinsSceneAssets,
 storage:typeof sessionStorage==='undefined'?null:sessionStorage,
 requestFrame:fn=>requestAnimationFrame(fn),cancelFrame:id=>cancelAnimationFrame(id)});
syncRuinsMenuMotion();

if(gameLoading.active&&loadingScreen.open){loadingScreen.close();loadingScreen.showModal();}
if(typeof navigator!=='undefined'&&navigator.userAgent){
 async function loadTitlePresentation(){
  const gate=gameLoading.start('presentation','Preparando sua aventura',{retry:loadTitlePresentation,back:()=>gate.cancel()});
  if(loadingScreen.open){loadingScreen.close();loadingScreen.showModal();}
  let loaded=0;const assets=Object.values(ruinsSceneAssets).filter(a=>a?.url);gate.update(0,assets.length,'Carregando a tela inicial…');
  const results=await Promise.all(assets.map(a=>new Promise(resolve=>{const image=new Image();image.onload=()=>{gate.update(++loaded,assets.length);resolve(true);};image.onerror=()=>resolve(false);image.src=a.url;})));
  if(results.every(Boolean))await gate.done();else gate.fail('A apresentação não carregou. Tente novamente ou continue com o fundo simples.');
 }
 loadTitlePresentation();
}
