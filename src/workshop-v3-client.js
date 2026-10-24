// The authenticated game opens the same approved canvas; the server owns its state and rewards.
let workshopV3Frame=null,workshopV3Closing=false,starterBirthSave=null;
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
  const owner=journeyOwner,epoch=journeyEpoch,jobId=event.data.jobId;
  starterBirthSave=(async()=>{
   try{
    const d=await accountRequest('session');if(owner!==journeyOwner||epoch!==journeyEpoch)return false;
    playerAccount=d.account;reflectAccount();
    if(event.data.completed&&journey?.starterTutorial?.required&&journey.starterTutorial.jobId===jobId){
     return !!await saveJourney('starter-finish');
    }
   }catch{toast('Parceiro salvo. Reabra a coleção para atualizar.');}
   return false;
  })();
 }
 if(event.data.type==='oficina-v3:close'){
  const owner=journeyOwner,epoch=journeyEpoch,wasTutorial=journey?.starterTutorial?.jobId===event.data.jobId;
  workshopV3Frame.remove();workshopV3Frame=null;accountModal.inert=false;workshopV3Closing=true;
  try{
   if(starterBirthSave)await starterBirthSave;
   if(owner!==journeyOwner||epoch!==journeyEpoch)return;
   // The persisted birth also reconciles if the result message was interrupted.
   if(wasTutorial)await saveJourney('read');
   await loadSummonTails();
  }finally{
   starterBirthSave=null;workshopV3Closing=false;
   if(owner===journeyOwner&&epoch===journeyEpoch){
    summonRitual=null;showSummonStage('npc');
    if(wasTutorial){leaveSummoner();closeAccount();showCourtyard();if(journey?.phase==='complete')starterTutorialCompleteDialogue();else renderStarterTutorial();}
   }
  }
 }
});
const legacyWorkshopCall=workshopCall;
workshopCall=async function(action,extra={}){
 if(action==='start'){const result=(await accountRequest('workshop-v3',{action,...extra})).workshop;return {...result,v3:true};}
 return legacyWorkshopCall(action,extra);
};

const v3LegacyLoad=workshopLoadArt;workshopLoadArt=async function(...args){if(!summonRitual?.v3)return v3LegacyLoad(...args);};

const v3CatalogRender=renderSummonCatalog;renderSummonCatalog=function(){v3CatalogRender();const cards=$('summonSeenGrid').children;const labels=['Diamante · 4 apoios','Pentágono · 5 apoios','Estrela de vento · 6 apoios'];for(let i=0;i<Math.min(3,cards.length);i++){const label=cards[i].querySelectorAll('small')[0];if(label)label.textContent=labels[i];}};
