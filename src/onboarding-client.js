// Introduction uses the same atlas and dialogue data shipped with the game.
let introductionOpen=false,introductionStep=0,introductionTick=0,introductionFocus=null;
const INTRO_SEEN='pipaAssisIntroV1';
function introSeen(){try{return localStorage.getItem(INTRO_SEEN)==='done';}catch{return false;}}
function rememberIntroduction(){try{localStorage.setItem(INTRO_SEEN,'done');}catch{}}
function renderIntroduction(){
 if(!introductionOpen)return;
 const step=ART_CONFIG.intro.steps[introductionStep];
 const painting=(id,atlas,name,fit=false)=>{const canvas=$(id),c=canvas.getContext('2d');c.clearRect(0,0,canvas.width,canvas.height);art.draw(c,atlas,name,0,0,canvas.width,canvas.height,fit);};
 painting('assisBody','sr-assis-poses',step.pose);
 const expression=step.expression==='speaking'&&!art.reduced&&introductionTick%4>1?'neutral':step.expression;
 painting('assisFace','sr-assis-expressions',expression,true);
 const seq=art.atlases.nozinho.animations[step.nozinho];painting('assisCompanion','nozinho',seq[art.reduced?0:introductionTick%seq.length]);
}
function showIntroductionStep(){
 const step=ART_CONFIG.intro.steps[introductionStep];introductionTick=0;
 $('assisTitle').textContent=step.title;$('assisSpeech').textContent=step.text;$('assisProgress').textContent=(introductionStep+1)+' / '+ART_CONFIG.intro.steps.length;
 $('assisPrevious').disabled=introductionStep===0;$('assisNext').textContent=introductionStep===ART_CONFIG.intro.steps.length-1?'Começar treino ↗':'Continuar →';renderIntroduction();
}
async function loadIntroductionArt(retry=false){
 $('assisLoad').textContent='Carregando Sr. Assis e Nozinho…';$('assisRetry').hidden=true;
 const loaded=await Promise.all(['sr-assis-poses','sr-assis-expressions','nozinho'].map(name=>art.load(name,retry)));
 if(!introductionOpen)return;
 $('assisLoad').textContent=loaded.every(Boolean)?'Sr. Assis · pesquisador almático e seu parceiro Nozinho':'Algumas artes não carregaram. Você pode continuar a leitura ou tentar novamente.';
 $('assisRetry').hidden=loaded.every(Boolean);renderIntroduction();
}
function openIntroduction(){
 if(mode){toast('Saia da partida para conversar com o Sr. Assis.');return;}
 if($('accountModal').style.display==='flex')return;
 introductionFocus=document.activeElement;introductionOpen=true;introductionStep=0;keys={};skillUntil=0;
 $('assisIntro').hidden=false;$('assisIntro').style.display='flex';document.body.classList.add('intro-open');showIntroductionStep();$('assisNext').focus?.();loadIntroductionArt();
}
function closeIntroduction(remember=true){
 if(!introductionOpen)return;if(remember)rememberIntroduction();introductionOpen=false;keys={};skillUntil=0;
 $('assisIntro').hidden=true;$('assisIntro').style.display='none';document.body.classList.remove('intro-open');introductionFocus?.focus?.();
}
$('assisPrevious').onclick=()=>{introductionStep=Math.max(0,introductionStep-1);showIntroductionStep();};
$('assisNext').onclick=()=>{if(introductionStep===ART_CONFIG.intro.steps.length-1){closeIntroduction();$('practice').click();}else{introductionStep++;showIntroductionStep();}};
$('assisSkip').onclick=$('assisClose').onclick=()=>closeIntroduction();
$('assisRetry').onclick=()=>loadIntroductionArt(true);
$('assisRules').onclick=()=>{closeIntroduction(false);showRules();};
$('meetAssis').onclick=$('how').onclick=openIntroduction;
addEventListener('keydown',e=>{
 if(!introductionOpen)return;
 if(e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();closeIntroduction();return;}
 if(e.key==='Tab'){const items=[...$('assisIntro').querySelectorAll('button')].filter(b=>!b.disabled&&!b.hidden);const first=items[0],last=items.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}
},true);
setInterval(()=>{if(introductionOpen&&!document.hidden){introductionTick++;renderIntroduction();}},180);
// Invitations go straight to the lobby, so newcomers can join friends without a blocking introduction.
setTimeout(()=>{if(!introSeen()&&!mode&&!param&&$('accountModal').style.display!=='flex'&&$('modal').style.display!=='flex')openIntroduction();},650);
