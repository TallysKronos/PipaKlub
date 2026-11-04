# Glacerol — Soulgen cutout v1

Terceira criatura do lote, após Trovareta e Rabiolava revisadas pelo dono. Preserva o felino A de geleira, paleta turquesa/azul-marinho/creme/lilás e os dois fios cortantes das orelhas.

## Contrato de montagem

- Torso sem patas, cabeça, cauda ou fios embutidos.
- Cabeça, quatro patas, cauda bifurcada completa e dois fios completos com seus terminais.
- Fios têm parentesco com a cabeça, não com o torso; os pivôs ficam na raiz das orelhas. A cauda liga ao quadril.
- Neutro, ataque, dano e vitória compartilham o alpha e o registro da cabeça; substituir apenas regiões faciais delimitadas.
- Repouso e deslocamento fecham os ciclos. Ataque, dano e vitória recuperam a postura; derrota sustenta a pose abatida.

Fontes e prompts em `cutout-rig-v1/`. O preset é `glacerol`. A anatomia de espécie e seus tempos serão medidos no projeto real; não reutilizar amplitudes da ave ou da raia por conveniência.

Preset local: `http://127.0.0.1:5241/?preset=glacerol`. Projeto editável e portátil: `cutout-rig-v1/glacerol.soulgen.json` e `glacerol.portable.soulgen.json`.

Seis ações: repouso 3 s, passo na corrente fria 1,25 s, bote 1,6 s (impacto 0,62 s), dano 0,8 s, vitória 2,2 s e derrota 1,1 s. Exportados 126 frames de estudo a 12 fps sem contato com as bordas. Fios e cauda são peças completas rígidas articuladas na raiz, sem deformação por malha ao longo do comprimento.

Reprodução: `slice.py` (Pillow, numpy e OpenCV), depois `register-faces.py` (Pillow), `build-rig.mjs` e `review-poses.mjs` (`@napi-rs/canvas` ou `SOULGEN_CANVAS_MODULE`). `node --test art/soulgen/keys/glacerol/rig.test.mjs` verifica arquivos, rostos, ciclos, recuperação, hierarquia dos fios e juntas ao longo das ações.

Revisão visual feita nas partes, montagem, rostos, fundos claro/escuro e extremos renderizados. Ajustadas as raízes dos fios para ficarem encobertas pelas orelhas, sem cortar os terminais no enquadramento. Uso automatizado do navegador local está desativado nas configurações do app; não foi declarado playtest interativo.

Estado: rig local para revisão do dono. Sem integração em jogo ou publicação antes dessa revisão. O contorno é híbrido no padrão Carcará; não implica grade nativa estrita de Aseprite. Efeitos de gelo e mecânicas de cerol não são criados por este rig.
