import {validate} from './model.mjs';
export async function createTatutrama(){
 const response=await fetch('/art/soulgen/keys/tatutrama/color-rig-v2/tatutrama.soulgen.json');
 if(!response.ok)throw Error('O rig do Tatutrama não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
