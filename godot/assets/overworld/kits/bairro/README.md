# Bairro — PIP-84

Primeira família modular do conceito aprovado da Rua dos Ventos. Kit em revisão visual; a campanha principal não foi substituída.

## Conteúdo

- 20 pisos 64×32: calçada, asfalto, terra, canteiro e construção, quatro variantes por material.
- 112 máscaras de transição, 16 para cada um dos sete pares presentes na planta. Bits 1, 2, 4 e 8 correspondem a cima, direita, baixo e esquerda.
- Três casas independentes: Kael 4×4, Assis 4×3, loja 4×3, com medidas, guia de porta e âncora do piso no manifesto.
- Mural, bancada de pipas e cerca-viva, sem nova colisão de navegação.
- Bancos, postes, árvores e vasos reutilizam a família comum.
- `bairro.isostudio.json` abre a família na régua do Iso Studio. `PRANCHA-ESCALA.png` mostra o tamanho de produção junto de Kael, com 84 px de altura.

Fontes pintadas e prompts: `fontes/`. Guias vetoriais determinam os volumes, e a pintura é normalizada uniformemente dentro deles. Os SVGs finais das peças pintadas incorporam a imagem normalizada; os caminhos de construção originais permanecem em `fontes/guias/`. A pintura não fornece colisões, posições de eventos ou medidas de navegação.

## Produção e consumo

`python tools/overworld/build_bairro.py` gera somente esta família e a copia para `godot/assets/overworld/kits/bairro/`. O conversor existente `buildPieceScenes()` cria as cenas de peça. A prévia independente `godot/scenes/overworld_preview.tscn` carrega o kit quando o estudo de arte está ativo na Rua dos Ventos.

O consumidor Bairro desenha cobertura opaca contínua e limita a amostragem das texturas ao interior dos losangos; isso evita a grade de alpha observada na primeira captura. As bordas retas de calçada e asfalto vêm das células da planta. As máscaras continuam disponíveis no kit, mas não substituem essas bordas por recortes arredondados na prévia Bairro.

O jardim decora somente células já bloqueadas, sem registrar interações ou ampliar colisões. Vasos e postes têm coordenadas explícitas em `dressing`. A fiação é uma linha do motor e fica atrás das fachadas. O Morro mantém seu consumidor de terreno próprio.

## Limites e próximo acabamento

As capturas 1280×720 em `documentation/overworld/bairro/captures/` são revisão de renderização, não percurso de campanha ou testes de combate. Não foi executada suíte de testes.

Ainda falta concluir os detalhes de portões/muros e faixa de pedestre, revisar a continuidade nas extremidades da rua e conferir a relação das fachadas com os interiores da PIP-89. A planta atual deixa margens bloqueadas nas pontas do asfalto; não foi pintada uma passagem falsa sobre elas. A pintura geral de conceito ainda não satisfaz o alinhamento de 4 px, portanto não serve como fundo único de navegação. A aprovação do kit completo e a substituição da campanha continuam pendentes.
