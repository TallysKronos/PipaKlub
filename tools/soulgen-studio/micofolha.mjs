import {validate} from './model.mjs';
export async function createMicofolha(){
 const response=await fetch('/art/soulgen/keys/micofolha/color-rig-v2/micofolha.soulgen.json');
 if(!response.ok)throw Error('O rig do Micofolha não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
