import {validate} from './model.mjs';
export async function createTamoataMemoria(){
 const response=await fetch('/art/soulgen/keys/tamoata-memoria/color-rig-v2/tamoata-memoria.soulgen.json');
 if(!response.ok)throw Error('O rig do TamoataMemoria não carregou.');
 const project=await response.json(),audit=validate(project);
 if(!audit.ok)throw Error(audit.errors.join(' '));
 return project;
}
