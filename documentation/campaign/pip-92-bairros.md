# PIP-92 — Fundação dos bairros no Godot

Implementada no branch `feature/pip-92-bairros-campeonato`. Nenhum mapa foi alterado.

## Comportamento

- Catálogo JSON dos 12 bairros, cinco etapas por bairro, distribuídas em A/A/B/B/C. Apenas o Morro tem encontros autorados e jogáveis; os demais registros reservam a estrutura sem inventar capangas, falas ou recompensas.
- Quatro vitórias liberam o campeão. A primeira conquista preserva as recompensas existentes, concede o emblema e registra o próximo bairro e áreas da trajetória 2.
- Conclusão histórica e posse atual do título são independentes. Perder uma defesa não apaga emblemas, estrelas ou acesso conquistado.
- Depois da conquista, conversar com um capanga do Morro oferece um desafio persistente. É possível adiar a resposta. Fechar o jogo não causa derrota automática.
- Vitória mantém o título. Derrota ou fuga explícita entrega o título ao desafiante; exige quatro novas vitórias antes da reconquista. O novo ocupante aparece no encontro final, inclusive com seu sprite existente.
- Reconquista não repete prêmio de primeira conclusão nem diálogo histórico. A contagem da história usa as conclusões dos bairros, sem depender exclusivamente de `morro-5`.

## Dados e integração

`godot/assets/campaign/championship/districts.json` define etapas, NPCs, partes, diálogos, recompensas e desbloqueios. `playable`/`authored` distinguem conteúdo pronto de reservas de autoria. A Beira-Canal reserva o requisito `comportaVeredasAberta`; sua missão ainda precisa publicar essa flag.

`district_rules.gd` é um redutor puro. `prepare` valida a etapa e fixa modo, adversário, desafio e época. `settle` calcula o novo estado; `award_emblem` aplica a premiação idempotente. O adaptador de combate deve gravar esse resultado junto com recompensas e recibo na mesma operação, como faz `morro.gd`.

Saves antigos continuam aceitos sem alteração da versão principal. A extensão opcional `player.championship` tem versão 1. Estrelas antigas do Morro são interpretadas de modo aditivo; um ciclo de requalificação já existente nunca é reconstruído a partir dessas estrelas. Versões futuras da extensão são recusadas como futuras, sem sobrescrever o arquivo.

No armazenamento local, resultado, título, qualificação, emblema e recibo usam a mesma gravação. Falha de escrita não publica o novo estado. Revisões obsoletas de outra sessão são rejeitadas. O contexto serializado normaliza os números após JSON.

## Verificação

Godot 4.7.2: `district_checks.gd` 450 verificações; `district_flow_checks.gd` 13; `morro_transaction_checks.gd` 42; `campaign_checks.gd` 206; `kronasta_regions_checks.gd` 88; `campaign_view_checks.gd` 25; `emblem_case_checks.gd` 61; `pipeiro_identity_checks.gd` 60. Todas passaram.

Os testes cobrem progressão dos 12 registros, requisitos, migração, persistência do desafio, defesa vencida/perdida, fuga, requalificação, reconquista, recompensa única, falha de escrita e sessão obsoleta. A integração visual percorre páginas e botões reais do diálogo e abre a batalha; usa resultados de combate preparados para verificar a liquidação.

Capturas nativas em `documentation/qa/pip-92/`: desafio, confirmação, requalificação e novo campeão. Revisadas em 1280×720. As suítes de emblemas e identidade emitem avisos preexistentes sobre carregamento direto de imagens do professor (`professor_modern.gd:65`), potencial problema de exportação; isso não foi corrigido nesta demanda.

## Limites e próximos passos

- A garantia de prêmio único desta entrega é por save/jornada local. Certificação online e unicidade por conta entre saves exigem implementação no servidor; este armazenamento não é uma autoridade antitrapaça nem um bloqueio entre processos.
- Frequência automática de desafios ainda depende de design; o gatilho atual é conversar com um capanga enquanto detém o título.
- Os outros 11 bairros precisam de encontros, mapas e adaptação de combate. Próxima autoria: PIP-105, Vila do Bambuzal.
- A conclusão dos 12 libera a condição do campeonato municipal; a sequência de batalhas finais ainda não foi autorada.
- Não foi realizada partida completa manual com controle físico, exportação de distribuição ou teste online. Nenhum push, merge ou deploy foi feito.
