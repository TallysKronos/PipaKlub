import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {serve} from './server.mjs';
import {validate} from './model.mjs';
const ids=['alvacordo','tramadraco','trovareta','rabiolava','glacerol','tufanocorte','retalho-original','retalho-mascarada','platyx','rai','riscaz','pipa-dragao','pipa-dragao-desatada','azulfazo','azulfazo-possuido','mormaco'];
test('approved campaign presets load through local Studio with their assets',async()=>{
 const server=http.createServer(serve);
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const original=globalThis.fetch,base='http://127.0.0.1:'+server.address().port;
 globalThis.fetch=(input,options)=>original(new URL(input,base),options);
 try{
  const page=await (await fetch('/')).text(),studio=await(await fetch('/studio.mjs')).text();
  for(const id of ids){
   assert(page.includes('id="'+id+'"'),id+' button');
   assert(studio.includes("requestedPreset==='"+id+"'"),id+' direct route');
   const response=await fetch('/art/soulgen/keys/'+id+'/preset.mjs');assert.equal(response.status,200,id+' module');
   const source=(await response.text()).replace("'/model.mjs'",JSON.stringify(new URL('./model.mjs',import.meta.url).href));
   const module=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
   const factory=Object.values(module).find(value=>typeof value==='function');
   const project=await factory();assert.equal(validate(project).ok,true,id);
   for(const asset of Object.values(project.assets)){
    if(asset.src.startsWith('data:'))continue;
    assert.equal((await fetch(asset.src)).status,200,id+' '+asset.src);
   }
  }
 }finally{globalThis.fetch=original;await new Promise(resolve=>server.close(resolve));}
});
