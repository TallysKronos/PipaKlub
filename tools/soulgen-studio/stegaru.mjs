import {validate} from './model.mjs';
export async function createStegaru(){
 const response=await fetch('/art/soulgen/keys/stegaru/color-rig-v2/stegaru.soulgen.json');
 if(!response.ok)throw Error('O rig do Stegaru não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
