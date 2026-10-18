# Chibi de exploração — Professor e Morro do Sol v1

Seis PNGs RGBA: Sr. Assis, Zeca, Bia, Juninho, Lia e Tião. Gerados com a ferramenta integrada image_gen. Identidade baseada nas artes existentes; estilo e contrato de oito poses baseados em `assets/hub/praca-v1/kael.png`. Prompts completos e caminhos das referências em `prompts.json`.

## Formato

4 colunas × 2 linhas: frente/sul, esquerda/oeste, direita/leste e costas/norte. Linha 1: repouso. Linha 2: passo. São 48 quadros no total. Caminhada inicial alterna repouso e passo a cada 170 ms, como o Kael de exploração; não é um ciclo de quatro fases.

PNGs originais de 1774×887, sem alteração de pixels. O gerador deslocou a separação visual das linhas: por isso o atlas usa o corredor transparente medido de cada folha e retângulos inteiros, em vez de presumir a metade do PNG. O atlas preserva `image`, `directions`, `frames` e `bounds` do contrato de ator existente. `footAnchor` permite alinhamento pelos pés; `referenceHeight` define escala fixa por personagem, sem redimensionar cada pose separadamente. Para uma importação por grade uniforme, primeiro é necessário normalizar o empacotamento; não usar 443,5 px como passo de linha.

## Entrega e limites

Abra `preview.html` para conferir as quatro direções, repouso/passo, fundo escuro e tamanhos 72/144 px. `atlas.json` contém todos os atores; cada personagem também tem seu JSON. `validation.json` registra alpha, recortes, margens, hashes e observações.

Inspeção geométrica não garante animação final. Há pequenas franjas em alguns contornos e simplificações de carretel/oclusão entre vistas. O crachá do professor e a vista traseira do boné do Juninho foram corrigidos nas folhas `-v2.png`, selecionadas no atlas e no ZIP. As primeiras versões estão preservadas apenas no workspace. As folhas preservam as características centrais, roupas e cores, mas ainda exigem revisão no cenário quando forem integradas.

Nenhuma alteração no carregamento do jogo, nos NPCs, no Git remoto ou no Render foi feita neste pedido. As artes anteriores foram preservadas.
