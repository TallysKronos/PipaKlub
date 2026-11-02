import {validate} from '/model.mjs';
export async function createAzulfazo(){
 const r=await fetch('/art/soulgen/keys/azulfazo/cutout-rig-v1/azulfazo.soulgen.json');
 if(!r.ok)throw Error('Não foi possível carregar Azulfazo.');
 const p=await r.json(),audit=validate(p);if(!audit.ok)throw Error(audit.errors.join(' '));return p;
}
