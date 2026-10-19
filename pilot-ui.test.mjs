import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createSwitchNav} from './src/switch-nav.js';
const client=fs.readFileSync('src/pilot-ui-client.js','utf8'),css=fs.readFileSync('src/pilot-ui.css','utf8');
test('PIP-50 pilot ships in both builds and can be turned off with ?classico',()=>{
 for(const file of ['worker/index.js','docs/index.html']){const page=fs.readFileSync(file,'utf8');assert.ok(page.includes('pilotRenderMenu'),file);assert.ok(page.includes('.pilot-menu'),file);}
 assert.match(client,/classico/);
});
test('every device has glyphs for the footer commands X and Y',()=>{
 const nav=createSwitchNav();
 for(const [name,set] of Object.entries(nav.GLYPHS))for(const command of ['actionX','actionY','confirm','back','tabLeft','tabRight'])assert.ok(set[command],name+' '+command);
});
test('back from a screen opened by the menu returns to its option',()=>{
 for(const close of ['closeAccount','closeDex','closeModal','closeSchool'])assert.match(client,new RegExp(close+'=function'),close);
 assert.match(fs.readFileSync('src/courtyard-client.js','utf8'),/!\(typeof dexOpen!=='undefined'&&dexOpen\)/,'Escape over the Dex closes the Dex, not opens the menu');
});
test('pilot respects reduced motion',()=>{assert.match(css,/prefers-reduced-motion:reduce/);});
