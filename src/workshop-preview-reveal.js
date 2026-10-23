// Preview adapter; scoring, silhouette and stroke sampling come from the game.
let paperOwner=null,paper=null,paperTool='estilete',paperCursor=null,paperStroke=null,paperStart=0,paperEnd=0,paperTry=0,paperStamp='';
function previewRevealControls(){
 if(paperOwner!==input){paperOwner=input;paper=createReveal(revealMask(images.parts,config.rects,true),++paperTry);paperTool='estilete';paperStroke=null;paperCursor=null;paperStart=clock+REVEAL_COUNTDOWN;paperEnd=paperStart+REVEAL_SECONDS;input.cuts=[];input.revealScore=null;}
 paperStamp='';const host=$('inputs');host.replaceChildren();
 const head=document.createElement('div');head.className='workshop-reveal-head';head.innerHTML='<b id="paperClock"></b><span>Tempo ativo · pausado com a animação e com a aba oculta</span>';host.append(head);
 const tools=document.createElement('div');tools.className='workshop-tools';tools.setAttribute('role','group');tools.setAttribute('aria-label','Ferramentas de revelação');
 for(const [id,label]of [['estilete','Estilete · 1'],['tesourinha','Tesourinha · 2'],['light','Luz do molde · L']]){const button=document.createElement('button');button.id='paper-'+id;button.textContent=label;button.onclick=()=>{if(id==='light')previewRevealLight();else{paperTool=id;paperStroke=null;paperStamp='';previewRevealReadout();}$('scene').focus({preventScroll:true});};tools.append(button);}host.append(tools);
 const bars=document.createElement('div');bars.className='workshop-reveal-bars';bars.innerHTML='<div><span>Marca revelada</span><em><i id="paperShown"></i></em><b id="paperShownValue"></b></div><div data-bar="tear"><span>Rasgo · cede em 50%</span><em><i id="paperTear"></i></em><b id="paperTearValue"></b></div>';host.append(bars);
 const help=document.createElement('p');help.textContent='Estilete retira camadas; tesourinha raspa ao arrastar. Setas movem, Espaço usa. A Luz revela a silhueta por 2,5 s e tem dois usos.';help.className='workshop-help';host.append(help);previewRevealFrame();
}
function previewRevealLive(){return stage===2&&paper&&playing&&!document.hidden&&clock>=paperStart&&clock<paperEnd&&!revealScore(paper).failed;}
function previewRevealStrike(p){if(!previewRevealLive())return;revealStrike(paper,paperTool,p.x,p.y);if(paperTool==='estilete')paper.flashes.push({...p,at:clock});previewRevealFrame();}
function previewRevealSnip(p){if(!paperStroke){paperStroke=revealStrokeStart(p);previewRevealStrike(p);}else for(const q of revealStrokePoints(paperStroke,p))previewRevealStrike(q);}
function previewRevealLight(){if(!previewRevealLive()||!paper.lights)return;paper.lights--;paper.lightUntil=clock+2.5;paperStamp='';previewRevealFrame();}
function previewRevealPointer(e,down){
 if(stage!==2||!paper)return;const c=$('scene'),r=c.getBoundingClientRect();paperCursor={x:(e.clientX-r.left)*960/r.width-480,y:(e.clientY-r.top)*640/r.height-400};
 if(e.type==='pointerdown'){if(e.button!==0)return;c.focus({preventScroll:true});c.setPointerCapture(e.pointerId);paperStroke=null;}
 if(!down)return;if(paperTool==='tesourinha')previewRevealSnip(paperCursor);else if(e.type==='pointerdown')previewRevealStrike(paperCursor);
}
function previewRevealReadout(){
 if(!paper)return;const r=revealScore(paper),left=Math.max(0,Math.ceil(paperEnd-Math.max(clock,paperStart))),stamp=[r.score,r.revealed,r.damage,left,Math.ceil(paperStart-clock),paper.lights,paperTool].join('|');if(stamp===paperStamp)return;paperStamp=stamp;
 $('paperClock').textContent=clock<paperStart?Math.ceil(paperStart-clock)+'s':left+'s';$('paperShown').style.width=Math.round(r.revealed*100)+'%';$('paperShownValue').textContent=Math.round(r.revealed*100)+'%';$('paperTear').style.width=Math.min(100,r.damage/REVEAL_FAIL*100)+'%';$('paperTearValue').textContent=Math.round(r.damage*100)+'%';
 for(const id of ['estilete','tesourinha']){$('paper-'+id).disabled=r.failed||!left;$('paper-'+id).setAttribute('aria-pressed',String(paperTool===id));}$('paper-light').disabled=r.failed||!left||!paper.lights;$('paper-light').textContent='Luz do molde ('+paper.lights+') · L';
 $('next').disabled=!workshopReady(2,input);$('score').textContent=r.failed?'A folha cedeu. Use Refazer etapa.':!left?'Tempo esgotado · nota '+r.score:r.score+'% · qualidade da revelação';
}
function previewRevealFrame(){
 if(!paper)return;const r=revealScore(paper);input.reveal=paper;input.revealView={tool:paperTool,cursor:paperCursor,lit:clock<paperStart||clock<paper.lightUntil};if(!r.failed&&(r.done||clock>=paperEnd)){input.cuts=[0,1,2,3];input.revealScore=r.score;}else{input.cuts=[];input.revealScore=null;}previewRevealReadout();
}
function previewRevealCountdown(g){if(!paper||clock>=paperStart)return;g.save();g.fillStyle='#fff8e9';g.strokeStyle='#294b53';g.lineWidth=7;g.font='bold 110px sans-serif';g.textAlign='center';g.strokeText(String(Math.ceil(paperStart-clock)),480,360);g.fillText(String(Math.ceil(paperStart-clock)),480,360);g.restore();}
const paperCanvas=$('scene');paperCanvas.tabIndex=0;paperCanvas.addEventListener('pointerdown',e=>previewRevealPointer(e,true));paperCanvas.addEventListener('pointermove',e=>previewRevealPointer(e,e.buttons===1));
paperCanvas.onpointerup=paperCanvas.onpointercancel=paperCanvas.onlostpointercapture=paperCanvas.onblur=()=>paperStroke=null;
paperCanvas.addEventListener('keydown',e=>{if(stage!==2||!paper)return;const moves={ArrowUp:[0,-8],ArrowDown:[0,8],ArrowLeft:[-8,0],ArrowRight:[8,0]},move=moves[e.key];if(move||e.key===' ')e.preventDefault();if(e.key==='1'||e.key==='2'){paperTool=e.key==='1'?'estilete':'tesourinha';paperStroke=null;paperStamp='';}if(e.key.toLowerCase()==='l')previewRevealLight();const p=paperCursor||{x:0,y:-20};if(move){paperCursor={x:Math.max(REVEAL_AREA.x,Math.min(REVEAL_AREA.x+REVEAL_AREA.w,p.x+move[0])),y:Math.max(REVEAL_AREA.y,Math.min(REVEAL_AREA.y+REVEAL_AREA.h,p.y+move[1]))};if(paperStroke&&paperTool==='tesourinha')previewRevealSnip(paperCursor);}if(e.key===' '&&!e.repeat){paperCursor=p;if(paperTool==='estilete')previewRevealStrike(p);else{paperStroke=null;previewRevealSnip(p);}}previewRevealFrame();});
paperCanvas.addEventListener('keyup',e=>{if(e.key===' ')paperStroke=null;});
