# PIP-82 — prancha única do overworld

**Estado: proposta v1 REJEITADA pelo responsável em 26/10/2026.**

Motivo: aparência de maquete ilustrada, volume e acabamento distantes da direção
2D mangá com energia gráfica de Splatoon aprovada para o projeto. Não usar as
esquinas desta prancha como referência de produção. Os contratos de grade da
PIP-79 continuam válidos, mas a pintura deve ser substituída. Próxima revisão:
um único alvo de esquina, antes de refazer a família de quatro biomas.

Abra [PRANCHA-ESTILO.png](PRANCHA-ESTILO.png). A fonte é o
[SVG autocontido](PRANCHA-ESTILO.svg), com fontes e imagens incorporadas,
e o gerador editável [gerar_prancha.py](gerar_prancha.py).
O PNG tem 3200 × 2920 pixels; `PREVIA.png` é a versão reduzida para leitura geral.
`ESCALA-NATIVA.png` mostra a régua sem a ampliação de apresentação.

## Decisões propostas para aprovação

- Projeção ortográfica isométrica 2:1 em **todos** os biomas; célula 64 × 32.
- Um nível tem 64 pixels verticais: duas células de altura de 32 do Iso Studio.
- **Morro do Sol será refeito em isométrico.** A arte 3/4 atual serve somente como
  referência de conteúdo (casas, varais, lajes, caixa-d'água e relações narrativas).
  Não copiar sua câmera para os kits novos.
- Luz do alto à esquerda, face SE média, SW escura e sombra de contato curta.
- Anime 2D: contorno cromático firme, massas grandes, base e uma sombra por material.
- Mundo mais suave que a HUD Recorte; texto sempre em suporte sólido.

As decisões só passam a ser referência **aprovada** após o aceite do responsável.
Não foi alterada a projeção de nenhum mapa em runtime nesta entrega.

## Régua para os próximos kits

Medidas em pixels nativos, antes de zoom da câmera. Altura visual inclui a silhueta;
o arquivo pode ter margem transparente. Os desenhos vetoriais de props são esquemas
de volume, não assets finais. A altura nominal é a meta de produção, não uma alegação
de que cada traço do esquema ocupa exatamente essa caixa.

| Elemento | Altura visual alvo | Ocupação / observação |
| --- | ---: | --- |
| Kael | 84 px | ponto de apoio em uma célula; usar rig atual como identidade |
| Rabbito | 42 px | parceiro de referência; outros parceiros respeitam sua espécie |
| Árvore comum | 128 px | copa em 2 × 2; tronco e colisão independentes da copa |
| Banco | 56 px | base 2 × 1; espaço frontal livre para interação |
| Poste | 112 px | base 1 × 1; luz não muda a iluminação solar da família |
| Porta | 80 px | vão com 32 px projetados; entrada alinhada ao piso |

Meta de traço em escala nativa: 2 px externo / 1 px interno, aplicada ao acabamento
novo de chão, objetos e personagens. Não engrossar proporcionalmente ao tamanho do
arquivo e não redesenhar os personagens existentes automaticamente. A prova de
integração deverá conferir estes valores em câmera real antes de fechar o kit.

### Chão, relevo e acessos

`x = (u - v) * 32`; `y = (u + v) * 16 - altura_px`.

Unir pisos de mesma altura; paredes surgem de diferenças de altura, não de material.
Não fechar a boca de uma rampa com parede. Rampa ilustrada: um nível em quatro
células de percurso. Escadaria ilustrada: oito espelhos de oito pixels, mesmo desnível.
Esses exemplos não substituem as dimensões de acessos das plantas aprovadas.
Pontes precisam de cabeceiras e sustentação; água encontra margem e leito.
Seguir também `documentation/continuidade-terreno-isometrico.md`.

### Materiais e leitura

Paleta comum: papel/reboco `#F5E9CB`, terracota `#BC6749`, azul `#26394D`,
verde `#668A55`, sol `#E8BC58`. As cores auxiliares estão na prancha.

- Bairro: calçada clara, asfalto azul dessaturado, reboco e telha.
- Parque: grama viva, terra batida, pedra clara, copas em massas.
- Veredas: **buritis e cerrado**, terra vermelha, arenito e água rasa.
  Não converter esse bioma em floresta tropical genérica.
- Morro: concreto, reboco colorido, telha, chapisco sugerido por poucos sinais,
  plantas em vaso; ocupação urbana com acessos sustentados.

Mato de encontros, chão andável e bloqueios precisam ter silhuetas distintas.
Esta entrega não modifica onde ocorrem encontros ou colisões.

## Como usar e o que não usar como medida

Os quatro quadros ilustrados repetem a composição da mesma esquina para comparar
materiais e acabamento. Foram gerados como uma família e revisados para reduzir
textura e perspectiva. **Não são tiles, plantas, nem desenhos técnicos pixel-exatos.**
Pequenas variações de desenho e inclinação na pintura não autorizam alterar a grade.
O próximo conceito deve partir da referência exportada do Mapa Studio; o kit deve
derivar suas bordas e medidas da planta e dos diagramas, não recortar estas ilustrações.

Após aprovação, anexar a prancha e este contrato a cada pedido de conceito/kit.
Ordem: planta conferida → exportação → paintover → kit modular → integração Godot.
Validar trechos longos, cantos internos/externos, rampas nos eixos usados, cabeceiras,
colisão, oclusão e leitura em escala nativa no jogo. Não disfarçar juntas com folhas.

## Origem e validação

- Escopo fornecido pelo usuário: PIP-82, filha da PIP-79.
- Plantas/inventário consultados em `origin/claude/mapas-areas`, commit
  `469cb4e4c498faf6afcca9ee3f6782d72538f4a7`; branch consultada, sem merge.
- Contratos locais: `DIRECAO-DE-ARTE.md`, `ESPECIFICACAO-MAPAS.md`, continuidade de
  terreno e cores da HUD em `godot/scripts/campaign/hud.gd`.
- Kael: composto do manifesto atual, respeitando as âncoras de cabelo, mochila e alças.
- Rabbito: primeiro quadro do asset de combate atual, recortado pelo alpha.
- Esquinas: geração original via `image_gen.imagegen`; prompts em `fontes/geracao.json`.
  Nenhuma imagem de jogo de referência foi usada como entrada ou copiada.
  A origem dos assets legados permanece a do projeto; não se atribui nova licença a eles.
- Fonte raster preservada em `fontes/esquinas-v2.png`; recortes sem deformação.
- Fontes Nunito e Barlow Condensed do próprio projeto; licenças OFL preservadas
  em `godot/assets/campaign/ui-modern/fonts/`.
- PNG e prévia inspecionados visualmente. Verificação de tamanho, geometria,
  texto dentro da tela, XML e contraste registrada em `verificacao.json`.

Sem execução de suítes do jogo: esta mudança só adiciona material de direção de arte.
O mockup da HUD verifica cores e legibilidade em suporte sólido; não é captura nem
validação de layout em runtime. Aprovação visual e integração permanecem etapas distintas.

Para regenerar, executar `python art/overworld/estilo/gerar_prancha.py` na raiz,
com Pillow instalado. Não é necessário Godot, navegador ou serviço de geração.
