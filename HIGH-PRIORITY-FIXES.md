# Correções de alta prioridade — 18/10/2026

As sete demandas High da auditoria foram implementadas na branch feature/ui-kit-consistente e validadas no ambiente local.

| Linear | Correção |
| --- | --- |
| PIP-15 | Pausa autoritativa nos duelos privados das Trilhas. Congela simulação, bots e relógios; ajuda abre acima da pausa; retomada explícita. Partidas multiplayer não podem ser pausadas. |
| PIP-16 | Zeca, Bia, Juninho, Lia e Tião visíveis nos locais do Morro, usando as artes existentes. Mikka continua oculta até desbloquear o encontro final. |
| PIP-17 | Objetivo indica o rival e o lugar, muda para conversar ao se aproximar e conduz ao encontro pelo botão da missão. |
| PIP-18 | Jornada concluída reconhece os quinze encontros disponíveis; oferece revisitas sem prometer bairros ainda em preparação. |
| PIP-19 | Texto claro no céu noturno das trocas e cabeçalho legível no mapa. |
| PIP-20 | Criar/entrar em convite e ações da negociação antes da cena decorativa; retrato de coleção limitado; ações de equipamento visíveis e acompanhando a rolagem. |
| PIP-21 | Seletor da coleção dentro da preparação do duelo, equipamento confirmado no servidor e retorno ao mesmo encontro. |

## Validação

- Build do servidor e das páginas concluídos; artefato ESM validado.
- Suíte final: **201 testes passaram, zero falhas**. Inclui segurança da pausa, retomada, expiração sem dono conectado, previsão de rede, objetivos, líder oculto, equipamento confirmado, ajuda, multiplayer, economia e recompensas.
- **12 casos de layout sem falhas**, em 854×612 e 1280×720, cobrindo coleção, trocas, mapa, apresentações e seletor. As ações principais também são verificadas dentro da primeira área visível.
- No navegador, o duelo real foi pausado durante a segunda rodada em 00:53. Relógio, linha, energia e placar permaneceram iguais enquanto a pausa estava aberta. A ajuda foi aberta/fechada sem retomar o duelo; Continuar retomou a partida.
- Troca real de equipamento local: Mata verde → Azulão, mantendo o encontro com Zeca. A conta conservou a propriedade dos itens.
- Estado de conclusão conferido na conta local Beto com os três bairros vencidos.

## Limites e estado de entrega

Sem novas migrações. A pausa depende de sessão ativa: se o dono desconectar e a sessão expirar, o duelo é encerrado sem inventar resultado. As artes de presença no mundo são poses estáticas; não foram criadas animações novas de caminhada dos rivais.

Não houve teste em controle físico, Steam ou Nintendo Switch. Esta etapa não inclui os treze itens Medium/Low da auditoria.

As sete tarefas foram registradas como concluídas localmente no Linear. A principal PIP-14 permanece em andamento. **Sem merge ou deploy**; o ambiente http://127.0.0.1:5194/ está atualizado.

## Evidências

- [Rival no mundo e objetivo contextual](art/player-flow-audit/alta-prioridade-rival-objetivo.png)
- [Seletor de parceiro](art/player-flow-audit/alta-prioridade-seletor-parceiro.png)
- [Coleção com ações visíveis](art/player-flow-audit/alta-prioridade-colecao-acoes.png)
- [Trocas com contraste e convite acessível](art/player-flow-audit/alta-prioridade-trocas-contraste.png)
- [Pausa confirmada em rodada ativa](art/player-flow-audit/alta-prioridade-pausa-confirmada.png)
- [Ajuda sem retomar o solo](art/player-flow-audit/alta-prioridade-ajuda-solo.png)
- [Comparação dos estados visíveis durante a pausa](art/player-flow-audit/alta-prioridade-pausa-prova.json)
- [Jornada concluída](art/player-flow-audit/alta-prioridade-jornada-concluida.png)
- [Resultados da geometria](art/player-flow-audit/alta-prioridade-geometria.json)

## Áreas principais alteradas

src/engine.js e src/backend.js: autorização e simulação pausada. src/network-view.js: renderização sem previsão durante pausa. src/index.html: confirmação da pausa, ajuda e foco. src/world-client.js: rivais e contexto. src/plaza-policy.js e src/plaza-client.js: objetivo e conclusão. src/trails-client.js: escolha de parceiro. src/trade-client.js e src/ui-kit.css: hierarquia e contraste. Testes de regressão e prévias de auditoria ampliados.
