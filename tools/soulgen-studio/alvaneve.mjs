import {validate} from './model.mjs';
export async function createAlvaneve(){
 const response=await fetch('/art/soulgen/keys/alvaneve/color-rig-v2/alvaneve.soulgen.json');
 if(!response.ok)throw Error('O rig do Alvaneve não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
