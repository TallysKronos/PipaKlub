import {validate} from './model.mjs';
export async function createMarulume(){
 const response=await fetch('/art/soulgen/keys/marulume/color-rig-v2/marulume.soulgen.json');
 if(!response.ok)throw Error('O rig do Marulume não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
