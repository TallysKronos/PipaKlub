# Demo: correções após o teste de jornada

Implementação local baseada na [auditoria da jornada](art/ui-reviews/demo-journey-2026-10-20/AUDITORIA-DEMO.md). Não houve push, publicação no Render ou alteração no Supabase de produção.

## Conteúdo da versão

- A aplicação e o servidor estão em modo demo: abertura, primeiro voo, cinco encontros do Morro do Sol e modalidades online existentes.
- Beira-Mar e Campanários ficam fora do recorte, mesmo em contas com vitórias antigas. Os registros anteriores são preservados.
- O servidor recusa iniciar esses encontros antes de reservar parceiro ou criar partida. Esconder um botão não é a única proteção.
- Mikka encerra a história desta demo. O resultado confirmado oferece concluir a demo; a missão na praça permite rever a conclusão. O encerramento leva a jogar com amigos, invocar ou revisitar o Morro. A saída final do percurso também usa esse encerramento.

## Online

- O identificador privado da sessão existente fica no armazenamento da aba, separado por código e conta. Não entra no convite nem nos snapshots públicos.
- Nas salas privadas e partidas rápidas identificadas pelo convite na URL, recarregar a mesma aba autenticada tenta retomar o mesmo jogador, na mesma partida. Não cria outro parceiro, reserva ou recompensa. Esta rodada não adiciona retomada automática dos duelos solo após recarga.
- A entrada manual pelo código também tenta retomar a sessão salva antes de pedir um novo lugar.
- O lugar desconectado fica disponível para recuperação por até 60 segundos. Seus comandos param após 500 ms sem atualização; o adversário continua jogando. Isso não concede invulnerabilidade.
- Uma conexão WebSocket nova assume o lugar da anterior. A aba substituída retorna ao quintal, em vez de disputar os comandos do mesmo jogador.
- Sair explicitamente apaga a sessão da aba e libera o lugar. Sessões inválidas ou removidas não podem ser ressuscitadas. Uma nova aba, outro navegador ou armazenamento bloqueado podem exigir entrada normal.
- A reconexão depende do servidor e da partida ainda existirem. Não cobre reinício do serviço nem queda longa de conexão.

## Tutorial e interface

- Ataque é clique/Espaço; habilidade do parceiro é Q/E; esquiva é Shift; rebicada é segurar/soltar R. As instruções distinguem as ações e se adaptam a teclado, toque e controle.
- A quarta lição observa o efeito real de cada classe: acerto com efeito, dash, proteção recebendo um acerto ou foco. Depois exige uma esquiva e a conclusão de uma manobra da linha.
- Os cinco checkpoints existentes continuam válidos. A prática não altera o inventário nem concede prêmios.
- A leitura de alvo segue o mesmo critério do servidor: cruzamento válido mais próximo do centro da faixa inimiga. O aviso identifica esse rival.
- Instruções de movimento da abertura voltaram a aparecer. Botões do treinador preservam o texto e quebram a fileira quando necessário.
- Resultados levam o foco à ação útil de continuação ou revanche. O convite recebido foca Entrar. Código curto recebe mensagem em português explicando o formato.
- Código da sala permanece em uma linha. Bots aparecem como IA; a partida rápida informa sua quantidade.
- O nível do jogador é identificado como Pipeiro. O histórico do parceiro explica que as transferências de Vale pipa não representam vitórias da história.

## Primeira invocação

- Há ensaio gratuito do feitiço, sem chamadas de início de ritual, tentativas gastas, consumo de rabiolas ou alteração de coleção.
- Para a conta com apenas seu primeiro parceiro, concluir o ensaio libera o início do ritual daquele alvo. A constelação do ensaio usa as mesmas regras de sequência da invocação.
- O ritual real conserva suas regras anteriores: consumo ao iniciar, três tentativas e dano ao interromper.
- A confirmação oferece Ver meu novo parceiro. O botão abre a coleção no exemplar retornado pelo servidor e leva ao comando de equipar.

## Verificação

- Suíte completa: **277 testes passaram**, incluindo PostgreSQL local, servidor HTTP, sockets reais, recuperação sem nova reserva, invalidação de sessões, conta diferente, conteúdo futuro e ensaio sem consumo.
- Após as duas últimas mudanças de texto/foco, repetidos os testes de resultados e das telas afetadas.
- Os dois builds foram regenerados: Worker e Pages. `git diff --check` sem erros.
- Navegador, banco isolado: Kael e Ana entraram na sala C6EDBB; recarga de ambos preservou P1/P2, código, rodada e placar. Comandos do convidado continuaram funcionando.
- Repetidas as cinco lições com Carcará, incluindo ativação seguida de acerto, esquiva, manobra completa e corte de Nozinho. O replay preservou 200 moedas e a coleção da história.
- Conferidos o final e o bloqueio de Beira-Mar com o Morro já concluído.
- Conta de fixture Beto: completado o ensaio do Javali de Biscoito pelo padrão mostrado, sem iniciar um ritual real.
- Prints em [art/ui-reviews/demo-fixes-2026-10-20](art/ui-reviews/demo-fixes-2026-10-20).

## Ainda antes de divulgar a demo

1. Validar login/e-mail de produção, uma partida privada inteira com duas pessoas ativas em redes distintas, latência e queda de conexão real.
2. Conferir controle físico/Steam Input, resoluções menores e aparelhos móveis. Os testes de regra de todas as classes passaram; o replay visual desta rodada usou Carcará.
3. Ajuste cosmético restante da auditoria: apresentação do presente da mãe pode se repetir ao recarregar antes do próximo checkpoint; não foi observada duplicação de parceiro ou prêmio.
4. Fazer playtest com jogadores novos para avaliar entendimento, ritmo e dificuldade. Automação de comandos não substitui essa avaliação.
