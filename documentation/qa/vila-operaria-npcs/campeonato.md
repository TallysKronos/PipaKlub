# Fundação do campeonato da Vila Operária

Atualização posterior: os encontros A/B/C foram autorados para QA. Consulte `documentation/qa/vila-operaria-encontros/RELATORIO.md` para estado atual, rosters/recompensas provisórios e testes. O restante deste documento registra a etapa anterior, ainda sem duelos autorados.

Catálogo existente atualizado com elenco aprovado: Vasken21 e Rivka22 em A, Odrik22 e Teyra23 em B, Bruno24 em C. Níveis intermediários são proposta de curva dentro da faixa21–24 da bíblia; champion24 já definido. Diálogos antes/vitória/derrota em pares locutor/texto, com voz dos designs, sem novas revelações. Caminhos dos cinco sprites associados nas definições.

Bruno exige `pipaDragaoDesatadaVencida`, condição nova reservada para o resultado persistido da sequência do galpão. Nenhuma função a concede ainda. Essa condição impede que a implementação posterior dos quatro duelos permita pular o boss.

Estado deliberadamente incompleto: playable=false e authored=false preservados. Recompensas permanecem zero/provisórias; não foram inventados parceiros para esses personagens. O serviço não oferece encontros authored=false. Nenhum mapa, posição definitiva, encontro ou UI foi habilitado. Esta entrega fecha o catálogo e a lógica de qualificação, não o bairro jogável.

Testes executados headless Godot4.7.2: `vila_operaria_definition_checks.gd`62 verificações/0 falhas; `district_checks.gd`452/0. Primeiro testa nomes, cenas, sprites, pares de diálogo, faixa de nível, bloqueio por Cais, ordem, derrota/fuga sem qualificação, resultado obsoleto, pré-requisito de galpão, título, serialização e defesa perdida. Regressão genérica cobre os12 bairros e transações existentes. Não há combate ou save real da Vila Operária nesta rodada.

Próxima etapa: autoria dos mapas A/B/C e D, posições de encontros, rosters e balanceamento de recompensas; implementar a sequência Gollia/Retalho/Tyler/Pipa-Dragão e só então habilitar a campanha. Seguir skill de mapas antes de alterar geometria/eventos dos mapas.
