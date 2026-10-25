let signatureUntil=0;const signatureBanner=createSignatureBanner(document.body,ART_CONFIG.signatures.images),signatureSeen=new Map();let signatureMatch=null;
const signatureButton=uiElement('button','Pulo do Elo · T','signature-button');signatureButton.hidden=true;document.body.append(signatureButton);
function queueSignature(){const p=mode&&ownKite(),def=p&&eng.signature(p);if(!battleLive()||!p||!def||p.bossId||p.signatureCooldown>0||p.signatureWindup>0||p.guardTime>0||p.evade>0||p.lineMove||p.energy<def.cost)return;if(!eng.signatureTarget(state,p)){toast('Aproxime-se de uma pipa rival para usar o especial.');return;}signatureUntil=Date.now()+220;}
signatureButton.onclick=queueSignature;addEventListener('keydown',e=>{if(e.key.toLowerCase()==='t'&&!e.repeat&&!e.target?.closest('input,textarea,select,[contenteditable=true]')&&battleLive()){e.preventDefault();queueSignature();}});
addEventListener('blur',()=>{signatureUntil=0;});document.addEventListener('visibilitychange',()=>{signatureUntil=0;});
const signatureUpdateHUD=updateBattleHUD;
updateBattleHUD=function(p){signatureUpdateHUD(p);if(signatureMatch!==state?.id){signatureMatch=state?.id;signatureSeen.clear();signatureBanner.hide();}
 const def=p&&eng.signature(p),blocked=!battleLive()||p?.respawn||state?.phase&&state.phase!=='live';signatureButton.hidden=!def||!!p?.bossId||showResult;
 if(!signatureButton.hidden){const inRange=!!eng.signatureTarget(state,p),command=inputDevice.startsWith('gamepad')?'RT / R2':'T',text=p.signatureWindup>0?'Preparando…':p.signatureCooldown>0?Math.ceil(p.signatureCooldown)+' s':p.energy<def.cost?'Precisa de '+def.cost+' energia':!inRange?'Aproxime-se do rival':def.cost+' energia · '+command;signatureButton.textContent=def.name+' · '+text;signatureButton.setAttribute('aria-disabled',String(!!(blocked||!inRange||p.signatureCooldown>0||p.signatureWindup>0||p.energy<def.cost||p.guardTime>0||p.evade>0||p.lineMove)));}
 if(!blocked)for(const q of state.players){const count=q.signatureCount||0,key=q.id,prior=signatureSeen.get(key)||0;signatureSeen.set(key,count);if(count>prior&&q.signatureWindup>0){const info=eng.signature(q);if(info)signatureBanner.show(info.id,{enemy:q.id!==me});}}
};
const signatureDrawBattle=drawGuardianBattle;
drawGuardianBattle=function(time){
 signatureDrawBattle(time);if(!mode||!state)return;
 for(const p of renderPlayers||state.players){
  const a=p.signatureAim;if(!a||p.respawn)continue;const def=eng.signature(p);if(!def)continue;
  const knot=def.id==='nozinho';ctx.save();ctx.strokeStyle=p.bossId||knot?'#ffcf78':'#66e8e2';ctx.fillStyle=p.bossId?'#ff923522':knot?'#ffd78622':'#66e8e222';
  if(p.signatureWindup>0){
   const progress=1-p.signatureWindup/def.windup;ctx.setLineDash([8,6]);ctx.lineWidth=2;ctx.beginPath();ctx.arc(a.x,a.y,def.radius,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.setLineDash([]);ctx.lineWidth=4;ctx.beginPath();ctx.arc(a.x,a.y,def.radius+7,-Math.PI/2,-Math.PI/2+Math.PI*2*progress);ctx.stroke();
  }else if(p.signatureBurst>0){
   const progress=1-p.signatureBurst/.45;ctx.globalAlpha=p.signatureBurst/.45;ctx.lineWidth=7;ctx.beginPath();ctx.moveTo(p.x,p.y);ctx.quadraticCurveTo((p.x+a.x)/2,Math.min(p.y,a.y)-90,a.x,a.y);ctx.stroke();ctx.beginPath();
   if(knot){const radius=reduceMotion?def.radius*.7:20+progress*def.radius;for(let i=0;i<=64;i++){const t=i/64*Math.PI*2,x=a.x+Math.sin(t)*radius,y=a.y+Math.sin(t*2)*radius*.45;if(i)ctx.lineTo(x,y);else ctx.moveTo(x,y);}ctx.stroke();ctx.strokeStyle='#66e8e2';ctx.lineWidth=2;ctx.stroke();}
   else{ctx.arc(a.x,a.y,15+progress*def.radius,0,Math.PI*2);ctx.stroke();}
  }
  ctx.restore();
 }
};
const signatureLeave=leave;leave=function(...args){signatureBanner.hide();signatureButton.hidden=true;signatureUntil=0;signatureSeen.clear();return signatureLeave(...args);};
