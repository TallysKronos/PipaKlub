const farm=createFarm();let farmOwner=null,farmSignature='',farmFrame=0,farmLast=0,farmDrawAt=0,farmPaused=art.reduced,farmEpoch=0;
farmPage.innerHTML=`<p class="farm-intro">Um cantinho para seus Pipamons passearem juntos.</p>
 <div class="farm-toolbar"><p id="farmCount" role="status"></p><button id="farmPause" class="secondary" type="button">Pausar passeio</button></div><p id="farmMotionHint" class="farm-note" hidden>Movimento reduzido ativo: o passeio começa pausado. Você pode retomá-lo quando quiser.</p>
 <div class="farm-field">
 <svg class="farm-landscape" viewBox="0 0 960 540" aria-hidden="true" focusable="false">
  <rect width="960" height="540" fill="#c8e5dd"/><circle cx="154" cy="85" r="37" fill="#f7d786"/>
  <g fill="#fff8e3"><path d="M320 80c-10-36 52-45 56-15 34-15 53 25 22 31h-69c-16 0-22-12-9-16Z"/><path d="M631 49c-4-24 35-30 42-8 28-10 43 20 19 25h-57c-17 0-15-15-4-17Z"/></g>
  <path d="M0 208Q155 111 337 207Q514 89 731 189Q870 136 960 184V540H0Z" fill="#a8c3a0"/>
  <path d="M0 237Q228 181 417 247Q705 167 960 240V540H0Z" fill="#7faa78"/>
  <path d="M0 295Q286 248 523 294T960 277V540H0Z" fill="#b8cf8c"/>
  <path d="M0 447Q223 408 480 467T960 425V540H0Z" fill="#a9c47a"/>
  <path d="M795 274Q747 330 821 387T960 435" fill="none" stroke="#dbcf9e" stroke-width="46"/>
  <g stroke="#38594c" stroke-width="4" stroke-linejoin="round">
   <path d="M719 191h170v100H719Z" fill="#c98161"/><path d="m700 194 104-78 105 78Z" fill="#6c7770"/><path d="m716 181 88-65 88 65" fill="none" stroke="#38594c" stroke-width="7"/>
   <path d="M781 222h47v69h-47Z" fill="#f0d99d"/><path d="M740 216h24v27h-24Z" fill="#b8e0dc"/><path d="M848 216h24v27h-24Z" fill="#b8e0dc"/>
   <path d="M804 222v69m-22-68 45 67m0-67-45 67" fill="none" stroke-width="3"/>
  </g>
  <g fill="#e7d6aa" stroke="#526850" stroke-width="3"><path d="M0 277h701v12H0Z"/><path d="M22 259h12v50H22Zm83 0h12v42h-12Zm84-4h12v45h-12Zm84 0h12v42h-12Zm84 0h12v47h-12Zm84 0h12v47h-12Zm84 0h12v45h-12Zm84 0h12v46h-12Zm84 0h12v50h-12Z"/></g>
  <g stroke="#38594c" stroke-width="4"><path d="M69 175v108m-18-76 18 19 20-24" fill="none" stroke-width="14"/><path d="M23 186c-26-22-5-58 20-57-6-35 48-47 60-15 37-3 54 42 24 59 10 31-47 51-58 27-26 15-47 6-46-14Z" fill="#67956d"/></g>
  <ellipse cx="115" cy="341" rx="75" ry="26" fill="#dfd7ac"/><ellipse cx="115" cy="337" rx="65" ry="21" fill="#82b8b7"/><path d="M78 335h42m-6 10h32" stroke="#d4eee0" stroke-width="3" stroke-linecap="round"/>
  <g fill="#6d9b62"><path d="m30 458 5-12 4 14 7-7-3 11Zm276-101 4-11 4 14 6-6-2 12Zm270 119 4-13 4 14 7-6-3 11Zm313-96 4-12 4 13 6-5-2 10Z"/></g>
  <g fill="#f7e9b1"><circle cx="228" cy="460" r="4"/><circle cx="514" cy="338" r="4"/><circle cx="681" cy="480" r="4"/><circle cx="414" cy="505" r="4"/></g>
 </svg>
 <canvas id="farmCanvas" width="960" height="540" role="img" aria-label="Pipamons da sua coleção passeando na fazenda"></canvas>
 <p id="farmEmpty" class="farm-empty" hidden>Sua fazenda está esperando seus primeiros Pipamons.</p>
 </div><p class="farm-note">Uma presença por espécie; as quantidades da coleção aparecem abaixo.</p>
 <div class="farm-pages" id="farmPages" hidden><button id="farmPrevious" class="secondary" type="button">← Grupo anterior</button><span id="farmPageCount"></span><button id="farmNext" class="secondary" type="button">Próximo grupo →</button></div>
 <ul id="farmResidents" class="farm-residents" aria-label="Pipamons neste grupo"></ul><p id="farmLoadStatus" class="history-note" role="status"></p><button id="farmRetry" class="secondary" type="button" hidden>Carregar sprites novamente</button>`;
const farmCanvas=$('farmCanvas'),farmContext=farmCanvas.getContext?.('2d');
function farmIsOpen(){return !!playerAccount&&accountPage==='farm'&&accountModal.style.display==='flex'&&!document.hidden;}
function stopFarm(){if(farmFrame)cancelAnimationFrame(farmFrame);farmFrame=0;farmLast=0;farmDrawAt=0;}
function drawFarm(time=0){
 if(!farmContext)return;farmContext.clearRect(0,0,960,540);
 for(const p of [...farm.visible()].sort((a,b)=>a.y-b.y||a.id.localeCompare(b.id))){
  const size=96+(p.y-310)*.1,hop=p.moving&&!farmPaused?Math.sin((time+p.phase)/110)*2:0;
  farmContext.fillStyle='#31584026';farmContext.beginPath();farmContext.ellipse(p.x,p.y-2,size*.27,6,0,0,Math.PI*2);farmContext.fill();
  art.creature(farmContext,p.color,time+p.phase,p.x-size/2,p.y-size+hop,size,{soul:p.soul,facing:p.facing,animate:!farmPaused,input:{x:p.moving?p.facing:0}});
 }
}
function farmTick(time){
 farmFrame=0;if(!farmIsOpen()||farmPaused){farmLast=0;return;}
 if(!farmDrawAt||time-farmDrawAt>=33){const dt=farmLast?(time-farmLast)/1000:0;farmLast=time;farmDrawAt=time;farm.step(dt);drawFarm(time);}
 farmFrame=requestAnimationFrame(farmTick);
}
function startFarm(){if(farmIsOpen()&&!farmPaused&&farm.visible().length&&!farmFrame)farmFrame=requestAnimationFrame(farmTick);}
async function loadFarmSprites(retry=false){
 const epoch=++farmEpoch,names=[...new Set(['pipas-almaticas',...farm.visible().map(p=>p.soul).filter(id=>art.atlases[id])])];
 $('farmLoadStatus').textContent='';$('farmRetry').hidden=true;
 const loaded=await Promise.all(names.map(name=>art.load(name,retry)));
 if(epoch!==farmEpoch||!farmIsOpen())return;
 const failed=loaded.some(ok=>!ok);$('farmLoadStatus').textContent=failed?'Alguns sprites não carregaram. Tente carregá-los novamente.':'';$('farmRetry').hidden=!failed;drawFarm();startFarm();
}
function renderFarmGroup(){
 const group=farm.visible();$('farmEmpty').hidden=!!farm.residents.length;$('farmPause').disabled=!group.length||!farmContext;
 $('farmPause').textContent=farmPaused?'Retomar passeio':'Pausar passeio';$('farmPause').setAttribute('aria-pressed',String(farmPaused));
 $('farmMotionHint').hidden=!art.reduced||!farmPaused;
 const count=farm.residents.reduce((n,p)=>n+p.count,0);$('farmCount').textContent=count+' Pipamon'+(count===1?'':'s')+' · '+farm.residents.length+' espécie'+(farm.residents.length===1?'':'s');
 $('farmPages').hidden=farm.pages<=1;$('farmPageCount').textContent=(farm.page+1)+' / '+farm.pages;$('farmPrevious').disabled=farm.page===0;$('farmNext').disabled=farm.page===farm.pages-1;
 $('farmResidents').replaceChildren(...group.map(p=>{const item=uiElement('li');item.append(uiElement('span',p.name),uiElement('b','×'+p.count));return item;}));
 if(!farmContext)$('farmLoadStatus').textContent='Seu navegador não conseguiu abrir a animação. Sua coleção está listada abaixo.';
 drawFarm();if(group.length&&farmContext)loadFarmSprites();startFarm();
}
function syncFarm(){
 if(!farmIsOpen()){stopFarm();if(!playerAccount){farmEpoch++;farmOwner=null;farmSignature='';farm.setCollection([]);$('farmResidents').replaceChildren();farmContext?.clearRect(0,0,960,540);}return;}
 const owner=playerAccount.profile?.id||'member',inventory=playerAccount.inventory||[],signature=JSON.stringify(inventory.map(k=>[k.id,k.model_id,k.model?.color,k.model?.soul,k.model?.name]));
 if(owner!==farmOwner){farm.setCollection([]);farmPaused=art.reduced;farmOwner=owner;farmSignature='';}
 if(signature!==farmSignature){farm.setCollection(inventory);farmSignature=signature;renderFarmGroup();}else{drawFarm();if(farm.visible().length&&farmContext)loadFarmSprites();startFarm();}
}
$('farmPause').onclick=()=>{farmPaused=!farmPaused;stopFarm();renderFarmGroup();};
for(const [id,delta] of [['farmPrevious',-1],['farmNext',1]])$(id).onclick=()=>{stopFarm();farm.turn(delta);renderFarmGroup();};
$('farmRetry').onclick=()=>loadFarmSprites(true);
const farmSyncMenu=syncClubMenu;syncClubMenu=function(){farmSyncMenu();syncFarm();};
const farmCloseAccount=closeAccount;closeAccount=function(){stopFarm();farmEpoch++;farmCloseAccount();};$('closeAccount').onclick=closeAccount;
addEventListener('visibilitychange',()=>{if(document.hidden)stopFarm();else syncFarm();});
