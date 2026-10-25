import {validate} from './model.mjs';
export async function createHerravento(){
 const response=await fetch('/art/soulgen/keys/herravento/color-rig-v2/herravento.soulgen.json');
 if(!response.ok)throw Error('O rig do Herravento não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
