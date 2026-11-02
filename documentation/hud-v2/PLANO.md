# HUD autoral do Soulmonsters — plano de execução

Origem: instrução do dono nesta conversa, 01/11/2026. Branch de trabalho: `codex/hud-identidade-soulmonsters`. Nenhum merge autorizado. Este documento acompanha trabalho local; não declara sincronização com o Linear.

Critério central: uma captura sem logo precisa ser reconhecível como Soulmonsters pela própria HUD. Matérias: pipa, bairro de Kronasta, almática, Elo e Pipa TV. A infraestrutura Recorte pode ser reaproveitada; sua estética não é a resposta automática.

| Ordem | Tarefa | Entrega/limite | Estado local |
| --- | --- | --- | --- |
| 1 | PIP-126 | Agente designer-de-hud e skill própria | Implementado; validação registrada em PIP-126.md |
| 2 | PIP-127 | Benchmark dos sete jogos; 10 princípios próprios | Estudo local entregue; 27 evidências, versões e limites em PIP-127.md |
| 3 | PIP-128 | A papel/vareta; B muro; C carretel/Elo; 3 mocks por direção | V1 rejeitada; B ilustrada v2 preferida pelo dono e adotada na PIP-129 |
| 4 | PIP-129 | Escolher direção e registrar justificativa | B — Mural de Kronasta; decisão local em DECISAO.md |
| 5 | PIP-130 | Forma-assinatura, paleta, tipografia, ícones e Theme | Fundação opt-in e ícones salientes implementados; 978 checks novos passaram; auditorias legadas falham em fontes inalteradas, ver PIP-130.md |
| 6 | PIP-131 | Logo e tela de título | Marca e menu real implementados; 336 checks novos, 16 capturas em quatro resoluções; ver PIP-131.md |
| 7 | PIP-132 | Exploração e Kronasta | Integrada à HUD compartilhada e carta regional; 616 checks novos, 153 do Atlas, 163 nativos da exploração; ver PIP-132.md |
| 8 | PIP-133 | Batalha, VS de campeão, enroscada | Integrada; área segura compartilhada, 792 checks novos e 10.428 de padding nativo; ver PIP-133.md |
| 9 | PIP-134 | Diálogo | Integrado ao diálogo compartilhado e à abertura; 384 verificações sem falhas, quatro resoluções e texto 100/150%; ver pip-134/REVISAO.md |
| 10 | PIP-135 | Pipa Dex, evolução, Varal, 12 emblemas | Próxima etapa |
| 11 | PIP-136 | Resultado e grandes momentos | Pendente do sistema |
| 12 | PIP-137 | Transições e sons | Pendente das telas |
| 13 | PIP-138 | Acessibilidade | Critérios desde o início; auditoria consolidada ao final |
| 14 | PIP-139 | Auditoria final e HUD-KIT v2 para a campanha PIP-91 | Pendente da implementação |

O agrupamento individual PIP-130/131 e PIP-132–137 segue a ordem descrita pelo dono; conferir os títulos exatos no Linear antes de atualizar tarefas.

## Relação com PIP-61

A direção B foi escolhida na PIP-129. Levantar IDs/títulos reais das 12 tarefas antigas e mapear cada uma para absorção em tarefa nova ou encerramento como substituída; inventário ainda pendente, critérios em ABSORCAO-PIP-61.md. Não reabrir trabalho visual antigo em paralelo por hábito. Preservar Theme, tokens, fontes/licenças e testes de margem úteis. O vínculo entre os dois épicos foi informado pelo dono; não foi alterado nem auditado nesta sessão.

## Restrições e provas

- Quatro resoluções e teclado/controle/mouse. As suítes consultadas cobrem principalmente três resoluções; proposta inicial de quarta: 1280×800, além de 1280×720, 1920×1080 e 1024×768. Confirmar se a descrição do épico prescreve outra.
- Sem merge até autorização explícita. Não há autorização permanente de push derivada do pedido anterior de envio da montaria.
- Nenhum gameplay/save/runtime foi alterado na PIP-126.
- Conector Linear indisponível nesta sessão. Os IDs e a sequência vêm da instrução do dono; não há mudanças de status no serviço.

## Pontos de entrada

Agente: `.codex/agents/designer-de-hud.toml`.
Skill: `.agents/skills/soulmonsters-designer-de-hud/SKILL.md`.
Invocação: «Use o agente designer-de-hud para trabalhar na PIP-127».
A criação do arquivo não prova registro dinâmico no app já aberto; se a lista de agentes não atualizar, reabra a sessão. A skill também pode ser invocada diretamente pelo caminho.
