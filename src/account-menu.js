// Keep account features on separate screens without recreating their live state.
let accountPage='home';
const clubRoot=$('accountCollection'),clubPages=new Map();
const clubHome=uiElement('div',undefined,'club-home');clubHome.id='clubHome';
const clubBack=uiElement('button','← Menu do clube','secondary club-back');clubBack.type='button';clubBack.hidden=true;
clubRoot.prepend(clubBack,clubHome);
function clubPage(id){const node=uiElement('section',undefined,'club-page');node.id='club-'+id;node.hidden=true;clubPages.set(id,node);clubRoot.append(node);return node;}
const collectionPage=clubPage('collection');collectionPage.append($('collectionMain'),$('kiteStory'));
const profilePage=clubPage('profile');profilePage.append(document.querySelector('.account-summary'),$('nicknameForm'),$('logoutAccount'));
const eventsPage=clubPage('events'),events=$('eventSoulsList');
eventsPage.append(events.previousElementSibling.previousElementSibling,events.previousElementSibling,events);
const duelsPage=clubPage('history'),duels=$('recentMatches');duelsPage.append(duels.previousElementSibling,duels);
clubPage('trades').append(tradePanel);
summonEntry.hidden=true;clubPage('summon').append(summonEntry,summonRoom);
const farmPage=clubPage('farm');
const clubTitles={home:'Seu cantinho no clube',collection:'Minhas pipas',trades:'Trocas por convite',summon:'Oficina das Almas',farm:'Fazenda de Pipamons',profile:'Meu perfil',history:'Meus duelos',events:'Souls de evento'};
const clubEntries=[['collection','Minhas pipas','Equipe e conheça sua coleção.',0],['trades','Trocas','Uma pipa, um novo encontro.',1],['summon','Oficina das Almas','Encontre o Sr. Assis.',2],['farm','Fazenda de Pipamons','Veja sua coleção passeando.',3],['profile','Meu perfil','Nome e progresso no clube.',4],['history','Meus duelos','Relembre suas partidas.',5]];
for(const [id,title,description,index] of clubEntries){
 const button=uiElement('button',undefined,'club-tile');button.type='button';button.dataset.page=id;
 const illustration=uiElement('span',undefined,'club-tile-art');illustration.setAttribute('aria-hidden','true');illustration.style.backgroundImage=`url("${ART_CONFIG.menu[id].url}")`;
 button.append(illustration,uiElement('b',title),uiElement('small',description));button.onclick=()=>navigateClub(id);clubHome.append(button);
}
const eventLink=uiElement('button','✦ Explorar Souls de evento','secondary club-events');eventLink.type='button';eventLink.onclick=()=>navigateClub('events');clubHome.append(eventLink);
function syncClubMenu(){
 if(!playerAccount)return;
 $('accountTitle').textContent=clubTitles[accountPage];clubHome.hidden=accountPage!=='home';clubBack.hidden=accountPage==='home';
 for(const [id,node] of clubPages)node.hidden=id!==accountPage;
}
function navigateClub(page){
 if(!playerAccount){openAccount();return;}
 if(!clubTitles[page])return;
 if(summonOpen&&page!=='summon')leaveSummoner();
 closeKiteStory();accountPage=page;$('accountMessage').textContent='';syncClubMenu();
 document.querySelector('.account-card').scrollTop=0;
 let ready=Promise.resolve();if(page==='summon'&&!summonOpen)ready=openSummoner();
 if(page==='history')ready=loadRecentMatches();
 if(page==='trades'&&playerAccount)ready=tradeAction('read',{code:currentTrade?.status==='open'?currentTrade.code:null});
 if(page==='home')clubHome.querySelector('button').focus();else (clubBack.offsetParent?clubBack:document.getElementById('club-'+page)?.querySelector('button,input,select')||$('closeAccount'))?.focus({preventScroll:true});
 return ready;
}
clubBack.onclick=()=>navigateClub('home');
const originalLeaveSummoner=leaveSummoner;
leaveSummoner=function(){originalLeaveSummoner();if(accountPage==='summon'){accountPage='home';syncClubMenu();}};
$('leaveSummoner').onclick=()=>navigateClub('home');
$('leaveSummoner').hidden=true;
const originalRenderAccountDialog=renderAccountDialog;
renderAccountDialog=function(){originalRenderAccountDialog();if(accountRecoveryMode)return;if(!playerAccount)accountPage='home';syncClubMenu();};
const originalOpenAccount=openAccount;
openAccount=async function(){if(!mode){accountPage='home';syncClubMenu();}return originalOpenAccount();};
$('accountButton').onclick=openAccount;
