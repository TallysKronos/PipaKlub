# Alvacordo — piloto de overworld diagonal

Duas poses estáticas de câmera elevada: frente SW e costas NW, cada uma em canvas 80×80. A vista traseira é mais próxima de costas retas, com rotação suave para NW. O corpo foi compactado em uma nova projeção; não deriva de uma rotação da pose de batalha.

## Arquivos

- `frente-sw.png`, `costas-nw.png`: poses transparentes em tamanho nativo.
- `duas-vistas.png`: prancha transparente 160×80, frente à esquerda e costas à direita.
- `preview-cinza-5x.png`: prancha ampliada 5× sem suavização.
- `alvacordo-overworld-diagonal.aseprite`: fonte editável; frames 1/2 são vistas, não animação.
- `prancha-comparativa.aseprite`: montagem da prévia.
- `geracao-v1-camera-baixa.png`: primeira geração, descartada como alvo de projeção.
- `geracao-v2.png`: base gerada com câmera mais elevada.
- `prompt.txt`: prompts e referências de produção.
- `validacao.json`: medidas reais dos PNGs.
- `index.html`: inspeção em escala nativa, ampliada e em diferentes fundos.

## Produção e limites

Identidade: concept-v4 e sprite de batalha 128 aprovados. Projeção/economia: folha enviada pelo usuário, documentada em `art/benchmarks/overworld-diagonal-2026-11-05/ESTUDO.md`.

As duas vistas foram geradas com image_gen, com uma segunda passagem para elevar a câmera. No Aseprite headless, foram amostradas na mesma escala (0,1×), normalizadas à paleta aprovada de 24 cores e alpha binário, posicionadas no canvas, e receberam retoques locais no âmbar dos olhos e no preenchimento teal/dourado do peitoral. O resultado é uma adaptação gerada com edição local, não desenho integral manual nem recuperação comprovada de uma grelha original.

Pivô de chão proposto: (40,65), independente da ponta inferior da rabiola. É um ponto inicial para teste no mapa; não foi validado por movimento ou integração. PNGs não contêm sombra de chão. Não foi alterado código do jogo, nem substituída a família de sprites anterior.

## Revisão independente

8/10, sem achados BLOCKING. Câmera elevada, rosto adulto canino, escala entre vistas, dois arcos, pipa frontal e raiz da cauda foram considerados legíveis. Limitações: costas pouco diagonais; cauda encobre quase toda a segunda perna. Mantidas as poses após a revisão, sem retoques adicionais no personagem.

Próxima etapa após avaliação visual: validar escala junto de Kael no mapa e preparar idle/walk; espelhar os lados quando a identidade permitir. Esta entrega contém somente duas poses estáticas.
