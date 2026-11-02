import {validate} from '/model.mjs';
export async function createPipaDragao(){
 const response=await fetch('/art/soulgen/keys/pipa-dragao/cutout-rig-v1/pipa-dragao.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Pipa-Dragão sobrecarregada.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
