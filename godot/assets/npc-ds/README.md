# NPCs direcionais no jogo

Correção de proporção: a altura opaca de referência do Kael em SE é 86 px. Cada consumidor multiplica essa altura pela escala real do avatar da cena. Jovens usam razão 1,00; mãe 1,08; professor e Tião 1,12. A altura do canvas transparente não entra na comparação. No Morro, os jovens passam de 72 px fixos para aproximadamente 59,7 px, acompanhando Kael (.62 × 1.12 × 86). Não diminuir cada NPC manualmente em telas diferentes: usar `height_for()`.

Origem: `art/characters/npc-ds-directions-v1/`. São oito identidades com oito bases estáticas de 64×96, ordem S,SO,O,NO / N,NE,E,SE. Pivô 32,94, alpha binário, filtro nearest, sem mipmaps.

`scripts/npc_pixel_sprite.gd` configura recorte, altura visível e pivô dos Sprite2D. A cidade usa o mesmo PNG, recorta a vista SE e mantém seu renderizador de profundidade e escala por altura visível.

Consumidores: mãe e professor em `campaign/room_view.gd`; Nina em `illustrated_veredas.gd` (também herdado pela campanha); rivais em `campaign/morro_view.gd`; moradores em `overworld/starter_neighborhood.gd`; humanos dos eventos em `overworld/view.gd`. A lojista Lia deixa de usar o desenho da Bia. Mikka e Lacertubo conservam as próprias imagens porque não pertencem ao lote produzido.

Os percursos, pausas e revelação pela escada da mãe continuam sendo controlados pela abertura. A orientação acompanha o caminho, mas as poses são estáticas: não existe novo ciclo de caminhada neste lote. O shader de revelação foi adaptado às duas linhas do atlas; ele não usa mais as células grandes da folha antiga.

Retratos de diálogo, campanha e recompensas não foram substituídos. Evidências em `documentation/pixelgen/npc-in-game-v1/`.
