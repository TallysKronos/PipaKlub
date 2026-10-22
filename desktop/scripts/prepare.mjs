import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const desktop=fileURLToPath(new URL('../',import.meta.url)),repo=path.resolve(desktop,'..'),client=path.join(desktop,'build','client');
// Only generated files under desktop/build can be removed by this preparer.
if(path.relative(path.join(desktop,'build'),client)!=='client')throw Error('Unsafe build target');
await fs.rm(client,{recursive:true,force:true});
const build=spawnSync(process.execPath,['build.mjs','--desktop'],{cwd:repo,stdio:'inherit'});if(build.status!==0)process.exit(build.status||1);
let html=await fs.readFile(path.join(client,'index.html'),'utf8'),css='';
await fs.mkdir(path.join(client,'assets','fonts'),{recursive:true});await fs.mkdir(path.join(client,'licenses'),{recursive:true});
for(const [family,weights]of [['nunito',[600,700,800,900]],['lilita-one',[400]],['pixelify-sans',[600,700]]]){
 const directory=path.join(desktop,'node_modules','@fontsource',family);
 for(const weight of weights){
  let source=await fs.readFile(path.join(directory,weight+'.css'),'utf8');
  const names=[...source.matchAll(/url\(\.\/files\/([a-z0-9-]+\.woff2?)\)/g)].map(m=>m[1]);
  for(const name of new Set(names))await fs.copyFile(path.join(directory,'files',name),path.join(client,'assets','fonts',name));
  source=source.replaceAll('url(./files/','url(/assets/fonts/');css+=source+'\n';
 }
 await fs.copyFile(path.join(directory,'LICENSE'),path.join(client,'licenses',family+'.txt'));
}
const googleImport=/@import url\('https:\/\/fonts\.googleapis\.com[^']+'\);/;
if(!googleImport.test(html))throw Error('Desktop font import contract changed');
html=html.replace(googleImport,css);await fs.writeFile(path.join(client,'index.html'),html);
async function filesIn(directory,prefix=''){const files=[];for(const entry of await fs.readdir(directory,{withFileTypes:true})){const relative=prefix+entry.name;if(entry.isDirectory())files.push(...await filesIn(path.join(directory,entry.name),relative+'/'));else files.push(relative);}return files;}
const files=(await filesIn(client)).filter(f=>f==='index.html'||f.startsWith('assets/')).sort(),metadata=JSON.parse(await fs.readFile(path.join(desktop,'package.json'),'utf8'));
const bundle={version:metadata.version,files,htmlSha256:createHash('sha256').update(html).digest('hex'),serverOrigin:JSON.parse(await fs.readFile(path.join(desktop,'config.json'),'utf8')).serverOrigin};
await fs.writeFile(path.join(client,'bundle.json'),JSON.stringify(bundle,null,2)+'\n');
console.log('Desktop prepared:',files.length,'bundled files. Fonts local; telemetry disabled; backend unchanged.');
