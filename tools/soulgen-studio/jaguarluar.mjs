import {validate} from './model.mjs';
export async function createJaguarluar(){
 const response=await fetch('/art/soulgen/keys/jaguarluar/color-rig-v2/jaguarluar.soulgen.json');
 if(!response.ok)throw Error('O rig do Jaguarluar não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
