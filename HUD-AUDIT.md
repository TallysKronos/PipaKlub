# Auditoria da HUD ilustrada

A auditoria usa a página `/hud-audit`, que monta a arena real em um iframe de tamanho explícito. Não utiliza contas, partidas online, recompensas ou telemetria.

## Problemas corrigidos

- Conteúdo sem uma área interna definida nos painéis do atlas: cada painel passou a ter uma área de papel explícita.
- Arte dos botões com recuo negativo, ultrapassando o próprio botão: decoração limitada à caixa clicável, com área própria para o texto.
- Troca do lado da rebicada removendo os sprites: atualização apenas do texto.
- Controles comprimidos no celular: abas para Rebicada, Parceiro e Voo, inclusive na horizontal.
- Grid antigo fazendo o painel de voo ocupar outra linha: painel responsivo único nas telas baixas.
- Nome longo, placar cheio, valores e recargas excedendo as áreas: truncamento apenas do nome, rolagem intencional do placar e medidas específicas para cada formato.
- Pausa maior que a tela: altura máxima e rolagem interna.

## Verificação reproduzível

Abra `/hud-audit` e clique em **Auditar matriz completa**. A matriz cobre 13 tamanhos, de 320x568 e 568x320 até 1920x1080, com dez estados: pronto, recarga, pouca energia, cortado, contagem, pausa, assets indisponíveis, carregando rebicada, movimento e foco. Nos formatos com abas são verificados os três painéis, totalizando 290 cenários.

São medidos limites da tela, encaixe no papel, colisão entre painéis, arte e texto dos botões, transbordamento interno e caixa da pausa. O placar possui rolagem intencional; nomes longos usam reticências e preservam o nome completo no título. A matriz é complementada por inspeção visual no navegador.

A primeira versão falhou em 77 de 77 cenários da matriz inicial. A suíte automatizada de regressão passou com 152 testes; o artefato passou na validação ESM.
