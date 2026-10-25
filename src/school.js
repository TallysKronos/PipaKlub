// Offline exercises use the real combat engine and never grant inventory or coins.
export function createSchool(engine){
 const lessons=[
  {id:'crossing',name:'Cruze as linhas',hint:'Leve sua pipa até o círculo verde. À distância, cruze as linhas e ataque com Espaço, clique ou Atacar.',success:'Acertou a linha! De perto, o mesmo ataque pode atingir a armação. Vamos treinar isso nas lições extras.'},
  {id:'tip',name:'A ponta da sua linha',hint:'Busque o círculo verde e ataque. O cruzamento deve ficar perto da sua pipa, fora da faixa vulnerável da sua linha.',success:'Boa! A ponta da sua linha alcança o rival, enquanto ele não alcança sua faixa vulnerável.'},
  {id:'golden',name:'Centro dourado',hint:'Alinhe com o círculo e ataque o trecho dourado da linha da pipa de treino. Observe a mira no cruzamento.',success:'No centro dourado, seu puxão desgasta mais a linha rival.'},
  {id:'critical',name:'Rele para o crítico',hint:'Chegue ao círculo. Mantenha a pipa em movimento enquanto ataca o centro dourado em ângulo aberto. Um toque na diagonal com ataque funciona.',success:'Crítico! Centro dourado + ângulo aberto + movimento no momento do puxão.'},
  {id:'dodge',name:'Esquiva perfeita',hint:'Aguarde o aviso “Agora!” e toque Shift, botão do meio ou Esquivar. Fique no cruzamento para desviar do puxão.',success:'Esquiva perfeita! Você recuperou a energia da esquiva e ganhou um contra-ataque crítico.'},
  {id:'energy',name:'Recupere seu fôlego',hint:'Sua energia começa baixa. Solte o ataque e observe a barra subir até 90%. Mover a pipa não impede a recuperação.',success:'Pronto para voar! Soltar o ataque recupera energia mais rápido. Sua linha não se conserta sozinha.'},
  {id:'body',name:'Ataque na armação',hint:'As pipas já estão próximas. Pressione Espaço ou Atacar. Observe a barra dourada: encostar sem atacar não causa dano.',success:'Acertou a armação! À distância, ataque corta a linha; de perto, atinge a pipa. Se a armação quebrar, o parceiro é preservado e o professor pode reparar.'},
  {id:'guard',name:'Guarda no momento certo',hint:'Fique dentro do círculo marcado. Quando o arco estiver quase completo, use G ou Guarda. A proteção dura só 0,5 s. Neste treino, você recebe outra chance logo após cada tentativa.',success:'Guarda perfeita! O golpe não danificou a armação. No duelo real, a guarda leva 20 s para recarregar. Sair do círculo ou esquivar também evita o especial.'},
  {id:'signature',name:'Seu golpe de assinatura',hint:'Vamos usar um Rabbito de treino. Pressione T ou Pulo do Elo e observe o círculo e a preparação. O golpe custa 40 de energia; o inimigo pode fugir ou defender.',success:'Pulo do Elo acertou! Na batalha, espere o rival se comprometer com um ataque e use a abertura. Cada especial tem sua própria recarga.'},
  {id:'guardian',name:'Revanche com o guardião',hint:'Rabbito nível 15 contra Lacertubo. É um treino sem perdas. Use as aberturas após os golpes dele, acompanhe linha e armação e guarde G para o impacto.',success:'Você venceu o guardião no treino! Aqui não há XP, recompensa ou vitória de campanha; o desafio real continua nas Veredas.'}
 ];
 function create(index,now){
  if(!Number.isInteger(index)||!lessons[index])throw Error('Lição inválida');
  const state=engine.create(now),p=engine.player('Você',0,'you',now),q=engine.player('Pipa de treino',1,'school-nozinho',now);
  Object.assign(p,{anchorX:90,x:index===4?700:350,y:180,shield:0,hp:100});
  Object.assign(q,{anchorX:910,x:300,y:180,shield:0,hp:100});state.players=[p,q];state.school=true;
  if(index===5)p.energy=25;
  Object.assign(p,{hull:100,hullMax:100});Object.assign(q,{hull:100,hullMax:100});
  if(index>=6){p.soul='rabbito';p.color=1;q.soul='nozinho';p.x=400;p.y=240;q.x=index===6?430:620;q.y=240;}
  if(index===7){q.bossId='lacertubo';q.soul='lacertubo';q.signatureCooldown=0;q.partnerName='Lacertubo de treino';}
  if(index===9){
   Object.assign(state,{mode:'rounds',phase:'waiting',round:0,roundsToWin:1,boss:{id:'lacertubo',name:'Lacertubo'},end:now+3600000});
   Object.assign(p,{pipamonLevel:15,partnerName:'Rabbito de treino',combatStarted:false,hull:engine.pipamonStats({pipamonLevel:15}).line,hullMax:engine.pipamonStats({pipamonLevel:15}).line});
   Object.assign(q,{name:'Lacertubo',bot:true,bossId:'lacertubo',soul:'lacertubo',partnerName:'Lacertubo',pipamonLevel:15,combatStarted:false});
   q.hull=q.hullMax=engine.pipamonStats(q).line;
  }
  return {index,state,target:index===1?{x:550,y:300}:{x:700,y:180},started:now,last:now,complete:false,warning:'',contact:null};
 }
 function tick(run,input,now){
  if(run.complete)return run;
  const {state,index}=run,[p,q]=state.players,dt=Math.min(.25,Math.max(0,(now-run.last)/1000));run.last=now;
  if(index===9){if(run.failed)return run;p.seen=q.seen=now;engine.practiceStep(state,p.id,input,now);run.complete=(p.rounds||0)>=1;run.failed=(q.rounds||0)>=1;run.warning=run.failed?'O guardião venceu este treino. Use Recomeçar; sua coleção não sofreu desgaste.':q.signatureWindup>0?'Ruptura dos Canos: saia do círculo ou defenda perto do impacto.':q.bossRecovery>0?'Abertura! O guardião está recuperando o fôlego.':'Observe o preparo dos golpes e escolha sua abertura.';return run;}
  // No time limit, eliminations, automatic opponent AI, network writes or rewards.
  state.end=now+3600000;p.seen=q.seen=now;q.input={};p.hp=q.hp=100;q.x=300;q.y=180;
  if(index>=6){q.x=index===6?Math.min(940,p.x+30):620;q.y=index===6?p.y:240;p.hull=100;q.hull=100;p.respawn=q.respawn=0;}
  if(index===7&&q.signatureCooldown>2&&!(q.signatureWindup>0)){q.signatureCooldown=2;p.guardCooldown=0;}
  if(index===4){const phase=((run.elapsed||0)*1000)%4000;q.input={cut:phase>=2200&&phase<2450};run.warning=phase>=2200&&phase<2450?'Agora! Esquive!':phase>=1200&&phase<2200?'Prepare-se… o puxão vem aí.':'Aguarde o sinal do alvo.';}
  const hits=p.hits||0,crits=p.crits||0,dodges=p.perfectDodges||0,blocks=p.blocks||0,signatureHits=p.signatureHits||0;
  engine.practiceStep(state,p.id,input,now);const c=engine.contact(p,q);run.contact=c;
  if(index===7)run.warning=q.signatureWindup>0&&q.signatureWindup<=.45?'Defenda agora!':q.signatureWindup>0?'Prepare-se: o círculo está carregando.':'Aguarde a próxima tentativa. Sua armação está protegida neste treino.';
  const hit=(p.hits||0)>hits;
  run.complete=index===6?q.hull<100:index===7?(p.blocks||0)>blocks:index===8?(p.signatureHits||0)>signatureHits:index===0?hit:index===1?hit&&c?.own>=.85&&!engine.contact(q,p)?.valid:index===2?hit&&c?.perfect:index===3?(p.crits||0)>crits:index===4?(p.perfectDodges||0)>dodges:!input.cut&&p.energy>=90;
  run.elapsed=(run.elapsed||0)+dt;return run;
 }
 return {lessons,create,tick};
}
