import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import fs from 'node:fs/promises';
import {serve} from './server.mjs';
import {validate} from './model.mjs';
test('four Lince forms load through Soulgen with registered complete faces and valid PNG sizes',async()=>{
 const server=http.createServer(serve);await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const original=globalThis.fetch,base=`http://127.0.0.1:${server.address().port}`;
 globalThis.fetch=(input,options)=>original(new URL(input,base),options);
 try{
  const source=await(await fetch('/art/soulgen/keys/lince-de-cerco/preset.mjs')).text();
  const mod=await import('data:text/javascript;base64,'+Buffer.from(source.replace("'/model.mjs'",JSON.stringify(new URL('./model.mjs',import.meta.url).href))).toString('base64'));
  const html=await(await fetch('/')).text(),studio=await(await fetch('/studio.mjs')).text();
  assert(studio.includes('const STORE=[...LINCE_PRESETS,'));
  assert(studio.includes('if(LINCE_PRESETS.includes(requestedPreset))'));
  for(const id of mod.LINCE_PRESETS){
   assert(html.includes(`id="${id}"`));
   const p=await mod.createLince(id),check=validate(p);assert(check.ok);assert.deepEqual(check.warnings,[]);
   for(const a of Object.values(p.assets)){
    const response=await fetch(a.src);assert.equal(response.status,200,a.src);
    const bytes=Buffer.from(await response.arrayBuffer());assert.equal(bytes.readUInt32BE(16),a.width);assert.equal(bytes.readUInt32BE(20),a.height);
   }
   const head=p.parts.find(x=>x.faces);assert(head);
   for(const face of ['fierce','hurt','happy'])assert.deepEqual(head.faces[face].source,head.source);
   for(const clip of Object.values(p.clips))if(clip.loop)assert.deepEqual(clip.frames[0].values,clip.frames.at(-1).values);
   const audit=JSON.parse(await fs.readFile(new URL(`../../art/soulgen/keys/${id}/cutout-rig-v1/validation.json`,import.meta.url)));
   assert.equal(audit.atlas.borderPixels,0);assert.equal(audit.atlas.frames,119);
   assert.deepEqual(Object.keys(p.clips),['idle','flight','skill','hurt','victory','defeat']);
  }
  await assert.rejects(()=>mod.createLince('../other'));
 }finally{globalThis.fetch=original;await new Promise(r=>server.close(r));}
});
