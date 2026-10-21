# Cobertura da candidata

## Cobertura existente

| Caso/regra | Comportamento esperado, inclusive negação | Evidência | Estado |
|---|---|---|---|
| Economia e ownership | Não forjar proprietário, privilégio ou duplicar liquidação | `accounts.test.mjs`, `trail-rewards.test.mjs`, `trades.test.mjs`, `summon.test.mjs` | Automatizado, PostgreSQL local |
| Recuperação | Destino fixo, limite de envios, bearer confirmado, identidade arbitrária ignorada; entrada automática exige o mesmo ID do usuário atualizado e usa o e-mail do provedor. Falha posterior não mascara a troca já concluída | `accounts.test.mjs`; [flows](flows.md) | Automatizado com provedor simulado |
| UI de recuperação | Confirmar senha, não reenviar senha antiga do login, não persistir token, abrir a conta quando a sessão da recuperação é confirmada | `art.test.mjs` | Automatizado de UI/DOM |
| Limite da demo | Negar bairros futuros antes de reservar; preservar histórico antigo | `test.mjs`, `art.test.mjs` | Automatizado |
| Reconexão | Mesmo jogador/partida; sem nova reserva; chave inválida/removida negada; um socket assume o lugar | `test.mjs`, `realtime.test.mjs` | Automatizado HTTP e socket real local |
| Tutorial | Movimento, acerto, energia, efeito das quatro classes, esquiva e manobra | `first-flight.test.mjs` | Automatizado; replay visual com Carcará |
| Gift/checkpoints | Não repetir apresentação já dispensada; replay explícito preservado | `opening.test.mjs` | Automatizado |
| Layout/artes | Atlas, bounds, arquivos publicados, navegação e regras do mundo | `art.test.mjs`, `ui-kit.test.mjs`, `pilot-ui.test.mjs`, testes `world-*` e `neighborhood-road.test.mjs` | Automatizado; não é cobertura de todas as resoluções |
| Partida completa | Dois visitantes, três vitórias, recuperação dos dois lados, mesma revanche, limpeza das salas | `scripts/smoke-demo-release.mjs` | Executado localmente; execução remota precisa constar no relatório da publicação |

Suíte atual: 287 testes passaram, incluindo a entrada após recuperação, os diagnósticos de autenticação, a recusa de WebSocket expirado em uma sala congelada e o retorno da aba substituída sem liberar o lugar da nova conexão. Avisos explícitos de sessão precedem o fechamento do socket para não depender da velocidade de propagação do close. O pacote de instalação 017/018 possui mais um teste separado em `scripts/demo-opening-package.test.mjs`, que verifica preservação de coleções e concessão única do parceiro. O workflow `Demo validation` executa os dois builds, esse teste do pacote e `npm test` em PRs e pushes em main, sem segredos de produção. Publicar o workflow não equivale a configurar branch protection nem a fazer o Render esperar o CI.

## Testes propostos

| Caso | Tipo | Critério |
|---|---|---|
| Login e confirmação reais | Live com acompanhamento do proprietário | Perfil aparece; refresh mantém conta; e-mail chega e retorna ao domínio oficial |
| Recuperação real | Live, senha preenchida e confirmada pelo jogador | E-mail chega; link válido altera somente a própria senha; nova entrada funciona |
| Partida em duas redes | Manual com duas pessoas | Partida inteira, revanche, queda/retorno e resultados consistentes |
| Controle, celular e computador modesto | Manual | Ações acessíveis, texto sem corte e fluidez observada com aparelho registrado |
| Cinco jogadores novos | Manual, [roteiro](demo-playtest.md) | Registrar bloqueios e pedidos de ajuda sem ensinar comandos por fora |

## Lacunas que ainda impedem afirmar prontidão geral

1. Dados confirmados em PostgreSQL não são o mesmo que persistir a fila SQLite durante falha/redeploy. Sem teste de recuperação de desastre em produção.
2. Sem medição de carga, diversidade de redes e latência sob condições reais.
3. Sem conclusão de estudo com jogadores novos, controle físico e matriz completa de dispositivos.
4. Mock de e-mail prova contrato do código, não entrega do provedor nem configuração externa do SMTP.
