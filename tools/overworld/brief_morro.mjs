import fs from 'node:fs';
import crypto from 'node:crypto';
import {parseTiled} from '../mapa-studio/model.mjs';
const out='art/overworld/conceitos/morro';fs.mkdirSync(out,{recursive:true});
const registry={'rascunho.tsj':JSON.parse(fs.readFileSync('art/overworld/tiles/rascunho.tsj'))};
const identities={
 'morro-praca-da-chegada':'Praça aberta; portão de chegada e oficina/banca de pipas',
 'morro-escadaria-da-sombra':'Árvore grande, sombra no patamar e varal',
 'morro-laje-dos-ventos':'Laje ensolarada, varais e banca de pipas',
 'morro-mirante-da-caixa-dagua':'Caixa azul, guarda-corpo e vista distante da cidade',
 'morro-parque-dos-ventos':'Gramado livre, árvore com banco e abrigo com bandeirolas; sem desnível'};
for(const [id,identity]of Object.entries(identities)){
 const source=`art/overworld/mapas/${id}.tmj`,raw=fs.readFileSync(source),m=parseTiled(JSON.parse(raw),registry);
 const brief={issue:'PIP-87',id,identity,source,sourceSha256:crypto.createHash('sha256').update(raw).digest('hex'),projection:{cell:[64,32],levelPx:64},size:[m.w,m.h],stage:'facades_access_and_railing_native_review',approval:'pending_owner_review',alignment:'painting_not_pixel_verified',pieces:m.pieces,events:m.events,ramps:m.cells.flatMap((c,i)=>c.ramp?[{u:i%m.w,v:Math.floor(i/m.w),...c}]:[]),locks:['Source cells and source event positions remain authoritative','Approved floor and stair geometry retained','Do not use whole concept as runtime ground','Review every stair mouth and wall corner without characters obscuring it','No generated backdrop forest; houses selected explicitly from existing lots']};
 fs.writeFileSync(`${out}/${id}-brief.json`,JSON.stringify(brief,null,2)+'\n');
}
console.log('Five Morro source briefs with landmarks, geometry locks and SHA256.');
