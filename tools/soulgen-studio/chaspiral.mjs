import {validate} from './model.mjs';
export async function createChaspiral(){
 const response=await fetch('/art/soulgen/keys/chaspiral/color-rig-v2/chaspiral.soulgen.json');
 if(!response.ok)throw Error('O rig do Chaspiral não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
