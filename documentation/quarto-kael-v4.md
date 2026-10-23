# Quarto de Kael — grade validada e acabamento ilustrado

## Resultado

A v3 geométrica foi considerada de baixa fidelidade pelo usuário. A v4 substitui todas as peças e a casca por arte ilustrada com o acabamento do parque: veios de madeira, tecido, relevo de molduras, pintura teal, detalhes de latão e desenhos de construção de pipa. O centro permanece livre; cama à esquerda, estante e armário ao fundo, oficina à direita e escada na frente esquerda.

## Contrato de nível

O preset `presetKaelRoom()` do Iso Studio define volumes e âncoras usados em `src/bedroom-layout.js`. Cada célula de arte (64×32 px) corresponde a 96×96 unidades lógicas de navegação. O quarto usa sua própria transformação e inversa: `(x-y)/3, (x+y)/6`. Assim a arte tem tamanho nativo exato; a projeção do parque continua intacta. Colisões e saves continuam nas coordenadas ortogonais. Abertura e exploração usam a mesma planta, renderer e câmera.

O renderer do quarto usa a ordem por pegadas do Iso Studio para móveis e atores, não apenas a altura do ponto de âncora. A escada é recortada da casca, com degraus ilustrados e guarda-corpo separado. Os cliques do quarto e a posição do parceiro usam a mesma transformação do renderer; a abertura mantém a projeção anterior ao descer para a sala.

## Arquivos e reprodução

Arte e fontes: `art/kael-bedroom-iso-v4/README.md`. Projeto editável: `art/kael-bedroom-iso-v4/quarto-kael.isostudio.json`. Manifesto de runtime: `assets/world/kael-bedroom-iso-v4/manifest.json`.

Exportar: `node scripts/prepare-bedroom-polished.mjs`, depois `node build.mjs` e `node build-pages.mjs`. A normalização é registrada no README, incluindo a retificação dos desvios presentes nas imagens originais. A conferência é geométrica; a aprovação artística final pertence ao usuário.

## Verificação

- Suíte final: **398 testes aprovados, zero falhas** (`.local/bedroom-v4-full-tests.log`).
- Nove peças com verdict `ok` no modelo e **9/9 aprovadas** na interface real do Iso Studio; casca 576×448 carregada.
- Navegação da abertura e overworld comparada ponto a ponto, objetos bloqueados, ações alcançáveis e rotas da narrativa livres.
- Projeção de 96 unidades lógicas para vetores de (32,16) e (-32,16), inversa dos cliques e ordem de frente/trás verificadas.
- Câmera conferida por testes em 1280×720, 825×885 e 390×700. Revisão manual no navegador em 825×885; não equivale a ensaio físico em celular.
- Conta local isolada: entrada pela casa, subida ao quarto, bancada e parceiro em exploração. Abertura: interação com desenhos e bancada, progressão até Rabbito e descida.
- Publicação não executada; versão disponível apenas na prévia local.

`npm run audit:world` também passou, mas verifica o quintal modular legado; não foi usado como comprovação visual do quarto novo.
