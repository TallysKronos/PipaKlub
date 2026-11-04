import {validate} from '/model.mjs';
export async function createMormaco(){
 const r=await fetch('/art/soulgen/keys/mormaco/cutout-rig-v1/mormaco.soulgen.json');
 if(!r.ok)throw Error('Não foi possível carregar Mormaço.');
 const p=await r.json(),audit=validate(p);if(!audit.ok)throw Error(audit.errors.join(' '));return p;
}
