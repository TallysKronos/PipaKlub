# Revisao - dobrim

2026-11-13. Critico independente `/root/animation_pixel_critic`: FINAL 7.5/10, sem BLOCKING atual. Sem correcao adicional necessaria apos comparacao com fonte. Identidade, face, perspectiva, porte baby/child e anatomia comparados explicitamente a fonte `art/creatures/soulmonsters-overworld-v2/dobrim/duas-vistas.png`.

2 geracoes de walk para este modelo. Aseprite finalizou grade, escala comum por folha, alfa e paleta fonte; sem deformacoes regionais de corpo. Idle da fonte original:4quadros por vista, apenas2pixels internos de peito/flamula variam. Cabeca/apoios/silhueta/centro exatos, ciclo750/200/750/200ms. Muito discreto, possivelmente quase imperceptivel em1x.

20poses finais; zero erros mecanicos de alfa/paleta/limites/ilhas minimas. ASE reaberto20quadros/3camadas/4tags, exportacoes PNG pixel-exatas. Evidencias: validacao.json, auditoria-aseprite.json, idle-regioes-protegidas.json. Testes mecanicos nao certificam arte/escala sozinhos.

Lote06:12geracoes (10iniciais+2R1),72poses walk geradas+40quadros idle autorados, atlas finais60walk+40idle. R1 mudou somente6SWFarpim+6SWAzulim;88poses restantes byteexatas por hash. Originais/snapshots antes-correcao-sw-r1 preservados e overrides explicitos na config. Sem video ou geracao de idle; sem medicao comparavel para economia percentual de tokens/tempo. Sem runtime/Git/queue alterados. Renderer/aceite humano continuam separados.

## Integração local

Aplicado e conferido no Godot:4.162checks de animação e1.669gráficos dos cinco modelos, zero falhas nessas suítes. Caminhada/corrida,orientações,espelhamento,oclusão,escala1 e16quadros de idle por modelo. Evidência em tmp/overworld-pranchas-lote-06/playtest/. Inspeção de capturas confirmou integridade e escala; não certifica ausência de deslizamento, aprovação individual pelo usuário ou regressão completa da campanha.
