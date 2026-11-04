import {validate} from '/model.mjs';
export async function createPlatyx(){
 const response=await fetch('/art/soulgen/keys/platyx/cutout-rig-v1/platyx.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar o Platyx.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
