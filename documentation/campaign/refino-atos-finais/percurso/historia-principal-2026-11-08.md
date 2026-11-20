# História principal · percurso completo e revisão do texto (08/11/2026)

Base: `claude/unificacao` depois do balanceamento, das tabelas de criaturas, dos mapas novos
(Centro, Condomínio, Porto Novo) e das três branches do Codex de 07/11.

## Percurso com lutas reais

O caminhante (`tools/campaign_walker.gd --fight=6`) jogou a campanha em dois trechos paralelos,
com o bot de leitura nível 6 em todos os duelos, cuidado com Kit de Remendo depois das derrotas
e o app fechado e reaberto entre os passos.

| Trecho | Duelos | Derrotas | Problemas | Registro |
| --- | --- | --- | --- | --- |
| Atos 1–3 (Bambuzal → chegada à Serra) | 51 | 8 | 0 | [percurso-atos-1-3](percurso-atos-1-3-2026-11-08.md) |
| Atos 4–6 (Serra → créditos e epílogo) | 70 | 17 | 0 | [percurso-atos-4-6](percurso-atos-4-6-2026-11-08.md) |

- Nenhum passo travou. Toda derrota se resolveu em uma a três tentativas.
- Os mapas novos funcionaram em uso real:
  - os quatro desafios do Centro e o Leo Antena;
  - os quatro do Condomínio e a Tainá;
  - os quatro do Porto Novo e o Jurandir.
  
  As falas dos rivais do Condomínio ("pelos jardins", "o clube logo acima", "pela piscina até o
  terraço") seguem a ordem das plantas A, B e C.
- A final é o ponto mais difícil. O Kael chega à chave dois níveis abaixo dos rivais
  (Nv.46–48 × 48–50). A Jamile caiu na terceira tentativa, já com o amortecedor de derrotas
  seguidas ativo. Confirmar com pessoas antes de mexer.
- Limite: o caminhante segue o caminho principal e quase não entra no mato. Os selvagens do Cais
  em diante foram conferidos pelo `wild_tables_checks`, não por este percurso.

## Revisão do texto (falas na ordem em que o jogador lê)

O registro do caminhante foi lido do Bambuzal aos créditos. A história se encadeia: cada passo
aponta o próximo e as pistas plantadas são retomadas:

- o bambu cortado no Bambuzal;
- o nó de expedição;
- a foto no ateliê;
- a fita da Pipa TV levando ao Sr. Assis;
- o Jurandir contando das três presas;
- a Jamile retomando a final vista do quarto.

Corrigido:

| Onde | Problema | Agora |
| --- | --- | --- |
| Mormaço, ao ser libertado (ato 3) | "O frio sabe onde estão os outros": sobra da Glacerol e da Geleira, que saíram em 04/11. | O próximo Vento chama do alto da Serra, como a Caio Garça confirma em seguida. |
| Dona Neve | "chegou com a linha inteira", com o Rabbito a 6% de linha. | "Você subiu a Serra a pé e ouviu os quatro." |
| Ícaro | "ligou o gerador na noite do cerol"; na cena, o jogador acende a torre do vento. | "acendeu a torre do vento". |
| Nina, dica do Lacertubo | "Ele arma a vela…" sem dizer quem. | "repara no Lacertubo: ele arma a vela…". |
| Depois da Pipa-Dragão | Nota de desenvolvimento na tela: "Sua função de remontagem será integrada depois." | Removida. |
| Selvagens do Bambuzal e da Feira | Nome com "[rascunho]" na batalha, na recompensa e na mochila. | Bicho-pau de Vareta e Joaninha-pião. |
| Mapa de Kronasta | "Região futura; nome provisório." no Vulcão, nas Cavernas e nas Planícies. | "Ainda não há caminho aberto até lá." |
| Retalho | "o Retalho / ele" nos atos 1–3 e no galpão, "a Retalho / ela" na bíblia, na Heleana e no epílogo. | Feminina em todo o jogo (decisão do dono, 08/11; bíblia §20). |

## O que ainda falta para fechar a história principal

**Arte (Codex).** É a maior lacuna visível. As pastas `npc-ds/centro-v1`, `lajes-v1`, `porto-v1`,
`mirante-v1`, `serra-v1`, `estadio-v1` e `liga-v1` ainda não existem, e 22 pessoas da história
aparecem com o sprite do Professor:

- os campeões Leo Antena, Tainá, Jurandir, Ícaro e Dona Neve;
- os rivais desses bairros;
- a Faye;
- a Dona Cida e o produtor da Pipa TV.

Lista completa em [PEDIDOS-VISUAIS-CODEX.md](../PEDIDOS-VISUAIS-CODEX.md), §1–2. Também faltam:

- o ciclo de caminhada do Rato;
- as variantes dos Desalmados;
- o interior do laboratório com escada.

**Validação humana.** O que o caminhante não mede:

- ritmo e clareza das cenas;
- a dificuldade da final;
- controle físico;
- o prólogo completo antes do Lohan, coberto por testes próprios, não por este percurso.

**Arco opcional da Retalho (F14).** A elipse do Varal e da fuga ainda é contada em texto.
