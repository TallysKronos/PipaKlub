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
| 10 | PIP-135 | Pipa Dex, evolução, Varal, 12 emblemas | Implementada localmente; revisão artística v2 após crítica ao aspecto chapado. 810 checks de menus e 292 de regressão do diálogo; ver pip-135/REVISAO.md. Aprovação visual do dono ainda não declarada |
| 11 | PIP-136 | Resultado e grandes momentos | Integrada localmente; três chamadas ilustradas, prévia explícita, nível após gravação e momentos de item/insígnia. 3.298 verificações incluindo regressão, 72 capturas; ver pip-136/REVISAO.md |
| 12 | PIP-137 | Transições e sons | Implementada localmente: cortina Mural, gate de primeiro frame, foco, áudio de viagem no bus UI e prioridade de jingles. 55 checks e 24 capturas; ver pip-137/REVISAO.md |
| 13 | PIP-138 | Acessibilidade | Implementada e auditada localmente: texto 150% persistido, foco por forma, dano legível em movimento reduzido, contraste do boss e apresentações ampliadas. 2.176 checks, 20 casos de contraste, 40 capturas; ver pip-138/REVISAO.md |
| 14 | PIP-139 | Auditoria final e HUD-KIT v2 para a campanha PIP-91 | Parte técnica e guia entregues localmente: 296 capturas, correções de layout, 84 checks novos e inventário real de 17 tarefas. Aceite externo e destinos de absorções parciais pendentes; ver pip-139/REVISAO.md |

O agrupamento individual PIP-130/131 e PIP-132–137 segue a ordem descrita pelo dono; conferir os títulos exatos no Linear antes de atualizar tarefas.

## Relação com PIP-61

A direção B foi escolhida na PIP-129. A consulta da PIP-139 encontrou 17 subtarefas reais (15 abertas), agora mapeadas em ABSORCAO-PIP-61.md. Há absorções parciais; nenhum ticket foi fechado. Preservar Theme, tokens, fontes/licenças e testes de margem úteis. O vínculo entre os dois épicos foi conferido em leitura, sem alterações no serviço.

## Restrições e provas

- Quatro resoluções e teclado/controle/mouse. As suítes consultadas cobrem principalmente três resoluções; proposta inicial de quarta: 1280×800, além de 1280×720, 1920×1080 e 1024×768. Confirmar se a descrição do épico prescreve outra.
- Sem merge até autorização explícita. Não há autorização permanente de push derivada do pedido anterior de envio da montaria.
- Nenhum gameplay/save/runtime foi alterado na PIP-126.
- Nas etapas iniciais o conector estava indisponível; na PIP-139 foi possível consultar a tarefa e o épico antigo. O inventário e suas descrições foram registrados localmente. Não há mudanças de status no serviço.

## Pontos de entrada

Agente: `.codex/agents/designer-de-hud.toml`.
Skill: `.agents/skills/soulmonsters-designer-de-hud/SKILL.md`.
Invocação: «Use o agente designer-de-hud para trabalhar na PIP-127».
A criação do arquivo não prova registro dinâmico no app já aberto; se a lista de agentes não atualizar, reabra a sessão. A skill também pode ser invocada diretamente pelo caminho.
