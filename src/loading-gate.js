// Named leases prevent an older request from revealing a newer screen.
export function createLoadingGate({change=()=>{},paint=fn=>Promise.resolve().then(fn),later=setTimeout,cancel=clearTimeout,timeout=25000}={}){
 const jobs=new Map();let sequence=0;
 const snapshot=()=>{const list=[...jobs.values()],current=list.at(-1);return {active:!!list.length,count:list.length,...current?{title:current.title,detail:current.detail,failed:current.failed,completed:current.completed,total:current.total,retry:current.retry,back:current.back}:{}};};
 const emit=()=>change(snapshot());
 function start(key,title,{retry=null,back=null,detail='Preparando o próximo lugar…'}={}){
  const previous=jobs.get(key);if(previous)cancel(previous.timer);
  const job={id:++sequence,title,detail,retry,back,failed:false,completed:0,total:0,timer:null};jobs.set(key,job);
  const current=()=>jobs.get(key)===job;
  function fail(message){if(!current())return;cancel(job.timer);job.failed=true;job.detail=message||'Não foi possível carregar. Tente novamente.';emit();}
  job.timer=later(()=>fail('O carregamento demorou mais que o esperado. Tente novamente ou volte.'),timeout);emit();
  return {
   update(completed,total,detail){if(!current())return;job.completed=Math.max(0,completed);job.total=Math.max(job.completed,total||0);if(detail)job.detail=detail;emit();},
   fail,
   done(){if(!current())return Promise.resolve(false);cancel(job.timer);return new Promise(resolve=>paint(()=>{if(!current()){resolve(false);return;}jobs.delete(key);emit();resolve(true);}));},
   cancel(){if(!current())return;cancel(job.timer);jobs.delete(key);emit();},
   get current(){return current();}
  };
 }
 return {start,snapshot,cancel(key){const j=jobs.get(key);if(j){cancel(j.timer);jobs.delete(key);emit();}},get active(){return jobs.size>0;}};
}
