import {validate} from './model.mjs';
export async function createJarabrasa(){
 const response=await fetch('/art/soulgen/keys/jarabrasa/color-rig-v2/jarabrasa.soulgen.json');
 if(!response.ok)throw Error('O rig do Jarabrasa não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
