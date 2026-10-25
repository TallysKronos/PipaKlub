import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {validate} from '../tools/soulgen-studio/model.mjs';
import {createCarcara} from '../tools/soulgen-studio/carcara.mjs';

const root=fileURLToPath(new URL('../',import.meta.url));
const out=path.join(root,'art/soulgen/pendentes');
const read=async p=>JSON.parse(await fs.readFile(path.join(root,p),'utf8'));
const slash=p=>p.split(path.sep).join('/');
const entries=(await read('assets/pipa-dex.json')).entries;
const atlases=(await read('assets/atlas.json')).atlases;
const required=['idle','flight','skill','hurt','victory'];
const problems=[];
async function png(src){
 const bytes=src.startsWith('data:image/png;base64,')?Buffer.from(src.split(',')[1],'base64'):await fs.readFile(path.join(root,src.replace(/^\//,'')));
 assert.equal(bytes.subarray(1,4).toString(),'PNG');
 return {width:bytes.readUInt32BE(16),height:bytes.readUInt32BE(20)};
}
async function auditProject(project,source){
 const report=validate(project),missing=required.filter(id=>!project.clips?.[id]);
 const errors=[...report.errors,...missing.map(id=>'Ação ausente: '+id)];
 for(const [id,asset] of Object.entries(project.assets||{})){
  try {const size=await png(asset.src);if(size.width!==asset.width||size.height!==asset.height)errors.push('Dimensão divergente: '+id);}
  catch {errors.push('Fonte PNG ausente/inválida: '+id);}
 }
 if(errors.length)problems.push({source,errors});
 return {source,ok:errors.length===0,errors,warnings:report.warnings,parts:project.parts.length,actions:Object.keys(project.clips),assets:Object.keys(project.assets).length};
}
// The current atlas metadata names the actual exported Soulgen source.
const records=[];
for(const entry of entries){
 const atlas=atlases[entry.atlas];assert(atlas,'Atlas ausente: '+entry.id);
 const image='assets/'+atlas.meta.image;await png(image);
 let source=atlas.meta.source||null;const runtimeSource=source;
 let rig=null;
 if(entry.id==='carcara')rig=await auditProject(await createCarcara(png),'tools/soulgen-studio/carcara.mjs');
 else if(source?.endsWith('.soulgen.json'))rig=await auditProject(await read(source),source);
 if(!rig){const candidate=`art/soulgen/keys/${entry.id}/color-rig-v2/${entry.id}.soulgen.json`;try{await fs.access(path.join(root,candidate));const project=await read(candidate);if(project.creatureId===entry.id){source=candidate;rig=await auditProject(project,source);}}catch(error){if(error.code!=='ENOENT')throw error;}}
 const animation=atlas.animations?.idle||Object.values(atlas.animations||{})[0];
 const frame=atlas.frames[animation?.[0]]||Object.values(atlas.frames)[0];
 records.push({id:entry.id,name:entry.name,group:entry.collection||(entry.group==='common'?'Básicos':entry.group==='companion'?'Companheiro do professor':entry.group==='story'?'História':'Especiais'),
  status:rig?'rig-existente':'pendente-conversao',title:entry.title,habitat:entry.habitat,reference:image,atlasId:entry.atlas,frame,viewport:atlas.meta.viewport||null,
  source,runtimeSource,rig,integratedSoulgen:!!rig&&(entry.id==='carcara'||!!runtimeSource),remaining:rig&&!runtimeSource&&entry.id!=='carcara'?['Revisar visual e animações no Soulgen','Exportar e integrar ao atlas do jogo após revisão']:rig?['Revisão visual e de animação conforme a direção atual; este inventário não aprova arte.']:['Revisar conceito no padrão Carcará','Produzir peças e expressões registradas','Montar pivôs e hierarquia no Soulgen','Criar/revisar as cinco ações','Validar e exportar antes de integrar ao jogo']});
}
const eremor=await auditProject(await read('art/soulgen/keys/eremor/eremor-v3.soulgen.json'),'art/soulgen/keys/eremor/eremor-v3.soulgen.json');
const extras=[
 {id:'eremor',name:'Eremor',status:'rig-fora-do-catalogo',rig:eremor,integratedSoulgen:false,reference:'art/concepts/eremor-v1/eremor.png',note:'Rig v3 existe; não consta na Dex nem no atlas global. Seus assets antigos de batalha/overworld não provam integração do rig novo.'},
 ...[['sakuradente','Sakuradente'],['bicoatrevido','Bicoatrevido']].map(([id,name])=>({id,name,status:'conceito-nao-aprovado',reference:`art/concepts/sakuradente-bicoatrevido-v1/${id}-conceito-v1.png`,note:'Sem rig Soulgen encontrado. README registra direção visual não aprovada. Rai e Platyx são nomes individuais provisórios do roteiro, não espécies extras.'}))
];
for(const extra of extras)await fs.access(path.join(root,extra.reference));
const pending=records.filter(x=>x.status==='pendente-conversao');
const converted=records.filter(x=>x.status==='rig-existente');
assert.equal(new Set(records.map(x=>x.id)).size,records.length);
assert.equal(pending.length+converted.length,entries.length);
if(problems.length)throw Error(JSON.stringify(problems,null,2));
const inventory={date:'2026-10-25',scope:'Catálogo local assets/pipa-dex.json, atlas consumido pelo jogo, projetos Soulgen atuais e conceitos externos identificados. Sem consulta a banco remoto.',criteria:'Conversão = projeto editável Soulgen com fontes PNG e cinco ações. Atlas antigo ou conceito isolado não contam. Validação estrutural não equivale a aprovação artística.',counts:{catalog:records.length,pending:pending.length,withRig:converted.length,rigOutsideCatalog:1,unapprovedConceptsOutsideCatalog:2},records,extras};
await fs.mkdir(path.join(out,'fichas'),{recursive:true});
await fs.writeFile(path.join(out,'inventario.json'),JSON.stringify(inventory,null,2)+'\n');
for(const record of [...pending,...extras.filter(x=>x.status==='conceito-nao-aprovado')])await fs.writeFile(path.join(out,'fichas',record.id+'.json'),JSON.stringify(record,null,2)+'\n');
for(const r of converted){const file=path.join(out,'fichas',r.id+'.json');try{await fs.access(file);await fs.writeFile(file,JSON.stringify(r,null,2)+'\n');}catch(error){if(error.code!=='ENOENT')throw error;}}
const groups=Map.groupBy(pending,x=>x.group);
const lines=['# Fila de conversão para Soulgen','',`Auditoria local de 25/10/2026: **${pending.length} dos ${records.length} Pipamons da Dex ainda sem conversão**, ${converted.length} com rig existente. Eremor tem rig fora da Dex. Dois conceitos adicionais continuam sem rig e sem aprovação visual.`,
 '', '## Critério', '', inventory.criteria,'', 'Não foi alterado nenhum PNG, rig, atlas, catálogo ou arquivo do Godot. As fichas apontam para as referências existentes; não duplicam nem movem as artes.','',
 '## Ainda não convertidos',''];
for(const [group,list] of groups){lines.push(`### ${group} (${list.length})`,'');for(const r of list)lines.push(`- **${r.name}** — [ficha](fichas/${r.id}.json) · [arte atual](../../../${r.reference})`);lines.push('');}
lines.push('## Com rig existente','',...converted.map(r=>`- **${r.name}** — ${r.rig.parts} peças; ${r.rig.actions.length} ações; fonte do projeto: \`${r.source||r.rig.source}\`. ${r.integratedSoulgen?'Atlas Soulgen integrado.':'Configurado no Studio; atlas do jogo ainda antigo.'}`),'',
 'Carcará é o modelo de direção; os outros básicos e Rabbito usam a revisão artesanal v2. Lacertubo usa o Estudo B exportado e registrado em approved-export.json. Projetos v1 e portáteis duplicados não foram contados como espécies diferentes.','',
 '## Fora do catálogo','',...extras.map(r=>`- **${r.name}** — ${r.note}`),'',
 '## Ordem proposta','', '1. **Nozinho já tem rig no Studio**; revisar com o autor antes de exportar para o jogo.','2. **Almas dos Biomas**, como lote para avaliação das criaturas de exploração; confirmar quais entram nos encontros antes de definir prioridade de gameplay.','3. Demais coleções em lotes de anatomias semelhantes, mantendo pivôs próprios.','4. Retomar Sakuradente e Bicoatrevido somente depois de resolver a direção visual dos conceitos.','',
 '## Arquivos e limites','', '- [Galeria visual](galeria.html): arte atual dos pendentes e os dois conceitos externos, com busca e filtro. Abra o HTML no navegador; não depende do Soulgen estar ligado.','- [Inventário completo](inventario.json): fontes e verificação estrutural dos sete rigs existentes, incluindo Eremor.','- `fichas/`: 32 fichas de referência, sem novas artes ou animações.','',
 'A galeria mostra um quadro do atlas existente, não uma animação nem uma prévia do formato novo. A comparação de estilo e a conferência de todas as expressões continuam pendentes. Reproduzir esta auditoria: `node scripts/audit-soulgen-migration.mjs`.','');
await fs.writeFile(path.join(out,'README.md'),lines.join('\n'));
const cards=[...pending,...extras.filter(x=>x.status==='conceito-nao-aprovado').map(x=>({...x,group:'Conceitos não aprovados'}))];
const encoded=JSON.stringify(cards).replace(/</g,'\\u003c');
await fs.writeFile(path.join(out,'galeria.html'),`<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pipamons · Fila Soulgen</title>
<style>*{box-sizing:border-box}body{margin:0;background:#142c2e;color:#f9eed3;font:16px system-ui}header,main{max-width:1400px;margin:auto;padding:24px}h1{margin:0 0 12px}p{line-height:1.5;color:#cfddd2}.toolbar{display:flex;gap:12px;flex-wrap:wrap}input,select,button{font:inherit;padding:10px;border-radius:8px;border:1px solid #709188;background:#223e3d;color:#fff}#grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:18px}article{padding:16px;border:1px solid #648278;border-radius:12px;background:#203b3a}canvas{width:100%;height:220px;object-fit:contain;background:repeating-conic-gradient(#f6ebcf 0% 25%,#e9ddbf 0% 50%) 0/24px 24px;border-radius:8px}body.dark canvas{background:#0d1d23}h2{font-size:20px;margin:12px 0 6px}.tag{color:#f4c371;font-size:13px}a{color:#91dfd2}small{display:block;color:#c9d6c8;line-height:1.5}#count{margin:12px 0}article[hidden]{display:none}</style>
<header><h1>Fila de conversão · Soulgen</h1><p>${pending.length} Pipamons do catálogo ainda sem rig. Dois conceitos extras precisam de revisão visual. Estes são quadros das artes atuais, sem aprovação automática para o novo padrão.</p><div class="toolbar"><input id="search" aria-label="Buscar Pipamon" placeholder="Buscar por nome"><select id="group" aria-label="Coleção"><option value="">Todas as coleções</option></select><button id="background">Alternar fundo da arte</button></div><div id="count" role="status"></div><a href="README.md">Lista e critérios</a> · <a href="inventario.json">Inventário completo</a></header><main id="grid"></main>
<script>const items=${encoded},grid=document.querySelector('#grid'),search=document.querySelector('#search'),group=document.querySelector('#group');for(const g of [...new Set(items.map(x=>x.group))]){const o=document.createElement('option');o.value=g;o.textContent=g;group.append(o)}const clean=s=>s.normalize('NFD').replace(/[\\u0300-\\u036f]/g,'').toLowerCase();for(const r of items){const card=document.createElement('article');card.dataset.name=clean(r.name+' '+r.id);card.dataset.group=r.group;const canvas=document.createElement('canvas');canvas.width=480;canvas.height=400;canvas.setAttribute('aria-label','Arte atual de '+r.name);card.append(canvas);const h=document.createElement('h2');h.textContent=r.name;card.append(h);const tag=document.createElement('div');tag.className='tag';tag.textContent=r.group+' · '+(r.status==='conceito-nao-aprovado'?'Conceito não aprovado':'Conversão pendente');card.append(tag);const info=document.createElement('p');info.textContent=r.title||r.note||'';card.append(info);const link=document.createElement('a');link.href='fichas/'+r.id+'.json';link.textContent='Abrir ficha';card.append(link);const image=new Image();image.onload=()=>{const ctx=canvas.getContext('2d'),f=r.frame?.frame||{x:0,y:0,w:image.naturalWidth,h:image.naturalHeight},b=r.frame?.contentBounds||r.viewport||{x:0,y:0,w:f.w,h:f.h},sx=f.x+b.x,sy=f.y+b.y,sw=Math.min(b.w,f.w-b.x),sh=Math.min(b.h,f.h-b.y),scale=Math.min(440/sw,360/sh);ctx.drawImage(image,sx,sy,sw,sh,(480-sw*scale)/2,(400-sh*scale)/2,sw*scale,sh*scale)};image.onerror=()=>{const msg=document.createElement('small');msg.textContent='Imagem não carregou. Consulte a referência na ficha.';card.append(msg)};image.src='../../../'+r.reference;grid.append(card)}function filter(){let n=0;for(const card of grid.children){card.hidden=!(card.dataset.name.includes(clean(search.value))&&(!group.value||card.dataset.group===group.value));if(!card.hidden)n++}document.querySelector('#count').textContent=n+' de '+items.length+' referências'}search.oninput=filter;group.onchange=filter;document.querySelector('#background').onclick=()=>document.body.classList.toggle('dark');filter();</script></html>`);
console.log(JSON.stringify({counts:inventory.counts,rigChecks:[...converted.map(r=>({id:r.id,...r.rig})),{id:'eremor',...eremor}],output:slash(path.relative(root,out))},null,2));
