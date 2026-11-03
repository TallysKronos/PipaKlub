import {validate} from '/model.mjs';
export async function createRetalhoMascarada(){
 const response=await fetch('/art/soulgen/keys/retalho-mascarada/cutout-rig-v1/retalho-mascarada.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar Retalho mascarada.');
 const p=await response.json(),audit=validate(p);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return p;
}
