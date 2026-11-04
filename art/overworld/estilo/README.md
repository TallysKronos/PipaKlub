# PIP-82 — prancha única do overworld, revisão 2

**Acabamento da esquina aprovado; família e prancha completa aguardando revisão.**

O responsável aprovou `revisao-manga-v2/ESQUINA-ALVO-SIMPLIFICADA.png` nesta conversa
com “Sim gostei”. Isso aprova a linguagem de desenho, não automaticamente a grade,
os quatro biomas, os kits ou sua integração. A proposta anterior, rejeitada por
aparentar maquete, foi preservada em `historico-v1/`.

## Entrega e fonte

- `PRANCHA-ESTILO.png`: prancha completa 3200 × 4600.
- `PRANCHA-ESTILO.svg`: fonte autocontida, textos/diagramas editáveis e fontes/imagens incorporadas.
- `gerar_prancha.py`: fonte de composição, usa Python 3 e Pillow.
- `PREVIA.png`: leitura geral em 1600 × 2300.
- `ESCALA-NATIVA.png`: amostras na escala de produção proposta, sem a ampliação da prancha.
- `fontes/manga-v2/`: gerações originais, recortes por bioma, props e relatório de normalização.
- `fontes/GUIA-ESQUINA-2x1.png` e seu gerador: geometria comum usada como referência.
- `manifesto.json`, `verificacao.json`: origem, hashes, estado de aprovação e verificações.

Os quadros de bioma e props são imagens raster editáveis em um editor de pintura;
o SVG permite recompor a prancha sem achatar textos e diagramas. Não são imagens
geradas com camadas de pintura separadas. Nenhum arquivo do jogo mudou nesta entrega.

## Linguagem do mundo

Mangá 2D de aventura com energia gráfica de tinta, recortes e cores chapadas.
Contorno azul escuro cromático e expressivo; massas amplas; base e uma sombra por
material. Copa legível em poucos blocos, telhas agrupadas e detalhes internos só
onde ajudam a reconhecer a função. Nada de render volumétrico, bevel, ruído de
textura ou maquete arredondada.

A identidade é própria: papel, dobras, pipas, varetas, carretéis, nós e rabiolas
vivem nos objetos do bairro. Usar a energia gráfica da referência citada pelo
responsável sem copiar símbolos, personagens, objetos ou interface de outro jogo.
Chão andável continua visualmente calmo; contraste e detalhe favorecem personagens,
interações e HUD. Contornos vivos não autorizam transformar cada piso em um painel
de quadrinhos cheio de manchas.

## Contratos compartilhados

**Projeção:** isométrica ortográfica 2:1, célula 64 × 32. `x=(u-v)*32` e
`y=(u+v)*16-altura_px`. Um nível = 64 px verticais = duas células de altura do
Iso Studio. Diagramas da prancha e guia técnico são a referência de medidas;
as pinturas não substituem uma planta ou validação de alinhamento pixel a pixel.

**Morro:** será refeito em isométrico 2:1. A arte 3/4 antiga fica somente como
referência de conteúdo (casas, lajes, varais, caixa-d'água), sem ditar a câmera nova.

**Luz:** alto à esquerda; topo claro, face SE média, SW escura e contato curto.
Comparar o mesmo volume, não inventar uma luz por bioma. A caixa é um diagrama
técnico de valores; não é a proposta de acabamento dos edifícios.

**Traço:** meta de produção de 2 px externo / 1 px interno na escala nativa,
com variação expressiva de tinta. Aplicar o mesmo peso óptico a chão, peças e
personagens. Os sprites legados preservam sua identidade; não foram redesenhados.
A futura integração deve ajustar o acabamento à leitura real da câmera, sem
compensar desencontro de estilos esticando arquivos.

### Paleta e biomas

Base comum: papel/reboco `#F5E9CB`, terracota `#BC6749`, azul `#26394D`, verde
`#668A55`, sol `#E8BC58`. A prancha mostra cores auxiliares para cada material.
Pinturas indicam relações visuais; amostras de cor são os valores exatos de produção.

| Bioma | Vocabulário obrigatório |
| --- | --- |
| Bairro | Calçada clara, asfalto azulado, reboco, telha e oficina de pipas |
| Parque | Grama viva, terra batida, pedra clara e abrigo aberto |
| Veredas | Cerrado/vereda, **buriti**, terra vermelha, arenito, água rasa e canos |
| Morro | Concreto, reboco colorido, telha, chapisco sugerido e vasos |

### Escala e apoios

Altura visual alvo em pixels nativos, medida após retirar margem transparente.
Props foram redimensionados uniformemente; fonte completa preservada. As pegadas
abaixo são metas da régua, não colisões já integradas ao jogo.

| Elemento | Altura | Pegada / regra |
| --- | ---: | --- |
| Kael | 84 px | Apoio 1 × 1; identidade do rig existente |
| Rabbito | 42 px | Apoio 1 × 1; outros parceiros variam por espécie |
| Árvore comum | 160 px | Copa 2 × 2; colisão no tronco |
| Banco | 56 px | Base 2 × 1, acesso frontal livre |
| Poste | 144 px | Base 1 × 1 |
| Porta | 112 px | Vão projetado alvo 32 px, guarnição separada |

A revisão aumentou porta, poste e árvore em relação ao esquema rejeitado: a porta
precisa dar passagem legível a Kael, e os marcos de cenário devem ultrapassar sua
silhueta. Estas medidas constituem a proposta comum desta prancha, não alterações
de escala aplicadas ao jogo existente.

`props-normalizacao.json` registra tamanhos reais, recortes de alpha e pivô de
apresentação no centro inferior. Para o kit, substituir esse pivô de apresentação
pelo ponto de apoio real na pegada. O recorte técnico remove apenas ruído de alpha
até 8/255 na margem; não redesenha as peças. A largura resulta da proporção da fonte.

## Continuidade e HUD

Unir pisos na mesma cota. Paredes surgem da diferença de alturas, não do material.
Encaixar rampas nos dois patamares, fechar cunhas laterais e não atravessar acessos
com paredes. Pontes precisam de margens e cabeceiras. Não esconder juntas com folhas.
Exemplos da prancha: rampa de quatro células por nível, escada de oito espelhos de
8 px. Dimensões específicas dos acessos continuam nas plantas aprovadas.
Seguir `documentation/continuidade-terreno-isometrico.md`.

As quatro amostras da HUD usam as cores existentes `#141E29` e `#F4E9D2` em suporte
opaco: contraste calculado 13,97:1. Ciano e coral ficam em foco/ação. Cantos e
ornamentos não esticam; apenas centros admitem repetição ou extensão. As amostras
são mockups estáticos de contraste, não captura nem validação de layout em runtime.

## Origem, conferência e próximo uso

Plantas/inventário consultados na branch `claude/mapas-areas`, commit
`469cb4e4c498faf6afcca9ee3f6782d72538f4a7`, sem merge. Referências locais:
`DIRECAO-DE-ARTE.md`, `art/overworld/ESPECIFICACAO-MAPAS.md`, contrato de continuidade
e cores da HUD Godot. Kael é composto do manifesto atual, com âncoras de cabelo,
mochila e alças; Rabbito usa o primeiro quadro do asset de combate atual.

Geração original via `image_gen.imagegen`, usando somente a esquina própria
aprovada e o guia técnico próprio; prompts completos junto às fontes. Nenhuma
imagem de jogo externo foi usada como entrada. Assets legados mantêm sua origem;
não se atribui nova licença. Fontes Nunito e Barlow Condensed e respectivas OFL
permanecem em `godot/assets/campaign/ui-modern/fonts/`.

Verificações da prancha: tamanho, XML do SVG, limites de texto, proporção das imagens,
alturas nativas dos props, projeção dos diagramas, desnível, contraste e inspeção
visual. Não são prova de encaixe de tile, colisão, animação ou cena jogável.
Não foram executadas suítes do jogo para uma entrega restrita a direção de arte.

**Após aprovação da prancha completa**, anexá-la junto deste contrato a cada pedido
de conceito e kit da PIP-79: planta conferida → exportação do Mapa Studio → paintover
alinhado → kit modular → integração Godot → conferência em câmera real.

Regenerar sem serviços externos: `python art/overworld/estilo/gerar_prancha.py`.
Se necessário, regenerar antes os recortes por
`python art/overworld/estilo/fontes/normalizar_props_manga.py`.
