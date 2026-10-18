# Muros do quintal · revisão aplicada

- Arte: `assets/world/quintal-kit-v1/walls-v2.png`, PNG RGBA original, 1254×1254, gerado pela ferramenta image_gen integrada. Prompt completo em `walls-v2-prompt.json`.
- Quatro retas orientadas e quatro quinas compartilham uma moldura conectada. Recortes fixos, sem rotação de iluminação ou redimensionamento de espessura. Trechos finais cortam a origem mantendo escala de 3/16.
- Planta padrão do quintal, projeto editável, pacote ZIP e builds servidor/Pages atualizados. O mapa preserva suas seis ações e rotas. Estado: 102 objetos, 10 decorações, 95 sprites e 762 pontos de caminhada.
- `audit-wall-edges.py` aprovado: alpha real no centro e exterior, coincidência de silhueta nas conexões superior a 99%, variação máxima de dois pixels de origem (0,375 px no jogo). Dados em `walls-v2-edge-audit.json`. O script lê pixels e escreve apenas o relatório, sem alterar o PNG.
- Conferência visual do painel: oito repetições por orientação; quatro cantos montados em fundo claro e escuro; nenhuma planta oculta as emendas. Imagens: `walls-v2-panel-review.jpg` e `walls-v2-dark-review.jpg`.
- Quintal conferido no Ateliê com o renderizador do jogo, sem grade e com modo de caminhada ativo. Captura: `quintal-muros-v3.jpg`.
- Build, Pages, validação ESM e auditoria estrutural aprovados. Suíte completa: 241 testes aprovados.
- As bancadas existentes foram preservadas. Revisão separada em `http://127.0.0.1:5210/?project=quintal&revision=muros-v3`; painel em `http://127.0.0.1:5210/wall-audit.html`.

O conjunto resolve o contorno atual do quintal. Não constitui um autotile universal: terminais livres, cruzamentos, terreno elevado e outras topologias exigem variantes e validação próprias. No mapa atual, os finais ficam sob os pilares do portão.

Mudanças aplicadas localmente, sem commit ou deploy nesta etapa.
