export let mountedRevision;
export async function createKaelMounted(cached){
 const r=await fetch('/api/mounted-rig');if(!r.ok)throw Error('Não foi possível abrir o Kael montado.');
 const data=await r.json();
 if(cached?.creatureId==='kael-mounted'&&cached.mountSourceRevision){mountedRevision=cached.mountSourceRevision;return cached;}
 mountedRevision=data.revision;data.project.mountSourceRevision=mountedRevision;return data.project;
}
export async function saveKaelMounted(project){
 const r=await fetch('/api/mounted-rig',{method:'PUT',headers:{'Content-Type':'application/json'},body:JSON.stringify({revision:mountedRevision,project})});
 const data=await r.json();if(!r.ok)throw Error(data.error||'Não foi possível salvar.');mountedRevision=data.revision;return data;
}
