import {validate} from './model.mjs';
export async function createRexal(){
 const response=await fetch('/art/soulgen/keys/rexal/color-rig-v2/rexal.soulgen.json');
 if(!response.ok)throw Error('O rig do Rexal não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
