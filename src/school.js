// Offline exercises use the real combat engine and never grant inventory or coins.
export function createSchool(engine){
 const lessons=[
  {id:'crossing',name:'Cruze as linhas',hint:'Leve sua pipa até o círculo verde. Quando as linhas se cruzarem, ataque com Espaço, clique ou o botão Cortar.',success:'Acertou! É o cruzamento das linhas que corta, não a proximidade das pipas.'},
  {id:'tip',name:'A ponta da sua linha',hint:'Busque o círculo verde e ataque. O cruzamento deve ficar perto da sua pipa, fora da faixa vulnerável da sua linha.',success:'Boa! A ponta da sua linha alcança o rival, enquanto ele não alcança sua faixa vulnerável.'},
  {id:'golden',name:'Centro dourado',hint:'Alinhe com o círculo e ataque o trecho dourado da linha da pipa de treino. Observe a mira no cruzamento.',success:'No centro dourado, seu puxão desgasta mais a linha rival.'},
  {id:'critical',name:'Rele para o crítico',hint:'Chegue ao círculo. Mantenha a pipa em movimento enquanto ataca o centro dourado em ângulo aberto. Um toque na diagonal com ataque funciona.',success:'Crítico! Centro dourado + ângulo aberto + movimento no momento do puxão.'},
  {id:'dodge',name:'Esquiva perfeita',hint:'Aguarde o aviso “Agora!” e toque Shift, botão do meio ou Esquivar. Fique no cruzamento para desviar do puxão.',success:'Esquiva perfeita! Você recuperou a energia da esquiva e ganhou um contra-ataque crítico.'},
  {id:'energy',name:'Recupere seu fôlego',hint:'Sua energia começa baixa. Solte o ataque e observe a barra subir até 90%. Mover a pipa não impede a recuperação.',success:'Pronto para voar! Soltar o ataque recupera energia mais rápido. Sua linha não se conserta sozinha.'}
 ];
 function create(index,now){
  if(!Number.isInteger(index)||!lessons[index])throw Error('Lição inválida');
  const state=engine.create(now),p=engine.player('Você',0,'you',now),q=engine.player('Pipa de treino',1,'school-nozinho',now);
  Object.assign(p,{anchorX:90,x:index===4?700:350,y:180,shield:0,hp:100});
  Object.assign(q,{anchorX:910,x:300,y:180,shield:0,hp:100});state.players=[p,q];state.school=true;
  if(index===5)p.energy=25;
  return {index,state,target:index===1?{x:550,y:300}:{x:700,y:180},started:now,last:now,complete:false,warning:'',contact:null};
 }
 function tick(run,input,now){
  if(run.complete)return run;
  const {state,index}=run,[p,q]=state.players,dt=Math.min(.25,Math.max(0,(now-run.last)/1000));run.last=now;
  // No time limit, eliminations, automatic opponent AI, network writes or rewards.
  state.end=now+3600000;p.seen=q.seen=now;q.input={};p.hp=q.hp=100;q.x=300;q.y=180;
  if(index===4){const phase=((run.elapsed||0)*1000)%4000;q.input={cut:phase>=2200&&phase<2450};run.warning=phase>=2200&&phase<2450?'Agora! Esquive!':phase>=1200&&phase<2200?'Prepare-se… o puxão vem aí.':'Aguarde o sinal do alvo.';}
  const hits=p.hits||0,crits=p.crits||0,dodges=p.perfectDodges||0;
  engine.practiceStep(state,p.id,input,now);const c=engine.contact(p,q);run.contact=c;
  const hit=(p.hits||0)>hits;
  run.complete=index===0?hit:index===1?hit&&c?.own>=.85&&!engine.contact(q,p)?.valid:index===2?hit&&c?.perfect:index===3?(p.crits||0)>crits:index===4?(p.perfectDodges||0)>dodges:!input.cut&&p.energy>=90;
  run.elapsed=(run.elapsed||0)+dt;return run;
 }
 return {lessons,create,tick};
}
