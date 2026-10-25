# Revisão do mapa piloto do overworld

Base recebida: branch `claude/mapas-overworld`, até `4bf09a2`, integrada em `2ebfbea`. Revisão e publicação solicitadas pelo usuário em 25/10/2026.

## Verificações

- 21 testes direcionados do conversor, Mapa Studio, terreno e navegação passaram. Incluem a conexão exclusiva pela rampa, ponte sobre a água, acessibilidade dos baús/Nina, paredes na boca da rampa e ordenação de árvore/patamar.
- Outros 34 testes de mapas, projeção isométrica, runtime do parque e salvamento de campanha passaram. Total: 55 testes distintos, sem falhas. Não foi executada a suíte completa do projeto.
- A conferência do Mapa Studio aprovou a planta com 970 células alcançáveis. O ator percorreu a rota da entrada ao mirante e depois à outra margem.
- No jogo com banco local isolado: entrada, subida e descida da rampa, interação com o baú do mirante, travessia da ponte, chegada à Nina, conversa e saída norte para as Veredas oficiais.
- Conferida a saída sul para a Clareira e a reentrada no piloto pela passagem correspondente.
- Revisão visual em desktop de 1131 × 884 e tela estreita emulada de 390 × 844, incluindo movimento por clique. Não equivale a teste em aparelho físico.
- Builds Worker e Pages concluídos e verificação sintática de 112 módulos/scripts selecionados e do script embutido de Pages, sem erros.

## Correções durante a revisão

O carregamento da cena passou a incluir sprites de NPCs cadastrados usados pela planta. Isso permite mostrar Nina com sua arte aprovada; nomes ainda sem sprite mantêm o marcador de rascunho, sem impedir a abertura do mapa.

Baús do piloto recebem o comando “Abrir baú”, preservando o texto de teste e a ausência de recompensas. O comportamento do baú foi percorrido no navegador; o rótulo também está protegido no teste do conversor.

Com o parâmetro `?overworld=veredas-piloto`, o menu de exploração oferece “Mapa piloto”, que inicia a revisão na entrada. A passagem da Clareira também continua funcionando. Sem o parâmetro, o atalho e a substituição da passagem não são ativados.

## Escopo da publicação

É uma prévia jogável da planta, com texturas e objetos do kit atual. Não substitui as Veredas oficiais para quem abre o jogo sem parâmetro. Não concede recompensas nem salva posição da campanha dentro do piloto. Não requer migração de banco.

Evidências locais em `artifacts/mapa-piloto-20261025/`: planta, encaixe da rampa/patamar, ponte/Nina, diálogo e tela estreita. Essas capturas não alteram saves reais; a sessão de revisão usou `.local/overworld-map-review-20261025`, em porta e hostname separados do jogo do usuário.
