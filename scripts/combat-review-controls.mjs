// Local-only manual controls for browser review. Never imported by production builds.
export function combatReviewControls(){return `<script>
(()=>{
 const originalInput=input,held={x:0,y:0,cut:false};let aim=null;
 const panel=document.createElement('details');panel.id='localCombatReview';panel.style.cssText='position:fixed;left:14px;top:220px;z-index:100000;width:230px;padding:9px;background:#123b49ed;color:#fff0c8;border:1px solid #cfab64;font:12px system-ui;border-radius:8px';
 panel.innerHTML='<summary>Comandos de revisão · só local</summary><p>Treino Rabbito 15 × Lacertubo. Comandos mantidos até soltar; engine e custos reais.</p><div style="display:grid;grid-template-columns:repeat(3,1fr);gap:4px"><button data-move="-1,-1">↖</button><button data-move="0,-1">↑</button><button data-move="1,-1">↗</button><button data-move="-1,0">←</button><button data-move="0,0">Parar</button><button data-move="1,0">→</button><button data-move="-1,1">↙</button><button data-move="0,1">↓</button><button data-move="1,1">↘</button></div><button id="reviewHoldAttack" aria-pressed="false">Manter ataque</button><button id="reviewRelease">Soltar comandos</button><p id="reviewHeldState" role="status"></p>';
 document.body.append(panel);panel.querySelectorAll('button').forEach(b=>{b.type='button';b.style.cssText='padding:8px;min-height:36px;min-width:0;margin:3px 0;background:#fff0c8;color:#153e44;border:1px solid #bc9857;border-radius:4px;font:700 12px system-ui';});
 const target=document.createElement('div');target.innerHTML='<label>Alvo X <input id="reviewAimX" type="number" value="700" min="55" max="945" style="width:55px"></label><label> Y <input id="reviewAimY" type="number" value="180" min="50" max="500" style="width:55px"></label><button type="button" id="reviewAim">Mover até o alvo</button>';panel.append(target);
 const active=()=>mode==='practice'&&schoolRun?.index===9&&!showResult;
 function reflect(){panel.querySelector('#reviewHoldAttack').textContent=held.cut?'Soltar ataque':'Manter ataque';panel.querySelector('#reviewHoldAttack').setAttribute('aria-pressed',String(held.cut));panel.querySelector('#reviewHeldState').textContent='Movimento '+held.x+', '+held.y+' · Ataque '+(held.cut?'mantido':'solto');}
 function release(){aim=null;held.x=held.y=0;held.cut=false;reflect();}
 panel.querySelector('#reviewAim').onclick=()=>{aim={x:Number(panel.querySelector('#reviewAimX').value),y:Number(panel.querySelector('#reviewAimY').value)};};
 panel.querySelectorAll('[data-move]').forEach(b=>b.onclick=()=>{aim=null;[held.x,held.y]=b.dataset.move.split(',').map(Number);reflect();});
 panel.querySelector('#reviewHoldAttack').onclick=()=>{held.cut=!held.cut;reflect();};panel.querySelector('#reviewRelease').onclick=release;
 input=function(){const base=originalInput();if(!active()||!battleLive())return base;let movement=held;if(aim){const p=ownKite();if(p){const dx=aim.x-p.x,dy=aim.y-p.y,d=Math.hypot(dx,dy),k=d<8?0:Math.min(1,d/70)/d;movement={x:Math.round(dx*k*10)/10,y:Math.round(dy*k*10)/10,cut:held.cut};}}return {...base,...movement};};
 let previous=false;setInterval(()=>{const enabled=active();panel.hidden=!enabled;if(!enabled||pausedAt)release();if(enabled&&!previous)panel.open=true;previous=enabled;},100);reflect();
})();
</script>`;}
