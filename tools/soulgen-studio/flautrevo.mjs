import {validate} from './model.mjs';
export async function createFlautrevo(){
 const response=await fetch('/art/soulgen/keys/flautrevo/color-rig-v2/flautrevo.soulgen.json');
 if(!response.ok)throw Error('O rig do Flautrevo não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
