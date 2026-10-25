import {validate} from './model.mjs';
export async function createAuriflama(){
 const response=await fetch('/art/soulgen/keys/auriflama/color-rig-v2/auriflama.soulgen.json');
 if(!response.ok)throw Error('O rig do Auriflama não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
