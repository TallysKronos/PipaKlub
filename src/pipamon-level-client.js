// Bounded, stateless particles: no particle pool, timers or new sprite atlases.
function drawPipamonGlow(context,level,time,x,y,radius=48,light=false,reduced=false){
 const tier=eng.pipamons.tier(level);if(!tier)return;
 context.save();context.strokeStyle=tier.color;context.fillStyle=tier.color;
 const count=reduced?3:light?4:tier.id==='aura'?16:10,clock=reduced?0:time/1600;
 if(tier.id==='aura'){context.globalAlpha=.25;context.lineWidth=2;context.beginPath();context.ellipse(x,y+radius*.55,radius*.85,radius*.24,0,0,Math.PI*2);context.stroke();}
 for(let i=0;i<count;i++){
  const phase=i/count*Math.PI*2+clock*(i%2?-1:1)*.4,r=radius*(.65+.3*Math.sin(i*2.4+clock)),px=x+Math.cos(phase)*r,py=y+Math.sin(phase)*r*.8;
  const size=reduced?3:2.5+2*(.5+.5*Math.sin(clock*3+i));context.globalAlpha=reduced?.85:.55+.4*(.5+.5*Math.sin(clock*3+i));
  context.beginPath();context.moveTo(px-size*2,py);context.lineTo(px+size*2,py);context.moveTo(px,py-size*2);context.lineTo(px,py+size*2);context.lineWidth=Math.max(2,size*.65);context.stroke();
 }
 context.restore();
}
function pipamonProgress(kite){return eng.pipamons.progress(kite?.pipamon_xp);}
function renderPipamonProgress(kite){
 const root=$('inventoryProgress');if(!root)return;
 const p=pipamonProgress(kite),tier=p.tier;root.replaceChildren();root.dataset.tier=tier?.id||'none';
 const heading=uiElement('div',undefined,'pipamon-progress-heading');heading.append(uiElement('h4','Nível '+p.level+' / 50'),uiElement('span',tier?'✦ '+tier.name:'Em formação','pipamon-tier'));root.append(heading);
 const meter=uiElement('div',undefined,'pipamon-xp-track');meter.setAttribute('role','progressbar');meter.setAttribute('aria-label','XP deste Pipamon');meter.setAttribute('aria-valuemin','0');meter.setAttribute('aria-valuemax','100');meter.setAttribute('aria-valuenow',String(Math.floor(p.percent)));meter.setAttribute('aria-valuetext',p.next===null?'Nível máximo':p.into+' de '+p.needed+' XP para o próximo nível');
 const fill=uiElement('span');fill.style.width=p.percent+'%';meter.append(fill);root.append(meter,uiElement('p',p.next===null?'Nível máximo · Aura desbloqueada':p.into+' / '+p.needed+' XP · faltam '+(p.next-p.xp)+' para o nível '+(p.level+1),'pipamon-xp-caption'));
 const stats=uiElement('dl',undefined,'pipamon-stats'),s=p.stats;
 for(const [label,value]of [['Linha',s.line],['Energia',s.energy],['Ataque',Math.round(s.attack*100)+'%'],['Defesa',Math.round(s.defense*100)+'%'],['Velocidade',Math.round(s.speed)+' px/s'],['Recuperação',s.regen.toFixed(1)+'/s']]){const item=uiElement('div');item.append(uiElement('dt',label),uiElement('dd',String(value)));stats.append(item);}root.append(stats);
 const milestones=uiElement('ol',undefined,'pipamon-milestones');milestones.setAttribute('aria-label','Marcos de brilho');for(const t of [...eng.pipamons.tiers].reverse()){const item=uiElement('li',t.min+' · '+t.name);item.dataset.unlocked=String(p.level>=t.min);milestones.append(item);}root.append(milestones);
 root.append(uiElement('p','XP individual: cortes válidos +25; Trilhas +120 na primeira vitória, +80 ao repetir ou +20 na derrota; desafio diário +100 uma vez ao dia. Treino e partidas como visitante não dão XP. Limite: 2.000 XP por conta/dia (UTC).','pipamon-xp-help'));
}
function announcePipamonLevels(previous,current){
 if(!previous||!current||previous.profile?.id!==current.profile?.id)return;
 const raised=(current.inventory||[]).filter(k=>{const old=previous.inventory?.find(o=>o.id===k.id);return old&&pipamonProgress(k).level>pipamonProgress(old).level;});
 if(!raised.length)return;const k=raised[0],p=pipamonProgress(k);toast((k.personal_name||k.model.name)+' chegou ao nível '+p.level+'!'+(p.tier?' Brilho '+p.tier.name+'.':'')+(raised.length>1?' Outros parceiros também evoluíram.':''));
}
