# Morro do Sol — Lugares, arenas e retorno à exploração

18/10/2026 · feature/ui-kit-consistente · Ambiente local. Sem merge ou deploy.

## Implementado

Cinco cenários inéditos, com céu amplo e composição contínua, são selecionados pelo identificador real do encontro:

| Encontro | Lugar | Arena |
|---|---|---|
| morro-1 | Praça de chegada | Praça, portão e piso com rosa dos ventos |
| morro-2 | Escadaria da sombra | Escadaria, árvore e casas do morro |
| morro-3 | Laje dos ventos | Terraço, parapeito e carretéis |
| morro-4 | Mirante da caixa-d’água | Mirante com torre, montanhas e baía |
| morro-5 | Parque dos Ventos | Gramado, coreto e luz de fim de tarde |

A seleção no mapa abre uma apresentação do lugar e do adversário. A partida só é solicitada ao servidor ao confirmar “Começar duelo”. A tela não consome o tempo de uma rodada. Cancelar preserva o bairro e o foco do comando anterior. A apresentação recebe foco exclusivo; os controles do bairro ficam inertes enquanto ela está aberta.

Mikka aparece na apresentação do encontro final somente quando os quatro lugares anteriores foram vencidos. A arte existente da personagem foi reaproveitada.

Os resultados oferecem retorno ao mapa do bairro. Uma vitória confirmada marca o local com seu progresso e seleciona o próximo lugar liberado. Se a confirmação ainda não chegou, a interface mostra a espera e não concede desbloqueio antecipado; a próxima sincronização atualiza o destaque. A derrota mantém a etapa e oferece nova tentativa. Revanche também passa pela apresentação e preserva uma saída para o mapa.

Falha no carregamento de uma arena usa o cenário de reserva. Assets não condicionam concessão de moedas, itens ou propriedade.

## Assets e prompts

Geração com a skill imagegen e a ferramenta integrada, uma chamada por arena. A imagem do mapa do Morro do Sol foi referência de estilo. Os cinco originais foram preservados; as cópias de produção estão no projeto, servidas com hash e incluídas na versão estática.

Raiz do projeto: C:/Users/Usuário/Documents/Codex/2026-10-17/referenced-chatgpt-conversation-this-is-an/PipaKlub.

Arquivos de produção: assets/backgrounds/arena-morro-1-v1.png até arena-morro-5-v1.png. Manifesto: assets/encounter-scenes.json. Prompts finais completos: arenas-morro-prompts.json nos outputs desta conversa, e assets/arena-morro-prompts.json no projeto.

## Verificação

- Build do servidor e da versão estática concluídos; artefato ESM validado.
- Testes novos cobrem apresentação sem partida antecipada, bloqueio do líder, cancelamento, espera de confirmação, seleção do próximo lugar e revanche após derrota.
- Revisão real no navegador: seleção da praça → apresentação → início da batalha com novo cenário → derrota registrada pelo servidor local → retorno ao mesmo ponto, sem liberar os seguintes.
- Cancelamento por Escape conferido no navegador, preservando o bairro.
- Revelação de Mikka e retorno após vitória conferidos em prévias isoladas, sem alterar o progresso da conta.
- 18 verificações geométricas das cinco apresentações e do retorno após vitória em 390×844, 854×612 e 1440×900: zero erros detectados. Isso não equivale a teste em TV ou controle físico.

## Limites

As cinco arenas novas atendem o Morro do Sol. Beira-Mar e Campanários continuam com seus cenários gerais de batalha. Não foram alterados engine, identificadores persistidos, regras de progressão, recompensas ou banco de produção. O circo permanece conceito para um bairro futuro e um líder novo.

A batalha real de revisão terminou em derrota. O caminho de vitória foi verificado por testes e pela prévia isolada; não foi declarado como vitória real obtida no navegador.

Validação final: 173 testes aprovados, zero falhas. Build e artefato validados; 18 verificações geométricas sem erros detectados.
