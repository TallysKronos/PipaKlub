# Trailer v2 — ilustrações e letreiros

Entrega de 13/11/2026, itens 4–7 do pedido. Geração exclusivamente pela ferramenta imagegen nativa, uma imagem por chamada. Os PNGs originais estão em `fontes/`; prompts completos individuais e referências constam de `manifest-ilustracoes.json`.

## Arquivos finais

- Quatro ilustrações 1920×1080: `abertura-carretel.png`, `kronasta-ceu.png`, `fecho-estadio.png`, `impact-especial-rabbito.png`.
- Seis retratos RGBA 1024×1536 em `godot/assets/campaign/portrait-<nome>-manga-v1.png`: Mikka, Dona Neve, Ícaro, Nina, Retalho e Tufanocorte.
- Sete letreiros RGBA 1536×1024 em `onomatopeias/`: `tsk`, `zaak`, `fwush`, `krak`, `vuuum`, `splash`, `grrraaaooo`.
- Três pedaços RGBA 512×1024: `grrraaaooo-01.png` a `03.png`. Posicionar em x=0,512,1024; y=0 reconstrói exatamente o letreiro inteiro. A montagem pode deslocar/rotacionar cada pedaço para rachar a página.
- Duas texturas RGBA 1920×1080: `linhas-velocidade-radial.png` e `linhas-velocidade-horizontal.png`.

22 PNGs finais no total. As quatro cenas e as duas texturas foram normalizadas com ffmpeg, mantendo proporção e recortando o excesso mínimo. Retratos e letras são cópias dos originais, sem retoques programáticos. Python foi usado apenas para QA e pranchas de inspeção.

## Continuidade e revisão

Kael, Rabbito e o estádio derivam das referências canônicas, sem redesenho de identidade. O céu usa telhados e terraços brasileiros com o atlas como geografia. A abertura mostra duas mãos e a ligação física entre carretel, nó e fita. O fecho mostra os dois personagens de costas.

Retalho usa a forma **mascarada** aprovada, com dorso alto, máscara berinjela, varetas e cicatrizes coral. A bíblia apresenta esta forma no arco de confiança; a forma antiga da parceira de Heleana permanece fora desta arte. A aprovação do concept de origem está em `art/soulgen/campaign-redesigns-v1/retalho-mascarada/concept-v2/APROVACAO.md`. Isso não é uma nova aprovação do retrato pelo dono.

Mikka e Dona Neve tiveram revisão independente inicial 8/10 sem bloqueios, relatada pelo coordenador. Todos os demais foram inspecionados durante autoria; a aprovação independente e a aceitação do dono devem ser registradas pelo coordenador. Não houve gravação, captura, montagem de vídeo ou alteração de runtime nesta entrega.

## Evidências

Pranchas em `fontes/portrait-preview.png`, `fontes/scenes-preview.png`, `fontes/lettering-preview.png` e `fontes/speed-preview.png`. As pranchas de transparência compõem sobre xadrez real; o halo que a interface nativa de imagegen exibe não faz parte do PNG composto.

`qa-ilustracoes.json` registra dimensões, modo, alpha, SHA-256 e reconstrução pixel a pixel dos três pedaços. Reexecutar com o Python instalado: `python art/trailer-v2/fontes/verificar-ilustracoes.py`. A QA verifica os 19 assets-base e a reconstrução exata dos três pedaços; não equivale a playback no trailer ou aprovação artística.
