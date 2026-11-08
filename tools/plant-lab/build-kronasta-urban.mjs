import fs from 'node:fs';
import {dockBuilding} from './dock-building-art.mjs';
import assert from 'node:assert/strict';
import {validateLayout} from './model.mjs';
import {auditMap} from './map-audit.mjs';
import {moveOnTerrain} from './terrain.mjs';
import {blockedByObjects} from './studio.mjs';
import {collisionDistance} from './collision-shapes.mjs';

const collection = new URL('../../art/environment/coletaneas-kronasta-v1/', import.meta.url);
const urban = new URL('../../godot/assets/overworld/kits/urbano/', import.meta.url);
const catalog = JSON.parse(fs.readFileSync(new URL('manifest.json', collection)));
const props = new Map(catalog.flatMap(page => page.sprites.map(sprite => [sprite.id, sprite])));
const buildings = JSON.parse(fs.readFileSync(new URL('kit.json', urban))).pieces;
const tile = 32;
const center = (x, y) => ({x: (x + .5) * tile, y: (y + .5) * tile});
const paving = 'chao-calcamento';
const brick = 'chao-tijolos';
const slate = 'chao-ardosia';
const lawn = 'chao-grama-baixa';
const garden = 'chao-prado-florido';

const dockAssets=new Map([
 ['galpao-terminal',dockBuilding('Galpão de triagem','warehouse',{front:'#a58d6c',side:'#827663',trim:'#6f635b',roof:'#487887',roofDark:'#315461',highlight:'#92aaad'})],
 ['palafita-ocre',dockBuilding('Palafita ocre','house',{front:'#d39b60',side:'#a76746',trim:'#8e634e',roof:'#ba694a',roofDark:'#823d3d',highlight:'#e49b69'})],
 ['palafita-verde',dockBuilding('Palafita verde','house',{front:'#8da88a',side:'#627c68',trim:'#485a4e',roof:'#b29c6a',roofDark:'#796d57',highlight:'#dfc78a'})],
 ['palafita-azul',dockBuilding('Palafita azul','house',{front:'#8db6ba',side:'#55838e',trim:'#426771',roof:'#7c88a9',roofDark:'#4d5475',highlight:'#adb6cc'})],
]);

function blockout(id, name, width, height, start, background = lawn) {
  const count = width * height;
  const layout = {
    version: 1, width, height, floors: Array(count).fill(background),
    levels: Array(count).fill(0), ramps: Array(count).fill(null),
    rampProfiles: Array(count).fill(null), cliffs: Array(count).fill('face-concreto'),
    events: [], objects: [], customAssets: [], autotiling: true, player: center(...start),
  };
  const ramps = [];
  const index = (x, y) => y * width + x;
  function rect(x0, y0, x1, y1, floor, level, wall) {
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
      const cell = index(x, y);
      layout.floors[cell] = floor;
      layout.levels[cell] = level;
      if(wall)layout.cliffs[cell]=wall;
    }
  }
  function ramp(x0, x1, bottom, base, floor, rise=2, wall) {
    assert.ok(x1 > x0, 'Acesso precisa ter pelo menos duas células de largura');
    for (let x = x0; x <= x1; x++) {
      for (let step = 0; step < rise*2; step++) {
        const y = bottom - step;
        const cell = index(x, y);
        rect(x, y, x, y, floor, base + Math.floor(step / 2), wall);
        layout.ramps[cell] = 'n';
        layout.rampProfiles[cell] = step % 2 ? [.5, 1] : [0, .5];
      }
      ramps.push([x, bottom,rise*2]);
    }
  }
  function event(id, type, x, y, label, text) {
    layout.events.push({id, type, ...center(x, y), label, text, once: type === 'item'});
  }
  function place(id, x, y, footprint, onWater=false) {
    const asset = 'custom-kronasta-' + id;
    const custom=dockAssets.get(id);
    if (!layout.customAssets.some(entry => entry.id === asset)) {
      const building = buildings[id]?.variants.default;
      const prop = custom??props.get(id);
      assert.ok(building || prop, 'Peça desconhecida: ' + id);
      const [frameWidth, frameHeight] = building?.size ?? [prop.width, prop.height];
      const source = custom?.pixels ?? fs.readFileSync(new URL(building?.file ?? prop.file, building ? urban : collection));
      layout.customAssets.push({
        id: asset, name: building?.displayName ?? prop.name,
        frameWidth, frameHeight, anchor: building?.anchor ?? prop.anchor,
        frames: 1, source: 'data:image/png;base64,' + source.toString('base64'),
      });
    }
    const position = center(x, y);
    const cell = index(Math.floor(x), Math.floor(y));
    assert.equal(layout.floors[cell]==='water',onWater,'Apoio incorreto: ' + id);
    assert.equal(layout.ramps[cell], null, 'Objeto sobre rampa: ' + id);
    const collision = footprint && {shape: 'rect', width: footprint[0], height: footprint[1], x: custom?-footprint[0]/2:0, y: -footprint[1] / 2};
    layout.objects.push({
      id: layout.objects.length + 1, asset, ...position, layer: 'objects',
      collidable: Boolean(collision), ...(collision && {collision}),
    });
  }
  function verify(stage) {
    const map = validateLayout(layout);
    const audit = auditMap(map);
    assert.deepEqual(audit.issues, [], 'Auditoria de terreno: ' + id);
    const queue = [start];
    const seen = new Set([index(...start)]);
    function move(from, dx, dy) {
      const next = moveOnTerrain(map, from, {x: dx, y: dy});
      return blockedByObjects(map, from, next) ? from : next;
    }
    for (const [x, y] of queue) {
      for (const [dx, dy] of [[1, 0], [0, 1], [-1, 0], [0, -1]]) {
        const xx = x + dx, yy = y + dy;
        if (xx < 0 || yy < 0 || xx >= width || yy >= height || seen.has(index(xx, yy))) continue;
        let at = center(x, y);
        for (let step = 0; step < 8; step++) at = move(at, dx * 4, dy * 4);
        const target = center(xx, yy);
        if (at.x !== target.x || at.y !== target.y) continue;
        seen.add(index(xx, yy));
        queue.push([xx, yy]);
      }
    }
    for (const entry of map.events) {
      assert.ok(seen.has(index(Math.floor(entry.x / tile), Math.floor(entry.y / tile))), 'Evento inacessível: ' + entry.label);
      assert.ok(!map.objects.some(object => object.collidable && collisionDistance(object, entry) < 0), 'Evento dentro de objeto: ' + entry.label);
    }
    for (const [x, bottom,length] of ramps) for (const direction of [-1, 1]) {
      const from = center(x, direction === -1 ? bottom + 1 : bottom - length);
      let at = from;
      for (let step = 0; step < (length+1)*8; step++) at = move(at, 0, direction * 4);
      assert.equal(at.y, from.y + direction * (length+1)*tile, 'Rampa interrompida em ' + x + ',' + bottom);
    }
    console.log(id, stage, seen.size + ' células alcançáveis,', ramps.length * 2 + ' travessias de rampa,', map.events.length + ' eventos.');
    return map;
  }
  function save() {
    if(background==='water'){
      layout.waterDepth=layout.floors.map((floor,i)=>{
        if(floor!=='water')return 0;
        const x=i%width,y=Math.floor(i/width);
        let nearest=4;
        for(let dy=-3;dy<=3;dy++)for(let dx=-3;dx<=3;dx++){
          const xx=x+dx,yy=y+dy;
          if(xx>=0&&xx<width&&yy>=0&&yy<height&&layout.floors[index(xx,yy)]!=='water'){
            nearest=Math.min(nearest,Math.abs(dx)+Math.abs(dy));
          }
        }
        return nearest-1;
      });
    }
    const map = verify('com arte');
    const file = new URL('mapas/' + id + '.json', collection);
    fs.writeFileSync(file, JSON.stringify({...map, name}, null, 2) + '\n');
    console.log(map.objects.length + ' peças, ' + map.customAssets.length + ' assets distintos.');
  }
  return {rect, ramp, event, place, verify, save};
}

// Centro: da rua estreita à praça aberta; um corredor lateral liga as duas subidas.
{
  const map = blockout('centro-praca-da-matriz', 'Centro · Praça da Matriz', 36, 31, [16, 27]);
  const {rect, ramp, event, place} = map;
  rect(2, 20, 33, 28, brick, 0);
  rect(12, 23, 21, 30, paving, 0);
  rect(6, 8, 30, 16, paving, 2);
  rect(9, 5, 27, 9, paving, 2);
  rect(7, 17, 26, 18, paving, 2);
  rect(11, 5, 21, 8, slate, 4);
  rect(10, 6, 22, 9, slate, 4);
  rect(11, 11, 21, 12, paving, 2);
  rect(5, 14, 10, 16, garden, 2);
  rect(25, 9, 29, 11, garden, 2);
  rect(11, 20, 26, 24, paving, 0);
  ramp(14, 18, 22, 0, paving);
  ramp(24, 26, 22, 0, brick);
  ramp(15, 18, 13, 2, slate);
  event('entrada', 'spawn', 16, 27, 'Rua da Matriz', '');
  event('praca', 'trigger', 15, 15, 'Praça da Matriz', 'A subida ao fundo leva ao campanário. A Pipa TV fica na ala lateral.');
  event('tv', 'trigger', 27, 14, 'Pipa TV', 'Daqui dá para ver a antena acima dos telhados.');
  event('alto', 'trigger', 16, 8, 'Adro da Matriz', 'O adro se abre sobre a praça.');
  event('linha', 'item', 8, 15, 'Linha de algodão', 'Um carretel ficou junto ao canteiro.');
  map.verify('blocagem');

  place('torre-elos', 16.5, 7.2, [100, 45]);
  place('coworking', 28, 11.7, [92, 62]);
  place('papelaria', 6, 24, [85, 55]);
  place('cafe-do-vento', 30, 23, [85, 55]);
  place('fonte-de-terracota', 20.8, 15.2, [46, 26]);
  place('barraca-de-feira', 6.5, 19.9, [55, 26]);
  place('caixotes-de-laranja', 5.3, 20.6, [34, 18]);
  place('bancada-de-pipas', 9.8, 22, [54, 25]);
  place('expositor-de-carreteis', 10.5, 22.8, [28, 16]);
  place('placa-de-trilha', 18.9, 23.4);
  for (const [x, y] of [[13, 25], [19.7, 25], [12.4, 17], [20.2, 17], [23.1, 14], [28.8, 15.5]]) place('poste-de-rua', x, y);
  place('ipe-florido', 7.2, 13.7, [32, 24]);
  place('arvore-costeira', 8.8, 13.3, [32, 24]);
  place('bromelia-no-banco', 9.8, 15.7, [40, 18]);
  place('arbusto-coral', 6.9, 15.2);
  place('capim-rabiola', 5.7, 16.3);
  place('mureta-de-pedra', 10.9, 17.9, [58, 12]);
  place('mureta-de-pedra', 22.4, 17.9, [58, 12]);
  place('bromelia-no-banco', 12, 8.1, [40, 18]);
  place('bromelia-no-banco', 20.5, 8.1, [40, 18]);
  map.save();
}

// Condomínio: chegada pelo jardim, circuito ao redor da piscina, terraço elevado.
{
  const map = blockout('condominio-terracos', 'Condomínio · Jardins e Terraços', 35, 32, [11, 28]);
  const {rect, ramp, event, place} = map;
  rect(3, 21, 29, 28, lawn, 0);
  rect(8, 22, 14, 31, brick, 0);
  rect(6, 20, 25, 23, paving, 0);
  rect(4, 9, 29, 18, garden, 2);
  rect(7, 8, 28, 19, paving, 2);
  rect(16, 11, 23, 16, slate, 2);
  rect(17, 12, 22, 15, 'water', 1);
  rect(6, 12, 8, 17, garden, 2);
  rect(9, 5, 25, 10, brick, 4);
  rect(11, 4, 22, 5, brick, 4);
  rect(12, 5, 17, 7, garden, 4);
  rect(9, 21, 13, 24, paving, 0);
  rect(23, 20, 26, 25, paving, 0);
  ramp(9, 13, 23, 0, paving);
  ramp(24, 26, 23, 0, paving);
  ramp(12, 15, 14, 2, brick);
  event('entrada', 'spawn', 11, 28, 'Portaria', '');
  event('jardim', 'trigger', 8, 21, 'Jardim da portaria', 'A alameda sobe ao clube. O acesso lateral volta ao jardim.');
  event('piscina', 'trigger', 19, 17, 'Clube', 'O passeio contorna a piscina e leva ao terraço.');
  event('terraco', 'trigger', 16, 9, 'Terraço da Tainá', 'A vista do terraço alcança os telhados de Kronasta.');
  event('retalho-de-vela', 'item', 27, 17, 'Retalho de vela', 'Um pedaço de tecido ficou no banco da alameda.');
  map.verify('blocagem');

  place('casa-geminada', 5.4, 25.2, [88, 50]);
  place('casa-ecologica', 18.8, 25.5, [90, 56]);
  place('sobrado-varanda', 29.1, 25.1, [90, 56]);
  place('clube-pipeiros', 26.1, 12, [95, 55]);
  place('residencia-terraco', 20.2, 6.6, [96, 54]);
  place('fonte-de-terracota', 18.5, 22.8, [44, 25]);
  place('placa-de-trilha', 13.6, 25.6);
  for (const [x, y] of [[8, 27], [14.6, 27], [6.8, 19], [26.9, 19], [15.9, 16.5], [23.2, 16.5]]) place('poste-de-rua', x, y);
  place('ipe-florido', 6, 13, [34, 26]);
  place('arvore-costeira', 6.4, 15.5, [32, 24]);
  place('arbusto-coral', 7.2, 14.3);
  place('samambaia-enrolada', 5.5, 14.2);
  place('arvore-costeira', 9.8, 7.8, [32, 24]);
  place('ipe-florido', 11.1, 6.6, [34, 26]);
  place('arbusto-coral', 12.1, 7.1);
  place('bromelia-no-banco', 10.1, 9.5, [35, 20]);
  place('bromelia-no-banco', 24.2, 9.3, [36, 18]);
  place('bromelia-no-banco', 27.8, 16.5, [40, 22]);
  place('cerca-de-madeira', 17.6, 10.5, [62, 12]);
  place('cerca-de-madeira', 19.6, 10.5, [62, 12]);
  place('cerca-de-madeira', 21.6, 10.5, [62, 12]);
  place('cerca-de-madeira', 23.6, 10.5, [62, 12]);
  map.save();
}


// Porto Novo: avenida → pátio → doca, com retorno pela rampa de serviço.
{
  const map=blockout('porto-novo-terminal','Porto Novo · Terminal de Carga',39,33,[12,28],'water');
  const {rect,ramp,event,place}=map;
  rect(3,5,30,29,'chao-areia-umida',0);
  rect(1,10,25,24,'chao-areia-umida',0);
  rect(7,7,31,25,paving,0);
  rect(9,25,24,31,paving,0);
  rect(8,7,31,17,slate,2);
  rect(7,12,13,17,paving,2);
  rect(22,4,30,9,slate,2);
  rect(21,20,35,23,'chao-tabua',0,'face-madeira');
  rect(27,18,30,24,paving,0);
  rect(30,21,37,22,'chao-tabua',0,'face-madeira');
  rect(11,18,15,22,paving,0);
  rect(25,18,27,22,slate,0);
  ramp(11,15,21,0,paving);
  ramp(25,27,21,0,slate);
  event('entrada','spawn',12,28,'Avenida do Terminal','');
  event('terminal','trigger',16,14,'Pátio de triagem','O corredor livre no pátio separa o galpão da pilha de carga.');
  event('doca','trigger',31,21,'Doca de carga','A rampa de serviço volta ao pátio. A passarela segue até a ponta.');
  event('linha','item',36,22,'Linha de reboque','Uma linha grossa entre os cabeços.');
  event('peca','item',23,5,'Engate de içamento','Um engate de reposição ficou no fundo do terminal.');
  map.verify('blocagem');

  place('galpao-terminal',21,13,[145,145]);
  place('portico-de-icamento',28.1,12.4,[58,18]);
  place('conteiner-ocre',25.2,8.7,[58,28]);
  place('conteiner-ocre',28.3,8.7,[58,28]);
  place('bobina-em-palete',27.8,10.6,[34,18]);
  place('tubos-com-valvula',23.5,11.2,[42,24]);
  place('compressor',29.9,10.7,[39,20]);
  place('caixas-amarradas',15.7,10.6,[35,24]);
  place('tambores',19.6,15.3,[36,20]);
  place('grelha-de-drenagem',16.8,15.5);
  place('grelha-de-drenagem',23.3,14.3);
  place('balizadores-com-corrente',8.4,17.6,[64,9]);
  place('balizadores-com-corrente',19.8,17.6,[64,9]);
  place('cabeco-com-corda',32.5,22.5);
  place('cabeco-com-corda',36,21);
  place('rede-e-covo',34.8,20.8,[35,16]);
  place('barco-a-remo',36,23.5,null,true);
  place('placa-de-trilha',15.7,24);
  place('arvore-costeira',5.3,17.2,[34,24]);
  place('arvore-costeira',6.4,16.1,[34,24]);
  place('rocha-musgosa',4.2,17.5,[36,20]);
  place('capim-rabiola',4.8,18.2);
  place('taboa',4.2,22);
  place('capim-rabiola',4.6,23.1);
  for(const [x,y] of [[10.2,24.2],[16.3,22],[19.8,20],[22.4,15.9],[29.2,20],[32.5,20.6]])place('poste-de-rua',x,y);
  map.save();
}

// Palafitas: margem → passarela → praça das casas; o retorno contorna o canal.
{
  const map=blockout('palafitas-passarelas','Palafitas · Caminhos sobre a Água',36,33,[8,28],'water');
  const {rect,ramp,event,place}=map;
  const deck='chao-tabua', wood='face-madeira', shoal='chao-areia-umida';
  rect(2,21,14,31,shoal,0,'face-arenito');
  rect(3,22,12,28,lawn,0,'face-arenito');
  rect(6,23,11,30,paving,0);
  rect(4,19,10,22,shoal,0,'face-arenito');
  rect(4,11,14,16,deck,1,wood);
  rect(7,8,10,19,deck,1,wood);
  rect(10,12,28,15,deck,1,wood);
  rect(23,6,32,15,deck,1,wood);
  rect(26,13,29,23,deck,1,wood);
  rect(11,21,28,24,deck,1,wood);
  rect(17,16,20,18,deck,1,wood);
  rect(23,4,29,6,'chao-pedra-musgosa',2,'face-alvenaria');
  rect(25,3,28,4,'chao-pedra-musgosa',2,'face-alvenaria');
  rect(7,19,10,22,deck,0,wood);
  rect(11,23,15,26,deck,0,wood);
  rect(11,23,15,23,deck,1,wood);
  ramp(7,10,20,0,deck,1,wood);
  ramp(13,15,25,0,deck,1,wood);
  ramp(25,27,8,1,'chao-pedra-musgosa',1,'face-alvenaria');
  event('entrada','spawn',8,28,'Margem das Palafitas','');
  event('praca','trigger',25,12,'Praça sobre a água','A passarela da direita fecha a volta pelo canal.');
  event('mirante','trigger',26,5,'Patamar de observação','Daqui se veem as passarelas e os barcos.');
  event('ponta','item',18,18,'Vareta de mangue','Uma vareta seca na ponta da passarela curta.');
  event('rede','item',29,21,'Nó de pescador','Um laço de reposição junto à margem do canal.');
  map.verify('blocagem');

  place('palafita-ocre',7,13,[80,80]);
  place('palafita-verde',23.1,13,[80,80]);
  place('palafita-azul',31,10,[80,80]);
  place('palafita-ocre',31,15,[80,80]);
  place('bancada-de-pipas',27.7,11,[48,18]);
  place('caixas-amarradas',30.4,12,[38,22]);
  place('rede-e-covo',20,17.3,[29,15]);
  place('rede-e-covo',24.6,22.5,[33,16]);
  place('barco-a-remo',16,19.5,null,true);
  place('barco-a-remo',31.5,20,null,true);
  place('cabeco-com-corda',17.2,18.6);
  place('cabeco-com-corda',29.2,19);
  place('placa-de-trilha',10.8,24.2);
  place('arvore-costeira',4.5,25.2,[30,22]);
  place('ipe-florido',5.6,25.5,[34,23]);
  place('arbusto-coral',4.1,26);
  place('taboa',3.4,22.1);
  place('taboa',4.5,21.2);
  place('vitoria-regia',16.5,17.6,null,true);
  place('vitoria-regia',31.9,18.9,null,true);
  place('bromelia-no-banco',28.3,4.7,[36,20]);
  for(const [x,y] of [[6.5,21],[9.7,17.7],[11.6,14.3],[19.5,13],[25.4,15],[28.4,18.4],[26.5,23.6],[19.8,22.6],[14.2,22]])place('poste-de-rua',x,y);
  map.save();
}
