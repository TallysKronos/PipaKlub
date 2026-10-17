// Presentation only: never changes combat rules, inputs or server rewards.
function updateBattleHUD(p){
 if(!mode||!p)return;
 const entry=ART_CONFIG.dex.entries.find(e=>p.soul?e.id===p.soul:e.atlas===art.basic(p.color));
 setText('partnerName',entry?.name||'Parceiro almático');
 setText('battleMode',state.trail?'Trilha · '+state.trail.split('-')[0]:state.daily?'Céu do dia':mode==='practice'?'Voo de treino':state.rules==='capture'?'Vale pipa':'Duelo de pipas');
 $('hud').dataset.danger=String(p.hp<=30&&!p.respawn);$('hud').dataset.phase=state.phase||'live';
 const key=(state.mode||'time')+'|'+(state.roundsToWin||3)+'|'+(p.rounds||0);
 if($('roundPips').dataset.key!==key){$('roundPips').dataset.key=key;$('roundPips').replaceChildren();if(state.mode==='rounds'){for(let n=0;n<(state.roundsToWin||3);n++){const pip=document.createElement('i');if(n<(p.rounds||0))pip.className='won';pip.setAttribute('aria-hidden','true');$('roundPips').append(pip);}$('roundPips').setAttribute('aria-label',(p.rounds||0)+' de '+(state.roundsToWin||3)+' rodadas vencidas');}}
 const blocked=!!(p.respawn||pausedAt||state.phase&&state.phase!=='live'),ready=!(p.skillCooldown>0)&&p.energy>=25&&!blocked;
 for(const b of document.querySelectorAll('.skill-actions button')){b.title=eng.type(p).description;b.disabled=!ready;}
 $('skillName').title=eng.type(p).description;
 const skill=p.skillTime>0?'Habilidade ativa':p.skillCooldown>0?'Recarga · '+p.skillCooldown.toFixed(1)+' s':p.energy<25?'Precisa de 25 de energia':'Pronta · 25 energia';setText('skillStatus',skill);
 setText('flightStatus',mode==='online'?(realtime?'Tempo real':'Conexão compatível')+' · '+ping+' ms':'Arraste ou use WASD para voar');
 const dodge=!(p.dodgeCooldown>0)&&p.energy>=eng.DODGE.cost&&!blocked;
 const button=document.querySelector('.hud-basics [data-key="dodge"]');button.title=p.dodgeCooldown>0?'Recarga · '+p.dodgeCooldown.toFixed(1)+' s':'Esquiva · Shift · 18 energia';button.disabled=!dodge;
 document.querySelector('.hud-basics [data-key=" "]').disabled=blocked||p.energy<12;
 for(const [id,value] of [['hp',p.hp],['energy',p.energy]]){const meter=$(id).parentElement;meter.setAttribute('role','meter');meter.setAttribute('aria-label',id==='hp'?'Durabilidade da linha':'Energia');meter.setAttribute('aria-valuemin','0');meter.setAttribute('aria-valuemax','100');meter.setAttribute('aria-valuenow',String(Math.max(0,Math.round(value))));}
}
