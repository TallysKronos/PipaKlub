# Revisao - mormaco

Data: 2026-11-13. Critico independente `/root/animation_pixel_critic`: 7.5/10, sem BLOCKING atual. Fonte comparada: `art/creatures/soulmonsters-overworld-v2/mormaco/duas-vistas.png`. Identidade, rosto, camera e porte foram priorizados sobre poses bonitas. Mormaco: R1 NW devolveu cadeia e tasseis ao lado esquerdo do casco, sem espelhamento global.

## Producao e verificacao

3 geracoes ImageGen de caminhada para este modelo. Grade, escala comum por folha, alfa e paleta fonte finalizados no Aseprite. Idle autorado da pose original: quatro quadros por vista, apenas dois pixels internos variam. Cabeca, apoios, silhueta e centro permanecem exatos. Ciclo 750/200/750/200 ms, sem lunge ou translacao. Respiracao muito sutil, possivelmente quase imperceptivel em 1x.

20 poses; zero erros mecanicos de alfa, paleta, limites e ilhas minimas. ASE reaberto: 20 quadros, tres camadas, quatro tags, PNGs idendicos pixel a pixel. Evidencias: validacao.json, auditoria-aseprite.json, idle-regioes-protegidas.json. Testes mecanicos nao substituem aceite visual.

Lote04: 12 geracoes (10 iniciais + duas correcoes NW), 72 poses walk geradas e 40 quadros idle autorados; atlas finais somam 60 walk + 40 idle. Sem videos ou geracoes de idle. Nao houve medicao comparavel para prometer economia percentual de tempo ou tokens.

## Correcao isolada e limites

Somente as seis poses NW de Lacertubo e as seis de Mormaco mudaram na R1. Hash por pose confirmou 88 poses restantes byteexatas. Config usa overrides para gerado-walk-nw-r1.png; fontes e geracoes iniciais preservadas. Snapshots PNG/ASE/GIF dos dois modelos em antes-correcao-nw-r1/. O critico escolheu DEPOIS para ambos, 7,5/10, bloqueios especificos resolvidos. Sem polimento geral depois da critica.

Nenhum runtime, Git ou fila de video alterado. Comparacao de ritmo no renderer e aprovacao humana continuam separadas desta revisao.

## Integração local

Aplicado e conferido no Godot. Rodada final:4.082 verificações de animação e1.674 gráficas dos cinco modelos, zero falhas nas suítes específicas. Caminhada, corrida, quatro orientações, espelhamento, oclusão e escala1. Por modelo:40capturas de movimento e16deidle, em tmp/overworld-pranchas-lote-04/playtest/. Inspeção das capturas confirmou integridade e escala. PNGs fonte/runtime idênticos. Não certifica ausência de deslizamento, aprovação humana individual ou regressão completa da campanha.
