import {validate} from './model.mjs';
export async function createTricerafan(){
 const response=await fetch('/art/soulgen/keys/tricerafan/color-rig-v2/tricerafan.soulgen.json');
 if(!response.ok)throw Error('O rig do Tricerafan não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
