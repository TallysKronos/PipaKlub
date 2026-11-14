# Trovareta — integração da arte aprovada no Godot

Estado: integrada localmente. O atlas aprovado foi copiado sem alterar pixels a partir de `art/soulgen/keys/trovareta/cutout-rig-v1/study-atlas.png`. O rig, pivôs e movimentos do autor foram preservados. Origem e SHA-256 constam de `content.combat.trovareta.source`.

- Atlas 2048×4096, 123 células de 256×256, seis ações a 12 fps.
- A ação Soulgen `skill` é mapeada para `attack` no consumidor existente.
- Overworld usa uma âncora de apoio fixa calculada para o ciclo inteiro, não recorte/recentralização de cada quadro. A criatura aparece presa no Bosque e livre na reunião dos Ventos.
- Batalha usa os clips de repouso, voo, ataque, dano, vitória e derrota pelo sampler Soulgen já existente.
- A identidade mecânica `raio` e o nível31 dos encontros salvos permanecem. Apenas a combinação de nome Trovareta com essa identidade recebe a arte nova. Não há captura, drop ou espécie jogável nova.

Reproduzir: `node tools/soulgen-studio/integrar-trovareta-godot.mjs`. O importador é idempotente, confere as dimensões do atlas e os retângulos e mantém a formatação dos campos alheios de content.json. Testes do rig e da cópia do atlas em `art/soulgen/keys/trovareta/rig.test.mjs` e `tools/soulgen-studio/integrar-trovareta-godot.test.mjs`.

A arte é a versão Soulgen de três quartos já aprovada, não uma nova produção de sprites em oito direções. Na cena atual ela não percorre uma rota de caminhada. Não houve nova geração ou alteração da imagem.
