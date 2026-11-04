import {validate} from '/model.mjs';
export async function createTrovareta(){
 const response=await fetch('/art/soulgen/keys/trovareta/cutout-rig-v1/trovareta.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Trovareta.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
