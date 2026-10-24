# Starters Soulgen no jogo

Atlas pré-renderizados dos projetos aprovados: Carcará e família artesanal v2 (Mata verde, Azulão, Raio de sol, Rabbito). Rabbito usa a hierarquia manual do usuário, revisão 1. Fontes, hashes e escala estão em `manifest.json`.

Combate/coleção/Dex: células transparentes de 256 px, 12 fps, cinco ações e expressões do rig. Acompanhamento/abertura: células de 128 px, repouso e voo, apoio fixo; vista em três quartos espelhada lateralmente. As entradas norte/sul usam essa mesma vista, sem inventar uma anatomia traseira. Os desenhos de quatro direções ainda precisam de produção própria.

Reexportar com `node tools/soulgen-studio/export-starters.mjs`. O comando requer `@napi-rs/canvas`; `SOULGEN_CANVAS_MODULE` permite usar uma instalação existente. Builds e servidor consomem somente PNGs e os manifestos comuns, sem essa dependência nativa.

Nenhum teste executado nesta publicação, por solicitação do usuário. Os recortes são renderizados diretamente do sampler do Studio; isso não constitui aprovação visual de todos os estados dentro do jogo.
