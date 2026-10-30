# Clareira — conjunto aplicado à área inteira

Aplicação de 29/10/2026 no mapa `clareira-do-papel`, 64×48 células. A campanha usa o renderer comum com o novo acabamento habilitado para esta área. Outros mapas preservam seus materiais atuais.

Grama e terra reutilizam as pinturas aprovadas; os barrancos usam a versão simplificada aprovada, com três planos de cor e detalhes pontuais. As faces e margens recebem apenas revestimento: altura, pegada, recorte, profundidade, eventos e colisões permanecem iguais.

## Carregamento

O contorno contínuo foi pré-calculado a 16 amostras por célula, com halo de três células. O arquivo PNG importado é carregado como Texture2D, inclusive em exportações. Não há geração de máscara ao entrar na área. A recarga medida nesta sessão foi 582 ms (máquina local, recursos aquecidos; não é garantia para outros dispositivos).

Fonte e máscara ficam em `godot/assets/overworld/kits/parque/manga-terrain/`. `manifest.json` registra a origem das pinturas e hash do mapa. Alterações na fonte do mapa exigem executar `godot --headless --path godot --script res://tools/bake_clareira_terrain.gd`; se o hash divergir, o renderer usa o acabamento anterior e avisa em log, sem utilizar um contorno desatualizado.

Os módulos `clareira_terrain.gd`, `clareira_banks.gd` e seus shaders são de produção, sem dependências de `godot/tools/`. As prévias v1–v5 continuam isoladas por configuração explícita.

## Conferência

[Galeria e comparação](index.html). Onze capturas nativas 1280×720, com revisão das quatro rampas, dois acessos das pontes, cores chapadas e uso no adaptador real da campanha com dados fictícios em memória. Não grava saves.

O relatório confirma dados de mapa preservados e material ativo na campanha. Verificações existentes: `parque_surfaces_checks.gd` — 544 verificações sem falhas; `parque_connections_checks.gd` — chegada e ida/volta B/C sem falhas, agora com arte habilitada. O carregamento adiado da View nesse teste evita compilação anterior à disponibilidade dos autoloads de sprites.

Recrie as capturas com `godot --path godot --script res://tools/clareira_materials_review.gd`. A revisão não constitui uma sessão completa de campanha nem publicação.
