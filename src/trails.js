// Trilhas: single-player road of AI duels. Pure data and rules, shared by the page and the tests.
export function createTrails(){
  const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
  const foe=(name,color,soul)=>soul?{name,color,soul}:{name,color};
  const TRAILS=[
    {id:'morro',leader:'mikka',leaderName:'Mikka',name:'Trilha do Morro do Sol',subtitle:'Onde todo pipeiro começa',accent:'#f28a3a',stages:[
      {id:'morro-1',name:'Primeiro cruzamento',level:1,rounds:2,coins:10,foes:[foe('Zeca',0)],tip:'Cruze sua linha na faixa tracejada dele e segure o clique quando a mira ficar verde.'},
      {id:'morro-2',name:'Folha ao vento',level:2,rounds:2,coins:12,foes:[foe('Bia',1)],tip:'A Bia muda de lado num sopro. Não persiga a pipa: espere a linha dela cruzar a sua.'},
      {id:'morro-3',counter:2,name:'Dois na laje',level:2,rounds:2,coins:16,foes:[foe('Juninho',2),foe('Lia',3)],tip:'Com três no céu, deixe os dois se cortarem e entre para terminar o serviço.'},
      {id:'morro-4',name:'Teimosia azul',level:3,rounds:2,coins:18,foes:[foe('Tião',2)],tip:'Quando aparecer o anel vermelho, você está na mira: aperte Shift (ou ESQ) para esquivar. Esquivando na hora do puxão, o próximo acerto sai crítico.'},
      {id:'morro-5',drop:'rabiola-raio-de-sol',name:'Desafio de Mikka',level:4,rounds:3,coins:30,boss:true,foes:[foe('Mikka',3)],tip:'Mikka lê o céu como um mapa. Guarde energia: quem puxa sem parar perde o fôlego.'}
    ]},
    {id:'praia',leader:'lohan',leaderName:'Lohan',name:'Trilha da Beira-Mar',subtitle:'Vento forte, linha firme',accent:'#2f9e8f',stages:[
      {id:'praia-1',name:'Brisa salgada',level:4,rounds:2,coins:20,foes:[foe('Dona Cida',0)],tip:'Abra o ângulo e puxe com a pipa em movimento: centro dourado + ângulo aberto + relada é CORTE CRÍTICO.'},
      {id:'praia-2',counter:0,name:'Ventania',level:3,rounds:2,coins:24,foes:[foe('Kauã',1),foe('Mel',3)],tip:'Dois rivais rápidos. Fique alto e escolha quem cruzar primeiro.'},
      {id:'praia-3',name:'Rede de pescador',level:5,rounds:2,coins:26,foes:[foe('Seu Dito',2)],tip:'Seu Dito desvia quando percebe a sua mira. Mude o ângulo antes de puxar.'},
      {id:'praia-4',name:'Trio do píer',level:5,rounds:2,coins:32,foes:[foe('Ravi',0),foe('Nina',1),foe('Caio',3)],tip:'Quatro linhas no céu. Quem sobrevive é quem não fica no meio da confusão.'},
      {id:'praia-5',drop:'rabiola-chaspiral',name:'Desafio de Lohan',level:6,rounds:3,coins:50,boss:true,foes:[foe('Lohan',1,'chaspiral')],tip:'A fada do chá dança de um lado ao outro. Mire onde ela vai estar, não onde está.'}
    ]},
    {id:'torres',leader:'kleie',leaderName:'Kleie',name:'Trilha dos Campanários',subtitle:'Lendas entre os sinos',accent:'#8b4fd6',stages:[
      {id:'torres-1',name:'Sino da tarde',level:6,rounds:2,coins:34,foes:[foe('Irmã Lu',3)],tip:'Irmã Lu amplia a zona de corte. Mantenha distância quando o foco dela acender.'},
      {id:'torres-2',counter:2,name:'Brasas do beco',level:7,rounds:2,coins:40,foes:[foe('Trinca-brasas',2,'trinca-brasas')],tip:'Três cabeças, uma guarda de ferro. Ataque nos intervalos da proteção.'},
      {id:'torres-3',counter:2,name:'Neve de verão',level:7,rounds:2,coins:44,foes:[foe('Alvaneve',0,'alvaneve')],tip:'Alvaneve pune quem fica parado. Cruze, puxe e saia.'},
      {id:'torres-4',counter:2,name:'Coro das torres',level:7,rounds:2,coins:50,foes:[foe('Benê',2),foe('Sol',3),foe('Teca',1)],tip:'O coro ataca o mais fraco. Não deixe sua linha baixar sem reagir.'},
      {id:'torres-5',drop:'rabiola-flautrevo',name:'Desafio de Kleie',level:8,rounds:3,coins:80,boss:true,foes:[foe('Kleie',3,'flautrevo')],tip:'A flauta dele confunde o vento. Respire, leia o cruzamento e seja paciente.'}
    ]}
  ];
  const stages=TRAILS.flatMap((t,ti)=>t.stages.map((s,si)=>({...s,trail:t.id,trailIndex:ti,index:si})));
  const stage=id=>stages.find(s=>s.id===id)||null;
  const MASTERY_MAX=8;
  const DROPS=stages.filter(s=>s.drop).map(s=>s.drop);
  function defaults(){return {coins:0,stars:{},mastery:0,wins:0,losses:0,fails:{},items:[]};}
  // Offline results and legacy saves are unverified; syncing does not authorize shared rewards.
  function sanitize(p){
    const d=defaults();if(!p||typeof p!=='object')return d;
    const stars={},fails={};for(const s of stages){const v=Math.trunc(Number(p.stars?.[s.id]));if(v>0)stars[s.id]=clamp(v,1,3);const f=Math.trunc(Number(p.fails?.[s.id]));if(f>0)fails[s.id]=clamp(f,1,99);}
    const n=(v,max)=>clamp(Math.trunc(Number(v))||0,0,max);
    return {coins:n(p.coins,1e9),stars,mastery:n(p.mastery,MASTERY_MAX),wins:n(p.wins,1e9),losses:n(p.losses,1e9),fails,items:[...new Set(Array.isArray(p.items)?p.items.filter(id=>DROPS.includes(id)):[])]};
  }
  function unlocked(p,id){const i=stages.findIndex(s=>s.id===id);return i===0||(i>0&&!!p.stars[stages[i-1].id]);}
  // Difficulty adapts: every two points of mastery add one AI level on top of the stage's base level.
  // Extra rivals already make a stage harder, so there mastery adds at most one level; after three
  // losses in a row on a stage its AI eases off by one level until the stage is won.
  const RELIEF_AFTER=3;
  function aiLevel(st,p){const bonus=Math.min(st.foes.length>1?1:MASTERY_MAX,Math.floor(p.mastery/2)),relief=(p.fails?.[st.id]||0)>=RELIEF_AFTER?1:0;return clamp(st.level+bonus-relief,1,10);}
  function settle(p,id,{won,roundsLost=0}){
    const st=stage(id),before=sanitize(p),next=sanitize(p);if(!st)return {progress:before,coins:0,stars:0,firstClear:false};
    const stars=won?clamp(3-roundsLost,1,3):0,firstClear=won&&!before.stars[id];
    const coins=won?Math.round(st.coins*(1+(stars-1)*.25))+(firstClear?st.coins:0):0;
    // Bosses drop their Pipamon's rabiola the first time they are beaten.
    const drop=won&&st.drop&&!before.items.includes(st.drop)?st.drop:null;if(drop)next.items.push(drop);
    next.coins+=coins;if(won){next.wins++;next.stars[id]=Math.max(before.stars[id]||0,stars);next.mastery=clamp(before.mastery+(stars===3?2:1),0,MASTERY_MAX);delete next.fails[id];}
    else{next.losses++;next.fails[id]=(before.fails[id]||0)+1;next.mastery=clamp(before.mastery-(next.fails[id]>=2?2:1),0,MASTERY_MAX);}
    return {progress:next,coins,stars,firstClear,drop,fails:next.fails[id]||0,levelBefore:aiLevel(st,before),levelAfter:aiLevel(st,next)};
  }
  const totalStars=p=>Object.values(p.stars).reduce((a,b)=>a+b,0);
  const nextStage=id=>{const i=stages.findIndex(s=>s.id===id);return i>=0?stages[i+1]||null:null;};
  return {DROPS,RELIEF_AFTER,trails:TRAILS,stages,stage,defaults,sanitize,unlocked,aiLevel,settle,totalStars,nextStage,MASTERY_MAX};
}
