// Guided local play with the real engine. Checkpoints carry no economic rewards.
export function createFirstFlight(engine){
 const lessons=[
  {title:'Encontre o vento',hint:'Mova o mouse ou use WASD / setas. Leve seu parceiro até o círculo.',success:'Seu parceiro acompanha você. Agora vamos cruzar as linhas.'},
  {title:'Seu primeiro rebique',hint:'Chegue ao círculo. Quando a mira ficar verde, clique ou pressione Espaço para rebicar.',success:'Bom puxão! O cruzamento das linhas é o que permite cortar.'},
  {title:'Recupere o fôlego',hint:'Solte o ataque. Você pode continuar voando enquanto a energia se recupera.',success:'É isso. Alternar ataque e descanso mantém sua energia.'},
  {title:'O jeito do seu parceiro',hint:'Use o botão direito do mouse, Q ou E para experimentar sua habilidade.',success:'Cada parceiro tem seu jeito de enfrentar o vento.'},
  {title:'Uma rodada com o Nozinho',hint:'Cruze as linhas e rebique para fazer seu primeiro corte. Nozinho está só treinando com você.',success:'Primeiro corte! Nozinho está bem e o professor está orgulhoso.'}
 ];
 function create({color=0,soul=null,lesson=0,name='Você'}={},now=Date.now()){
  const state=engine.create(now),p=engine.player(name,color,'you',now),q=engine.player('Nozinho',1,'first-nozinho',now);
  Object.assign(p,{anchorX:90,x:350,y:180,shield:0,soul});Object.assign(q,{anchorX:910,x:300,y:180,shield:0,soul:'nozinho'});
  state.players=[p,q];state.firstFlight=true;state.end=now+3600000;
  const run={state,index:Math.max(0,Math.min(4,lesson)),complete:false,target:{x:700,y:180},last:now};prepare(run);return run;
 }
 function prepare(run){const [p,q]=run.state.players;run.complete=false;run.baseScore=p.score;run.baseHits=p.hits||0;p.hp=100;p.energy=run.index===2?25:100;p.skillCooldown=0;p.respawn=0;p.shield=0;q.hp=run.index===4?30:100;q.respawn=0;q.shield=0;q.x=300;q.y=180;}
 function next(run){if(!run.complete)return false;if(run.index===4)return false;run.index++;prepare(run);return true;}
 function tick(run,input,now){
  if(run.complete)return run;const [p,q]=run.state.players;run.state.end=now+3600000;p.seen=q.seen=now;p.hp=100;q.input={};q.x=300;q.y=180;
  if(run.index<4)q.hp=100;
  engine.practiceStep(run.state,p.id,input,now);run.last=now;
  run.complete=run.index===0?Math.hypot(p.x-run.target.x,p.y-run.target.y)<45:run.index===1?(p.hits||0)>run.baseHits:run.index===2?!input.cut&&p.energy>=90:run.index===3?p.skillCooldown>0:p.score>run.baseScore;
  return run;
 }
 return {lessons,create,next,tick};
}
