import {validate} from '/model.mjs';
export async function createTufanocorte(){
 const response=await fetch('/art/soulgen/keys/tufanocorte/cutout-rig-v1/tufanocorte.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar o Tufanocorte.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
