import {validate} from '/model.mjs';
export async function createRai(){
 const response=await fetch('/art/soulgen/keys/rai/cutout-rig-v1/rai.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar Rai / Saber.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
