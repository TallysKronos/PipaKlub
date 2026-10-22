// Cookie sessions stay HttpOnly. The recovery-link token is kept only in memory until submission or cancellation.
let playerAccount=null,accountsEnabled=false,accountTab='login',accountSaving=false,rewardRefreshTimer;
let accountConnection='checking',accountConfigPending=null,accountRetryTimer=null,accountRetryCount=0;
const accountConnectionMessages={checking:'Conectando ao serviço de contas…',offline:'Não foi possível conectar ao serviço de contas. Vamos tentar novamente; você também pode usar o botão abaixo.',disabled:'O login está temporariamente indisponível no servidor. Tente conectar novamente em instantes.',static:'O login está disponível no endereço oficial do jogo. Abra o PipaKlub online para entrar na sua conta.'};
const accountModal=$('accountModal');
let accountRecoveryMode=null,passwordRecoveryToken=null;
const recoveryFragment=new URLSearchParams(location.hash.slice(1));
if(recoveryFragment.get('type')==='recovery'&&recoveryFragment.get('access_token')){passwordRecoveryToken=recoveryFragment.get('access_token');accountRecoveryMode='reset';history.replaceState(null,'',location.pathname+location.search);}
recoveryFragment.delete('access_token');recoveryFragment.delete('refresh_token');
const forgotPassword=uiElement('button','Esqueci minha senha','secondary');forgotPassword.id='forgotPassword';forgotPassword.type='button';$('accountAuth').append(forgotPassword);
const passwordRecovery=uiElement('section');passwordRecovery.id='passwordRecovery';passwordRecovery.hidden=true;
passwordRecovery.innerHTML='<p id="recoveryHelp"></p><form class="account-form" id="recoveryForm"><label id="recoveryEmailLabel" for="recoveryEmail">E-mail da conta</label><input id="recoveryEmail" type="email" autocomplete="email"><label id="recoveryPasswordLabel" for="recoveryPassword">Nova senha</label><input id="recoveryPassword" type="password" minlength="8" maxlength="128" autocomplete="new-password"><label id="recoveryConfirmLabel" for="recoveryConfirm">Repita a nova senha</label><input id="recoveryConfirm" type="password" minlength="8" maxlength="128" autocomplete="new-password"><button type="submit" class="primary" id="recoverySubmit">Enviar link de recuperação</button></form><button type="button" class="secondary" id="recoveryCancel">Voltar ao login</button><p id="recoveryStatus" role="status" aria-live="polite"></p>';
$('accountAuth').after(passwordRecovery);
function closeRecovery(){accountRecoveryMode=null;passwordRecoveryToken=null;$('recoveryPassword').value='';$('recoveryConfirm').value='';$('recoveryStatus').textContent='';}
forgotPassword.onclick=()=>{accountRecoveryMode='request';$('recoveryEmail').value=$('accountEmail').value;renderAccountDialog();$('recoveryEmail').focus({preventScroll:true});};
$('recoveryCancel').onclick=()=>{closeRecovery();renderAccountDialog();$('accountEmail').focus({preventScroll:true});};
$('recoveryForm').onsubmit=async e=>{
 e.preventDefault();if(accountSaving)return;const resetting=accountRecoveryMode==='reset',token=passwordRecoveryToken;
 if(resetting&&$('recoveryPassword').value!==$('recoveryConfirm').value){$('recoveryStatus').textContent='As duas senhas precisam ser iguais.';return;}
 accountSaving=true;$('recoverySubmit').disabled=true;$('recoveryCancel').disabled=true;$('recoveryStatus').textContent=resetting?'Atualizando sua senha…':'Enviando o link…';
 try{const result=await accountRequest(resetting?'reset-password':'recover',resetting?{token,password:$('recoveryPassword').value}:{email:$('recoveryEmail').value});if(resetting){closeRecovery();playerAccount=result.account||null;if(result.loginEmail)$('accountEmail').value=result.loginEmail;accountTab='login';reflectAccount();$('accountMessage').textContent=result.message;if(playerAccount){loadRecentMatches();toast('Bem-vindo de volta!');}}else $('recoveryStatus').textContent=result.message;}
 catch(err){$('recoveryStatus').textContent=err.name==='AbortError'?'A conexão demorou. Tente novamente.':err.message;}
 finally{accountSaving=false;$('recoverySubmit').disabled=false;$('recoveryCancel').disabled=false;$('recoveryPassword').value='';$('recoveryConfirm').value='';renderAccountDialog();}
};
function requireClubAccount(feature){if(playerAccount)return true;toast('Entre ou crie sua conta para acessar '+feature+'.');openAccount();return false;}
async function accountRequest(action,body){
 const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),action==='reset-password'?30000:12000);
 try{const r=await fetch('/account/'+action,{method:body===undefined?'GET':'POST',headers:body===undefined?{}:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:controller.signal});const d=await r.json();if(!r.ok)throw Object.assign(Error(d.error||'Não foi possível acessar sua conta.'),{status:r.status});return d;}finally{clearTimeout(timeout);}
}
function reflectAccount(){
 $('accountButton').textContent=playerAccount?'Minha conta':'Entrar';
 for(const el of document.querySelectorAll('[data-members-only]'))el.hidden=!playerAccount;
 $('lobby').classList.toggle('guest-menu',!playerAccount);
 $('dailyButton').textContent='✦ Céu do dia';
 $('trailsButton').textContent=playerAccount?'⚔ Trilhas':'🔒 Trilhas';$('dexButton').textContent=playerAccount?'Pipa Dex':'🔒 Pipa Dex';document.querySelector('.coin-chip').hidden=!playerAccount;
 $('matchFormat').disabled=!playerAccount;$('roomRules').disabled=!playerAccount;
 if(!playerAccount){$('matchFormat').value='rounds';$('roomRules').value='casual';}
 $('profileSummary').textContent=playerAccount?playerAccount.profile.nickname+' · Nível '+playerAccount.profile.level:'Jogue como visitante';
 $('accountHint').textContent=playerAccount?'Seu progresso e suas pipas ficam na sua conta.':'Entre para guardar pipas e ganhar XP nas disputas.';
 $('roomRules').querySelector('[value="capture"]').disabled=!playerAccount;
 if(!playerAccount&&$('roomRules').value==='capture')$('roomRules').value='casual';
 if(playerAccount){const p=playerAccount.profile,k=playerAccount.inventory.find(k=>k.id===p.equipped_kite_id);$('name').value=p.nickname;$('name').readOnly=true;if(k){selected=k.model.color;choices();const chosen=$('kites').querySelector('[data-color="'+selected+'"]');if(chosen){chosen.innerHTML=art.markup(selected,k.model.soul);chosen.setAttribute('aria-label',(k.personal_name||k.model.name)+' · equipada');}$('selectionName').textContent=(k.personal_name||k.model.name)+' · '+eng.type({color:k.model.color}).name+' · equipada';}}
 else {$('name').readOnly=false;choices();}
 if(accountModal.style.display==='flex')renderAccountDialog();
 if(typeof onTrailAccountChange==='function')onTrailAccountChange();
 if(typeof onLineAccountChange==='function')onLineAccountChange();
 if(typeof onCourtyardAccount==='function')onCourtyardAccount();
}
async function refreshAccount(){
 if(!accountsEnabled)return;
 try{const d=await accountRequest('session');const previous=playerAccount;playerAccount=d.account;announcePipamonLevels(previous,playerAccount);reflectAccount();}catch(e){if(accountModal.style.display==='flex')$('accountMessage').textContent=e.message;}
}
function renderAccountDialog(){
 passwordRecovery.hidden=!accountRecoveryMode;forgotPassword.hidden=!!playerAccount||accountTab!=='login';
 if(accountRecoveryMode){const resetting=accountRecoveryMode==='reset';$('accountAuth').hidden=true;$('accountCollection').hidden=true;$('accountTitle').textContent=resetting?'Escolha sua nova senha':'Recupere sua conta';$('recoveryHelp').textContent=resetting?'Escolha uma senha exclusiva para jogar. Nunca envie sua senha pelo chat.':'Enviaremos um link ao e-mail da sua conta. Se o link expirar, você pode solicitar outro.';for(const id of ['recoveryEmail','recoveryEmailLabel'])$(id).hidden=resetting;$('recoveryEmail').required=!resetting;for(const id of ['recoveryPassword','recoveryPasswordLabel','recoveryConfirm','recoveryConfirmLabel'])$(id).hidden=!resetting;$('recoveryPassword').required=$('recoveryConfirm').required=resetting;$('recoverySubmit').textContent=resetting?'Salvar nova senha':'Enviar link de recuperação';return;}
 const logged=!!playerAccount;$('accountAuth').hidden=logged;$('accountCollection').hidden=!logged;
 $('accountTitle').textContent=logged?'Sua coleção, sua história.':accountTab==='signup'?'Seu lugar no céu.':'De volta ao céu.';
 $('signupFields').hidden=accountTab!=='signup';$('accountPassword').autocomplete=accountTab==='signup'?'new-password':'current-password';
 $('submitAccount').textContent=accountTab==='signup'?'Criar minha conta':'Entrar';$('switchAccount').textContent=accountTab==='signup'?'Já tenho uma conta':'Ainda não tenho conta';
 $('submitAccount').disabled=!accountsEnabled||accountSaving;
 $('retryAccounts').hidden=accountsEnabled||accountConnection==='checking'||accountConnection==='static';$('retryAccounts').disabled=accountConnection==='checking';
 $('accountServerLink').hidden=accountConnection!=='static';$('submitAccount').setAttribute('aria-busy',String(accountConnection==='checking'||accountSaving));
 if(!accountsEnabled)$('accountMessage').textContent=accountConnectionMessages[accountConnection]||accountConnectionMessages.offline;
 else if(Object.values(accountConnectionMessages).includes($('accountMessage').textContent))$('accountMessage').textContent='';
 if(!logged){closeKiteStory();return;}
 const p=playerAccount.profile;$('accountNickname').value=p.nickname;
 $('accountLevel').textContent='Nível '+p.level;$('accountXP').textContent=p.level===100?'Nível máximo · '+p.xp+' XP':p.xp+' / '+p.next_level_xp+' XP';
 const base=p.level_base_xp??(p.level-1)**2*100;$('accountXPBar').style.width=(p.level===100?100:Math.min(100,(p.xp-base)/Math.max(1,p.next_level_xp-base)*100))+'%';
 $('accountCuts').textContent=p.cuts+' cortes';$('collectionCount').textContent=playerAccount.inventory.length+(playerAccount.inventory.length===1?' pipa':' pipas');
 renderInventory();
 const owned=new Set(playerAccount.inventory.map(k=>k.model_id));
 $('eventSoulsList').replaceChildren(...art.specials.filter(s=>s.id!=='rabbito').map(s=>{
  const card=uiElement('article',undefined,'inventory-card event-soul'+(owned.has(s.id)?'':' event-locked'));
  const image=uiElement('div',undefined,'inventory-art');image.innerHTML=art.markup(s.color,s.id);
  card.append(image,uiElement('b',s.name),uiElement('small',(owned.has(s.id)?'Na sua coleção':'Bloqueada · recompensa de evento')+(s.rarity==='rara'?' · Rara':'')),uiElement('p',s.legend,'skill-info'));
  return card;
 }));
}

async function openAccount(){
 if(mode){toast('Saia da partida para abrir sua coleção.');return;}
 keys={};closeKiteStory();$('accountMessage').textContent='';accountModal.style.display='flex';renderAccountDialog();$('closeAccount').focus();if(!accountsEnabled)await initializeAccounts();else await refreshAccount();await loadRecentMatches();
}
function closeAccount(){closeRecovery();if(typeof leaveSummoner==='function'&&summonOpen)leaveSummoner();closeKiteStory();accountModal.style.display='none';$('accountPassword').value='';((!playerAccount&&!mode&&$('ruinsContinue'))||$('accountButton')).focus();}
$('accountButton').onclick=openAccount;$('closeAccount').onclick=closeAccount;
accountModal.onclick=e=>{if(e.target===accountModal)closeAccount();};
$('switchAccount').onclick=()=>{accountTab=accountTab==='login'?'signup':'login';$('accountMessage').textContent='';renderAccountDialog();};
$('accountForm').onsubmit=async e=>{
 e.preventDefault();if(accountSaving||!accountsEnabled)return;accountSaving=true;renderAccountDialog();$('accountMessage').textContent='Conectando…';
 try{const d=await accountRequest(accountTab,{email:$('accountEmail').value,password:$('accountPassword').value,nickname:$('signupName').value});$('accountPassword').value='';
   if(d.confirmation){accountTab='login';$('accountMessage').textContent=d.message;}
   else{playerAccount=d.account;reflectAccount();loadRecentMatches();$('accountMessage').textContent='Conta conectada. Sua coleção está pronta.';toast('Bem-vindo a Soulmonsters!');}
 }catch(e){$('accountMessage').textContent=e.name==='AbortError'?'A conexão demorou. Tente novamente.':e.message;}
 finally{accountSaving=false;renderAccountDialog();}
};
$('nicknameForm').onsubmit=async e=>{e.preventDefault();try{const d=await accountRequest('profile',{nickname:$('accountNickname').value});playerAccount=d.account;reflectAccount();$('accountMessage').textContent='Apelido atualizado.';}catch(e){$('accountMessage').textContent=e.message;}};
$('logoutAccount').onclick=async()=>{if(mode)return;try{await accountRequest('logout',{});playerAccount=null;reflectAccount();$('accountMessage').textContent='Você saiu da conta.';}catch(e){$('accountMessage').textContent=e.message;}};
$('roomRules').onchange=()=>$('rulesDescription').textContent=$('roomRules').value==='capture'?'Vale pipa: ao ser cortado, você perde a pipa equipada para o adversário.':'Casual: suas pipas ficam protegidas. Cortes entre contas rendem XP.';
addEventListener('keydown',e=>{
 if(accountModal.style.display!=='flex')return;
 if(e.key==='Escape'){e.preventDefault();closeAccount();}
 if(e.key==='Tab'){const items=[...accountModal.querySelectorAll('button,input,select')].filter(el=>!el.disabled&&el.getClientRects().length);const first=items[0],last=items.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}
});
async function initializeAccounts(){
 if(typeof STATIC_HOST!=='undefined'&&STATIC_HOST){accountConnection='static';if(accountModal.style.display==='flex')renderAccountDialog();bootLoading.done();return false;}
 if(accountConfigPending)return accountConfigPending;
 clearTimeout(accountRetryTimer);accountRetryTimer=null;accountConnection='checking';if(accountModal.style.display==='flex')renderAccountDialog();
 accountConfigPending=(async()=>{
  try{const config=await accountRequest('config');accountsEnabled=config.enabled===true;accountConnection=accountsEnabled?'ready':'disabled';if(accountsEnabled){accountRetryCount=0;await refreshAccount();}}
  catch{accountConnection='offline';if(accountRetryCount<3){const delay=3000*2**accountRetryCount++;accountRetryTimer=setTimeout(()=>{accountRetryTimer=null;return initializeAccounts();},delay);}}
  finally{reflectAccount();bootLoading.done();}
  return accountsEnabled;
 })();
 try{return await accountConfigPending;}finally{accountConfigPending=null;}
}
$('retryAccounts').onclick=()=>{accountRetryCount=0;return initializeAccounts();};
addEventListener('online',()=>{if(!accountsEnabled)initializeAccounts();});
document.addEventListener('visibilitychange',()=>{if(!document.hidden&&!accountsEnabled&&accountConnection==='offline')initializeAccounts();});
function refreshRewards(){if(!playerAccount)return;clearTimeout(rewardRefreshTimer);rewardRefreshTimer=setTimeout(refreshAccount,1800);}
if(location.hash.includes('access_token=')){history.replaceState(null,'',location.pathname+location.search);if(!passwordRecoveryToken)toast('E-mail confirmado. Entre na sua conta para continuar.');}
if(passwordRecoveryToken)Promise.resolve().then(()=>{accountModal.style.display='flex';renderAccountDialog();$('recoveryPassword').focus({preventScroll:true});});
initializeAccounts();setInterval(refreshAccount,15*60*1000);
