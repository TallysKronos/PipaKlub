import {validate} from '/model.mjs';
export async function createAzulfazoPossuido(){
 const r=await fetch('/art/soulgen/keys/azulfazo-possuido/cutout-rig-v1/azulfazo-possuido.soulgen.json');
 if(!r.ok)throw Error('Não foi possível carregar Azulfazo possuído.');
 const p=await r.json(),audit=validate(p);if(!audit.ok)throw Error(audit.errors.join(' '));return p;
}
