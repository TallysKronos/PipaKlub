import {validateLayout,clone} from './model.mjs';
const request=r=>new Promise((resolve,reject)=>{r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
const completed=t=>new Promise((resolve,reject)=>{t.oncomplete=resolve;t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error??Error('Salvamento cancelado.'));});
export class ProjectStore{
 constructor(db){this.db=db;this.queue=Promise.resolve();}
 static async open(){const r=indexedDB.open('soulmonsters-studio-projects',2);r.onupgradeneeded=()=>{const db=r.result;if(!db.objectStoreNames.contains('projects')){db.createObjectStore('projects',{keyPath:'id'});const v=db.createObjectStore('versions',{keyPath:'id'});v.createIndex('project','projectId');db.createObjectStore('meta');}for(const name of ['stamps','assets'])if(!db.objectStoreNames.contains(name))db.createObjectStore(name,{keyPath:'id'});};return new ProjectStore(await request(r));}
 async list(){await this.queue;return request(this.db.transaction('projects').objectStore('projects').getAll());}
 async get(id){await this.queue;return request(this.db.transaction('projects').objectStore('projects').get(id));}
 async versions(id){await this.queue;return (await request(this.db.transaction('versions').objectStore('versions').index('project').getAll(id))).sort((a,b)=>b.at-a.at);}
 async ensure(layout){const id=await request(this.db.transaction('meta').objectStore('meta').get('active'));if(id){const project=await this.get(id);if(project)return project;}return this.create('Bosque de Kronasta',layout);}
 async create(name,layout){const id=crypto.randomUUID();await this.save(id,layout,{name:name.trim()||'Novo mapa',reason:'Criação'});await this.activate(id);return this.get(id);}
 async activate(id){await this.queue;const t=this.db.transaction('meta','readwrite');t.objectStore('meta').put(id,'active');await completed(t);}
 save(id,layout,{name,reason='Salvamento automático'}={}){
  const value=validateLayout(clone(layout));
  const work=async()=>{
   const t=this.db.transaction(['projects','versions'],'readwrite'),done=completed(t),projects=t.objectStore('projects'),versions=t.objectStore('versions'),old=await request(projects.get(id)),at=Date.now();
   if(!old||JSON.stringify(old.layout)!==JSON.stringify(value)){
    versions.put({id:crypto.randomUUID(),projectId:id,at,reason,layout:value});
    const history=await request(versions.index('project').getAll(id));history.sort((a,b)=>b.at-a.at);for(const entry of history.slice(20))versions.delete(entry.id);
   }
   projects.put({id,name:name?.trim()||old?.name||'Novo mapa',updatedAt:at,layout:value});await done;
  };
  const result=this.queue.then(work);this.queue=result.catch(()=>{});return result;
 }
 async records(store){await this.queue;return request(this.db.transaction(store).objectStore(store).getAll());}
 async putRecord(store,value){const t=this.db.transaction(store,'readwrite');t.objectStore(store).put(value);await completed(t);}
 flush(){return this.queue;}
}
