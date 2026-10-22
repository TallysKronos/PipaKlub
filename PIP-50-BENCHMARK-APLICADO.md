# PIP-50 - Aplicação do benchmark

Revisão local de 20/10/2026, sobre o piloto de `7183063`.

## Alterações

- Parceiros: criatura e identidade permanecem visíveis; páginas de visão geral, status, técnica e história. Linha, energia, nível e técnica aparecem primeiro.
- Dex: páginas de visão geral, técnica, história, rabiola e animações. Os controles de reprodução e seleção de animação voltaram a ficar acessíveis. Rodapé separado da área de leitura.
- Retratos: nomes maiores, filtros sem corte, consulta com contorno ocre, foco com contorno terracota e equipado com selo próprio.
- Navegação: Q/E ou LB/RB trocam a página de detalhe, sem mudar o filtro de criaturas. Baixo entra na leitura; Page Up/Down e setas permitem rolar. O direcional e o analógico direito também têm rota para a leitura no código de controle.
- Pausa: seletor de uma rebicada por vez, com seis opções, índice, nome completo, descrição, energia e recarga extraídos do motor. Mantém o seletor real da partida sincronizado.
- Missões: foco inicial na ação principal e retorno ao controle que abriu a tela.
- Mochila: unidades do mesmo modelo e condição agrupadas visualmente com quantidade. Prontas e danificadas continuam em grupos separados. Não altera dados, propriedade ou consumo.
- Combate: remoção da redução uniforme da ficha do jogador; linha, energia, nome e números maiores dentro das molduras existentes de nove partes.

## Verificação realizada

- Builds web e Pages concluídos.
- Suíte completa: 269 testes, com 268 aprovados na execução padrão. O teste restante, de WebSocket, recebeu `EACCES` do sandbox e passou isoladamente com acesso ao socket local.
- Depois dos últimos ajustes, os quatro testes direcionados de mochila, páginas e builds passaram novamente.
- Testes novos verificam preservação dos elementos e ações ao trocar páginas, atributos de acessibilidade, navegação e rolagem. O teste de mochila cobre duplicatas e separação por condição.
- Navegador: coleção, Dex, animação de voo, rabiola, mochila, missões, treino e pausa. Q/E, entrada na leitura e Page Down verificados com teclado.
- As seis rebicadas foram percorridas no seletor e os valores dos dois controles confirmados iguais.
- Amostras em 1280 x 720 e 1920 x 1080. Não houve rolagem global nas fichas observadas. Na Dex, o conteúdo termina 10 px antes do rodapé nas duas resoluções.
- Console sem erros na sessão de revisão.
- Banco PGlite de teste isolado: `.local/ui-benchmark-applied`. Sem Supabase de produção.

## Evidências

Prints em [art/ui-reviews/benchmark-applied-2026-10-20](art/ui-reviews/benchmark-applied-2026-10-20/).

## Limites

Controle físico, Steam Input, jornada completa até Zeca, testes extensos em celular e homologação de migrações continuam pendentes. O teste com teclado e as rotas implementadas para controle não equivalem a uma validação física.

Não houve push, implantação no Render ou alteração de conta real nesta revisão. A opção `?classico` mantém a apresentação anterior para comparação.
