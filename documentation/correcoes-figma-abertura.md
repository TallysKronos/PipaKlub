# Abertura — correções da página Melhorias

Fonte: [Figma PipaKlub / Melhorias](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-674). Imagens e descrições dos seis frames foram lidas pelo conector oficial. Elas são registros de problemas do jogo, não telas para copiar literalmente. A engine Canvas/DOM e os assets aprovados foram preservados.

## Frame a frame

| Frame | Correção implementada | Consumidores |
|---|---|---|
| [1 · 85:674](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-674) | A final regional ocupa a cena inteira, com nomes legíveis, arena e as novas criaturas. Botões permitem acompanhar Jamile ou Gollia. A câmera do quarto deixa de ampliar a TV sete vezes; a transmissão pequena continua apenas como detalhe ambiental. A escolha de acompanhamento não altera o resultado narrativo. | `opening-client.js`, `opening-room-client.js`, `opening.css` |
| [2 · 85:675](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-675) | Etiquetas e atalhos de lugares ficam ocultos. Após 18 segundos de exploração, aparece a opção de pedir dicas; só então surgem pequenas setas. “Continuar depois” e sua ação por Esc/controle foram removidos do diálogo. A reprise mantém sua própria saída. Falas curtas avançam localmente; eventos concluídos são confirmados por checkpoint no servidor. | `opening-client.js`, `opening-room-client.js`, `accounts.js` |
| [3 · 85:676](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-676) | A bancada ocupa o palco inteiro em primeira pessoa, com fundo de madeira do kit existente, folha, vareta e encaixe. Arrastar/soltar aproxima a vareta da armação; soltar longe retorna a peça. Teclado e controle também pegam, movem e encaixam. A mão vem do mesmo renderer da Oficina v3, injetado por ambos os builds. A animação de conclusão mantém a transição de evento existente. | `opening-room-client.js`, `opening.css`, `switch-ui-client.js`, `build*.mjs` |
| [4 · 85:677](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-677) | Kael permanece na bancada enquanto a mãe sobe. Ao ela chegar, ele se assusta e vira para ela, sem caminhar para trás. Depois de guardar a rabiola, a mãe percorre a rota até a escada; o movimento do jogador é liberado ao fim desse trajeto. A mãe deixa de ser desenhada no nascimento no quarto; reaparece na sala. | `opening-room-client.js`, `opening-client.js`, `opening-story.js` |
| [5 · 85:678](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-678) | O clarão é seguido de uma reação de queda/recuperação, usando o avatar composto atual para manter cabelo, roupa e pele. A animação visual não bloqueia a sequência. Falas do nascimento usam “Avançar” com a pipa do kit; removida a espera pela aproximação do Rabbito. A fala deixa de chamar pela mãe que já desceu. | `opening-client.js`, `opening-room-client.js`, `opening-story.js` |
| [6 · 85:679](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=85-679) | Nomeação em tela cheia: Rabbito animado, origem, nível, elo e atributos base reais de linha, energia e velocidade, com campo e confirmação de nome. O formulário continua usando a operação restrita existente; não concede uma segunda cópia. Erros e estado de confirmação aparecem nessa mesma tela. | `opening-room-client.js`, `opening.css`, `opening-client.js` |

## Salvamento

Não há um intervalo universal recomendado para todo jogo. A [orientação de Game Saves da Microsoft](https://github.com/MicrosoftDocs/playfab-docs/blob/docs/playfab-docs/player-progression/game-saves/quickstart.md) inclui salvar após progresso significativo, como checkpoints e fim de níveis. Para esta abertura, os marcos são terminar a transmissão, construir a armação, iniciar a conversa, receber/usar a rabiola, concluir o nascimento, mudar de andar e sair de casa. O nome continua sendo confirmado pela função SQL existente.

O endpoint `checkpoint` agrupa o transporte e reaproveita as transições de `player_opening`: não instala SQL novo. Repetir um marco concluído não repete concessões. Uma falha pode deixar transições intermediárias persistidas; reler a abertura retoma o estado confirmado pelo servidor. Não há promessa de salvar cada fala local: ao fechar entre marcos, algumas falas podem ser reapresentadas.

No mundo, preservados o salvamento por mudança de lugar e a verificação de alterações a cada 30 segundos, quando o jogador está parado. Esse valor é uma escolha já existente no projeto, não uma recomendação universal da fonte. Acrescentada confirmação de checkpoint antes de iniciar chefe de Trilha; uma falha é informada antes da luta. A preferência de desativar autosave continua sendo respeitada.

## Limites e verificação desta entrega

- Não foi criado um spritesheet inédito de queda. A reação usa transformação do avatar já composto e mantém todas as camadas juntas. Uma pose anatômica de chão exigirá arte própria no Avatar Studio.
- A primeira bancada reutiliza a ilustração física do projeto e o fundo existentes. Não foram geradas novas ilustrações nesta correção.
- **Nenhum teste automatizado ou sessão de teste de gameplay foi executado**, por instrução expressa do usuário. Houve leitura das imagens/descrições, revisão estática, conferência de sintaxe e geração dos builds.
- Após a revisão local, o responsável autorizou subir esta entrega para o Git e o Render. A publicação não requer migração nem alteração no banco de produção. Os testes continuam não executados, conforme a orientação recebida.

## Segunda rodada: correções 7 e 8

- [7 · 87:685](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=87-685): direção numérica e direção do Avatar Studio agora acompanham a posição projetada do Rabbito durante o nascimento. Após a nomeação, Kael olha para o parceiro quando está parado; ao caminhar, o controle mantém a direção de movimento. A TV usa os quatro pontos da tela no PNG nativo 80×82, com transformação afim e clip no plano inclinado. A transmissão é desenhada junto da própria TV, dentro da ordem de profundidade, antes de personagens que a encobrem.
- [8 · 87:691](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=87-691): palco em tela inteira sobre preto, título superior oculto, diálogo flutuante central inferior com altura fixa por breakpoint e áreas reservadas para nome, fala, status e ações. Conteúdo longo rola dentro da área de fala; não reduz o canvas. O buffer e a câmera respondem só ao tamanho do palco, com espaço reservado para o diálogo. A dica deixa de herdar `top:0!important` do botão global, que a esticava como um pergaminho vertical.

Execução local solicitada, em banco isolado. `LOCAL_OPENING_REVIEW=1` permite entrar por `/local/davi` diretamente no nascimento, sem retroceder progresso já existente. `/local/kael` mantém a abertura normal. Nenhum teste automatizado executado, nenhuma publicação ou mudança no banco de produção nesta rodada.
