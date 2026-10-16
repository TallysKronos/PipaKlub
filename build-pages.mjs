import fs from 'node:fs';
import {Script} from 'node:vm';
const engine=fs.readFileSync('src/engine.js','utf8').replace('export function','function');
const html=fs.readFileSync('src/index.html','utf8')
  .replace('/* ENGINE */',engine)
  .replace('/* NETWORK_VIEW */',fs.readFileSync('src/network-view.js','utf8').replace('export function','function'))
  .replace('/* HOST_CONFIG */','const STATIC_HOST = true;');
new Script(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
fs.mkdirSync('docs',{recursive:true});
fs.writeFileSync('docs/index.html',html);
fs.writeFileSync('docs/.nojekyll','');
console.log('GitHub Pages ready in docs/. Multiplayer server is deployed separately.');
