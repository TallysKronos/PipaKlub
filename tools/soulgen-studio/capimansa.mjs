import {validate} from './model.mjs';
export async function createCapimansa(){
 const response=await fetch('/art/soulgen/keys/capimansa/color-rig-v2/capimansa.soulgen.json');
 if(!response.ok)throw Error('O rig do Capimansa não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
