# Veskoro · batalha de Caio

## Entrega local

Novo nome aprovado e asset próprio no combate de Caio, nível27. O modelo deixa de inferir toda espécie somente da cor e passa a aceitar modelId explícito no adversário; os demais encontros preservam o mapeamento anterior. Defesa/reconquista selecionam a espécie do dono atual: um desafiante não herda o veneno de Caio. XP de reconquista de Veskoro mantém a curva usada no protótipo anterior, sem elevar recompensa.

Golpes alternados: jato numa faixa de32 unidades de meia-largura e nuvem de raio70. Alvo e origem fixados no início do aviso de1,35s; impacto único, efeito ativo0,55s e recuperação1,8s, seguida de3s de intervalo. Há contorno claro/escuro e aviso textual, além do roxo. Sair da área evita o golpe; guarda ou esquiva no impacto evitam dano e envenenamento. Acerto causa8 de dano-base à linha e três pulsos de2 durante3s, sujeitos ao modificador de nível já existente. Não danifica diretamente a armação nem acumula múltiplas aplicações. Veneno termina ao iniciar nova rodada; não vira condição permanente da conta.

Estado de aviso, alvo, impacto e veneno é serializado e validado. Saves antigos com Mata verde num duelo já iniciado continuam carregáveis; não há troca de espécie no meio desse encontro. Novos encontros usam Veskoro. Nenhum recibo ou emblema é reemitido pela mudança.

## Verificação executada

| Suíte | Resultado |
| --- | --- |
| Veskoro: aviso, sair da área, guarda/esquiva, dano limitado, fim do veneno, suspensão e dados inválidos |19 checks,0 falhas; inclui vitória real do loop de combate em três rodadas por controlador programado |
| Palafitas: serviço, save durante aviso, compatibilidade antiga, dono correto, fuga/derrota/recibos |112 checks,0 falhas |
| Bairros genéricos |452 checks,0 falhas |
| Morro |377 checks,0 falhas |
| Sinais de batalha |2635 checks,0 falhas |
| Recorte de batalha |7994 checks,0 falhas,46 casos de contato |
| Cantos do HUD |214 checks,0 falhas |
| Mormaço |44 checks,0 falhas |
| Espelhamento nativo por pixels |retângulo centrado e cores invertidas corretamente |

Cinco capturas1280×720 em OpenGL/Godot4.7.2 de fases que ocorreram naturalmente no controlador real, sem forçar resultado ou fase: aviso/impacto de jato, recuperação, aviso/impacto de nuvem. Inspecionadas: nome, arte, direção, faixa, círculo, texto e contagem do veneno. O teste de pixels confirma o comportamento padrão de espelhamento do renderer, que foi preservado.

## Limites

A vitória programada usa Rabbito de nível50 com bônus de criação12 contra Veskoro27; comprova conclusão mecânica, não balanceamento para jogador de nível27. Os resultados de fuga/derrota e liquidação da suíte Palafitas continuam fixtures. Não houve sessão humana completa por controle, teste de Steam/export ou economia online. O PNG é pose estática com efeitos procedurais; não declarar animação articulada concluída. Arena de telhado mantida, docas ainda pendentes. Não houve alteração de mapa, geometria ou kit.json.

Avisos do ambiente: cache de shader sem escrita; a suíte de Mormaço ainda reporta recursos em uso na saída, com contagem de falhas zero. A captura final registra as ações de controle antes de iniciar a cena e não tem os avisos de InputMap da primeira tentativa descartada.

Sem push, merge ou deploy nesta etapa. Prompts, fonte e metadados preservados no pacote de arte.

## Atualização · arena de Palafitas

O cenário de telhado foi substituído por arena original das docas para todos os duelos palafitas-*. As cinco capturas deste diretório foram atualizadas com o novo cenário. Removida a faixa de vegetação de terra firme. Repetidos19 checks de Veskoro e112 de campeonato, zero falhas; captura nativa das cinco fases concluída. Esta atualização substitui a pendência anterior de cenário das docas; animação articulada continua pendente.
