import {validate} from './model.mjs';
export async function createNozinho(){
 const response=await fetch('/art/soulgen/keys/nozinho/color-rig-v2/nozinho.soulgen.json');
 if(!response.ok)throw Error('O rig do Nozinho não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
