// The same maneuver rules run locally and on the authoritative room server.
let normalLineNonce=0,normalLineHeld=false,normalLineSide=1;
const normalLineHUD=document.createElement('section');normalLineHUD.id='normalLineHUD';normalLineHUD.hidden=true;
normalLineHUD.setAttribute('aria-label','Rebicadas da linha');
normalLineHUD.innerHTML=`<label>Rebicada<select id="normalLineChoice" aria-label="Escolher rebicada"></select></label><button id="normalLineSide" class="secondary" aria-label="Trocar lado da rebicada">Direita</button><button id="normalLineUse" class="primary">Rebicar · R</button><small id="normalLineState" role="status"></small><p id="normalLineHint"></p>`;
document.querySelector('.combat-deck').prepend(normalLineHUD);
for(const d of eng.lineSkills){const o=document.createElement('option');o.value=d.id;o.textContent=d.name;$('normalLineChoice').append(o);}
try{const saved=localStorage.getItem('pipaLineMove');if(eng.lineSkills.some(d=>d.id===saved))$('normalLineChoice').value=saved;}catch{}
function normalLineChoice(){return eng.lineSkills.find(d=>d.id===$('normalLineChoice').value)||eng.lineSkills[0];}
function normalLineInput(){return normalLineNonce?{lineNonce:normalLineNonce,lineId:normalLineChoice().id,lineHeld:normalLineHeld,lineSide:normalLineSide}:{};}
function resetNormalLine(){normalLineHeld=false;}
function normalLineStart(){
 const p=ownKite();if(!mode||!p||p.respawn||p.evade>0||pausedAt||showResult||skyActive||!$('pauseSheet').hidden||$('modal').style.display==='flex'||state?.phase&&state.phase!=='live'||p.lineMove||p.lineCooldown>0||p.energy<normalLineChoice().cost)return;
 normalLineNonce=Math.max(normalLineNonce,p.lineSeen||0)+1;normalLineHeld=true;
}
function updateNormalLineHUD(){
 const p=ownKite();updateBattleHUD(p);normalLineHUD.hidden=!mode||!p||showResult;if(normalLineHUD.hidden)return;
 const d=normalLineChoice(),k=p.lineMove;const blocked=!!(p.respawn||pausedAt||state.phase&&state.phase!=='live');
 $('normalLineChoice').disabled=!!k||normalLineHeld;$('normalLineSide').disabled=!!k||normalLineHeld;
 $('normalLineUse').disabled=blocked||(!normalLineHeld&&(!!k||p.lineCooldown>0||p.energy<d.cost));
 setText('normalLineState',k?.phase==='charge'?'Linha tensionada · solte R':k?'Em movimento':blocked?'Aguarde a partida':p.lineCooldown>0?'Recarga · '+p.lineCooldown.toFixed(1)+' s':p.energy<d.cost?'Precisa de '+d.cost+' de energia':'Pronta · segure R e solte');
 setText('normalLineHint',d.description+' · '+d.cost+' energia · '+d.cooldown+' s de recarga.');
 $('normalLineChoice').title=$('normalLineHint').textContent;$('normalLineUse').title=$('normalLineHint').textContent;$('normalLineUse').setAttribute('aria-describedby','normalLineHint');
}
$('normalLineChoice').onchange=()=>{try{localStorage.setItem('pipaLineMove',normalLineChoice().id);}catch{}updateNormalLineHUD();};
$('normalLineSide').onclick=()=>{normalLineSide*=-1;const button=$('normalLineSide'),label=button.querySelector('.hud-button-content')||button;label.textContent=normalLineSide<0?'Esquerda':'Direita';button.title='Lado da rebicada: '+(normalLineSide<0?'esquerda':'direita');};
$('normalLineUse').onpointerdown=e=>{e.preventDefault();e.stopPropagation();normalLineStart();e.currentTarget.setPointerCapture?.(e.pointerId);};
for(const event of ['pointerup','pointercancel','lostpointercapture'])$('normalLineUse').addEventListener(event,resetNormalLine);
$('normalLineUse').addEventListener('keydown',e=>{if(['Enter',' '].includes(e.key)){e.preventDefault();if(!e.repeat)normalLineStart();}});
$('normalLineUse').addEventListener('keyup',e=>{if(['Enter',' '].includes(e.key)){e.preventDefault();resetNormalLine();}});
document.addEventListener('keydown',e=>{if(e.key.toLowerCase()!=='r'||!mode||skyActive||/INPUT|TEXTAREA|SELECT/.test(e.target.tagName))return;e.preventDefault();if(!e.repeat)normalLineStart();},true);
document.addEventListener('keyup',e=>{if(e.key.toLowerCase()==='r')resetNormalLine();},true);
function drawNormalLineEffect(p){
 const k=p.lineMove;if(!k||p.respawn)return;
 const d=eng.lineSkills.find(d=>d.id===k.id);if(!d)return;const a=eng.line(p).a,t=Math.min(1,k.elapsed/d.duration),col={puxao:'#ed9c26',chicote:'#9874ce',estilingue:'#e87445',laco:'#4b9dd3',folha:'#438f67',duplo:'#ce6d94'}[k.id];
 ctx.save();ctx.strokeStyle=col;ctx.lineWidth=k.phase==='charge'?4:3;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(p.x,p.y);ctx.stroke();
 if(p.id===me&&!reduceMotion){ctx.globalAlpha=.5;ctx.setLineDash([4,7]);ctx.lineWidth=2;ctx.beginPath();for(let n=0;n<=24;n++){const o=eng.lineMotion(k,n/24),x=Math.max(55,Math.min(945,k.origin.x+o.x)),y=Math.max(70,Math.min(480,k.origin.y+o.y));if(n)ctx.lineTo(x,y);else ctx.moveTo(x,y);}ctx.stroke();ctx.setLineDash([]);ctx.globalAlpha=1;}
 const window=eng.lineWindow(k.id,t);ctx.beginPath();ctx.arc(p.x,p.y,k.phase==='charge'?42:48,0,Math.PI*2);ctx.lineWidth=window?4:2;ctx.stroke();ctx.restore();
}
