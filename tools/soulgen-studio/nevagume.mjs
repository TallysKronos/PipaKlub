import {validate} from './model.mjs';
export async function createNevagume(){
 const response=await fetch('/art/soulgen/keys/nevagume/color-rig-v2/nevagume.soulgen.json');
 if(!response.ok)throw Error('O rig do Nevagume não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
