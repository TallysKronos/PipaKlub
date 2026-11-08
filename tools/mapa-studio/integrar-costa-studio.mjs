import {integrateDistrict} from './integrar-centro-studio.mjs';

integrateDistrict('porto',{
  a:[
    ['bobina','Bobina da oficina',20,9],
    ['cabeco','Amarração do terminal',38,12],
    ['rede','Covo junto à doca',37,24],
  ],
  b:[
    ['conteiner','Contêiner da triagem',30,9,2,1],
    ['conteiner','Contêiner de expedição',30,11,2,1],
    ['portico','Pórtico do galpão',32,14,2,1],
    ['bobina','Bobina da rampa de serviço',29,15],
    ['tambores','Tambores da oficina',38,12],
  ],
  c:[
    ['bobina','Bobina da oficina de sinais',14,33],
    ['cabeco','Amarração do cais alto',33,20],
    ['rede','Rede de reparo',29,15],
  ],
},{a:[],b:[],c:[]});

integrateDistrict('palafitas',{
  a:[
    ['cabeco','Amarração do ancoradouro',36,24],
    ['rede','Covo junto às casas',33,20],
    ['poste','Lampião da margem',22,32],
  ],
  b:[
    ['cabeco','Amarração da cabeceira sul',26,28],
    ['rede','Rede de pescador',38,12],
    ['poste','Lampião da passagem',29,15],
  ],
  c:[
    ['poste','Lampião do patamar',20,9],
    ['poste','Lampião da curva',30,9],
    ['rede','Rede no varal do cais',28,22],
  ],
},{a:[],b:[],c:[]});
