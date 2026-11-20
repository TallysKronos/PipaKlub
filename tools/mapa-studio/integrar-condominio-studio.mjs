import {integrateDistrict} from './integrar-centro-studio.mjs';

// Portaria → clube → terraço. Keep the centre of each ascent clear.
integrateDistrict('lajes',{
  a:[
    ['poste','Balizador da portaria',21,35],
    ['poste','Balizador da portaria',27,35],
    ['jardineira','Banco do jardim oeste',15,24],
    ['jardineira','Banco do jardim leste',32,24],
  ],
  b:[
    ['jardineira','Banco junto ao clube',32,12],
    ['poste','Iluminação do clube',32,14],
    ['jardineira','Banco da alameda',20,15],
  ],
  c:[
    ['jardineira','Banco do terraço oeste',19,9],
    ['jardineira','Banco do terraço leste',28,9],
    ['poste','Iluminação do terraço',21,5],
    ['poste','Iluminação do terraço',27,5],
  ],
},{
  a:[[17,30,31,33,0]],
  b:[[30,11,34,14,1]],
  c:[[18,8,20,9,2],[28,8,30,9,2]],
});
