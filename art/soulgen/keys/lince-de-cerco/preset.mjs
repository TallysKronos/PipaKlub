import {validate} from '/model.mjs';
export const LINCE_PRESETS=['lince-de-cerco-baby','lince-de-cerco-child','lince-de-cerco-young','lince-de-cerco'];
export async function createLince(id='lince-de-cerco'){
 if(!LINCE_PRESETS.includes(id))throw Error('Forma de Lince desconhecida.');
 const response=await fetch(`/art/soulgen/keys/${id}/cutout-rig-v1/${id}.soulgen.json`);
 if(!response.ok)throw Error('Não foi possível carregar '+id);
 const project=await response.json(),check=validate(project);
 if(!check.ok)throw Error(check.errors.join(' '));
 return project;
}
