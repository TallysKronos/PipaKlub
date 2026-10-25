# Orientação da demo — proposta

Base: observação manual da jornada em 25/10/2026, skills game-ui-ux e level-design. Proposta de próximos ajustes; não representa comportamento já implementado.

## Objetivo por etapa

Reaproveitar a clareza do objetivo da missão de Nina, com uma frase e destino concreto, sem checklist de etapas na HUD.

| Momento | Objetivo visível |
| --- | --- |
| Quarto antes da criação | Termine sua primeira pipa na mesa. |
| Rabbito nasceu | Desça e mostre seu parceiro à sua mãe. |
| Saída de casa | Encontre Sr. Assis na casa ao lado. |
| Treino concluído | Escolha sua rabiola e monte a pipa na Oficina. |
| Tutorial concluído | Escolha seu próximo caminho: Morro do Sol ou além da cidade. |
| Pedido de Nina aceito | Recupere a rabiola nas Veredas. |

A conclusão deve vir do estado persistido da campanha, evitando instruções atrasadas após recarregar a página. Na Oficina, o tutorial só termina após o nascimento confirmado pelo servidor.

## Direção no mundo

1. Distinguir a casa do professor com marco exclusivo, placa legível e símbolo de treino. Posicionar placas antes das bifurcações, com os nomes reais dos destinos.
2. Transformar saídas em passagens visuais claras. Quando bloqueadas, explicar a condição concreta: “Termine sua pipa na mesa antes de descer”.
3. Oferecer “Mostrar dica” para apontar o destino imediato com marcador temporário na borda da tela. Esconder ao chegar; preservar a exploração do labirinto e do minimapa.
4. Ao fim do tutorial, apresentar os dois caminhos e seus propósitos. Antes do boss, explicar que nível recomendado 15 é o do parceiro e indicar onde se preparar.

## Critérios para revisão manual

Um jogador novo identifica o próximo destino sem usar o menu de desenvolvimento; as placas correspondem às saídas reais; objetivo muda após concluir ou recarregar; dicas não cobrem comandos; entradas bloqueadas explicam o motivo. Verificar primeiro o percurso quarto → professor → Oficina, depois as duas rotas da demo.

## Salvamento: diagnóstico independente

O erro observado na Oficina não depende exclusivamente do ambiente local. `src/accounts.js` limita a rota workshop-v3 a 120 requisições por jogador/IP em 15 minutos, incluindo leituras e salvamentos. O cliente envia eventos pendentes aproximadamente a cada três segundos e registra ticks durante a montagem ativa. Uma sessão demorada pode consumir essa cota. O servidor local usa o mesmo módulo; não houve reprodução equivalente em produção nesta revisão.

Correção pendente: separar a proteção das operações de início/nascimento da frequência dos checkpoints e reduzir o tráfego de progresso sem comprometer o diário recuperável, a validação no servidor ou a idempotência. Não basta remover o limite global nem atribuir o erro ao localhost.
