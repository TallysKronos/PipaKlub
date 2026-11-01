import {validate} from '/model.mjs';
export async function createDoberman(){
 const response=await fetch('/art/soulgen/keys/doberman-c/sliced-rig-v2/doberman-c.soulgen.json');
 if(!response.ok)throw Error('O recorte do Dóber de papel não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
