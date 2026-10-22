// Presentation only: identifiers and combat/progression rules remain independent of artwork.
function trailLeaderMarkup(trail,pose='idle',label=true){
 const leader=ART_CONFIG.designs.leaders[trail.id];if(!leader)return '';
 const atlas=art.atlases[leader.id],frame=atlas.animations[pose]?.[0]||'0';
 return '<span class="trail-leader-art">'+art.frameMarkup(leader.id,frame)+'</span>'+(label?'<span class="trail-leader-caption"><b>'+escapeHTML(leader.name)+'</b><small>Líder da Trilha</small></span>':'');
}
function renderTrailLeader(trail,stage){
 const leader=stage.boss&&districtLeaderKnown(trail)?ART_CONFIG.designs.leaders[trail.id]:null,id=leader?.id||'sr-assis-expressions',frame=leader?'14':'speaking';
 $('stageSpeaker').textContent=(leader?.name||'Sr. Assis')+':';
 const canvas=$('stageAssis'),context=canvas.getContext('2d');context.clearRect(0,0,canvas.width,canvas.height);
 art.load(id).then(ok=>{if(!ok||trailPick!==stage.id||$('trails').hidden)return;context.clearRect(0,0,canvas.width,canvas.height);art.draw(context,id,frame,0,0,canvas.width,canvas.height,true);});
}
const coin=document.querySelector('.coin-chip');if(coin?.firstChild?.nodeType===3)coin.firstChild.textContent='';if(coin)coin.insertAdjacentHTML('afterbegin',art.icon('coin'));
const wallet=document.querySelector('.trail-wallet b');if(wallet?.firstChild?.nodeType===3)wallet.firstChild.textContent='';wallet?.insertAdjacentHTML('afterbegin',art.icon('coin'));
for(const [selector,id]of [['.trade-panel h3','trade'],['#summonMenu h3','summon'],['#summonDamaged h3','tail-damaged']])document.querySelector(selector)?.insertAdjacentHTML('afterbegin',art.icon(id));
