// The same maneuver rules run locally and on the authoritative room server.
let normalLineNonce=0,normalLineHeld=false,normalLineSide=1;
const normalLineHUD=document.createElement('section');normalLineHUD.id='normalLineHUD';normalLineHUD.hidden=true;
normalLineHUD.setAttribute('aria-label','Rebicadas da linha');
normalLineHUD.innerHTML=`<label>Rebicada<select id="normalLineChoice" aria-label="Escolher rebicada"></select></label><button id="normalLineSide" class="secondary" aria-label="Trocar lado da rebicada">Direita ↔</button><button id="normalLineUse" class="primary">Rebicar · R</button><small id="normalLineState" role="status"></small><p id="normalLineHint"></p>`;
document.querySelector('.arena').append(normalLineHUD);
const normalLineStyle=document.createElement('style');normalLineStyle.textContent=`
#normalLineHUD{position:absolute;z-index:7;bottom:18px;left:50%;transform:translateX(-50%);width:min(580px,calc(100% - 28px));padding:10px 12px;background:#f7f3e8f5;border:1px solid #314d49;border-radius:12px;display:grid;grid-template-columns:minmax(125px,1fr) auto auto;gap:6px;box-shadow:0 3px 12px #122f3320}
#normalLineHUD[hidden],body:not(.in-match) #normalLineHUD,body.sky-testing #normalLineHUD{display:none}
#normalLineHUD label{font-size:10px;font-weight:800;text-transform:uppercase}#normalLineHUD select{display:block;width:100%;font:700 13px Nunito,sans-serif;padding:4px;border:0;background:transparent;color:#223b37}#normalLineHUD button{min-height:42px;padding:8px 12px;touch-action:none}#normalLineHUD small{grid-column:1/-1;font-weight:800;color:#315751}#normalLineHUD p{grid-column:1/-1;margin:0;font-size:11px;line-height:1.3;color:#40554e}
@media(max-width:700px){#normalLineHUD{bottom:80px;gap:4px;padding:6px 9px}#normalLineHUD button{padding:7px;font-size:12px}#normalLineHUD p{font-size:10px}}
`;
document.head.append(normalLineStyle);
for(const d of eng.lineSkills){const o=document.createElement('option');o.value=d.id;o.textContent=d.name;$('normalLineChoice').append(o);}
try{const saved=localStorage.getItem('pipaLineMove');if(eng.lineSkills.some(d=>d.id===saved))$('normalLineChoice').value=saved;}catch{}
function normalLineChoice(){return eng.lineSkills.find(d=>d.id===$('normalLineChoice').value)||eng.lineSkills[0];}
function normalLineInput(){return normalLineNonce?{lineNonce:normalLineNonce,lineId:normalLineChoice().id,lineHeld:normalLineHeld,lineSide:normalLineSide}:{};}
function resetNormalLine(){normalLineHeld=false;}
function normalLineStart(){
 const p=ownKite();if(!mode||!p||p.respawn||pausedAt||showResult||skyActive||!$('pauseSheet').hidden||$('modal').style.display==='flex'||state?.phase&&state.phase!=='live'||p.lineMove||p.lineCooldown>0||p.energy<normalLineChoice().cost)return;
 normalLineNonce=Math.max(normalLineNonce,p.lineSeen||0)+1;normalLineHeld=true;
}
function updateNormalLineHUD(){
 const p=ownKite();normalLineHUD.hidden=!mode||!p||showResult;if(normalLineHUD.hidden)return;
 const d=normalLineChoice(),k=p.lineMove;const blocked=!!(p.respawn||pausedAt||state.phase&&state.phase!=='live');
 $('normalLineChoice').disabled=!!k||normalLineHeld;$('normalLineSide').disabled=!!k||normalLineHeld;
 $('normalLineUse').disabled=blocked||(!normalLineHeld&&(!!k||p.lineCooldown>0||p.energy<d.cost));
 setText('normalLineState',k?.phase==='charge'?'Linha tensionada · solte R':k?eng.lineSkills.find(s=>s.id===k.id).name+' em movimento':blocked?'Aguarde a partida':p.lineCooldown>0?'Recarga · '+p.lineCooldown.toFixed(1)+' s':p.energy<d.cost?'Precisa de '+d.cost+' de energia':'Pronta · segure R e solte');
 setText('normalLineHint',d.description+' · '+d.cost+' energia · '+d.cooldown+' s de recarga.');
}
$('normalLineChoice').onchange=()=>{try{localStorage.setItem('pipaLineMove',normalLineChoice().id);}catch{}updateNormalLineHUD();};
$('normalLineSide').onclick=()=>{normalLineSide*=-1;$('normalLineSide').textContent=normalLineSide<0?'Esquerda ↔':'Direita ↔';};
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
