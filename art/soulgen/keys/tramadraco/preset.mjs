import {validate} from '/model.mjs';
export async function createTramadraco(){
 const response=await fetch('/art/soulgen/keys/tramadraco/cutout-rig-v1/tramadraco.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar Tramadraco.');
 const p=await response.json(),check=validate(p);if(!check.ok)throw Error(check.errors.join(' '));return p;
}
