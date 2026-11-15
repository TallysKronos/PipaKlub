# Portão — estudo geométrico antes da pintura

Resposta ao feedback de ambiguidade entre muro e chão. Estudo isolado na projeção 64 × 32 do jogo. Não substitui os assets nem modifica a cena jogável.

## Construção proposta

- Dois pilares completos, com topo, frente e laterais derivados dos mesmos vértices. O arremate esquerdo deixa de ser representado apenas por uma faixa azul.
- Muro com espessura de 0,24 célula e altura de 40 px sobre o chão. Pilares com 0,45 × 0,52 célula e tampa de 3 px, chegando à cota 53.
- Vão livre entre u 3,55 e 5,25, total 1,7 célula. Centro em u 4,4, no mesmo acesso da campanha.
- Passagem e calçada na cota 8. O piso azul do estudo representa uma superfície horizontal contínua, sem espelho de degrau ou ressalto desenhado na abertura.
- A faixa de pedras para nos limites do vão, sem ponta inclinada solta dentro da passagem.
- Folha do portão aberta para dentro, com um plano retangular e dobradiças junto ao pilar esquerdo. O correio continua preso à face vertical do pilar direito.

## Entregas

- `blockout.png` e `blockout-2x.png`, vista limpa e ampliação nearest.
- `planos.png` e `planos-2x.png`, cores de leitura e identificação das faces.
- `volumes.png`, materiais neutros para conferir a separação dos planos.
- `medidas.json`, cotas e limites da proposta.

A cena não tem personagens, bicicleta ou plantas escondendo os encontros. É uma proposta de volumes para aprovação antes de transferir a pintura da fachada. O azul do piso é uma cor de diagnóstico, não uma decisão final de material.

## Reprodução

```powershell
& './.local/godot/Godot_v4.7.2-stable_win64_console.exe' --path godot --script tools/casa_kael_v2_portao_blockout.gd --rendering-method gl_compatibility
```

O gerador usa as mesmas coordenadas para topo, faces e base. Conferiu automaticamente a largura livre de 1,7 célula e registrou piso e calçada na mesma cota. As capturas foram inspecionadas em 1× e 2×. Não foram executados testes de caminhada, pois nenhuma geometria de runtime foi alterada nesta etapa.

A revisão visual independente não encontrou bloqueios geométricos nas vistas de planos e volumes. Confirmou as faces fechadas dos arremates e o encontro coplanar do piso com a calçada. A aprovação do dono permanece antes da pintura, conforme `documentation/art/PIPELINE-CONCEPT-PARA-JOGO.md`, etapa 1.
