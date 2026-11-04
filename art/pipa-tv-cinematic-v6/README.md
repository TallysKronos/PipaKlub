# Plano contínuo · H3 com guias temporais

Objetivo: nova geração única de Kael → janela → Tyler e Saber, substituindo a lógica de cortina de flores e emenda de clipes. Não se afirma que um prompt garante continuidade perfeita; o vídeo será revisado depois de amostrado.

## O que significa latente aqui

O grafo usa uma única amostragem AV e um único latente de saída, com quatro condicionamentos `MiniMaxH3AddGuide`. As imagens guia são codificadas pelo VAE e inseridas na linha temporal do mesmo resultado. Isso não é recuperação do ruído, seed ou latente original dos MP4 V4/V5. O MP4 existente só fornece quadros de referência decodificados.

Implementação verificada no código local `comfy_extras/nodes_minimax_h3.py`, classe `MiniMaxH3AddGuide`, e na [fonte oficial do ComfyUI](https://github.com/Comfy-Org/ComfyUI/blob/master/comfy_extras/nodes_minimax_h3.py). O nó aceita também lotes de quadros e áudio para contexto de continuação; esse primeiro estudo usa imagens estáticas ancoradas. Não há continuação automática ilimitada ou promessa de 30 segundos numa só execução.

## Papéis das referências

1. Quarto: quadro V4, geometria e identidade do Kael, guia no frame 0.
2. Janela/jardim: nova imagem intermediária em `fontes/pipatv-v6-janela-jardim.png`, guia no frame 72 (3s). Estabelece o espaço visto pela janela antes de chegar aos dois; não é só referência decorativa.
3. Exterior: cena sob cerejeira V5, guia no frame 168 (7s) e no último frame. Mantém o fundo presente até o fim.
4. Tyler V3: referência semântica de rosto, roupa e cabelo; não é usada como quadro temporal, pois uma prancha dentro da sequência provocaria montagem indevida.

Os guias 0/72/168/-1 compartilham o mesmo latente; condicionamento final é encadeado até BasicGuider. Prompt, papéis e parâmetros em `prompts.json`. Plano solicitado: 8s, 24fps, 0,4MP, 20 passos, seed2810202611, H3 ref2va local instalado. Sem LoRA turbo ausente e sem nós pagos. Workflow customizado validado: zero erros/avisos, 27 nós.

## Templates de pesquisa

`h3-continuation-template.json` e `h3-multiframe-template.json` são cópias de estudo da galeria, não workflows prontos para esta instalação. Seus checks locais apontaram nomes de checkpoint/LoRA não encontrados. Não foram executados nem corrigidos com troca de família de modelo. O grafo executado foi construído a partir do ref2va já usado, incorporando os nós de guia disponíveis. `tools/prepare-pipa-tv-v6.py` documenta essa construção.

## Estado

Job `812d220a-5278-4ab7-a9e7-211671a5f292` concluído. Fonte `video-original/812d220a_000.mp4`, 8 segundos, 864×480, 24fps, com áudio gerado. Preview exportado por `tools/export-pipa-tv-v6.py`, sem junção de clipes, holds ou dissolves, em 1280×720 redimensionado proporcionalmente. Vídeo ativo no jogo preservado. Sem gameplay, publicação, atualização do ComfyUI ou novos downloads de modelo.

## Revisão visual

Quadros em `documentation/pipa-tv-cinematic-v6/planos.png` mostram a progressão quarto → janela com personagens já visíveis → exterior com aproximação. Não houve apagamento do cenário para preto nem transformação de Kael em Tyler. A janela gerada conserva travessas que não estavam no guia de abertura livre, e a escala do enquadramento muda durante a aproximação; a geometria é generativa, não uma câmera 3D fisicamente validada. O plano final mantém ambiente e pétalas em movimento. O método melhorou a continuidade neste teste, sem garantir reprodução exata de rostos, manchas e cabelo de um rig.

Preview: `documentation/pipa-tv-cinematic-v6/kael-janela-tyler-plano-continuo.mp4`. Metadados em `documentation/pipa-tv-cinematic-v6/metadados.json`. A sequência anterior de 30 segundos não foi remontada nesta etapa: esta é a nova tomada única de oito segundos que estabelece o método.
