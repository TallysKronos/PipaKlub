# Rua dos Ventos — espaço e continuidade visual

**Revisão posterior:** as fachadas antigas foram rejeitadas pelo usuário por inclinação incompatível com a grade e substituídas por `village-grid-v2`. Professor e loja também receberam interiores medidos. A planta espaçosa desta página permanece; a afirmação abaixo sobre preservar as fachadas descreve somente a primeira entrega. Ver `vila-grade-v2.md`.

## Direção

O pedido é ampliar a sensação de espaço e trabalhar a rua inicial no estilo isométrico do parque e da casa. A planta anterior tinha corredores de 224 unidades, retornos estreitos e objetos distribuídos entre recortes de piso. A v2 usa uma via principal de 336 unidades, calçadas contínuas de 144 e 160 unidades, acessos independentes e uma praça de 960×480. As casas ficam separadas por 864–896 unidades. O mapa passa de 1536×1024 para 2816×2112; o personagem mantém altura 100.

`src/street-layout.js` é o contrato único: terreno, posições das fachadas, objetos, colisões, portais e ações. `streetMap()` gera o mapa Tiled usado em `artConfig()`; o arquivo legado `street-v1/quintal.tmj` permanece histórico. Os IDs `quintal` e `tiled-11` até `tiled-17`, mais `tiled-150`, são preservados. As coordenadas da rua mudaram; um save antigo fora da área caminhável usa a recuperação existente para o spawn seguro, sem reset de campanha ou coleção.

## Acabamento

`src/street-ground.js` pinta uma superfície contínua no plano 2:1: terra batida quente, calçadas de pedra creme, meio-fio baixo, travessia junto ao professor e um losango de pipa na praça. A variação de material tem semente fixa e é calculada uma vez. A câmera acompanha o jogador e não reduz o bairro inteiro para caber numa tela.

As fachadas preservam os PNGs ilustrados de `village-isometric-v1`, com proporção e pivô de origem. Vegetação, bancos, luminárias, bandeirinhas, biruta e pipa vêm da família `park-isometric-v1`. Não houve nova geração raster ou deformação de silhuetas. Árvores e objetos animados usam os rigs Soulgen existentes; a linha da pipa acompanha a articulação animada. A vegetação fica nas bordas e jardins, os móveis da praça têm apoios sólidos e os acessos ficam livres.

O cache de chão mede 4352×2304, aproximadamente 38 MiB RGBA, criado uma vez por renderer. Seu tamanho acompanha a ampliação da rua. Movimento reduzido continua congelando os rigs, sem impedir navegação.

## Verificação

- Builds Worker e Pages concluídos.
- 47 testes direcionados aprovados: `street-layout`, `village-runtime`, `street`, `first-flight`, `campaign`, `world-isometric` e `world-navigation`. Resultado final em `.local/street-v2-tests.log`.
- Quatro testes novos cobrem largura útil, acessos, percurso entre todos os destinos com parceiro seguro, colisões e câmera desktop/estreita.
- O teste de caminhada direta da campanha passou a usar a borda real da varanda nova, em vez das coordenadas do jardim antigo; mantém a verificação contra atravessar limites e ganhar velocidade diagonal.
- O teste manual identificou retorno pelo lado externo do portão do parque: a rota seguinte reatravessava o portal. A chegada agora é ao norte, dentro da praça; um teste de integração verifica o percurso parque → praça → loja sem reentrada indevida.
- Navegador desktop, banco isolado: casa do professor e retorno, mural de trocas sem criar convite, ida ao parque e retorno, loja e retorno, caminhada/cliques e abertura dos destinos. Capturas em `documentation/evidence/street-v2/`.
- A validação da rua não equivale à aprovação geométrica dos móveis da sala: a pendência registrada em `sala-kael-isometrica.md` continua separada.

Integração local em `127.0.0.1:5243`. Sem migração, push ou deploy nesta revisão. A câmera estreita foi verificada por testes; não houve revisão em telefone físico.
