// The authenticated game opens the same approved canvas; the server owns its state and rewards.
let workshopV3Frame=null,workshopV3Closing=false;
const legacyWorkshopRender=renderWorkshop;
renderWorkshop=function(){
 if(workshopV3Closing){showSummonStage('npc');return;}
 if(!summonRitual?.v3){legacyWorkshopRender();return;}
 if(workshopFrame)cancelAnimationFrame(workshopFrame);workshopFrame=0;workshopDraw=null;showSummonStage('build');
 if(workshopV3Frame?.dataset.job===summonRitual.id)return;
 workshopV3Frame?.remove();workshopV3Frame=document.createElement('iframe');workshopV3Frame.title='Oficina das Almas — montagem salva na conta';workshopV3Frame.dataset.job=summonRitual.id;
 workshopV3Frame.src='/oficina-v3/?job='+encodeURIComponent(summonRitual.id);workshopV3Frame.className='workshop-v3-frame';document.body.append(workshopV3Frame);accountModal.inert=true;
};
globalThis.addEventListener?.('message',async event=>{
 if(event.origin!==location.origin||event.source!==workshopV3Frame?.contentWindow||event.data?.jobId!==workshopV3Frame.dataset.job)return;
 if(event.data.type==='oficina-v3:saved'){
  try{const d=await accountRequest('session');playerAccount=d.account;reflectAccount();}catch{toast('Parceiro salvo. Reabra a coleção para atualizar.');}
 }
 if(event.data.type==='oficina-v3:close'){
  workshopV3Frame.remove();workshopV3Frame=null;accountModal.inert=false;workshopV3Closing=true;try{await loadSummonTails();}finally{workshopV3Closing=false;summonRitual=null;showSummonStage('npc');}
 }
});
const legacyWorkshopCall=workshopCall;
workshopCall=async function(action,extra={}){
 if(action==='start'){const result=(await accountRequest('workshop-v3',{action,...extra})).workshop;return {...result,v3:true};}
 return legacyWorkshopCall(action,extra);
};

const v3LegacyLoad=workshopLoadArt;workshopLoadArt=async function(...args){if(!summonRitual?.v3)return v3LegacyLoad(...args);};

const v3CatalogRender=renderSummonCatalog;renderSummonCatalog=function(){v3CatalogRender();const cards=$('summonSeenGrid').children;const labels=['Diamante · 4 apoios','Pentágono · 5 apoios','Estrela de vento · 6 apoios'];for(let i=0;i<Math.min(3,cards.length);i++){const label=cards[i].querySelectorAll('small')[0];if(label)label.textContent=labels[i];}};
