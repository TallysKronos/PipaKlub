import fs from 'node:fs';
const manifest=JSON.parse(fs.readFileSync('assets/workshop/v1/manifest.json','utf8'));
const runtime=['workshop-model','workshop-reveal','workshop-renderer'].map(id=>fs.readFileSync('src/'+id+'.js','utf8').replace(/^export /gm,'')).join('\n');
const html=fs.readFileSync('src/workshop-preview.html','utf8').replace('/* WORKSHOP_PREVIEW_RUNTIME */',()=>runtime).replace('/* WORKSHOP_PREVIEW_STYLE */',()=>fs.readFileSync('src/workshop.css','utf8')).replace('/* WORKSHOP_PREVIEW_INPUT */',()=>fs.readFileSync('src/workshop-preview-reveal.js','utf8')).replace('/* WORKSHOP_PREVIEW_CONFIG */',()=>JSON.stringify(manifest));
fs.mkdirSync('art/workshop-v1',{recursive:true});fs.writeFileSync('art/workshop-v1/index.html',html);console.log('Built interactive workshop preview.');
