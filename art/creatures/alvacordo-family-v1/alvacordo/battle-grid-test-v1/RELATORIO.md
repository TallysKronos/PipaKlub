# Teste da recuperação de grelha — Alvacordo

## Resultado

Inconclusivo. Não apareceu ganho visual consistente que justifique substituir os assets aprovados. O detector encontra a grelha fracionária num controle sintético, mas este original não apresenta um período único forte. Nenhuma fonte aprovada foi modificada.

## Entrada e método

Original gerado: ../battle-pixel-v1/pose-gerada.png,1024×1536. O algoritmo mede energia de diferençasRGB entre colunas/linhas, com threshold de ruído14 e alpha>0,85 para excluir o glow translúcido. Usa busca contínua de frequência (equivalente a avaliar coeficientesFourier em frequências densas), não arredonda o período a inteiros. Candidatos procurados entre3 e18px; resultados não são inferências fora desse intervalo.

measure_grid.py preserva os sinais e candidatos. measure_local.py compara regiões de rosto, peito, dois arcos e pernas e calcula a média geométrica da concentração nos dois eixos, sob hipótese de grelha quadrada. O candidato conjunto mais forte é5,3356555px, com fases aproximadas X5,0239 eY2,3976px. A concentração conjunta0,0953 é próxima do candidato3,9536px/0,0883. Regiões locais discordam: não tratar o primeiro pico como verdade demonstrada.

recover_grid.py reconstrói uma candidata192×288: seleciona umaRGBA realmente existente na região central44% de cada bloco, usando moda e desempate pelo pixel mais próximo do centro. Alpha por maioria em128. Só depois remapeia para a mesma paleta24 da versão aprovada. sampled-source-rgba.json preserva as amostras antes da remapagem; grids.json registra os pixels finais desenhados/exportados pelo Aseprite.

O controleB usa redução por centros nearest-neighbor diretamente de1024×1536 para192×288, sem buscar a fase, com a mesma paleta/alpha. Assim a comparação principal não é favorecida por diferença de resolução ou quantidade de cores. As mudanças incluem tanto alinhamento da amostragem quanto moda central; este experimento não isola qual das duas operações responde por cada pixel diferente.

## Controle positivo

Padrão sintético regular com período conhecido9,31px e blocos de cores sólidas. Recuperado9,3090928px em ambos os eixos; concentração~0,981. Isso verifica o detector em uma situação que cumpre a hipótese de grelha regular. Não demonstra que a fonte do Alvacordo também cumpra essa hipótese. Concentração não é porcentagem de confiança.

## Conferência visual

Comparação independente de a.png (candidata) e b.png (controle): sem preferência consistente. Pequenas diferenças de compactação nos arcos e na cintura, mas sem ganho global nas escadarias. Olho, dedos e cordas continuam com leitura equivalente. Não se concluiu recuperação da grelha verdadeira.

A prancha comparacao-2x.png mostra candidataA à esquerda e controleB à direita, mesma ampliação inteira. Há também fundo magenta e um playerestáticoHTML com zoom nativo e troca de lados. Não houve retoque manual para favorecer a candidata. As duas saídas são192×288, alpha binário,24cores. O sprite aprovado é192×192, com figura118×164; comparar um candidato maior com ele não isola melhoria de algoritmo.

## Limites e decisão

Manter o master e as animações aprovadas. O método da thread é útil quando há uma grelha ampliada regular identificável. Nesta entrada, a periodicidade é fraca e misturada; ele não substitui a revisão de clusters ou anatomia. Esta entrega testa uma pose estática, não os framesH3. Não há alegação de melhoria temporal ou de integração em jogo.

Fonte do método estudado: https://x.com/MagcPixel/status/2118362886359630086 . O código aqui é uma implementação própria de teste, não código publicado pelo autor da thread.
