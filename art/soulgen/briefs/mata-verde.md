# Brief · Mata verde (rig colorido)

**Atualização de 24/10/2026: revisão artística necessária.** Seguir [Direção de arte — padrão Carcará](../DIRECAO-ARTE-CARCARA.md). A tentativa em `keys/mata-verde/color-rig/` tem montagem técnica, mas olhos grandes e acabamento limpo precisam de revisão. A fonte anterior preserva identidade vegetal e paleta; seu rosto e suas proporções não têm prioridade sobre a direção atual. Usar olhos escuros menores, papel facetado e remendos costurados, sem transformar a criatura em ave. O texto abaixo descreve o brief original.

**Status:** pendente · **Formato:** rig colorido em recortes, igual ao Carcará aprovado · **Entrega:** `art/soulgen/keys/mata-verde/` · **Dados:** [`mata-verde.json`](mata-verde.json)

Siga [`DIRETRIZES-RIG-COLORIDO.md`](../DIRETRIZES-RIG-COLORIDO.md) e use o Carcará em `keys/carcara/color-rig/` como exemplo de acabamento, registro facial e prévia. Não copie coordenadas, pivôs ou tempos do Carcará: a anatomia é outra.

## Quem é

"A folha que não quis cair." Uma folha ficou presa na armação de uma pipa durante uma ventania e, em vez de cair, enrolou-se na linha e aprendeu a dançar entre os galhos. Não segue caminhos retos: muda de lado num sopro e escapa por espaços que parecem pequenos demais. Habitat: copas de árvores e quintais. (Pipa Dex, `assets/pipa-dex.json`)

Referência aprovada de identidade: `assets/creatures/basicos-v2/mata-verde.png`. Preserve cores, nervuras, rosto e proporções; o resultado é uma ilustração colorida, não pixel art.

## Anatomia e camadas

| Peça | O que é | Ordem | Pivô |
|---|---|---|---|
| `tail` | Cipó com contas douradas terminando numa folha | 0 (atrás) | Nó do cipó sob a vela |
| `wingFar` | Folha lateral distante, parcialmente escondida | 1 | Junção com a vela, lado distante |
| `body` | Vela-folha central com nervura, rosto e coroa | 2 | Raiz do corpo |
| `wingNear` | Folha lateral próxima, sobre o corpo | 3 | Junção com a vela, lado próximo |
| `crown` (opcional) | Coroa de três folhas | 4 | Base da coroa; só separe se não abrir fenda |

As folhas laterais são finas e flexíveis: a raiz precisa cobrir a junção ao girar. A silhueta tem que se distinguir da do Carcará em tamanho de jogo (folha larga e baixa × losango com asas de penas).

## Expressões

Normal (curiosa), golpe (travessa e decidida, sem perder o sorriso de canto), dano (olhos apertados), vitória (olhos `^ ^`). Piscar é opcional. Mesmas regras do Carcará: corpo canônico, alpha idêntico, só as janelas dos olhos mudam. Janelas sugeridas: golpe 0,15–1,2 s; dano 0,03–0,65 s; vitória 0,2–1,9 s.

## Ações

| Ação | Duração | Leitura |
|---|---|---|
| Repouso | 2,8 s, contínua | Flutua com balanço lateral; folhas ondulam fora de fase; o cipó atrasa |
| Voo | 1,0 s, contínua | Batida ondulante de arraia: a ponta da folha atrasa em relação à raiz |
| Golpe | 1,6 s, impacto em 0,5 s | Esquiva: recolhe, dispara de lado num sopro e volta |
| Dano | 1,0 s | Recuo curto e balanço de recuperação |
| Vitória | 2,2 s | Giro alegre com as folhas abertas e retorno ao repouso |

O Soulgen Studio já tem atraso por peça: sugestão inicial de rabiola +0,12 s e asa distante +0,05 s. A interpolação "Contínua" serve bem para o voo ondulante.

## Pronto quando

- Fontes, prompts, recortes, pivôs, registro facial e prévia independente na pasta de entrega, como no Carcará.
- O preset abre no Soulgen Studio e passa em **Auditar rig e expressões**.
- Revisado em fundo claro e escuro e na escala de jogo ao lado do Carcará.
- Integração no jogo e publicação continuam etapas separadas (no jogo, o caminho é o mesmo do Carcará: exportar com `npm run studio:export-game` e testar com `?rig`).
