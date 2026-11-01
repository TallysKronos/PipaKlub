import fs from 'node:fs/promises';
import path from 'node:path';
const [action,base='http://localhost:8188']=process.argv.slice(2);
const root=process.cwd(),folder=path.join(root,'art/lacertubo-cinematic-video-v1');
async function get(route){const r=await fetch(base+route);if(!r.ok)throw Error(await r.text());return r.json();}
async function upload(file,name){
 const form=new FormData();form.set('image',new Blob([await fs.readFile(file)],{type:'image/png'}),name);form.set('overwrite','false');
 const r=await fetch(base+'/upload/image',{method:'POST',body:form});if(!r.ok)throw Error(await r.text());
 const out=await r.json();return out.subfolder?out.subfolder+'/'+out.name:out.name;
}
if(action==='submit'){
 const queue=await get('/queue');if(queue.queue_running.length||queue.queue_pending.length)throw Error('ComfyUI queue is occupied; do not displace other work.');
 const file=path.join(folder,'workflows/lacertubo-patio-h3-local.json');const graph=JSON.parse(await fs.readFile(file,'utf8'));
 graph['5'].inputs.image=await upload(path.join(folder,'fontes/lacertubo-patio-keyframe.png'),'lacertubo-patio-keyframe.png');
 graph['7'].inputs.image=await upload(path.join(root,'art/tyler-saber-forest-film-v1/keyframes/forest-lacertubo.png'),'lacertubo-approved-identity.png');
 const catalog=await get('/object_info');
 for(const [id,node]of Object.entries(graph)){
  if(!catalog[node.class_type])throw Error('Missing node '+node.class_type);
  if(/API|Partner/.test(node.class_type))throw Error('Hosted/API nodes are not authorized');
  for(const [key,value]of Object.entries(node.inputs)){
   const schema=catalog[node.class_type].input.required?.[key]||catalog[node.class_type].input.optional?.[key];
   if(schema&&Array.isArray(schema[0])&&!schema[0].includes(value))throw Error(id+': unavailable '+key+' '+value);
  }
 }
 await fs.writeFile(file,JSON.stringify(graph,null,2));
 const r=await fetch(base+'/prompt',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({prompt:graph,client_id:'soulmonsters-lacertubo-cinematic-v1'})});
 const result=await r.json();if(!r.ok||!result.prompt_id)throw Error(JSON.stringify(result));
 await fs.writeFile(path.join(folder,'job.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}else if(action==='status'||action==='fetch'){
 const {prompt_id}=JSON.parse(await fs.readFile(path.join(folder,'job.json'),'utf8'));
 const history=await get('/history/'+prompt_id),job=history[prompt_id];
 if(!job){const q=await get('/queue');console.log(JSON.stringify({prompt_id,running:q.queue_running.map(x=>[x[0],x[1]]),pending:q.queue_pending.map(x=>[x[0],x[1]])}));process.exit(0);}
 await fs.writeFile(path.join(folder,'history.json'),JSON.stringify(job,null,2));
 console.log(JSON.stringify({prompt_id,status:job.status,outputs:job.outputs}));
 if(action==='fetch'&&job.status?.status_str==='success'){
  for(const output of Object.values(job.outputs))for(const entries of Object.values(output))if(Array.isArray(entries))for(const item of entries){
   if(!item.filename||!item.filename.endsWith('.mp4'))continue;
   const query=new URLSearchParams({filename:item.filename,subfolder:item.subfolder||'',type:item.type||'output'});
   const r=await fetch(base+'/view?'+query);if(!r.ok)throw Error(await r.text());
   const dir=path.join(folder,'video-original');await fs.mkdir(dir,{recursive:true});
   const file=path.join(dir,item.filename);await fs.writeFile(file,Buffer.from(await r.arrayBuffer()));console.log(file);
  }
 }
}else throw Error('Use submit, status, or fetch');
