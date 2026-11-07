import {WALLS} from './wall-kit.mjs';
import {GROUNDS} from './ground-kit.mjs';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {atlas,texture,MASKS,VARIANTS} from './autotile.mjs';
import {forestSample} from './forest-sample.mjs';
import {initialLayout} from './model.mjs';
import {png} from './png.mjs';
const out=fileURLToPath(new URL('../../art/environment/topdown-autotile-v1/',import.meta.url));await fs.mkdir(out,{recursive:true});
for(const kind of ['grass','stone','sand','water',...GROUNDS.map(g=>g.id)])await fs.writeFile(out+kind+'.png',png(atlas(kind)));
for(const kind of ['dirt','earth','rock',...WALLS.map(w=>w.id)])await fs.writeFile(out+kind+'.png',png(texture(kind)));
await fs.writeFile(out+'kit.json',JSON.stringify({id:'kronasta-topdown-autotile-v1',revision:5,surfaceModel:'shared-dual-field',wallTextureSize:[64,64],wallMaterials:[{id:'earth',name:'Terra original'},{id:'rock',name:'Rocha original'},...WALLS],tileSize:[32,32],variants:VARIANTS,atlas:{columns:8,rowsPerVariant:6},terrains:[{id:'dirt',priority:0},{id:'stone',priority:1},{id:'grass',priority:2},{id:'sand',priority:1},{id:'water',priority:0},...GROUNDS],bits:{N:1,E:2,S:4,W:8,NE:16,SE:32,SW:64,NW:128},masks:MASKS,parts:MASKS.map((mask,index)=>({mask,index,x:index%8,y:Math.floor(index/8)})),layers:['top','faces','shadow'],authoring:'Materiais básicos procedurais; pisos e faces adicionais recortados de arte gerada própria. Referências sem cópia de pixels externos.'},null,2));
await fs.writeFile(out+'README.md','# Autotiling de Kronasta · 32×32\n\nGrama/terra, pedra/terra, areia/grama e água/grama:47 máscaras canônicas ×3 variações. Atlas256×576,8 colunas e6 linhas por variação. A última célula de cada bloco fica vazia. kit.json descreve máscara e posição.\n\nCantos externos, internos, bordas, corredores e ilhas; diagonais só contam quando os dois lados correspondentes existem. Semeadura estável preserva a variação ao editar. Terra é a base das transições.\n\nTopo, face e sombra dos penhascos são gerados a partir de uma única altura/pegada; earth.png e rock.png são texturas de parede em fase mundial. Rampas preservam as duas bocas.\n\nO Studio usa os mesmos geradores deste kit. Exportar Godot inclui atlas, terreno montado e scripts nativos. Nenhum pixel das referências foi redistribuído ou traçado.\n');
await fs.copyFile(fileURLToPath(new URL('./godot-template/terrain-set.tres',import.meta.url)),out+'terrain-set.tres');
await fs.appendFile(out+'README.md','\nRevisão4: mais 27 pisos gerados, 31 conjuntos de terrenos pintáveis;  inclui os atlas de água e areia e os novos pisos;  geometria por campo dual compartilhado, independente do recorte de textura; chegada/saída das rampas fechadas; paredes de rocha64×64 com facetas irregulares. Use terrain-set.tres com este kit em res://autotile/. O volume é regenerado pelos scripts nativos da exportação do Studio.\n');
await fs.writeFile(out+'bosque-reconstruido.json',JSON.stringify(forestSample(initialLayout(),{keepObjects:false}),null,2));
console.log(out);

