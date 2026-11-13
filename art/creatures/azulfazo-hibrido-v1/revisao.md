# RevisÃ£o â€” Azulfazo hÃ­brido

RevisÃ£o independente em 13/11/2026, com nota 7/10 e nenhum achado bloqueante apÃ³s a primeira rodada de correÃ§Ãµes. O crÃ­tico comparou as seis poses de caminhada nas duas vistas, as quatro poses de idle e o snapshot anterior. A versÃ£o revisada foi escolhida.

A leitura a frio identificou uma ave-pipa azul que alterna passos e dobra as asas. O primeiro resultado tinha pequenos resÃ­duos da antiga vareta ao lado da crista e pÃ©s claros sem garras bem separadas. Foram removidos os fragmentos nas coordenadas apontadas. Os pÃ©s ganharam trÃªs garras escuras distintas e apoio ajustado, e as asas recuperaram pontas de penas e trÃªs espirais contÃ­nuas. O corpo e o rosto continuam com a arte da fonte.

ConferÃªncia tÃ©cnica no Aseprite confirmou vinte quadros, cinco camadas e quatro tags. A imagem mesclada de cada quadro Ã© idÃªntica ao recorte correspondente do PNG exportado. Os atlas usam exclusivamente as 16 cores opacas da fonte, alpha binÃ¡rio e margens dentro das cÃ©lulas de 112 Ã— 112 px. O manifesto registra a Ã¢ncora (56, 100), as duas linhas SW/NW e os tempos dos ciclos.

Os vÃ­deos orientaram a abertura, a descida e o retorno das asas. As varetas, os painÃ©is e as penas foram desenhados novamente em cada chave, com alternÃ¢ncia das patas de apoio. NÃ£o houve extraÃ§Ã£o de pixels do vÃ­deo nem suavizaÃ§Ã£o das imagens finais.

Limites registrados pelo crÃ­tico e pelo autor: as asas ainda tÃªm uma superfÃ­cie contÃ­nua de leque mais evidente que as penas lobadas da base. A cauda permanece estÃ¡tica, e o idle usa uma amplitude pequena de acomodaÃ§Ã£o das asas. A versÃ£o estÃ¡ pronta para avaliar ritmo e contatos no Godot. A integraÃ§Ã£o e a conferÃªncia no jogo sÃ£o conduzidas separadamente.

## Integração local

Aplicado no Godot em 13/11/2026, com os PNGs autorados copiados sem reprocessar pixels. As 3.938 verificações da suíte de animação passaram. O playtest gráfico dos dois híbridos integrados passou em 672 verificações (336 por modelo): caminhada, corrida, quatro orientações, espelhamento, escala nativa e oclusão. Azulfazo foi registrado em 40 capturas de deslocamento e 12 de idle, em `tmp/overworld-hybrid/playtest/`. A inspeção da prancha das capturas confirmou integridade e escala do corpo e das asas. A ausência de deslizamento de pés não é certificada por esses testes; o GIF permite avaliar a cadência. A aprovação artística do novo Azulfazo pelo usuário permanece pendente; a revisão independente autorizou a integração local.
