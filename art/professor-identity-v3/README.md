# Professor · identidade aprovada aplicada no Godot

Autoridade de identidade: `approved-sheet.png`, cópia exata da imagem anexada pelo usuário ao escolher a versão anterior. Essa seleção prevalece sobre a correção de idade da V1 e sobre a versão jovem V2. A V2 fica preservada para outro momento, sem uso atual no jogo.

## Assets integrados

- `godot/assets/campaign/portrait-assis.png`: novo retrato transparente, enquadramento até a coxa, canvas 753×1200 preservado. Consumido pelo diálogo via `content.json`, dicas em `hud_lesson_coach.gd` e apresentação do professor em `front_end.gd`.
- `godot/assets/campaign/assis-overworld.png`: novo idle de cenário derivado da identidade aprovada, canvas 199×368 preservado, pés alinhados a dois pixels do fundo. Consumido pela sala, guia do parque e bairro inicial. Continua estático como o asset anterior; esta entrega não cria animações direcionais.

Fontes raster geradas com image_gen estão em `source-*.png`; prompts em `prompts.json`. `tools/normalize-professor-identity.py` faz apenas normalização técnica de tamanho/alpha e alinhamento, sem repintura. Original de cada arquivo de runtime preservado em `previous/`. Nomes e dimensões originais mantidos para alcançar todos os consumidores existentes sem alterar regras do jogo.

## Verificação realizada

Alpha real 0–255; dimensões e bounds em `normalization.json`. Importação do editor Godot concluída para os dois PNGs. Captura visual nativa 1280×720 do diálogo e sala em `documentation/professor-identity-v3/dialogo-professor.png`, gerada por `godot/tools/professor_identity_preview.gd`, usando estado fictício em memória e perfil local isolado; sem operações de save/recompensa. Retrato e sprite visíveis, transparência e baseline conferidos. Dicas/parque/bairro compartilham as mesmas referências, localizadas no código; não houve playthrough de todas essas telas.

Integração local no Godot, sem publicação ou alteração do jogo web legado. Não executada suíte de testes de gameplay. Saves e identidade jovem preservados.
