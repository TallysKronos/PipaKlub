import {validate} from './model.mjs';
export async function createHiponilo(){
 const response=await fetch('/art/soulgen/keys/hiponilo/color-rig-v2/hiponilo.soulgen.json');
 if(!response.ok)throw Error('O rig do Hiponilo não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
