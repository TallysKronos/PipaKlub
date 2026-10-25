// Guided local play with the real engine. Checkpoints carry no economic rewards.
export function createFirstFlight(engine){
 const lessons=[
  {title:'Encontre o vento',hint:'Mova o mouse ou use WASD / setas. Leve seu parceiro até o círculo.',success:'Seu parceiro acompanha você. Agora vamos cruzar as linhas.'},
  {title:'Ataque no cruzamento',hint:'Seu alvo é Nozinho. Mantenha distância e cruze sua linha na faixa tracejada dele. Quando a mira ficar verde, clique ou pressione Espaço para atacar. De perto, o ataque atinge a armação; aqui vamos praticar a linha.',success:'Acertou! Ataque é clique / Espaço. Rebicada é outra ação: uma manobra da linha, usada com R.'},
  {title:'Recupere o fôlego',hint:'A barra azul é sua energia. Solte Espaço ou o botão Atacar e espere ela chegar a 90%. A recuperação é automática; pode continuar voando. Evite habilidades enquanto recarrega.',success:'Muito bem! Você recuperou energia sem precisar parar. Soltar o ataque recupera mais rápido; habilidades e especiais gastam energia.'},
  {title:'Ferramentas para o duelo',hint:'Experimente a habilidade do parceiro, a esquiva, a rebicada e a guarda contra o especial do Nozinho.',success:'Você usou as ferramentas e defendeu o Nó de Vendaval! A guarda dura 0,5 s e, fora desta demonstração, leva 20 s para recarregar. O professor pode reparar sua pipa depois das aventuras.'},
  {title:'Uma rodada com o Nozinho',hint:'Escolha a linha de Nozinho como alvo: cruze a faixa tracejada e ataque com clique / Espaço. O centro dourado, em ângulo aberto e em movimento, favorece o crítico.',success:'Primeiro corte! Nozinho está bem e o professor está orgulhoso.'}
 ];
 function create({color=0,soul=null,lesson=0,name='Você',partnerName=null}={},now=Date.now()){
  const state=engine.create(now),p=engine.player(name,color,'you',now),q=engine.player('Nozinho',1,'first-nozinho',now);
  Object.assign(p,{anchorX:90,x:190,y:320,shield:0,soul,partnerName});Object.assign(q,{anchorX:910,x:300,y:180,shield:0,soul:'nozinho'});
  state.players=[p,q];state.firstFlight=true;state.end=now+3600000;
  const run={state,index:Math.max(0,Math.min(4,lesson)),complete:false,target:{x:700,y:180},last:now};prepare(run);return run;
 }
 function prepare(run){const [p,q]=run.state.players;run.complete=false;run.exercise='skill';run.skillActivated=false;run.baseSkill=p.skillCount||0;run.baseDodge=p.dodges||0;run.baseLine=p.lineCount||0;run.baseBlocks=p.blocks||0;run.baseScore=p.score;run.baseHits=p.hits||0;p.hp=p.hull=100;p.energy=run.index===2?25:100;p.skillCooldown=0;p.skillTime=0;p.dodgeCooldown=0;p.evade=0;p.guardCooldown=p.guardTime=0;p.lineCooldown=0;p.lineMove=null;p.respawn=0;p.shield=0;q.hp=run.index===4?30:100;q.hull=100;q.signatureWindup=q.signatureBurst=0;q.signatureAim=null;q.signatureHeld=false;q.signatureCooldown=0;q.respawn=0;q.shield=0;q.x=300;q.y=180;if(run.index===3){p.x=700;p.y=180;}}
 function next(run){if(!run.complete)return false;if(run.index===4)return false;run.index++;prepare(run);return true;}
 function tick(run,input,now){
  if(run.complete)return run;const [p,q]=run.state.players;run.state.end=now+3600000;p.seen=q.seen=now;p.hp=100;q.input={};q.x=300;q.y=180;
  if(run.index<4)q.hp=100;
  if(run.index===3&&run.exercise==='skill'&&p.color===2&&p.skillTime>0)q.input={cut:true};
  if(run.index===3&&run.exercise==='guard'){
   // Safe demonstration: the same authoritative signature and guard, with quick retries.
   p.hp=p.hull=100;p.respawn=0;q.hull=100;q.energy=100;
   if(!q.signatureWindup&&q.signatureCooldown>1.5){q.signatureCooldown=1.5;p.guardCooldown=0;}
   q.input={signature:q.signatureCooldown<=0};
  }
  const hadSkill=p.skillTime>0,oldSkills=p.skillCount||0,oldX=p.x,oldHits=p.hits||0,oldFoeHits=q.hits||0;
  engine.practiceStep(run.state,p.id,input,now);run.last=now;
  if(run.index===3){
   run.skillActivated||=(p.skillCount||0)>run.baseSkill;
   const effect=p.color===1?Math.abs(p.x-oldX)>=70:p.color===2?(q.hits||0)>oldFoeHits&&p.hp<100:(p.hits||0)>oldHits;
   if(run.exercise==='skill'&&run.skillActivated&&(hadSkill||p.skillTime>0||(p.skillCount||0)>oldSkills)&&effect){run.exercise='dodge';p.energy=100;}
   if(run.exercise==='dodge'&&(p.dodges||0)>run.baseDodge){run.exercise='line';p.energy=100;}
   if(run.exercise==='line'&&(p.lineCount||0)>run.baseLine&&!p.lineMove){run.exercise='guard';p.energy=100;p.x=620;p.y=240;q.signatureCooldown=1;p.guardCooldown=0;run.baseBlocks=p.blocks||0;}
   run.complete=run.exercise==='guard'&&(p.blocks||0)>run.baseBlocks;
  }else run.complete=run.index===0?Math.hypot(p.x-run.target.x,p.y-run.target.y)<45:run.index===1?(p.hits||0)>run.baseHits:run.index===2?!input.cut&&p.energy>=90:p.score>run.baseScore;
  return run;
 }
 return {lessons,create,next,tick};
}
