# Kael — piloto quadro a quadro

Teste solicitado após a rejeição visual do rig recortado. O objetivo desta etapa é avaliar uma caminhada lateral com oito poses completas, uma roupa e um cabelo, antes de investir em outras direções e em camadas de personalização.

Prévia: `http://127.0.0.1:5245/kael-frames.html`. Mostra o ciclo ampliado e em 96 px lógicos de altura; permite pausar, avançar/voltar quadros, selecionar uma pose, reduzir velocidade e comparar fundos. A exibição CSS pode reduzir essa dimensão em telas menores.

## Entregas

- `source/walk-east.png`: fonte original da ferramenta nativa `image_gen`, preservada sem alterações. Referência de identidade: `assets/hub/praca-v1/kael.png`. Prompt em `prompts.json`.
- `frames/east-0.png` a `east-7.png`: oito quadros completos com alpha, 256×256.
- `walk-east-atlas.png`: 1024×512, quatro colunas e duas linhas; leitura da esquerda para a direita e de cima para baixo.
- `walk-east.gif`: oito quadros, 100 ms por quadro, ciclo de 800 ms.
- `manifest.json`: recortes, duração, escala e registro dos quadros. Pivô `(128,224)` na célula de 256 px.
- `audit.json`: conferência técnica dos arquivos, sem aprovação artística automática.

## Método

A arte muda por quadro, inclusive nos cotovelos e joelhos. O player não usa ossos, rotações de recortes, deformação por escala ou interpolação entre duas poses. Não é pintura manual de um animador: é uma primeira sequência gerada por IA, registrada e examinada como piloto.

A fonte entregue tem 1774×887, diferente da grade pedida no prompt. O recorte usa divisões medidas; não presume uma grade perfeita. Cada pose recebe a mesma redução de 50%, com deslocamento global para registrar cabeça e apoio dos pés. Nenhum quadro recebe uma escala individual para disfarçar proporções. O alpha residual abaixo de 32/255 é removido antes da redução. O apoio opaco é medido de novo depois de reduzir e alinhado à mesma linha, evitando erro de arredondamento de um pixel.

Esta etapa **não implementa as camadas de roupa/cabelo/pele**. Ela testa primeiro a viabilidade visual da animação completa. Se o movimento for aceito, as peças de roupa e cabelo precisarão ser desenhadas sobre estes mesmos quadros, respeitando as poses e oclusões, em vez de girar uma única peça sobre o ciclo.

## Revisão

O corpo mantém continuidade entre braços, tronco e pernas; a flexão da passada é desenhada nas poses. Foram inspecionados a reprodução, os dois tamanhos e quadros de contato/passo na prévia. Há pequenas variações de contorno, cabelo e mochila entre desenhos; a passagem 8→1 e o ritmo dos apoios continuam sujeitos a revisão artística. Não foi declarado pronto para produção ou aplicado no jogo.

A auditoria técnica verifica oito PNGs distintos, mesma escala, alpha, margens sem cortes, mesma linha de apoio e oito páginas de GIF de 100 ms. Diferenças de hash não comprovam naturalidade.

```sh
node scripts/build-kael-frame-test.mjs
node scripts/audit-kael-frame-test.mjs
```

Não houve push, deploy ou alteração no personagem em uso no jogo.
