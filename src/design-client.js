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
function summonDesignReveal(reveal){
 for(const className of ['ritual-reveal-portal','ritual-reveal-particles']){const effect=uiElement('span',undefined,className);effect.setAttribute('aria-hidden','true');reveal.append(effect);}
}
const designVars={'--ritual-scene':ART_CONFIG.designs.ritual.background,'--ritual-portal':ART_CONFIG.designs.ritual.portal,'--ritual-particles':ART_CONFIG.designs.ritual.particles};
for(const [key,id]of Object.entries(designVars))document.documentElement.style.setProperty(key,'url("'+art.atlases[id].meta.url+'")');
// Generated sheets are 1254 px, not a multiple of four: CSS also uses the actual integer frames.
function designFrameCSS(id,key){const a=art.atlases[id],r=a.frames[String(key)].frame;return 'background-size:'+a.meta.size.w/r.w*100+'% '+a.meta.size.h/r.h*100+'%;background-position:'+r.x/(a.meta.size.w-r.w)*100+'% '+r.y/(a.meta.size.h-r.h)*100+'%;';}
function designKeyframes(name,id,seq,fade=false){return '@keyframes '+name+'{'+seq.map((key,i)=>i/seq.length*100+'%{'+designFrameCSS(id,key)+(fade?'opacity:'+(i===0?0:1)+';':'')+'}').join('')+'100%{'+designFrameCSS(id,seq.at(-1))+(fade?'opacity:0;':'')+'}}';}
const ritualStyles=document.createElement('style'),portalId=ART_CONFIG.designs.ritual.portal,particlesId=ART_CONFIG.designs.ritual.particles;
ritualStyles.textContent=designKeyframes('ritual-pulse',portalId,[8,9,10,11])+designKeyframes('ritual-reveal',portalId,Array.from({length:16},(_,i)=>i),true)+designKeyframes('ritual-particles',particlesId,[12,13,14,15],true)+'.ritual-board-portal{'+designFrameCSS(portalId,8)+'}@media(prefers-reduced-motion:reduce){.ritual-reveal-portal{'+designFrameCSS(portalId,8)+'}}';document.head.append(ritualStyles);
const ritualPortal=uiElement('span',undefined,'ritual-board-portal');ritualPortal.setAttribute('aria-hidden','true');$('summonBoard').prepend(ritualPortal);
const coin=document.querySelector('.coin-chip');if(coin?.firstChild?.nodeType===3)coin.firstChild.textContent='';if(coin)coin.insertAdjacentHTML('afterbegin',art.icon('coin'));
const wallet=document.querySelector('.trail-wallet b');if(wallet?.firstChild?.nodeType===3)wallet.firstChild.textContent='';wallet?.insertAdjacentHTML('afterbegin',art.icon('coin'));
for(const [selector,id]of [['.trade-panel h3','trade'],['#summonMenu h3','summon'],['#summonDamaged h3','tail-damaged']])document.querySelector(selector)?.insertAdjacentHTML('afterbegin',art.icon(id));
