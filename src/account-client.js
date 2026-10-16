// This script is embedded into the page. It never stores authentication tokens.
let playerAccount=null,accountsEnabled=false,accountTab='login',accountSaving=false,rewardRefreshTimer;
const accountModal=$('accountModal');
async function accountRequest(action,body){
 const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),12000);
 try{const r=await fetch('/account/'+action,{method:body===undefined?'GET':'POST',headers:body===undefined?{}:{'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:controller.signal});const d=await r.json();if(!r.ok)throw Error(d.error||'Não foi possível acessar sua conta.');return d;}finally{clearTimeout(timeout);}
}
function reflectAccount(){
 $('accountButton').textContent=playerAccount?'Minha conta':'Entrar';
 $('profileSummary').textContent=playerAccount?playerAccount.profile.nickname+' · Nível '+playerAccount.profile.level:'Jogue como visitante';
 $('accountHint').textContent=playerAccount?'Seu progresso e suas pipas ficam na sua conta.':'Entre para guardar pipas e ganhar XP nas disputas.';
 $('roomRules').querySelector('[value="capture"]').disabled=!playerAccount;
 if(!playerAccount&&$('roomRules').value==='capture')$('roomRules').value='casual';
 if(playerAccount){const p=playerAccount.profile,k=playerAccount.inventory.find(k=>k.id===p.equipped_kite_id);$('name').value=p.nickname;$('name').readOnly=true;if(k){selected=k.model.color;choices();$('selectionName').textContent=k.model.name+' · equipada';}}
 else $('name').readOnly=false;
 if(accountModal.style.display==='flex')renderAccountDialog();
}
async function refreshAccount(){
 if(!accountsEnabled)return;
 try{const d=await accountRequest('session');playerAccount=d.account;reflectAccount();}catch(e){if(accountModal.style.display==='flex')$('accountMessage').textContent=e.message;}
}
function renderAccountDialog(){
 const logged=!!playerAccount;$('accountAuth').hidden=logged;$('accountCollection').hidden=!logged;
 $('accountTitle').textContent=logged?'Sua coleção, sua história.':accountTab==='signup'?'Seu lugar no céu.':'De volta ao céu.';
 $('signupFields').hidden=accountTab!=='signup';$('accountPassword').autocomplete=accountTab==='signup'?'new-password':'current-password';
 $('submitAccount').textContent=accountTab==='signup'?'Criar minha conta':'Entrar';$('switchAccount').textContent=accountTab==='signup'?'Já tenho uma conta':'Ainda não tenho conta';
 $('submitAccount').disabled=!accountsEnabled||accountSaving;
 if(accountsEnabled&&$('accountMessage').textContent==='O serviço de contas ainda está sendo conectado. O treino e as salas casuais continuam disponíveis.')$('accountMessage').textContent='';
 if(!accountsEnabled)$('accountMessage').textContent='O serviço de contas ainda está sendo conectado. O treino e as salas casuais continuam disponíveis.';
 if(!logged)return;
 const p=playerAccount.profile;$('accountNickname').value=p.nickname;
 $('accountLevel').textContent='Nível '+p.level;$('accountXP').textContent=p.xp+' / '+p.next_level_xp+' XP';
 const base=(p.level-1)**2*100;$('accountXPBar').style.width=Math.min(100,(p.xp-base)/Math.max(1,p.next_level_xp-base)*100)+'%';
 $('accountCuts').textContent=p.cuts+' cortes';$('collectionCount').textContent=playerAccount.inventory.length+' pipas';
 const list=$('inventoryList');list.replaceChildren(...playerAccount.inventory.map(k=>{
   const card=document.createElement('article');card.className='inventory-card'+(k.id===p.equipped_kite_id?' equipped':'');
   const art=document.createElement('div');art.className='inventory-art';art.innerHTML=kiteSVG(colors[k.model.color]||colors[0]);
   const name=document.createElement('b');name.textContent=k.model.name;
   const badge=document.createElement('small');badge.textContent=k.permanent?'Básica permanente':k.capture_count?'Conquistada em duelo':'Colecionável';
   const button=document.createElement('button');button.className='secondary';button.textContent=k.id===p.equipped_kite_id?'Equipada':'Equipar';button.disabled=accountSaving||k.id===p.equipped_kite_id||!!mode;
   button.onclick=async()=>{accountSaving=true;renderAccountDialog();try{const d=await accountRequest('equip',{kiteId:k.id});playerAccount=d.account;reflectAccount();toast('Pipa equipada. Pronta para voar!');}catch(e){$('accountMessage').textContent=e.message;}finally{accountSaving=false;renderAccountDialog();}};
   card.append(art,name,badge,button);return card;
 }));
}
async function openAccount(){
 if(mode){toast('Saia da partida para abrir sua coleção.');return;}
 keys={};$('accountMessage').textContent='';accountModal.style.display='flex';renderAccountDialog();$('closeAccount').focus();await refreshAccount();
}
function closeAccount(){accountModal.style.display='none';$('accountPassword').value='';$('accountButton').focus();}
$('accountButton').onclick=openAccount;$('closeAccount').onclick=closeAccount;
accountModal.onclick=e=>{if(e.target===accountModal)closeAccount();};
$('switchAccount').onclick=()=>{accountTab=accountTab==='login'?'signup':'login';$('accountMessage').textContent='';renderAccountDialog();};
$('accountForm').onsubmit=async e=>{
 e.preventDefault();if(accountSaving||!accountsEnabled)return;accountSaving=true;renderAccountDialog();$('accountMessage').textContent='Conectando…';
 try{const d=await accountRequest(accountTab,{email:$('accountEmail').value,password:$('accountPassword').value,nickname:$('signupName').value});$('accountPassword').value='';
   if(d.confirmation){accountTab='login';$('accountMessage').textContent=d.message;}
   else{playerAccount=d.account;reflectAccount();$('accountMessage').textContent='Conta conectada. Sua coleção está pronta.';toast('Bem-vindo ao Pipa Club!');}
 }catch(e){$('accountMessage').textContent=e.name==='AbortError'?'A conexão demorou. Tente novamente.':e.message;}
 finally{accountSaving=false;renderAccountDialog();}
};
$('nicknameForm').onsubmit=async e=>{e.preventDefault();try{const d=await accountRequest('profile',{nickname:$('accountNickname').value});playerAccount=d.account;reflectAccount();$('accountMessage').textContent='Apelido atualizado.';}catch(e){$('accountMessage').textContent=e.message;}};
$('logoutAccount').onclick=async()=>{if(mode)return;try{await accountRequest('logout',{});playerAccount=null;reflectAccount();$('accountMessage').textContent='Você saiu da conta.';}catch(e){$('accountMessage').textContent=e.message;}};
$('roomRules').onchange=()=>$('rulesDescription').textContent=$('roomRules').value==='capture'?'Vale pipa: ao ser cortado, você perde a pipa equipada para o adversário.':'Casual: suas pipas ficam protegidas. Cortes entre contas rendem XP.';
addEventListener('keydown',e=>{
 if(accountModal.style.display!=='flex')return;
 if(e.key==='Escape'){e.preventDefault();closeAccount();}
 if(e.key==='Tab'){const items=[...accountModal.querySelectorAll('button,input')].filter(el=>!el.disabled&&el.getClientRects().length);const first=items[0],last=items.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}
});
async function initializeAccounts(){
 if(typeof STATIC_HOST!=='undefined'&&STATIC_HOST)return;
 try{accountsEnabled=(await accountRequest('config')).enabled;if(accountsEnabled)await refreshAccount();}catch{}reflectAccount();
}
function refreshRewards(){if(!playerAccount)return;clearTimeout(rewardRefreshTimer);rewardRefreshTimer=setTimeout(refreshAccount,1800);}
if(location.hash.includes('access_token=')){history.replaceState(null,'',location.pathname+location.search);toast('E-mail confirmado. Entre na sua conta para continuar.');}
initializeAccounts();setInterval(refreshAccount,15*60*1000);
