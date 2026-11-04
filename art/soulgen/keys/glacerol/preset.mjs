import {validate} from '/model.mjs';
export async function createGlacerol(){
 const response=await fetch('/art/soulgen/keys/glacerol/cutout-rig-v1/glacerol.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Glacerol.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
