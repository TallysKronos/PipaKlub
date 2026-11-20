# Review - pipa-dragao-desatada

2026-11-13. Independent critic `/root/animation_pixel_critic`: FINAL 7/10, no current BLOCKING. Desatada NW exterior white halo removed; normalization then measured on real body, not sticker bounds. Corrected versions were chosen AFTER in comparison against snapshots and canonical source. Identity, face camera, body proportions and ornament side take priority over attractive poses.

## Production and evidence

2 ImageGen walk sheets for this model. Aseprite finalization: common scale per view sheet, source palette, binary alpha; no regional body warp. Four source-authored idle frames per view, only two interior pixels vary, source head/feet/silhouette/center exact. 750/200/750/200ms cycle; subtle, potentially almost imperceptible at1x.

20 final poses; zero mechanical errors of palette/alpha/bounds/tiny islands. Saved ASE reopened20frames/3layers/4tags and flattened pixels identical to PNG atlas exports. Evidence: validacao.json, auditoria-aseprite.json, idle-regioes-protegidas.json. Mechanical proof is not full art/scale certification.

## Isolated corrections and limitations

Only six Trovareta SW and six Tufanocorte NW poses changed for R1; 88 remaining poses preserved byteexact relative to the checkpoint AFTER Desatada scale/alpha correction. Original generations and snapshots preserved; config uses explicit R1 path overrides. No general polishing after the final critic.

Batch05:12generations (10 initial+2R1),72generated walk poses plus40authored idle frames; final atlases60walk+40idle. No video or generated idle, no comparable measurement to promise percentage token/time savings. No runtime/Git/video queue changes. Renderer idle-to-walk comparison and human approval remain separate.

Desatada exact measured WALK heights: SW [74,76,80,79,78,73]px, common scale with reference maximum80px to fit complete nose/tail inside112; NW [84,82,80,82,84,82]px, common scale with reference maximum84px after exterior halo exclusion. Original idle remains84px. No per-frame bounding-box normalization. Critic accepted SW80/NW84 difference as a documented limitation, not perfect scale certification. No body part was warped to fit.

## Integração local

Aplicado no Godot. Rodada final:4.122checks de animação e1.680gráficos dos cinco modelos, zero falhas nas suítes específicas. Capturas de caminhada/corrida,direções,espelhamento,oclusão,escala1 e16quadrosidle em2,4s por modelo, em tmp/overworld-pranchas-lote-05/playtest/. PNGs fonte/runtime exatos. Inspeção de capturas confirmou corpo e integridade no cenário; não certifica ausência de deslizamento, equivalência perfeita de volume ou regressão completa da campanha.
