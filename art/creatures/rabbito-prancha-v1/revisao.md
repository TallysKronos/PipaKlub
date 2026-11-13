# Revisão — rabbito

Data: 2026-11-13. Crítica independente: `/root/animation_pixel_critic`, 7/10 após R1. Sem bloqueio residual de porte/anatomia. A primeira versão foi bloqueada por perda de volume e aparência mais adolescente. A correção recupera cabeça/peito arredondados e pés mais curtos, mantendo orelhas, cauda e direções. Resta pequena diferença de massa entre idle e walk, não bloqueante; conferir troca de estados e ritmo no renderer. Escolha independente: DEPOIS, sem necessidade de nova rodada ampla.

## Método e verificações

Quatro gerações ImageGen de caminhada (duas iniciais e duas correções R1), seis poses por vista. Originais e snapshots de antes preservados; overrides explícitos apontam somente para gerado-walk-sw-r1.png e gerado-walk-nw-r1.png. Importação de grade, escala comum por folha, paleta e alfa finalizadas no Aseprite. Nenhum desenho regional de membros foi aplicado por deformação. Idle autorado da pose de repouso aprovada, com quatro quadros por vista e ciclo 750/200/750/200 ms.

A auditoria confirma cabeça, apoios, silhueta e pixels fora da região de peito idênticos à fonte. A variação de 2–4 pixels internos é sutil e pode ser quase imperceptível a 1×; não há arranco ou translação global.

QA: 20 poses, zero erros mecânicos de alfa/paleta/limites/ilhas mínimas. ASE reaberto: 20 quadros, três camadas, quatro tags, pixels achatados idênticos aos atlas exportados. Arquivos: `validacao.json`, `auditoria-aseprite.json`, `idle-regioes-protegidas.json`.

A aprovação mecânica não substitui a avaliação visual; a integração não foi modificada. O lote contém 12 gerações de walk (10 iniciais + duas correções do Rabbito), 72 poses geradas e 40 quadros de idle autorados; os atlas finais contêm 60 poses walk + 40 idle, sem vídeos e sem gerações de idle. Não há medição comparável para afirmar economia percentual de tempo ou tokens.

A correção foi isolada: hashes confirmam cinco idles e os quatro outros atlas walk intocados. A nova importação foi feita no Aseprite; ASE/PNG novamente idênticos.

## Integra��o e teste

Integrado localmente. Rodada final: 4.042 verifica��es de anima��o e 1.672 verifica��es gr�ficas dos cinco modelos, sem falhas nessas su�tes. Caminhada, corrida, dire��es, espelhamento, oclus�o e escala nativa. Por modelo: 40 capturas de movimento e 16 de idle (2,4 s), em tmp/overworld-pranchas-lote-03/playtest/. Inspe��o de captura confirmou integridade e escala; n�o certifica aus�ncia de deslizamento nem equivale a regress�o completa da campanha. PNGs de fonte e runtime s�o id�nticos.
