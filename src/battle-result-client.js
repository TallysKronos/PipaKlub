// Shared presentation only. Each mode keeps its settlement and return flow.
let battleResultView=null,battleResultFrame=0,battleResultGeneration=0;
function clearBattleResult(){
 battleResultGeneration++;cancelAnimationFrame(battleResultFrame);battleResultView=null;
 const root=$('modal');root.classList.remove('battle-result');delete root.dataset.outcome;
 root.querySelector('.battle-result-hero')?.remove();root.querySelector('.battle-result-ribbon')?.remove();root.querySelector('.battle-result-progress')?.remove();
}
function presentBattleResult(s,ranking=[],mine=s.players?.find(p=>p.id===me)){
 const root=$('modal');if(root.style.display!=='flex'||!mine)return;
 if(battleResultView?.match===s.id&&root.classList.contains('battle-result'))return;
 const oldAccount=playerAccount?JSON.parse(JSON.stringify(playerAccount)):null;
 clearBattleResult();const generation=battleResultGeneration,rounds=s.mode==='rounds',fled=s.resultOutcome==='fled'||s.wildResult?.status==='fled'||s.wildResult?.outcome==='fled';
 const first=ranking[0],tie=!rounds&&first&&ranking.filter(p=>p.score===first.score).length>1&&mine.score===first.score;
 const won=rounds?(mine.rounds||0)>=s.roundsToWin:first?.id===mine.id;
 const outcome=fled?'fled':tie?'draw':won?'victory':'defeat';
 root.classList.add('battle-result');root.dataset.outcome=outcome;
 const dialog=root.querySelector('.dialog'),hero=uiElement('div',undefined,'battle-result-hero'),canvas=document.createElement('canvas');
 canvas.width=600;canvas.height=210;canvas.setAttribute('aria-hidden','true');hero.append(canvas);
 const ribbon=uiElement('div',undefined,'battle-result-ribbon'),title=uiElement('b',({victory:'Vitória!',defeat:'Derrota',fled:'Retirada',draw:'Empate'})[outcome]);
 ribbon.setAttribute('aria-hidden','true');ribbon.append(title);const ribbonAsset=ART_CONFIG.battleResults.images[won&&!fled&&!tie?'victory':'defeat'];
 ribbon.style.setProperty('--result-ribbon','url("'+ribbonAsset.url+'")');ribbon.style.setProperty('--result-slice',String(ribbonAsset.slice));
 const previousTitle=$('dialogTitle').textContent;$('dialogTitle').textContent=title.textContent;
 hero.setAttribute('aria-label',outcome==='victory'?'Seu pipeiro e parceiro comemoram.':outcome==='defeat'?'Seu pipeiro e parceiro recuperam o fôlego.':'Seu pipeiro e parceiro estão prontos para voltar.');
 $('dialogEyebrow').before(hero,ribbon);$('dialogEyebrow').textContent=s.wild?(worldScenes[s.wild.zone]?.name||'Parque dos Ventos'):s.daily?'Céu do dia':s.trail?trails.stage(s.trail).name:'Resultado do duelo';
 const progress=uiElement('div',undefined,'battle-result-progress');progress.setAttribute('aria-live','polite');$('dialogBody').prepend(progress);
 if(outcome!=='victory'){const tip=uiElement('div',undefined,'battle-result-tip');tip.append(uiElement('b',fled?'Parceiro protegido':outcome==='draw'?'Duelo equilibrado':'Uma nova chance'),uiElement('p',fled?'Você pode se preparar e voltar quando quiser.':outcome==='draw'?'O duelo terminou empatado. Que tal tentar mais uma vez?':'Observe o ataque do rival, esquive e aproveite a abertura.'));$('dialogBody').append(tip);}
 battleResultView={match:s.id,generation,before:oldAccount,mine:{...mine},progress,outcome,previousTitle};
 if(typeof gameAvatar!=='undefined'){gameAvatar.setOwner(playerAccount?.profile?.id);gameAvatar.load();}artLoadResultPartner(mine);
 const started=performance.now(),g=canvas.getContext('2d');if(!g)return;
 function paint(now){
  if(generation!==battleResultGeneration||root.style.display!=='flex'||!root.classList.contains('battle-result'))return;
  const still=reduceMotion||art.reduced,t=still?900:now-started;g.clearRect(0,0,600,210);
  const celebrating=outcome==='victory',jump=celebrating&&!still?Math.max(0,Math.sin(t/290))*9:0;
  g.save();g.fillStyle=celebrating?'#d3ad5140':'#24445530';g.beginPath();g.ellipse(295,197,138,9,0,0,Math.PI*2);g.fill();g.restore();
  // The avatar currently has standing and seated clips; keep its real appearance.
  gameAvatar.draw(g,{x:246,y:204-jump,height:152,dir:'se',action:celebrating?'parado':'sentado',time:t});
  const p={...mine,input:{x:0,y:0},facing:1,bossIntroTime:null,bossRoar:0,bossTelegraph:0,flash:0,skillCooldown:0,hitFlash:0,resultPose:celebrating?'victory':'defeat',resultTime:t};
  art.creature(g,mine.color,t,323,38-jump,160,p,celebrating);
  if(!still)battleResultFrame=requestAnimationFrame(paint);
 }
 // Paint once after assets resolve too, including in reduced motion.
 Promise.all([gameAvatar.load(),artLoadResultPartner(mine)]).then(()=>{if(generation===battleResultGeneration){cancelAnimationFrame(battleResultFrame);paint(performance.now());}});
 paint(started);dialog.scrollTop=0;
}
function artLoadResultPartner(p){return art.load(p.soul||art.basic(p.color));}
function renderBattleResultProgress({tamerXp=0,partnerXp=0,account=null}={}){
 const view=battleResultView;if(!view||!$('modal').classList.contains('battle-result'))return;
 const before=view.before,prior=before?.inventory?.find(k=>k.id===before.profile.equipped_kite_id),after=account?.inventory?.find(k=>k.id===prior?.id),mine=view.mine;
 const root=view.progress;root.replaceChildren();
 const rows=[{name:before?.profile.nickname||mine.name,xp:tamerXp,from:eng.tamers.progress(before?.profile.xp||0),to:eng.tamers.progress(account?.profile.xp??((before?.profile.xp||0)+tamerXp)),human:true},{name:prior?.personal_name||prior?.model?.name||mine.partnerName||art.special(mine.soul)?.name||'Parceiro',xp:partnerXp,from:eng.pipamons.progress(prior?.pipamon_xp||0),to:eng.pipamons.progress(after?.pipamon_xp??((prior?.pipamon_xp||0)+partnerXp))}];
 for(const row of rows){
  if(row.human?tamerXp===null:partnerXp===null)continue;
  const item=uiElement('div',undefined,'battle-result-xp'),portrait=document.createElement('canvas');portrait.width=72;portrait.height=72;portrait.setAttribute('aria-hidden','true');
  const text=uiElement('div',undefined,'battle-result-xp-copy'),heading=uiElement('div');heading.append(uiElement('b',row.name),uiElement('strong','+ '+(row.xp||0)+' XP'));
  const level=uiElement('small','Nv. '+row.from.level+(row.to.level>row.from.level?' → '+row.to.level:'')),meter=uiElement('div',undefined,'battle-result-xp-meter');meter.setAttribute('role','progressbar');meter.setAttribute('aria-label','Experiência de '+row.name);meter.setAttribute('aria-valuemin','0');meter.setAttribute('aria-valuemax','100');meter.setAttribute('aria-valuenow',String(Math.floor(row.to.percent)));
  const fill=uiElement('i');fill.style.width=row.to.percent+'%';meter.append(fill);const amount=row.to.next===null?'Nível máximo':(row.to.xp-row.to.start)+' / '+(row.to.next-row.to.start)+' XP';meter.setAttribute('aria-valuetext',amount+' · nível '+row.to.level);text.append(heading,level,meter,uiElement('small',amount,'battle-result-xp-total'));item.append(portrait,text);root.append(item);
  const g=portrait.getContext('2d');if(g)Promise.all([gameAvatar.load(),artLoadResultPartner(mine)]).then(()=>{if(view!==battleResultView||!portrait.isConnected)return;g.clearRect(0,0,72,72);if(row.human)gameAvatar.draw(g,{x:36,y:94,height:96,dir:'se',action:'parado',time:0});else art.creature(g,mine.color,0,4,4,64,{...mine,input:{x:0,y:0},hitFlash:0},false);});
 }
}
const resultBaseModal=modal;modal=function(...args){clearBattleResult();return resultBaseModal(...args);};
const resultBaseClose=closeModal;closeModal=function(...args){clearBattleResult();return resultBaseClose(...args);};
const resultBaseLeave=leave;leave=function(...args){clearBattleResult();return resultBaseLeave(...args);};
const resultBaseShow=showMatchResult;showMatchResult=function(s,ranking=[]){const value=resultBaseShow(s,ranking);presentBattleResult(s,ranking);return value;};
