import {validate} from '/model.mjs';
export async function createRabiolava(){
 const response=await fetch('/art/soulgen/keys/rabiolava/cutout-rig-v1/rabiolava.soulgen.json');
 if(!response.ok)throw Error('Não foi possível carregar a Rabiolava.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
