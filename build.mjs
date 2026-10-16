import fs from 'node:fs';
const engine=fs.readFileSync('src/engine.js','utf8').replace('export function','function');
const network=fs.readFileSync('src/network-view.js','utf8').replace('export function','function');
const html=fs.readFileSync('src/index.html','utf8').replace('/* ENGINE */',engine).replace('/* NETWORK_VIEW */',network);
const source=engine+'\nconst PAGE='+JSON.stringify(html)+';\n'+fs.readFileSync('src/backend.js','utf8');
fs.mkdirSync('worker',{recursive:true});fs.writeFileSync('worker/index.js',source);
fs.mkdirSync('dist/server',{recursive:true});fs.mkdirSync('dist/.openai',{recursive:true});
fs.writeFileSync('dist/server/index.js',source);fs.copyFileSync('.openai/hosting.json','dist/.openai/hosting.json');
console.log('Built Pipa Club (Worker + embedded game).');
