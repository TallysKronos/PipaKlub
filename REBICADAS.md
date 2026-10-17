# Rebicadas no combate normal

As seis manobras usam o motor compartilhado `src/engine.js`, tanto no treino quanto nas salas online. O Duelo nas Alturas continua um laboratório local separado.

Escolha a rebicada e o lado no painel da arena. Segure **R** (ou o botão Rebicar) e solte para executar; a tensão é liberada automaticamente após 1,2 s. **Q/E** continuam ativando a habilidade do tipo de Pipamon. A energia é descontada ao tensionar; errar não devolve o custo.

| Manobra | Energia | Recarga | Efeito |
| --- | ---: | ---: | --- |
| Puxão | 28 | 4 s | Desce e sobe; 32 de desgaste na retomada, se houver cruzamento válido. |
| Chicote lateral | 26 | 4,5 s | Varre para o lado escolhido; 24 de desgaste. Recuperação de 0,85 s ao errar. |
| Estilingue | 32 | 5 s | Recua e dispara na direção da linha; 28 de desgaste. |
| Laço | 30 | 5 s | Faz uma volta para mudar o cruzamento; 20 de desgaste. Receber acerto interrompe a volta. |
| Folha solta | 20 | 3,5 s | Reposiciona cedendo linha. Sem dano ou invulnerabilidade. |
| Duplo toque | 30 | 4,5 s | Dois pulsos, de 8 e 18. O segundo remove Linha firme ativa e ignora sua redução de dano. |

Cada pulso precisa cruzar a faixa vulnerável de uma linha inimiga e atinge no máximo um alvo. Proteção de nascimento e esquiva continuam válidas; Linha firme reduz o dano, exceto no segundo pulso do Duplo toque. Linha encerada do Céu do dia mantém seu multiplicador. Cortes, XP e captura usam o fluxo existente verificado pelo servidor.

O protocolo envia um identificador crescente por gesto, escolha, lado e estado pressionado. O servidor valida o catálogo, energia, recarga e janela de ataque; nunca aceita dano ou trajetória enviados pelo cliente. Comandos repetidos ou recusados não são reexecutados depois da recarga. A previsão local clona os estados de animação para não alterar o histórico autoritativo.

Validação: suíte `npm test`, incluindo gestos duplicados, 30/60 Hz, acertos e erros, interrupção, defesa, fases da rodada, previsão local, interface e transporte HTTP/WebSocket.
