import {validate} from './model.mjs';
export async function createTrincaBrasas(){
 const response=await fetch('/art/soulgen/keys/trinca-brasas/color-rig-v2/trinca-brasas.soulgen.json');
 if(!response.ok)throw Error('O rig do TrincaBrasas não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
