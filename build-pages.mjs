import {artSource,copyArt} from './scripts/art-build.mjs';
import fs from 'node:fs';
import {Script} from 'node:vm';
const engine=fs.readFileSync('src/engine.js','utf8').replace('export function','function');
const clarityId=String(process.env.CLARITY_ID??'yz4vye9268').trim();if(clarityId&&!/^[a-z0-9]{6,20}$/i.test(clarityId))throw Error('CLARITY_ID inválido: use o id do projeto no Clarity.');
const telemetry=fs.readFileSync('src/telemetry-client.js','utf8').replace("/* CLARITY_ID */''",JSON.stringify(clarityId));
const html=fs.readFileSync('src/index.html','utf8')
  .replace('/* ENGINE */',engine).replace('/* ART_CLIENT */',artSource()).replace('/* ONBOARDING_CLIENT */',fs.readFileSync('src/onboarding-client.js','utf8')+'\n'+fs.readFileSync('src/school.js','utf8').replace('export function','function')+'\n'+fs.readFileSync('src/school-client.js','utf8'))
  .replace('/* NETWORK_VIEW */',fs.readFileSync('src/network-view.js','utf8').replace('export function','function'))
  .replace('/* FRAME_HEALTH */',fs.readFileSync('src/frame-health.js','utf8').replace('export function','function'))
  .replace('/* ACCOUNT_CLIENT */',fs.readFileSync('src/account-client.js','utf8')+'\n'+fs.readFileSync('src/results-client.js','utf8')+'\n'+fs.readFileSync('src/trade-client.js','utf8')+'\n'+fs.readFileSync('src/summon-pattern.js','utf8').replaceAll('export function','function')+'\n'+fs.readFileSync('src/summon-client.js','utf8')+'\n'+fs.readFileSync('src/account-menu.js','utf8')+'\n'+fs.readFileSync('src/farm.js','utf8').replace('export function','function')+'\n'+fs.readFileSync('src/farm-client.js','utf8'))
  .replace('/* HOST_CONFIG */','const STATIC_HOST = true;')
  .replace('/* DEX_CLIENT */',fs.readFileSync('src/dex-client.js','utf8')).replace('/* TELEMETRY */',telemetry).replace('/* TRAILS */',fs.readFileSync('src/trails.js','utf8').replace('export function','function')+'\n'+fs.readFileSync('src/trail-sync.js','utf8').replace('export function','function')+'\n'+fs.readFileSync('src/trails-client.js','utf8')+'\n'+fs.readFileSync('src/trail-sync-client.js','utf8')+'\n'+fs.readFileSync('src/trail-rewards-client.js','utf8')+'\n'+fs.readFileSync('src/line-styles.js','utf8').replace('export function','function')+'\nconst lineStyles=createLineStyles();\n'+fs.readFileSync('src/line-shop-client.js','utf8')+'\n'+fs.readFileSync('src/daily-client.js','utf8')+'\n'+fs.readFileSync('src/design-client.js','utf8'));
new Script(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
fs.mkdirSync('docs',{recursive:true});
fs.writeFileSync('docs/index.html',html);
fs.writeFileSync('docs/.nojekyll','');
console.log('GitHub Pages ready in docs/. Multiplayer server is deployed separately.');

copyArt('docs');
