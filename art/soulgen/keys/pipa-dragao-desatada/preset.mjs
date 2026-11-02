import {validate} from '/model.mjs';
export async function createPipaDragaoDesatada(){
 const response=await fetch('/art/soulgen/keys/pipa-dragao-desatada/cutout-rig-v3/pipa-dragao-desatada.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Pipa-Dragão desatada.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
