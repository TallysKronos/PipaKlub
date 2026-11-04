# Trilha · segunda rodada

Novas composições solicitadas depois da pesquisa em `documentation/curso-trilha-soulmonsters.md`. V1 preservada: 01 rejeitada, 02 e 03 com interesse parcial.

Três novas gerações locais ACE-Step 1.5 Turbo, oito passos, sem API paga. Os fluxos passaram em validação com zero erros e zero avisos. Prompts, tonalidade, andamento e duração pedidos em `prompts-v2.json`; jobs em `jobs-v2.json`; arquivos e medições em `manifest-v2.json` após a exportação.

| Arquivo | Mudança de briefing | Planejamento solicitado |
| --- | --- | --- |
| 01-vila-v2 | Recomeço: sopros como voz principal, frase articulada, baixo independente; retirar violão e piano elétrico de clima lounge | Sol maior, 112 BPM, 32 compassos, ~68,57 s |
| 02-parque-v2 | Flauta com motivo curto e pausas; marimba responde nos espaços; contraste central | Ré maior, 120 BPM, 32 compassos, 64 s |
| 03-batalha-v2 | Gancho rítmico entre metais e sintetizador, baixo móvel; contraste luminoso e volta tensa | Mi menor, 152 BPM, 32 compassos, ~50,53 s |

O planejamento orienta o modelo; não comprova notas, forma, instrumentação ou BPM efetivamente gerados. Estas são novas composições independentes, não edições que preservam as melodias da V1. A avaliação musical cabe à escuta; os três retornos não foram transcritos nem certificados como loops perfeitos.

FLACs originais em `originals/`, prévias MP3 em `previews/`, com folga de 4 dB. Verificação: decodificação integral, duração e níveis medidos. Os campos de tom, BPM e compassos continuam sendo parâmetros solicitados. Nenhuma integração, publicação ou teste de gameplay.

Preparar novamente com `tools/prepare-soundtrack-study.py --version v2`. Nenhuma amostra de Pokémon ou dos MP3s de referência foi enviada como entrada ao modelo.
