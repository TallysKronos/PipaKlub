import fs from 'node:fs/promises';import path from 'node:path';
const out=path.resolve(import.meta.dirname,'../../art/concepts/montaria-doberman/animation-v1'),manifestPath=path.join(out,'manifest.json');
const [base,command,id]=process.argv.slice(2);if(!base||!['submit','status','collect'].includes(command))throw Error('Use: node run-mount-motion.mjs <ComfyUI URL> submit|status|collect <action-direction>');
const url=new URL(base);if(!['localhost','127.0.0.1','[::1]'].includes(url.hostname))throw Error('Only the local ComfyUI is authorized for this project.');
const manifest=JSON.parse(await fs.readFile(manifestPath)),shot=manifest.shots.find(s=>s.id===id);if(!shot)throw Error('Unknown shot.');
async function json(route,options){const r=await fetch(new URL(route,base),{...options,signal:AbortSignal.timeout(60000)}),j=await r.json();if(!r.ok)throw Error(JSON.stringify(j).slice(0,1800));return j;}
async function save(){await fs.writeFile(manifestPath,JSON.stringify(manifest,null,2));}
if(command==='submit'){
 if(shot.promptId)throw Error('Already submitted: '+shot.promptId+'; inspect before resubmitting.');
 const queue=await json('/queue');const queued=[...queue.queue_running,...queue.queue_pending],owned=new Set(manifest.shots.map(s=>s.promptId).filter(Boolean));if(queued.length&&(!process.argv.includes('--allow-owned-queue')||queued.some(j=>!owned.has(j[1]))))throw Error('ComfyUI queue has other jobs; preserve them.');
 const graph=JSON.parse(await fs.readFile(path.join(out,shot.workflow))),info=await json('/object_info');
 for(const node of Object.values(graph)){if(!info[node.class_type])throw Error('Missing node: '+node.class_type);if(/Api$|API|Kling|Veo/.test(node.class_type))throw Error('Partner nodes forbidden.');}
 for(const [key,field]of [['1','unet_name'],['2','clip_name'],['3','vae_name'],['4','vae_name']]){
 const node=graph[key],options=info[node.class_type].input.required[field][0];if(!options.includes(node.inputs[field]))throw Error('Installed model missing: '+node.inputs[field]);}
 const bytes=await fs.readFile(path.join(out,shot.reference)),form=new FormData();form.set('image',new Blob([bytes],{type:'image/png'}),'mount-edited-'+manifest.source['kael-rider-refined.png'].sha256.slice(0,10)+'-'+shot.direction+'.png');form.set('overwrite','false');form.set('type','input');
 const upload=await json('/upload/image',{method:'POST',body:form});graph['5'].inputs.image=[upload.subfolder,upload.name].filter(Boolean).join('/');
 graph['8'].inputs.length=124;shot.frames=124;
 await fs.writeFile(path.join(out,shot.workflow),JSON.stringify(graph,null,2));
 const result=await json('/prompt',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({prompt:graph,client_id:'soulmonsters-mount-motion-v1'})});
 shot.promptId=result.prompt_id;shot.status='submitted';shot.submittedAt=new Date().toISOString();shot.nodeErrors=result.node_errors;await save();console.log(JSON.stringify({id:shot.id,...result}));
}else{
 if(!shot.promptId)throw Error('Not submitted.');const h=await json('/history/'+shot.promptId),history=h[shot.promptId];
 if(!history){const q=await json('/queue');console.log(JSON.stringify({id:shot.id,status:q.queue_running.some(x=>x[1]===shot.promptId)?'running':'pending',promptId:shot.promptId}));process.exit(0);}
 await fs.writeFile(path.join(out,'review',shot.id+'-history.json'),JSON.stringify(history,null,2));shot.status=history.status?.completed?'completed':history.status?.status_str||'unknown';await save();
 const files=[];for(const output of Object.values(history.outputs||{}))for(const [kind,list]of Object.entries(output))if(Array.isArray(list))for(const f of list)if(f?.filename)files.push({...f,kind});
 if(command==='collect'&&shot.status==='completed'){
 shot.outputs=[];for(const file of files){const r=await fetch(new URL('/view?'+new URLSearchParams({filename:file.filename,subfolder:file.subfolder||'',type:file.type||'output'}),base));if(!r.ok)throw Error('Output download failed');const dest=path.join(out,'video-original',shot.id+path.extname(file.filename));await fs.writeFile(dest,Buffer.from(await r.arrayBuffer()));shot.outputs.push(path.relative(out,dest).replaceAll('\\','/'));}await save();}
 console.log(JSON.stringify({id:shot.id,status:shot.status,files,errors:history.status?.messages?.filter(m=>m[0]==='execution_error').map(m=>({node:m[1].node_type,error:m[1].exception_message}))}));
}
