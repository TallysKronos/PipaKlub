# Auditoria visual de encaixes · Tricerafan

Problemas encontrados na revisão 2:

- Bocas de tubo escuras no pescoço, na raiz da cauda e no leque; cavidades desenhadas na própria fonte, apesar da validação técnica do rig.
- Aberturas inferiores no torso e tampas com pinos dourados nas patas.
- Raízes das patas próximas desenhadas à frente do torso, expondo os cortes.
- Critérios anteriores de pivô, proporção e borda de atlas não detectavam cavidades pintadas dentro das peças.

Correção na revisão 3:

- Fonte corrigida com ImageGen em seamless-source.png: superfícies de papel fechadas, sem tubos ou pinos; fonte anterior preservada para comparação.
- Recortes regenerados; patas montadas sob o torso com sobreposição de raiz.
- Ordem de profundidade, tamanhos e pontos de união reajustados. Mantida postura horizontal e quadrúpede.
- Cinco poses renderizadas sobre fundo claro e escuro em review.png e sequência completa em review-full.png; atlas com 116 quadros e zero pixels na borda.

Limite: os testes estruturais não substituem inspeção artística. Esta revisão local não equivale à aprovação do autor nem à integração ao jogo. A correção também simplificou os detalhes dourados da fonte; esta mudança pode ser avaliada no Soulgen.
