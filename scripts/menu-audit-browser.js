function menuAuditBoot(screen){
 introductionOpen=false;accountSaving=false;accountsEnabled=true;accountConnection='ready';
 $('assisIntro').hidden=true;
 const entries=ART_CONFIG.dex.entries.filter(e=>e.model),inventory=entries.map((e,n)=>({id:'visual-'+n,model_id:e.model,permanent:n<4,capture_count:n%3,model:{name:e.name,color:e.color,soul:e.group==='event'?e.id:null,acquisition:e.group==='event'?'event':'starter'}}));
 playerAccount={profile:{id:'visual-only',nickname:'Pipeiro da prévia',level:8,xp:5100,next_level_xp:6400,cuts:28,equipped_kite_id:inventory[0].id},inventory};
 accountRequest=async(action)=>{if(['equip','profile','logout','sighting','trade','summon'].includes(action))throw Error('Esta é apenas uma prévia visual.');return {account:playerAccount,matches:[],coins:0};};
 $('accountModal').style.display='flex';renderAccountDialog();
 if(screen==='dex'){$('accountModal').style.display='none';openDex();}
 else if(screen==='inventory')navigateClub('collection');
 else if(screen==='club')navigateClub('home');
 else if(screen==='profile')navigateClub('profile');
 else if(screen==='friends'){$('accountModal').style.display='none';openSheet('friendsSheet');}
 else if(screen==='trails'){$('accountModal').style.display='none';openTrails();}
 function visible(e){const r=e.getBoundingClientRect(),s=getComputedStyle(e);return r.width>1&&r.height>1&&s.display!=='none'&&s.visibility!=='hidden';}
 document.fonts.ready.then(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>{
  const errors=[],W=innerWidth,H=innerHeight,dialogs=[...document.querySelectorAll('[role="dialog"]')].filter(visible);
  for(const dialog of dialogs){const r=dialog.getBoundingClientRect();if(r.x<-1||r.y<-1||r.right>W+1||r.bottom>H+1)errors.push({kind:'dialog-viewport',element:dialog.className,box:{x:r.x,y:r.y,w:r.width,h:r.height}});
   for(const e of dialog.querySelectorAll('input,select,button,canvas')){if(!visible(e)||e.closest('.inventory-list,.dex-list'))continue;const b=e.getBoundingClientRect();if(b.x<r.x-1||b.right>r.right+1)errors.push({kind:'horizontal-overflow',element:e.id||e.className});}
  }
  for(const e of document.querySelectorAll('.collection-stage canvas,.dex-stage canvas'))if(visible(e)){const r=e.getBoundingClientRect(),p=e.parentElement.getBoundingClientRect();if(r.y<p.y-1||r.bottom>p.bottom+1)errors.push({kind:'sprite-clipped',element:e.id});}
  for(const selector of ['.dex-list','.dex-details','.collection-browser','.inventory-details']){const e=document.querySelector(selector);if(e&&visible(e)&&e.getBoundingClientRect().height<65)errors.push({kind:'collapsed-pane',element:selector});}
  for(const e of document.querySelectorAll('.portrait-card'))if(visible(e)&&e.scrollHeight>e.clientHeight+2)errors.push({kind:'portrait-overflow',id:e.dataset.dexId||e.dataset.kiteId,scroll:e.scrollHeight,height:e.clientHeight});
  parent.postMessage({type:'menu-audit',result:{width:W,height:H,screen,errors,portraits:document.querySelectorAll('.pipamon-portrait').length}},'*');
 })));
}
let currentFrame,pending;
function showMenu(w,h,screen){return new Promise(resolve=>{currentFrame?.remove();const frame=document.createElement('iframe');frame.width=w;frame.height=h;frame.style.width=w+'px';frame.style.height=h+'px';frame.title='Menus '+w+' por '+h;frame.srcdoc=MENU_GAME.replace('</body>','<script>('+menuAuditBoot.toString()+')('+JSON.stringify(screen)+')<\/script></body>');currentFrame=frame;pending=resolve;document.querySelector('#preview').append(frame);});}
addEventListener('message',e=>{if(e.source!==currentFrame?.contentWindow||e.origin!==location.origin||e.data?.type!=='menu-audit')return;document.querySelector('#report').textContent=JSON.stringify(e.data.result,null,2);pending?.(e.data.result);pending=null;});
document.querySelector('#show').onclick=()=>showMenu(+document.querySelector('#w').value,+document.querySelector('#h').value,document.querySelector('#screen').value);
document.querySelector('#matrix').onclick=async()=>{const b=document.querySelector('#matrix');b.disabled=true;const rows=[];try{for(const [w,h]of [[320,568],[390,844],[568,320],[768,1024],[1104,700],[1440,900],[1920,1080]])for(const screen of ['dex','inventory','club','profile','friends','trails']){document.querySelector('#progress').textContent=(rows.length+1)+'/42 · '+w+'×'+h+' · '+screen;rows.push(await showMenu(w,h,screen));}document.querySelector('#report').textContent=JSON.stringify({cases:rows.length,failures:rows.filter(r=>r.errors.length).length,rows},null,2);document.querySelector('#progress').textContent='Concluído';}finally{b.disabled=false;}};
document.querySelector('#show').click();
