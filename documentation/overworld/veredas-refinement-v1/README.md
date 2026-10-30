# Veredas — acabamento de terreno e pátio hidráulico

Implementado no mapa nativo Godot em 30/10/2026.

- Materiais contínuos de grama e terra do piloto aprovado, com pequenos tufos, folhas, flores e pedras; a fase da pintura acompanha o plano do terreno inclusive nos desníveis.
- Piso de pedra próprio para o pátio, com desgaste na borda exposta e juntas de baixo contraste. As células internas não recebem contornos individuais.
- Uma estação hidráulica com válvula, manômetro e conexões substitui os três canos idênticos. O centro da arena permanece livre para Lacertubo.
- Barrancos com o acabamento simplificado aprovado. Laterais triangulares das rampas agora têm sustentação fechada na mesma altura do terreno; os vazios verdes observados na revisão foram corrigidos.
- As alterações de superfície não mudam alturas nem navegação. A estação mantém o caráter decorativo dos canos anteriores.

## Fontes e reprodução

Arte nova produzida por imagegen. Originais preservados em `art/overworld/kits/parque/veredas-manga-v1/*-source.png`. PNGs normalizados espelhados em `godot/assets/overworld/kits/parque/veredas-manga-v1/`.

Piso: `exec-b233272d-7d77-42bd-9171-7f57ddf7ddc8.png`; estação: `exec-346e3219-69ec-497f-914d-9e81a4ec036f.png`. Diretório original: `C:/Users/user/.codex/generated_images/01a17924-9eaf-7951-8ded-c6920198ad3f`.

Máscara reproduzível: `godot --headless --path godot --script res://tools/bake_clareira_terrain.gd -- veredas-do-encanamento`. Reimportar depois. O manifesto verifica o SHA-256 do mapa compilado antes de aplicar a máscara.

## Verificação

- `park_campaign_integration.gd`: **104 verificações, zero falhas**, incluindo deslocamento real pelo controlador, luta vencida, coleta da rabiola, atalho, devolução à Nina, fuga e derrota. O processo headless foi encerrado após imprimir o relatório completo, pois continuou aberto.
- `veredas_art_review.gd`: **4 verificações, zero falhas**, capturas nativas 1280×720 em save temporário. Revisão visual das quatro rampas ampliadas, sem personagens encobrindo a geometria. A última correção das laterais é apenas visual e foi revalidada por estas capturas.
- Há um defeito anterior na miniatura do mapa (faixas claras/escuras), visível nas capturas. Esta entrega trata o cenário; não certifica o minimapa.

Nenhum commit ou push nesta etapa.
