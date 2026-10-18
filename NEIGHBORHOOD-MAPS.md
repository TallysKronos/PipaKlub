# Mapas de bairro e descoberta dos líderes

18/10/2026 · Implementado localmente, sem deploy.

## Resultado

Os três bairros jogáveis têm ilustrações próprias com cinco pontos de batalha. Morro do Sol termina no Parque dos Ventos; Beira-Mar termina no Terraço da Maré; Campanários termina na Quadra de Copas. Os nomes são configuráveis em assets/district-places.json, separados das regras dos confrontos.

Nome, retrato, fala e botão com identidade do líder ficam ocultos enquanto o encontro final estiver bloqueado. Vencer os quatro encontros anteriores libera a descoberta. Não é necessário migrar o banco: os identificadores e a progressão existentes foram preservados.

O circo e um novo líder com traje de palhaço ficam reservados para um bairro futuro, conforme preferência confirmada. Lohan permanece como está. Esse bairro futuro não foi apresentado como conteúdo disponível.

## Assets

Skill imagegen, ferramenta integrada, geração de imagens novas. Três PNGs copiados para o projeto e para os assets da versão estática, com URL de hash e rota de arquivos autorizados. A imagem do quintal foi referência de estilo para o mapa do morro.

- assets/backgrounds/bairro-morro-v1.png
- assets/backgrounds/bairro-praia-v1.png
- assets/backgrounds/bairro-torres-v1.png

Raiz do projeto: C:/Users/Usuário/Documents/Codex/2026-10-17/referenced-chatgpt-conversation-this-is-an/PipaKlub.

## Prompts finais

Morro: Create a NEW production game background, using the supplied courtyard image ONLY as style reference, not an edit. Wide landscape illustrated neighborhood exploration map for Brazilian 2D creature-and-kite RPG PipaKlub. Hand-drawn clean dark outlines, warm cel shaded 2D anime game art, colorful terracotta roofs, tropical foliage, warm sunshine, matching reference. Bird's-eye oblique view of ONE coherent hillside neighborhood Morro do Sol, no collage, no UI, no text, no labels, no numbers, no characters or portraits, no frames. Exactly five distinguishable landmarks linked by a winding pedestrian route: (1) small neighborhood gate and plaza near x15% y75%; (2) a leafy stairway with tree near x30% y43%; (3) a flat rooftop terrace with kite strings near x50% y68%; (4) a small blue water-tower lookout near x66% y36%; (5) a spacious leafy public park with circular open lawn and pavilion at x84% y53%, the final arena. These locations must be clearly separated and visible, not cut off. Rest of image has charming hillside homes, gardens and paths, hills in distant top edge. Keep spaces over landmarks for interface hotspot overlays. Entire canvas is the illustrated map; no parchment margin. Landscape 3:2 composition.

Base dos dois outros mapas: Create a NEW production game background illustration for Brazilian 2D creature-and-kite RPG PipaKlub. Wide landscape 3:2 neighborhood map, bird's-eye oblique view. Clean dark hand-drawn outlines, warm cel shaded anime 2D art, colorful buildings and tropical greenery, matching a cozy Brazilian kite village. ONE continuous illustrated neighborhood, not collage. No text, labels, numbers, portraits, characters, UI or frames. Five clearly separated landmarks connected by winding paths, all visible away from edges. Landmark centers x15% y75%, x30% y43%, x50% y68%, x66% y36%, x84% y53%.

Praia — complemento: Beira-Mar seaside fishing neighborhood: 1 beach entrance plaza, 2 palm-lined beach promenade, 3 fishermen's net yard with colorful boats, 4 timber pier and small lighthouse, 5 spacious raised seaside public terrace with tea pavilion and flags, final arena. Sandy paths, turquoise sea along top, terracotta pastel fishermen houses. No circus.

Campanários — complemento: Campanários hillside bell-tower neighborhood: 1 plaza with small bell arch, 2 warm brick alley courtyard, 3 white flower garden and fountain, 4 a square between two tiled bell towers, 5 large red paved sports court decorated with subtle heart motifs and pennants at the top of the hill, final arena. Brazilian colonial architecture, bougainvillea, warm sun. No circus.

Após inspecionar as imagens, as coordenadas dos pontos foram ajustadas aos locais efetivamente desenhados, sem recortar ou alterar os assets gerados.

## Verificações

169 testes passaram, incluindo ocultação dos três líderes antes do desbloqueio e revelação correta depois. Build e artefato validados. Revisão no navegador do Morro do Sol, inclusive seleção do encontro final bloqueado. Nove verificações de geometria das três prévias em 390×844, 854×612 e 1440×900 terminaram sem erros detectados. Essas prévias são isoladas e não concedem progresso à conta.

## Limites

Estas são ilustrações da navegação entre encontros. Os fundos de combate ainda não foram substituídos por arenas específicas de cada lugar. A implementação não adiciona os nove bairros futuros nem promete suas recompensas. A estrutura permite acrescentar temas e locais sem renomear os confrontos persistidos.
