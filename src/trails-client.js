// Trilhas UI: trail map, stage briefing, AI duels and coin payouts. Progress is stored on this device.
const trails=createTrails(),TRAILS_KEY='pipaTrailsV1',TYPE_NAMES=['Precisa','Ágil','Guardiã','Técnica'];
let trailProgress=loadTrails(),trailStage=null,trailPick=null;
function loadTrails(){try{return trails.sanitize(JSON.parse(localStorage.getItem(TRAILS_KEY)||'null'));}catch{return trails.defaults();}}
function saveTrails(){try{localStorage.setItem(TRAILS_KEY,JSON.stringify(trailProgress));}catch{}}
function reflectCoins(){setText('coinCount',String(trailProgress.coins));}
const starText=n=>'★'.repeat(n)+'☆'.repeat(3-n);
function firstOpenStage(){return trails.stages.find(s=>trails.unlocked(trailProgress,s.id)&&!trailProgress.stars[s.id])||trails.stages.at(-1);}
function openTrails(){
 if(mode){toast('Saia da partida para abrir as trilhas.');return;}
 trailPick=trailPick&&trails.unlocked(trailProgress,trailPick)?trailPick:firstOpenStage().id;
 renderTrails();$('trails').hidden=false;$('trails').style.display='flex';$('trailStart').focus({preventScroll:true});
}
function closeTrails(){$('trails').hidden=true;$('trails').style.display='none';}
function renderTrails(){
 setText('trailCoins',String(trailProgress.coins));
 const bonus=Math.floor(trailProgress.mastery/2);
 setText('trailMastery','Maestria '+trailProgress.mastery+'/'+trails.MASTERY_MAX+(bonus?' · a IA está +'+bonus+' nível'+(bonus>1?'s':'')+' mais esperta':' · a IA ainda está te conhecendo'));
 $('trailList').replaceChildren(...trails.trails.map(t=>{
  const card=document.createElement('section');card.className='trail';card.style.setProperty('--accent',t.accent);
  const earned=t.stages.reduce((n,s)=>n+(trailProgress.stars[s.id]||0),0);
  card.innerHTML='<header><div><b></b><small></small></div><span class="trail-stars"></span></header><div class="trail-path"></div>';
  card.querySelector('b').textContent=t.name;card.querySelector('small').textContent=t.subtitle;card.querySelector('.trail-stars').textContent='★ '+earned+'/'+t.stages.length*3;
  card.querySelector('.trail-path').append(...t.stages.map((s,i)=>{
   const node=document.createElement('button'),open=trails.unlocked(trailProgress,s.id),stars=trailProgress.stars[s.id]||0;
   node.className='trail-node'+(s.boss?' boss':'')+(open?'':' locked')+(stars?' cleared':'')+(s.id===trailPick?' picked':'');
   node.innerHTML='<span class="node-dot"></span><span class="node-stars"></span>';
   node.querySelector('.node-dot').textContent=open?(s.boss?'☠':String(i+1)):'🔒';node.querySelector('.node-stars').textContent=stars?starText(stars):'';
   node.setAttribute('aria-label',s.name+(open?'':' (bloqueada)')+(stars?' · '+stars+' estrelas':''));node.setAttribute('aria-pressed',String(s.id===trailPick));
   node.onclick=()=>{trailPick=s.id;renderTrails();};return node;}));
  return card;}));
 renderStage();
}
function renderStage(){
 const st=trails.stage(trailPick),open=trails.unlocked(trailProgress,st.id),level=trails.aiLevel(st,trailProgress),best=trailProgress.stars[st.id]||0,trail=trails.trails[st.trailIndex];
 setText('stageTrail',trail.name+' · Etapa '+(st.index+1)+(st.boss?' · CHEFE':''));setText('stageName',st.name);
 $('stageFoes').replaceChildren(...st.foes.map(f=>{const row=document.createElement('div');row.className='stage-foe';row.innerHTML='<span class="foe-art">'+art.markup(f.color,f.soul)+'</span><div><b></b><small></small></div>';row.querySelector('b').textContent=f.name;row.querySelector('small').textContent=TYPE_NAMES[f.color]+(f.soul?' · Alma lendária':'');return row;}));
 setText('stageLevel','IA nível '+level+(level>st.level?' (base '+st.level+', +'+(level-st.level)+' pela sua maestria)':''));
 setText('stageFormat','Melhor de '+(st.rounds*2-1)+' · vence quem fizer '+st.rounds+' rodada'+(st.rounds>1?'s':''));
 setText('stageReward','🪙 '+st.coins+'–'+Math.round(st.coins*1.5)+' moedas'+(best?'':' · +'+st.coins+' na primeira vitória'));
 setText('stageBest',best?'Seu melhor: '+starText(best):'Ainda não vencida');
 setText('stageTip',st.tip);
 $('trailStart').disabled=!open;$('trailStart').textContent=open?(best?'Voar de novo ▶':'Voar ▶'):'Vença a etapa anterior';
 if(art.load)art.load('sr-assis-expressions').then(()=>{const c=$('stageAssis'),g=c.getContext('2d');g.clearRect(0,0,c.width,c.height);art.draw(g,'sr-assis-expressions','speaking',0,0,c.width,c.height,true);});
}
function startStage(id){
 const st=trails.stage(id);if(!st||!trails.unlocked(trailProgress,id))return;
 closeTrails();const now=Date.now(),level=trails.aiLevel(st,trailProgress),s=eng.create(now,{mode:'rounds',roundsToWin:st.rounds});s.trail=id;
 eng.admit(s,trainee(now),now);
 st.foes.forEach((f,i)=>{const b=eng.player(f.name,f.color,'ai'+i,now);b.bot=true;b.ai={level};if(f.soul){b.soul=f.soul;art.load(f.soul);}eng.admit(s,b,now);});
 trailStage=id;enter(s,'you','practice');setText('liveLabel',st.name+' · IA nível '+level);
}
// Called by the results screen when a trail duel ends.
function showTrailResult(s,ranking,mine){
 const won=(mine?.rounds||0)>=s.roundsToWin,r=trails.settle(trailProgress,s.trail,{won,roundsLost:Math.max(0,(s.round||0)-(mine?.rounds||0))});
 trailProgress=r.progress;saveTrails();reflectCoins();
 const st=trails.stage(s.trail),next=trails.nextStage(s.trail),canNext=won&&next&&trails.unlocked(trailProgress,next.id);
 const rows=ranking.map((q,i)=>'<div class="result-rank'+(q.id===me?' me':'')+'"><span><i class="result-dot" style="background:'+playerColor(q)+'"></i>'+(i+1)+'. '+escapeHTML(q.name)+(q.id===me?' · você':'')+'</span><b>'+(q.rounds||0)+' ★</b></div>').join('');
 const levelNote=r.levelAfter>r.levelBefore?'A IA aprendeu com você: agora ela joga no nível '+r.levelAfter+'.':r.levelAfter<r.levelBefore?'A IA vai pegar um pouco mais leve: nível '+r.levelAfter+'.':'IA desta etapa: nível '+r.levelAfter+'.';
 modal(won?(st.boss?'Chefe derrotado!':'Etapa vencida!'):'Não foi dessa vez.',
  '<div class="trail-result"><div class="result-stars">'+starText(r.stars)+'</div>'+(won?'<div class="coin-gain">+'+r.coins+' 🪙'+(r.firstClear?'<small>inclui bônus da primeira vitória</small>':'')+'</div>':'<p>Rodadas vencidas: '+(mine?.rounds||0)+' de '+s.roundsToWin+'. Treine o cruzamento e tente de novo.</p>')+'<p class="trail-note">'+levelNote+' Total: '+trailProgress.coins+' moedas.</p></div>'+rows+
  '<button class="primary" id="rematchButton">'+(canNext?'Próxima etapa ▶':'Tentar de novo ↻')+'</button>','Voltar às trilhas',st.name);
 $('rematchButton').onclick=()=>{closeModal();startStage(canNext?next.id:s.trail);};
 $('dialogAction').className='secondary';$('dialogAction').onclick=()=>{closeModal();openTrails();};
}
$('trailsButton').onclick=openTrails;$('trailsClose').onclick=closeTrails;$('trailStart').onclick=()=>startStage(trailPick);
$('trails').onclick=e=>{if(e.target===$('trails'))closeTrails();};
addEventListener('keydown',e=>{if(e.key==='Escape'&&!$('trails').hidden)closeTrails();});
reflectCoins();
