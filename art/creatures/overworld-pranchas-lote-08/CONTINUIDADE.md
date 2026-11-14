# Continuidade curta — lote08

Repo C:/Users/user/produto/pipa-club-integracao-atualizada, branch codex/estudos-designs-soulmonsters.40/194novas animações integradas (35até lote07+5lote08). Lote08: raibroto41,raivela70,raigume70,raisoberano84,raiatar84. Configbatch.json;pastas<id>-prancha-v1.112célulaSW/NW,apoio56,100,escala1,4idle/6walk por vista.

10gerações walk; nenhuma extra/vídeo. Fonte/cabeça/rosto/núcleo superior preservados por máscaras positivas incluindo gaps; membros inteiros livres desde quadril/ombro, não pontas de pés (lição07). Raivela NW110px:dobrar velas para dentro desde raiz, sem downscale da criatura. Não reimportar raws sobre finais. Idles autorados discretos sem arranco.

Revisão independente critica.md: Raibroto7, demais7,5; semBLOCKING/semrodadafix. Limites: atuação mínima bebê41, núcleos superiores estáveis. Aprovação humana pendente. Root confirmou máscaras/fontes/cópiasruntime;ASE20quadros por modelo. 4242checks animação/0, 1674percurso/0. Capturas/GIFs em tmp/overworld-pranchas-lote-08/antes eplaytest;index/comparacao.html.

Pipeline comum: prancha-batch.py/import.lua/review.py,hybrid-review.py --id --publish somente após crítica>=7semBLOCKING;Godotimportantesdos testes;tests/overworld_animation_checks.gd eoverworld_visual_playtest.gd com --models e--evidence. Depois hybrid-runtime-gifs.py ehybrid-review.py --batch --evidence. Novo batch-finish.py --batch art/creatures/overworld-pranchas-lote-XX/batch.json --evidence tmp/overworld-pranchas-lote-XX confere fontehashbaseline/runtimeexato/reports egera comparação+resultado,sem editarpixels. Requer baseline-hashes.json eantes/playtestGIFs.

Vídeos explicitamente parados; semmerge/push. AzulimR3 aprovado2026-11-13,preservar original face eart_versionsheet-v1-approved;Carcará ativo hibrido-v1,prancha-v1 rejeitada. Próximo lote via continuidade;usar este resumo/configsem reler histórico inteiro.
