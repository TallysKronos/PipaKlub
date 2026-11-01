# Clareira: Tyler/Rai e selvagens provisórios

## Entrega

- Encontro de Tyler e Rai na roda da Clareira do Papel (24,20 e 26,20), acessível após Lohan. A conversa apresenta Tyler como filho de Assis; Kael estranha nunca ter ouvido falar dele. O remendo do carretel é uma pista, sem expor DNA, homúnculo ou Elo.
- Onze falas com IDs em `godot/assets/campaign/tyler-clareira-v1/dialogue.pt-BR.json`. O jogador pode continuar depois. Cada fala confirmada grava um recibo antes de avançar; fechar/reabrir retoma na seguinte. Falha de gravação mantém a fala. A cena concluída vira uma conversa curta e não dá recompensa.
- O objetivo da história passa por Tyler entre Lohan e a recuperação da rabiola nas Veredas. A devolução da rabiola por Tyler é uma proposta da bíblia e NÃO foi aplicada: preservada a resolução jogável existente com Lacertubo/Nina, evitando duas entregas do mesmo item.
- Pool do mato opcional do Bambuzal: 45% Bicho-pau de Vareta [rascunho], 40% Mata verde, 15% Joaninha-pião [rascunho], níveis 7–9. Rascunhos têm IDs próprios e arte distinta. Mantidos os critérios existentes de XP, fuga, derrota, sorteio e garantia de rabiola.
- As rabiolas provisórias aparecem na mochila. Invocação, rig, classes e animações finais dessas duas espécies ainda não foram produzidos; não há receita falsa reaproveitando outra criatura. Os sprites provisórios usam pose única com o feedback procedural existente de combate.

## Arte

Sprites de Tyler e Rai foram adaptados dos concepts existentes (`art/tyler-manga-v3/tyler-sheet-v3.png` e `art/tyler-saber-manga-v2/saber-sheet-v2.png`) com a ferramenta de imagem integrada. Preservados os três tufos brancos laterais de Tyler e o tigre branco/rosa. A bíblia usa Rai; o arquivo de referência antigo se chama Saber. Conceitos originais não alterados.

Fonte preservada em `art/characters/tyler-clareira-v1/source-atlas.png`, recortes com alpha no projeto. Sprite dianteiro estático, sem reivindicação de spritesheet de caminhada. Atlas inspecionado e recortes normalizados por componentes alfa para remover sobras dos vizinhos. Carretel é um pequeno prop nativo, apoiado na mesma cota do personagem. Não mudou geometria do terreno.

## Verificação

Godot 4.7.2: `tyler_clareira_checks.gd` 57/0 (gating, distância, gravação falha, retomada de cada fala, conclusão única, ausência de recompensa narrativa, dois selvagens salvos/recarregados e drops). `tyler_clareira_flow_checks.gd` 26/0 em janela nativa 1280×720: controlador real chega ao encontro, abre todas falas, adia/retoma, avança objetivo e monta combate com ambas artes. Combates usam fixtures; não foram vencidos manualmente.

Regressões: campanha 207/0, interface 25/0, Bambuzal 143/0, ordem Nina 17/0. Capturas em `documentation/qa/tyler-clareira-v1/`: encontro, falas 0/3/6 e os dois selvagens. Revisadas no tamanho nativo.

A importação de recursos terminou, mas o editor emitiu aviso de safe save de suas configurações; nenhuma proteção foi desativada. Suítes e execução nativa não emitiram erro de script. Sem teste de controle físico, exportação de distribuição, áudio falado ou integração online. Sem push/merge/deploy.
