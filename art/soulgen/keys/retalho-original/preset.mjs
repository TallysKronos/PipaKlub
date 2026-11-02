import {validate} from '/model.mjs';
export async function createRetalhoOriginal(){
 const response=await fetch('/art/soulgen/keys/retalho-original/cutout-rig-v2/retalho-original.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Retalho original.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
