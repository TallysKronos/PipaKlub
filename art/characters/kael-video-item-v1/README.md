# Kael · recebe item e aponta para o céu

Vídeo gerado pelo MiniMax H3 local, sem nós de API paga. Job `70d5e310-a34d-45ad-b2f1-eb384fc10489`; receita completa em `workflows/item-local.json`. Referências derivadas das vistas S/SE do Kael. O personagem foi reduzido uniformemente na referência para reservar espaço para a mão erguida; o empacotador compensa essa redução com uma escala fixa para todos os quadros.

O pacote tem 16 quadros, com poses sustentadas, em célula **96×144**, pivô **48,142**, paleta de 32 cores e transparência binária. Duração da pose: **1710 ms**, sem loop. No Godot, uma virada inicial de **240 ms** usa as poses direcionais da caminhada a partir do ângulo atual; total **1950 ms**. Os sprites da pose permanecem de frente. Não há rotação geométrica do PNG.

Kael olha para a câmera, abre um sorriso, mantém uma mão na cintura e aponta o indicador da outra mão para o céu. A pose de ombro da descida vem de 4,625 s do vídeo. Uma pose da subida (1 s) é reaproveitada na descida para mostrar a mão próxima ao quadril antes do repouso. Essa reutilização é intencional, por isso os timestamps não são estritamente crescentes. O GIF repete apenas para revisão.

O acabamento reutiliza a regra aprovada do salto: contorno nativo com índice 31, remoção de ilhas de até dois pixels e máscara da calça restringindo base/sombra aos índices 6/19. As cores não são escolhidas livremente a cada pose. O documento Aseprite foi criado, desenhado, etiquetado e salvo pelo MCP nativo; os 16 PNGs exportados foram comparados ao Pixelgen e ao atlas.

## Consumidor

`godot/scripts/kael_video_avatar.gd` reproduz a pose e faz a virada em oito direções. `park_view.gd` mantém o jogador parado, limpa a rota de clique anterior, respeita pausa e ignora nova interação até o fim. O aviso do item aparece durante a pose erguida.

`front_end.gd` solicita a apresentação depois do recebimento confirmado dos itens dos baús ou da rabiola de Nina, nas Veredas. A apresentação não concede recompensas nem escreve inventário/saves. Outras cenas continuam usando o aviso de item existente. Recusar a apresentação não impede o aviso nem o recebimento.

## Evidências

- `pacote/qa.json`: células, paleta, PNG/projeto exatos, dedo inteiro dentro da célula, tons da calça, tempo e exportação Aseprite.
- `godot/tools/item_receipt_review.gd`: fluxo no consumidor real com perfil fictício, sem escrita de campanha; testa pausa, reentrada, movimento, aviso único e retorno ao repouso frontal.
- `documentation/overworld/kael-item-v1/`: captura 1280×720, animação no mapa e relatório.
- Revisão independente: 8/10, sem bloqueios visuais para o estudo integrado após inserir a descida intermediária do braço. A revisão estática é complementada pela prévia em movimento.

Pixelgen: botão **Kael · recebeu item**. O projeto editável, o PNG, o atlas e o `.aseprite` ficam em `pacote/`. Empacotamento reproduzível em `tools/pixelgen/examples/pack-kael-video-item.py`.
