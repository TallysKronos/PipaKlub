// IndexedDB stores editable projects and sources locally; no server uploads.
export function createStorage(idb=globalThis.indexedDB,local=globalThis.localStorage){
 let opening,queue=Promise.resolve();
 function db(){if(!idb)return Promise.reject(Error('IndexedDB indisponível. Exporte uma cópia do projeto.'));if(!opening)opening=new Promise((resolve,reject)=>{const r=idb.open('pixelgen-workbench',1);r.onupgradeneeded=()=>{for(const name of ['autosave','projects','catalog'])if(!r.result.objectStoreNames.contains(name))r.result.createObjectStore(name);};r.onsuccess=()=>{r.result.onversionchange=()=>{r.result.close();opening=undefined;};resolve(r.result);};r.onerror=()=>{opening=undefined;reject(r.error);};r.onblocked=()=>{opening=undefined;reject(Error('Feche outra aba antiga do Pixelgen para abrir a biblioteca.'));};});return opening;}
 async function get(store,key){const d=await db();return new Promise((resolve,reject)=>{const t=d.transaction(store,'readonly'),r=t.objectStore(store).get(key);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});}
 function serializeWrite(job){const next=queue.catch(()=>{}).then(job);queue=next;return next;}
 return {
  async automatic(value){return serializeWrite(async()=>{
   if(!idb){const old=local?.getItem('pixelgen-autosave-v2');if(old)local.setItem('pixelgen-recovery-v2',old);local.setItem('pixelgen-autosave-v2',JSON.stringify(value));return;}
   const d=await db();await new Promise((resolve,reject)=>{const t=d.transaction('autosave','readwrite'),s=t.objectStore('autosave'),r=s.get('current');r.onsuccess=()=>{if(r.result)s.put(r.result,'previous');s.put(value,'current');};t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error||Error('Gravação cancelada.'));});
  });},
  async restore(previous=false){if(!idb){const v=local?.getItem(previous?'pixelgen-recovery-v2':'pixelgen-autosave-v2');return v?JSON.parse(v):undefined;}return get('autosave',previous?'previous':'current');},
  async save(value){return serializeWrite(async()=>{const id=value.id||globalThis.crypto.randomUUID(),data={...value,id},d=await db(),updatedAt=Date.now();await new Promise((resolve,reject)=>{const t=d.transaction(['projects','catalog'],'readwrite');t.objectStore('projects').put(data,id);t.objectStore('catalog').put({id,name:String(data.name||'Projeto'),width:data.width,height:data.height,frames:data.frames.length,updatedAt},id);t.oncomplete=()=>resolve();t.onerror=()=>reject(t.error);t.onabort=()=>reject(t.error||Error('Gravação cancelada.'));});return id;});},
  async list(){const d=await db();return new Promise((resolve,reject)=>{const t=d.transaction('catalog','readonly'),r=t.objectStore('catalog').getAll();r.onsuccess=()=>resolve(r.result.sort((a,b)=>b.updatedAt-a.updatedAt));r.onerror=()=>reject(r.error);});},
  load:id=>get('projects',id),
 };
}
