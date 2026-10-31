# Integração de claude/unificacao — 31/10/2026

Branch: codex/integracao-bosque-kronasta. Balanceamento preservado em e6e661f9; integração sem conflitos em 382dd6f6, incluindo os 19 commits até 97c81d9f.

Inclui Montanha e Pântano A/B/C como prévias independentes, kits, construtores, agente de personagens e correções de carregamento de sprites/testes/estado do Lacertubo após vitória. Não adiciona capítulos ou acessos narrativos aos mapas de prévia.

Verificado nesta integração:
- Node: 12 testes de modelo/Montanha/Pântano aprovados.
- campaign_view_checks: 25 verificações aprovadas, incluindo a regressão após vitória. O runner ainda avisa sobre recursos não liberados ao encerrar.
- Jornada com recompensas reduzidas: 157 verificações aprovadas. Seis duelos mais 12 selvagens levam ao nível 5; a regra do parceiro igual ao selvagem equivalente continua intacta.
- pantano_water_checks: zero falhas nas três partes.
- Percurso real automatizado: Montanha A/B/C, respectivamente 56/58/106 viagens, zero falhas; Pântano A, 74 viagens, zero falhas.
- Pântano B/C: percurso completo não concluído nesta rodada rápida. Revisão visual nova e controle humano não realizados; evidências anteriores dos autores estão nas pastas dos mapas.

Logs locais: tmp/playtest-humanlike/integration-*.log. Save pessoal preservado. Nenhum push nesta etapa.
