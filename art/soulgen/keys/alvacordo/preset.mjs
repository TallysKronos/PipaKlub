import {validate} from '/model.mjs';
export async function createAlvacordo(){
 const response=await fetch('/art/soulgen/keys/alvacordo/cutout-rig-v1/alvacordo.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar Alvacordo.');
 const p=await response.json(),check=validate(p);if(!check.ok)throw Error(check.errors.join(' '));return p;
}
