import {validate} from './model.mjs';
export async function createUmbrocasco(){
 const response=await fetch('/art/soulgen/keys/umbrocasco/color-rig-v2/umbrocasco.soulgen.json');
 if(!response.ok)throw Error('O rig do Umbrocasco não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
