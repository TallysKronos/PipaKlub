let lineShopUser=null,lineShopData=null,lineShopBusy=false,playerLineStyle='classic',lineShopEpoch=0;
const lineShopPage=clubPage('lines');clubTitles.lines='Visuais de linha';
lineShopPage.innerHTML='<p class="collection-info">Cores, padrões e brilho para deixar sua marca no céu. Os visuais não mudam o desempenho da pipa.</p><p id="lineShopBalance"></p><p id="lineShopMessage" role="status" aria-live="polite"></p><button class="secondary" id="lineShopReload">Atualizar loja</button><div id="lineShopCards" class="line-shop-cards"></div>';
const lineShopEntry=uiElement('button','〰 Visuais de linha','secondary club-events');lineShopEntry.type='button';clubHome.insertBefore(lineShopEntry,eventLink);
lineShopEntry.onclick=()=>{navigateClub('lines');loadLineShop();};
const linePurchaseRequests=new Map();
function renderLineShop(){
 $('lineShopBalance').textContent=lineShopData?'Seu saldo: 🪙 '+lineShopData.progress.coins:'Carregando seus visuais…';
 $('lineShopReload').disabled=lineShopBusy;
 $('lineShopCards').replaceChildren(...(lineShopData?.catalog||[]).map(item=>{
  const style=lineStyles.get(item.id),owned=item.id==='classic'||lineShopData.owned.includes(item.id),equipped=lineShopData.equipped===item.id;
  const card=uiElement('article',undefined,'line-shop-card'+(equipped?' equipped':'')),preview=uiElement('div',undefined,'line-preview');
  preview.setAttribute('aria-hidden','true');preview.style.setProperty('--line-colour',style.colour||'#3f6e65');preview.classList.toggle('dotted',style.dash.length>0);preview.classList.toggle('glowing',style.glow);
  const button=uiElement('button',equipped?'Em uso':owned?'Usar este visual':'Comprar · 🪙 '+item.price,owned?'secondary':'primary');button.type='button';
  button.disabled=lineShopBusy||equipped||!!mode||!owned&&lineShopData.progress.coins<item.price;
  button.onclick=()=>changeLineStyle(owned?'equip':'buy',item.id);
  card.append(preview,uiElement('b',item.name),uiElement('small',equipped?'Sua linha atual':owned?'Na sua coleção':'Visual para sua conta'),button);return card;
 }));
}
async function loadLineShop(){
 const owner=playerAccount?.profile?.id;if(!owner||lineShopBusy)return;
 const epoch=lineShopEpoch;lineShopBusy=true;renderLineShop();
 try{const data=(await accountRequest('lines',{action:'read'})).lines;if(playerAccount?.profile?.id!==owner||epoch!==lineShopEpoch)return;lineShopData=data;playerLineStyle=data.equipped;trailSync.accept(data,owner);$('lineShopMessage').textContent='';}
 catch(e){if(playerAccount?.profile?.id===owner&&epoch===lineShopEpoch)$('lineShopMessage').textContent=e.message;}
 finally{if(playerAccount?.profile?.id===owner&&epoch===lineShopEpoch){lineShopBusy=false;renderLineShop();}}
}
async function changeLineStyle(action,id){
 if(lineShopBusy||mode)return;const owner=playerAccount?.profile?.id;if(!owner)return;const epoch=lineShopEpoch;
 lineShopBusy=true;renderLineShop();$('lineShopMessage').textContent=action==='buy'?'Conferindo suas moedas…':'Trocando o visual…';
 try{
  await trailSync.sync();
  if(playerAccount?.profile?.id!==owner||epoch!==lineShopEpoch)return;
  if(trailSync.pending(owner).length)throw Error('Aguarde suas Trilhas serem salvas antes de comprar.');
  if(!linePurchaseRequests.has(id))linePurchaseRequests.set(id,crypto.randomUUID());
  const data=(await accountRequest('lines',{action,styleId:id,...(action==='buy'?{operationId:linePurchaseRequests.get(id)}:{})})).lines;
  if(playerAccount?.profile?.id!==owner||epoch!==lineShopEpoch)return;
  lineShopData=data;playerLineStyle=data.equipped;trailSync.accept(data,owner);linePurchaseRequests.delete(id);
  $('lineShopMessage').textContent=action==='buy'?'Visual adquirido! Escolha Usar este visual para equipar.':'Seu novo visual está pronto para voar.';
 }catch(e){if(playerAccount?.profile?.id===owner&&epoch===lineShopEpoch)$('lineShopMessage').textContent=e.message;}
 finally{if(playerAccount?.profile?.id===owner&&epoch===lineShopEpoch){lineShopBusy=false;renderLineShop();}}
}
function onLineAccountChange(){const id=playerAccount?.profile?.id||null;if(id===lineShopUser)return;lineShopUser=id;lineShopEpoch++;lineShopData=null;lineShopBusy=false;playerLineStyle='classic';linePurchaseRequests.clear();renderLineShop();if(id)loadLineShop();}
$('lineShopReload').onclick=loadLineShop;
onLineAccountChange();
