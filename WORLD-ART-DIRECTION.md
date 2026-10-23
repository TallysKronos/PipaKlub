# Quintal e Morro do Sol — identidade antes da arte

## O que define este mundo

O PipaKlub nasce de quintais, telhados e amizades de bairro. Papel colorido, varetas, nós, carretéis e rabiolas são materiais cotidianos que carregam as almas dos Pipamons. A arquitetura acompanha essa origem: casas brasileiras pequenas, telhas de barro, reboco gasto, madeira reaproveitada, árvores de sombra e plantas cuidadas pelos moradores. A imagem costeira anterior serve como referência de acabamento e legibilidade; sua praça de resort, porto e edifício monumental não definem o clube.

Paleta comum: reboco creme, terracota, azul-petróleo, verde de quintal e amarelo de sol. Contornos azul-escuros, cores em planos simples, detalhe concentrado nos pontos de interesse. Perspectiva elevada de RPG 2D, sem distorção de grande-angular. Personagens não fazem parte do fundo: são sprites com os pés apoiados no chão e ordenados pela profundidade.

## Quintal do Clube: chegar, cuidar, preparar o voo

É um terreno cercado entre as casas de Kronasta. A casa da esquerda mantém porta azul-petróleo, telhado cerâmico e varanda do cenário original. A exposição mistura pipas prontas e remendadas; a bancada tem papel, varetas e carretéis. Isso comunica coleção e aprendizado sem depender de uma placa de menu.

O portão de madeira ao fundo é a saída para a cidade. A vista mostra os telhados e morros de Kronasta, em continuidade com o bairro. À direita ficam a banca de toldo laranja, o círculo de invocação em pedra com losango incrustado e, mais abaixo, o mural e banco de encontro entre amigos. O círculo não contém magia permanente: o efeito pertence à interação.

O centro é gramado baixo com caminhos de terra batida conectando cada destino. Há área livre para Kael, parceiro e professor. Árvores e vegetação enquadram o terreno pelas bordas, sem esconder as passagens. O lugar é íntimo e artesanal; a escala da casa permite imaginar alguém morando e trabalhando ali.

## Morro do Sol: subir é aprender a ler o vento

O bairro tem cinco clareiras conectadas por um caminho contínuo, sem teletransportes visuais. A cota baixa está à esquerda; o percurso sobe por escadas e patamares até o mirante, antes de chegar ao parque. Os muros de arrimo deixam claro quais terrenos têm alturas diferentes. As escadas desembocam em chão utilizável, nunca em telhados sem acesso.

1. **Praça de chegada / Zeca:** portão baixo, banco, piso com losango de pipa e árvore pequena. Um encontro simples perto da entrada.
2. **Escadaria da sombra / Bia:** escada larga sob uma árvore de copa grande, muro com pintura de pipa e pequenos vasos. Um patamar permite parar e conversar.
3. **Laje dos ventos / Juninho e Lia:** terraço de uma casa coral, acessível por escada externa. Parapeito baixo, toldo pequeno e carretéis deixam claro o uso do lugar. A área de interação fica livre de mobília.
4. **Mirante da caixa-d’água / Tião:** caixa azul como marco de orientação, patamar com guarda-corpo e vista dos telhados. Um trecho de caminho permite contornar a estrutura.
5. **Parque dos Ventos / encontro final:** espaço de terra e grama com coreto simples, bandeirolas e bancos, amplo o bastante para o encontro de Mikka. O nome e a identidade da campeã só aparecem conforme os desbloqueios atuais.

Os detalhes contam hábitos locais: cadeira na varanda, varal discreto, remendo em um muro, latas usadas como vasos. Não haverá monumentos ou lojas sem função inventados para preencher o mapa. Pipas decorativas aparecem guardadas ou nos murais; os Pipamons e NPCs permanecem em camadas móveis.

## Regras para exploração

- O mapa não será reduzido inteiro para caber atrás da HUD. A câmera mostra uma região do mundo e acompanha o personagem, limitada às bordas.
- O traçado de navegação será ajustado à imagem produzida e verificado visualmente, incluindo escadas, entradas de laje e contornos dos muros.
- Caminhos são um grafo: ao clicar longe, o personagem percorre as conexões. Não atravessa casas em linha reta.
- O parceiro usa o mesmo percurso, com atraso, e não corta caminho pelo meio das construções.
- Pontos próximos permitem interação por botão/teclado; desafios bloqueados explicam qual encontro anterior falta. Andar pelo mapa não concede vitórias, XP ou itens.
- As partidas continuam nas arenas existentes. Confirmar um desafio usa o fluxo atual, com validação do servidor. O retorno mantém a posição de exploração.
- Em movimento reduzido, a posição e a câmera mudam sem animação contínua. A interface precisa continuar acessível sem passeio.

## Entrega artística

Dois fundos sem HUD, textos, personagens, partículas ou marcadores de missão pintados. O original do quintal e o mapa atual do morro são referências de identidade; a praça recente é referência de acabamento. As gerações serão salvas em versões novas, com prompts e caminhos preservados, antes de conectar qualquer consumo no jogo.

## Vila inicial isométrica — continuidade do parque

Quarto, sala de Kael, Rua dos Ventos, professor e loja passam a usar peças separadas em `village-isometric-v1`, com o mesmo chão projetado do parque. Reboco creme, telhas cerâmicas, azul-petróleo e madeira quente formam uma família; a vegetação e os rigs ambientais continuam os do parque. Contornos legíveis e sombras simples prevalecem sobre texturas detalhadas.

A rua acompanha o jogador. Os interiores pequenos usam paredes em corte e uma câmera que enquadra a sala para tornar móveis e saídas legíveis. A abertura tem enquadramentos próprios para TV e nascimento do parceiro. O piso segue a navegação real; a projeção visual não altera coordenadas de salvamento ou regras de história. Fontes, recortes e verificação: `art/soulgen/keys/village-isometric-v1/README.md` e `documentation/village-isometric-v1.md`.
# Quarto de Kael: atualização de 23/10/2026

Para o quarto, a entrega atual é `assets/world/kael-bedroom-iso-v4/manifest.json`, com fontes e projeto editável em `art/kael-bedroom-iso-v4/`. O Iso Studio controla pegadas, volumes, âncoras e conferência. A aparência vetorial da v3 é apenas guia geométrica: não é o acabamento aprovado do mundo. A v4 retorna a materiais ilustrados e ao traço do parque. Veja `documentation/quarto-kael-v4.md`.

O piso inferior segue o mesmo acabamento, com contrato em `src/home-layout.js`, kit em `assets/world/kael-home-iso-v1/` e projeto do Iso Studio em `art/kael-home-iso-v1/`. Estar, refeições e cozinha compartilham grade, escala e renderer com o quarto; os assets finais são ilustrados e a planta mantém rotas livres entre mãe, porta e escada. Veja `documentation/sala-kael-isometrica.md`.

A Rua dos Ventos usa a planta v2 em `src/street-layout.js`: rua larga, calçadas contínuas, varandas afastadas e praça aberta. A arte existente é preservada sem deformação; árvores, biruta, bandeirinhas e pipa reaproveitam rigs do parque. Piso e navegação derivam da mesma planta, com câmera que acompanha o jogador. Veja `documentation/rua-dos-ventos-v2.md`.

As fachadas antigas foram substituídas por `village-grid-v2`: pinturas ortográficas sobre faces 64×32×32, bases e soleiras em 2:1, pivô na porta e escala nativa. Professor e loja usam plantas medidas de 14×11 células, no mesmo renderer por pegadas dos interiores novos. Veja `documentation/vila-grade-v2.md`; a arte desta revisão fica em `art/village-grid-v2/`, com prompts e projetos do Iso Studio.
