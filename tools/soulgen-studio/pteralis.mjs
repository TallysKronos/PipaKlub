import {validate} from './model.mjs';
export async function createPteralis(){
 const response=await fetch('/art/soulgen/keys/pteralis/color-rig-v2/pteralis.soulgen.json');
 if(!response.ok)throw Error('O rig do Pteralis não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
