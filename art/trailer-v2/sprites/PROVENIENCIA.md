# Sprites e efeitos do trailer v2

Produção em 13/11/2026. Modo Aseprite **headless**, versão 1.3.18.6. Não foi alterado nenhum arquivo da worktree `pipa-club-integracao-atualizada`, nem as animações aprovadas anteriores.

## Fontes de overworld

Os originais de Trincaguarda, Carcará, Mata Verde e Rabbito vieram de `art/creatures/soulmonsters-overworld-v2/<id>/geracao.png` da worktree anterior. Foram copiados sem alteração de bytes para `<família>/<forma>/overworld-diagonal-v1/geracao.png`; os SHA-256 e as dimensões reais estão em cada `normalizacao.json`. O recorte divide a imagem original ao meio; não a reduz. O original de Carcará olha para sudeste na vista frontal: a normalização do consumidor deve espelhar apenas essa vista, preservando o RAW.

Vertim e Urso-polar jovem não tinham original com duas vistas na worktree anterior. Foram produzidos pelo `image_gen.imagegen` integrado, com transparência nativa, usando exclusivamente seus respectivos `concept-v1/concept.png` como identidade. O verso de Vertim recebeu uma correção dirigida de orientação, sem redesenhar sua identidade. Não são novas famílias ou novas formas.

## Rugido

`eremor-rugido-v1/geracao.png` preserva a geração original completa de 2073×758. A entrada de identidade foi `godot/assets/campaign/combat-eremor.png`. Foram pedidos oito desenhos efetivos: repouso, inspiração, abertura, três poses de rugido e dois estágios de recuo. O resultado tem oito poses distintas, incluindo mandíbulas abertas.

Aseprite importou os oito painéis 4×2 com o mesmo fator de escala em uma área de 285×208; o canvas passou a 350×313 e todos os cels receberam o deslocamento (31,94), mantendo a pegada e o apoio próximos da arte de combate. Limpeza nativa por operações de pixels eliminou alpha menor que 160: 3863, 3749, 3957, 3333, 3278, 3644, 3322 e 3478 pixels fracos, respectivamente. Isso remove a franja RGB vermelha quase invisível que também existe no original de combate, sem apagar os detalhes vermelhos opacos.

A medição de apoio do original com alpha≥160 foi `[60,104..303,284]`. Um ajuste dirigido posterior moveu apenas os cels (normal e silhueta): **dx −4**, **dy −5,−4,−4,−4,−5,−5,−5,−5**. Todos os pés da versão normal terminam em **y284**, e a borda fria da silhueta em **y285**. Não mudou anatomia, escala, cor ou contagem de quadros. Snapshots completos anteriores e comparação cega estão em `tmp/trailer-sprite-alignment/`; a decisão de comparação deve constar da revisão independente.

Tempos: 400,350,250,250,450,350,350,500 ms; total **2900 ms**, uma execução. Célula **350×313**, pivô **(175,285)**. A animação normal é material de arena. **No trailer só entram a silhueta e o som; não mostrar nome nem revelar o desenho colorido.**

A versão de silhueta foi derivada dos mesmos cels no Aseprite: massa preta, dois tons de luz fria (#517891 e #a6d9ef), cavidade oral recortada como espaço negativo nos quadros de boca aberta. Não existem olhos ou detalhes coloridos na variante do trailer.

## Onda e vento

A onda foi desenhada nativamente no Aseprite em camadas `shockwave` e `dust`, sem importar PixelFX ou código de terceiros. Doze células **512×512**, expansão rápida com desaceleração, anel frio, poeira violeta em lóbulos e fragmentação final. Tempos: 100,50,50,67,67,83,83,100,100,117,133,150 ms; **1100 ms**. Transparência real, sem fundo, sem borda preta de adesivo.

O rastro opcional de Rabbito foi desenhado no Aseprite em `wind-ribbon`: seis células **512×512**, três crescentes afilados em marfim/ciano, expansão e dissipação sem esconder o centro da arena. Tempos **100,50,50,83,100,150 ms**, total **533 ms**. Pivô **(256,256)**; nenhuma criatura foi incorporada ao efeito. Desenho nativo original, sem fonte externa.

Os arquivos `.aseprite` são as fontes editáveis; os GIFs são prévias. PNGs/atlas ficam em `godot/assets/campaign/`. A aprovação artística e a integração em Godot são registradas separadamente pela revisão do lote; presença do arquivo não comprova gravação ou integração.

## Limites da validação

O servidor expôs `preflight`, desenho, inspeção, paleta e exportação, mas **nenhuma ferramenta `validate`**. A verificação técnica deve usar os PNGs/atlas exportados: dimensões, número de quadros, alpha, recortes, apoio, duração e ausência de vazamento entre células. A leitura visual usa filmstrips nativos e revisão independente. Não foi gravado vídeo.

`verificar-exports.ps1` verifica os quatro exports sem modificar pixels. A execução passou: **8,8,12 e 6 desenhos distintos**, recortes dentro de cada PNG, todos os quadros com conteúdo e transparência. Dimensões finais: **2800×313**, **2800×313**, **6144×512**, **3072×512**. Resultado detalhado, hash e apoio medido por quadro: `qa-exports.json`. Os JSONs contêm tanto atlas Aseprite quanto `animations.roar`/`shockwave`/`wind-trail` em retângulos `{x,y,w,h}`, com `durations_ms` separado. A animação é executada uma vez (`loop:false`).

## Revisão independente final

A revisão independente coordenada pelo agente principal aceitou o lote, **sem achados BLOCKING**: rugido normal **8/10**, silhueta **8/10**, rastro Rabbito **8/10**, onda **7/10**. A comparação cega de alinhamento escolheu **B normal** e **A silhueta**, ambas as versões com apoio corrigido; confirmou que a mudança era somente translação. Os exports atuais são essas versões escolhidas. Não houve alteração de pixels depois dessa decisão.

Estado: validado tecnicamente e aceito pela revisão independente; **aprovação humana e verificação em Godot continuam separadas**. O desenho colorido completo é material interno da arena; a apresentação pública padrão do trailer usa apenas a silhueta e o som, sem nome ou revelação.
