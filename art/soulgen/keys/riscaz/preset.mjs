import {validate} from '/model.mjs';
export async function createRiscaz(){
 const response=await fetch('/art/soulgen/keys/riscaz/cutout-rig-v1/riscaz.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar Riscaz.');
 const p=await response.json(),audit=validate(p);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return p;
}
