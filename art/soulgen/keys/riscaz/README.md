# Riscaz — direção A no Soulgen

**Versão final aprovada pelo autor.** O projeto enviado `riscaz-direcao-a.soulgen.json` foi incorporado como rig revisão 2, preservando suas peças, pivôs, hierarquia, clipes e PNGs embutidos. Cópia integral em `author-approved.portable.soulgen.json`, hash e normalizações em `author-import.json`. Metadados de auditoria das juntas foram recalibrados; não alteram a montagem. O construtor protege a edição final por padrão e o editor arquiva o rascunho anterior ao carregar esta revisão. A aprovação deste asset não define por inferência vínculo narrativo, poderes ou integração no jogo.

Fonte de identidade recuperada de `codex/concepts-personagens`, em `art/characters/riscaz/concept-v1/prancha.png`. Cópias, decisões, revisão e hashes em `art/soulgen/campaign-redesigns-v1/references/riscaz-git/`. A arquitetura A e a montagem final editada foram aprovadas pelo autor. O vínculo definitivo com Rato e os atributos não são decididos por este rig.

Abrir: http://127.0.0.1:5241/?preset=riscaz

Preservados focinho em cunha, incisivos de papel, orelhas assimétricas, olho verde, carvão/creme/verde e arquitetura baixa com vela de ombro. Oito peças: torso, cabeça, quatro membros, vela e rabiola completa com nó e duas fitas desiguais. Fio solto do peito omitido do asset independente; o pequeno nó permanece. O fio de vínculo não foi convertido numa terceira rabiola.

Quatro cabeças completas registradas: normal, ataque, dano e confiança discreta. Seis clipes propostos: escuta, deslocamento rasteiro, avanço, dano, vitória e derrota. ID técnico `flight` representa deslocamento, sem definir capacidade de voo. Amplitudes curtas para manter massa baixa, com vela e rabiola em atraso suave.

Arte gerada via image_gen: `cutout-rig-v1/source.png`. `prepare.py` apenas recorta componentes alpha e registra cabeças inteiras com nearest-neighbor; não repinta. `build-rig.mjs` monta hierarquia, pivôs e atlas. Ajustados encaixe da cabeça e sobreposição da vela; juntas proximais dos membros ficam sob a vela.

127 frames a 12 fps, sem pixels nas bordas das células. Estrutura, articulações, dimensões e expressões testadas; poses renderizadas inspecionadas sobre fundos claro e escuro. Isso não substitui a revisão interativa do autor nem comprova implementação de campanha. Projeto portátil e prévia independente incluídos. Sem alterações de jogo, raridade, poderes, história ou publicação.
