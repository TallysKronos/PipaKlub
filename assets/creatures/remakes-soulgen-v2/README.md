# Remakes aprovados no jogo

Integração de Nozinho, Guaravento, Micofolha, Capimansa, Tatutrama, Flautrevo, Trinca-brasas, Alvaneve, Chaspiral e Hiponilo recebidos até `f7d08be`.

Fontes: `art/soulgen/keys/<espécie>/color-rig-v2/<espécie>.soulgen.json`. Não reconstruímos peças, pivôs ou animações. O exportador usa `sample` e `render` do próprio Soulgen, incluindo `artTransform`, expressões, hierarquia e dimensões manuais aprovadas. O manifesto registra hashes dos projetos e de cada PNG fonte.

Exportação: `node tools/soulgen-studio/export-remakes.mjs`, com `SOULGEN_CANVAS_MODULE` apontando para uma instalação existente de `@napi-rs/canvas` quando necessário. Atlas de combate: 12 fps, células RGBA de 256 px. Um enquadramento constante por espécie é calculado sobre todas as ações para normalizar o espaço vazio e evitar cortes; isso não altera o rig de origem. Retratos usam o rosto exportado. Acompanhamento: células de 128 px, duas ações e quatro direções, mantendo a vista de três quartos aprovada e espelhando oeste. Não foram inventadas vistas traseiras.

Consumidores: atlas global, Pipa Dex, coleção/retratos, batalha, treino do Nozinho, Oficina e acompanhantes do mundo. Nozinho mantém os aliases `greet` e `happy` exigidos pelas conversas antigas; o banner de assinatura passa a usar a pose do remake, em `nozinho-signature.png`.

`review.png` é uma prancha de produção com repouso e amostras das outras quatro ações. Não substitui inspeção da sequência animada em jogo. `manifest.json` registra procedência e parâmetros de enquadramento. Os PNGs antigos permanecem disponíveis para histórico, mas os manifestos ativos apontam para este pacote. Não altera identidade, inventário, atributos, recompensas ou dados de produção.
