// Presentation only: engine coordinates, contacts and server state stay authoritative.
function cinematicBattleActive(){return !!mode&&!!state&&state.players.length===2;}
const duelHud=document.createElement('section');duelHud.className='duel-hud';duelHud.hidden=true;duelHud.setAttribute('aria-label','Pipeiros e parceiros');
for(const side of ['you','rival']){
 const identity=document.createElement('div');identity.className='duel-pipeiro duel-'+side;
 identity.innerHTML='<canvas width="120" height="120" aria-hidden="true"></canvas><div><b></b><small></small><span class="duel-wins"></span></div>';
 const partner=document.createElement('div');partner.className='duel-partner duel-'+side;
 partner.innerHTML='<canvas width="96" height="96" aria-hidden="true"></canvas><div class="duel-partner-copy"><b></b><div class="duel-line"><span>Linha</span><div role="meter" aria-label="Integridade da linha" aria-valuemin="0" aria-valuemax="100"><i></i></div><strong></strong></div>'+(side==='you'?'<div class="duel-energy"><span>Energia</span><div role="meter" aria-label="Energia" aria-valuemin="0" aria-valuemax="100"><i></i></div><strong></strong></div>':'')+'</div>';
 duelHud.append(identity,partner);
}
$('hud').append(duelHud);
const duelLoads=new Set();let duelPaintAt=0;
function duelActorName(p){return p.soul==='nozinho'?'Sr. Assis':worldActors.get(p.name)?.name||null;}
function duelLoadActor(p){const name=duelActorName(p);if(name&&!duelLoads.has(name)){duelLoads.add(name);loadWorldActors([name]).catch(()=>{duelLoads.delete(name);});}}
function duelHuman(g,p,x,y,height,time,portrait=false){
 const mine=p.id===me,name=duelActorName(p),left=(p.anchorX??500)<500;
 g.save();
 if(state.wild&&!mine){art.creature(g,p.color,time,x-height/2,y-height,height,{...p,animate:!reduceMotion});g.restore();return;}
 if(mine){gameAvatar.setOwner(playerAccount?.profile?.id);if(gameAvatar.draw(g,{x,y,height,dir:portrait?'se':left?'ne':'nw',action:'parado',time})){g.restore();return;}}
 if(name&&worldActors.draw(g,homeImages,name,x,y,height,{direction:portrait?0:left?2:1,time})){g.restore();return;}
 // An unknown online player has no replicated avatar yet: use an explicit neutral silhouette.
 g.fillStyle='#284b54';g.strokeStyle='#d7bc7a';g.lineWidth=1.5;g.beginPath();g.ellipse(x,y-height*.74,height*.16,height*.19,0,0,Math.PI*2);g.fill();g.stroke();g.beginPath();g.roundRect(x-height*.24,y-height*.5,height*.48,height*.48,height*.12);g.fill();g.stroke();
 g.fillStyle='#f4e5bc';g.font='700 '+Math.round(height*.15)+'px Nunito,sans-serif';g.textAlign='center';g.fillText((p.name||'?').slice(0,1).toUpperCase(),x,y-height*.25);g.restore();
}
function drawBattlePipeiros(time){
 if(!cinematicBattleActive())return;
 for(const p of renderPlayers||state.players){
  if(state.wild&&p.id!==me)continue;duelLoadActor(p);const x=eng.line(p).a.x,y=eng.line(p).a.y+30,left=x<500,active=!reduceMotion&&!p.respawn&&(p.flash>0||p.skillTime>0);
  ctx.save();ctx.fillStyle='#10334640';ctx.beginPath();ctx.ellipse(x,y-2,30,8,0,0,Math.PI*2);ctx.fill();
  ctx.save();if(active){ctx.translate(x,y);ctx.rotate((left?-1:1)*.025);ctx.translate(-x,-y);}
  duelHuman(ctx,p,x,y,108,time);ctx.restore();
  // The spool is exactly at the authoritative origin of the line, including during a cut.
  const a=eng.line(p).a;ctx.strokeStyle='#eac89a';ctx.lineWidth=6;ctx.lineCap='round';ctx.beginPath();ctx.moveTo(x+(left?14:-14),a.y+7);ctx.lineTo(a.x,a.y);ctx.stroke();
  ctx.fillStyle='#b97e41';ctx.strokeStyle='#294547';ctx.lineWidth=2;ctx.beginPath();ctx.roundRect(a.x-9,a.y-7,18,14,3);ctx.fill();ctx.stroke();ctx.strokeStyle='#f4dfb5';ctx.lineWidth=1.5;for(let i=-4;i<6;i+=3){ctx.beginPath();ctx.moveTo(a.x-6,a.y+i);ctx.lineTo(a.x+6,a.y+i);ctx.stroke();}
  ctx.restore();
 }
}
function updateCinematicBattle(p){
 const active=cinematicBattleActive();document.body.classList.toggle('cinematic-battle',active);duelHud.hidden=!active;if(!active)return;
 const players=renderPlayers||state.players,rival=players.find(q=>q.id!==me);if(!rival)return;
 const now=performance.now(),paint=now-duelPaintAt>90;if(paint)duelPaintAt=now;
 for(const [side,q]of [['you',p],['rival',rival]]){
  duelLoadActor(q);const head=duelHud.querySelector('.duel-pipeiro.duel-'+side),panel=duelHud.querySelector('.duel-partner.duel-'+side),entry=ART_CONFIG.dex.entries.find(e=>q.soul?e.id===q.soul:e.atlas===art.basic(q.color));
  const name=q.partnerName||entry?.name||'Soulmonster',stats=eng.pipamonStats(q),hp=Math.max(0,Math.min(100,q.hp/stats.line*100));
  const write=(el,text)=>{if(el.textContent!==text)el.textContent=text;};
  write(head.querySelector('b'),q.name);write(head.querySelector('small'),side==='you'&&playerAccount?'Pipeiro · Nv. '+(playerAccount.profile.level||1):q.soul==='nozinho'?'Professor · treino sem perdas':state.wild?'Soulmonster selvagem':'Pipeiro rival');
  write(head.querySelector('.duel-wins'),state.mode==='rounds'?(q.rounds||0)+' / '+(state.roundsToWin||3)+' vitórias':'Duelo em tempo real');
  write(panel.querySelector('b'),name+' · Nv. '+eng.pipamons.level(q.pipamonLevel));
  const meter=panel.querySelector('.duel-line [role=meter]');meter.setAttribute('aria-valuenow',String(Math.round(hp)));meter.querySelector('i').style.width=hp+'%';write(panel.querySelector('.duel-line strong'),Math.round(hp)+'%');panel.dataset.danger=String(hp<=30);
  if(side==='you'){const energy=Math.max(0,Math.min(100,q.energy/stats.energy*100)),bar=panel.querySelector('.duel-energy [role=meter]');bar.setAttribute('aria-valuenow',String(Math.round(energy)));bar.querySelector('i').style.width=energy+'%';write(panel.querySelector('.duel-energy strong'),Math.round(energy)+'%');}
  if(paint){const face=head.querySelector('canvas'),g=face.getContext('2d');g.clearRect(0,0,120,120);duelHuman(g,q,60,177,187,now,true);const thumb=panel.querySelector('canvas'),cg=thumb.getContext('2d');cg.clearRect(0,0,96,96);art.creature(cg,q.color,now,0,0,96,{...q,animate:!reduceMotion});}
 }
}
