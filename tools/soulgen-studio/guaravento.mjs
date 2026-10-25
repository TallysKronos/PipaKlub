import {validate} from './model.mjs';
export async function createGuaravento(){
 const response=await fetch('/art/soulgen/keys/guaravento/color-rig-v2/guaravento.soulgen.json');
 if(!response.ok)throw Error('O rig do Guaravento não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
