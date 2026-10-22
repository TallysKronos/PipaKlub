# Oficina das Almas · proposta de design (PIP-58)

Status: **proposta para aprovação**. Nada aqui está no jogo. O protótipo jogável fica em `tools/oficina-prototipo/` (abrir `index.html` por um servidor local) e suas regras em `tools/oficina-prototipo/model.mjs`, com testes em `model.test.mjs`.

A primeira oficina local citada no épico (migração `024_soul_workshop.sql`, `src/workshop-model.js`, `src/workshop-renderer.js`) ainda não está no repositório. Esta proposta não depende dela e não toca na invocação atual. Quando ela subir, a integração segue a seção "Ordem de implementação".

Cada item traz uma **recomendação**. Os marcados ⚑ precisam da sua decisão antes de virar código.

## 1. Fluxo e estados da tentativa

```
preparar → corte → colagem → montagem → equilíbrio → rabiola e elo → despertar
              ╲________ falha estrutural ________╱            ╲→ sucesso (exemplar criado)
```

Estados no servidor: `reservada → em_bancada(etapa) → concluida | falhou | abandonada`.

- **Reserva** (ao confirmar a preparação): debita o lote do molde numa transação; o lote fica preso à tentativa. A rabiola **não** é debitada aqui: só é verificada.
- **Etapas**: cada etapa envia as ações da bancada; o servidor recalcula a nota e a integridade e salva o último estado confirmado.
- **Falha**: integridade chega a 0. O lote já reservado é consumido (fica registrado o motivo), a rabiola continua no inventário, nenhum sorteio acontece.
- **Despertar**: numa única transação, consome a rabiola, cria o exemplar com notas, bônus e aparência, e marca a tentativa como concluída. Reenvio da mesma confirmação devolve o mesmo exemplar.

## 2. Ferramentas (implementadas no protótipo)

| Ferramenta | Ação na bancada | O que mede | Feedback |
|---|---|---|---|
| Tesoura | Traçar o contorno do molde (mouse, toque, ou setas + Espaço) | Cobertura do contorno, erro médio até a linha, cortes para dentro | Traço vermelho quando entra na peça; barras de contorno, precisão e integridade |
| Pincel de cola | Pintar as faixas onde as varetas encostam | Cobertura das faixas, excesso fora delas, cola nas articulações | Excesso visível, aviso nas articulações |
| Pinça | Arrastar, girar (roda, Q/E, botões) e assentar a vela na armação | Distância e ângulo do encaixe | Distância e ângulo ao vivo |
| Luz do molde | Liga/desliga o contorno, as faixas e as articulações | Não pontua | Só orienta, não completa nada |

O caminho do ponteiro é interpolado a cada 3 px, então a nota não depende da taxa de quadros nem da frequência de eventos do aparelho.

**Correção local:** "Desfazer último traço" remove o traço e devolve metade do dano dele (o papel fica marcado). ⚑ Recomendação: manter assim; um erro pequeno custa nota e um pouco de integridade, nunca a tentativa inteira.

## 3. Falha, desistência e tempo

- **O que é falha** (recomendação): só dano estrutural acumulado. Cortes que entram mais de 6 px na peça e cola nas articulações descontam integridade; em 0, a armação cede. Sem falha aleatória depois de uma execução correta.
- **Limites mostrados antes**: a preparação lista o lote que será comprometido e diz que a rabiola fica protegida. A barra de integridade acompanha todas as etapas de corte e cola.
- **Interrupções técnicas** (queda, recarga, servidor fora): nunca contam como falha. A tentativa reabre na última etapa confirmada.
- ⚑ **Desistência**: recomendação é tratar "Desistir" como falha **com confirmação explícita** ("o lote será perdido"). Fechar o jogo sem desistir mantém a tentativa aberta por 24 h para retomada; depois disso, ela é encerrada sem consumir a rabiola e o lote volta ao estoque. Não há perda silenciosa.
- ⚑ **Cronômetro**: recomendação é **sem cronômetro na fabricação normal**. O tempo aparece só em desafios futuros, avisado antes de começar e pausado em ajuda, menus, carregamento e perda de conexão.
- ⚑ **Luz do molde**: recomendação é consulta permanente na fabricação normal (é aprendizado, não atalho) e limitada em desafios.

## 4. Moldes, raridade e materiais

| Molde | Espécie | Raridade | Receita (proposta) | Teto de bônus |
|---|---|---|---|---|
| Tradicional | Rabbito | comum | 2 papel de seda, 2 varetas, 1 cola | 4% |
| Vela leve | Rabbito | raro | 3 papel de seda, 2 varetas, 1 cola, 1 fio encerado | 6% |
| (futuro) Armação reforçada | — | épico | a definir | 8% |

- Espécie (anatomia) ≠ molde (projeto e teto) ≠ materiais (receita) ≠ qualidade (execução) ≠ aparência rara (sorteio). O protótipo mantém cada um em um campo separado.
- Iniciar sem a receita completa ou sem rabiola compatível é bloqueado sem consumir nada.
- ⚑ **Fontes de materiais na demo** (recomendação): papel de seda e cola na loja de pipas da Rua dos Ventos por moedas; varetas como recompensa dos encontros do Morro; fio encerado como drop raro de encontros selvagens no Parque. Sem estoque ilimitado em produção.
- **Treino**: sempre disponível, não consome nada e não cria parceiro.

## 5. Notas e bônus

Quatro notas de 0 a 100, cada uma ligada a um atributo que o combate já usa (`src/engine.js`):

| Etapa | Atributo | Por quê |
|---|---|---|
| Corte | `speed` | contorno limpo, menos arrasto |
| Colagem | `line` | colagem firme aguenta mais corte |
| Equilíbrio | `regen` | voo estável gasta menos energia |
| Elo | `energy` | sintonia aumenta a reserva |

- **Fórmula**: o teto do molde é dividido em quatro fatias iguais. Cada nota entrega `((nota − 50) / 50)^1.2` da sua fatia: abaixo de 50 não dá bônus nem penalidade, 100 entrega a fatia inteira. Montagem conta para concluir a etapa e para a aparência, sem bônus próprio.
- **Escala**: o nível 50 dá +20% de linha e a classe no rank 3 dá até +24% de velocidade. Um teto de 4–8% faz a oficina diferenciar exemplares sem superar progressão e classe.
- **Ficha**: base do nível, contribuição da oficina e total aparecem separados (a classe entra como uma terceira coluna no jogo).
- **Online**: o bônus pertence ao exemplar e vale em todos os modos, como pede o épico. Regras de torneio ficam para depois.
- ⚑ Os números (teto, curva, divisão igual) são propostas para balanceamento.

## 6. Aparência rara (`appearance_variant`)

- **Recomendação**: sorteio único no servidor, no **primeiro despertar bem-sucedido**, salvo na mesma transação que cria o exemplar. Falha, recarga, reenvio e remontagem não sorteiam de novo.
- ⚑ **Chance**: proposta de 1 em 256, configurável e versionada. Não depende da nota, dos materiais nem de compras.
- Valores: `padrao` | `excepcional`. A diferença é física (no Carcará, o capuz castanho e o padrão facial da referência). Sem bônus de combate extra.
- ⚑ Qual das duas referências do Carcará é a padrão.
- O protótipo tem a caixa "forçar a aparência excepcional" só para teste; no jogo, isso vira fixture de teste no servidor.

## 7. Remontagem

- Mesma bancada, sobre um exemplar existente. Preserva ID, nome, XP, classe, histórico e aparência.
- Usa um lote novo, informado antes. Em falha, perde esse lote e mantém a montagem anterior.
- No fim, mostra as duas montagens lado a lado e o jogador escolhe qual fica. Sem misturar notas de tentativas diferentes.
- Não sorteia aparência e não cria outro exemplar.

## 8. Servidor e dados (proposta de migração aditiva)

- `workshop_molds(id, species, rarity, recipe jsonb, budget numeric, rules_version)`.
- `player_materials(owner_id, material, quantity)` com `check (quantity >= 0)`.
- `workshop_attempts(id uuid, owner_id, mold_id, kite_id null, mode treino|fabricacao|remontagem, state, stage, integrity, scores jsonb, reserved jsonb, rules_version, operation_id unique, created_at, updated_at)`.
- Em `player_kites`: `craft_scores jsonb`, `craft_bonus jsonb`, `craft_rules_version`, `appearance_variant text default 'padrao'`.
- RPCs autenticadas `player_workshop(action, …)` no mesmo padrão de `player_campaign`: `start`, `stage`, `abandon`, `awaken`, `rebuild_choose`. O servidor recalcula notas a partir das ações; nunca aceita nota, bônus ou aparência do cliente.
- Idempotência por `operation_id`; bloqueio por jogador como nas outras RPCs; tentativas abertas impedem trocas e invocação do mesmo exemplar.
- Contas existentes não recebem materiais nem aparências em massa na migração.

## 9. Arte e animação

- Por molde e espécie: contorno de corte, faixas de cola, articulações, armação, pivôs, amarração e ponto da rabiola, desenhados sobre a mesma arte do rig colorido.
- O despertar usa a peça montada e passa para o rig do Soulgen Studio, sem trocar de desenho no meio.
- Aparência excepcional: peças próprias (capuz, padrão facial) nas mesmas camadas e pivôs, validadas em repouso, voo, golpe, dano e vitória, como o Carcará aprovado.

## 10. Ordem de implementação

1. Aprovar os itens ⚑ deste documento.
2. Subir a oficina local (024) e integrá-la à `main` atual.
3. Inventário de materiais e loja/drops da demo.
4. Bancada no jogo, reaproveitando as regras de `model.mjs` no servidor.
5. Equilíbrio, elo e concessão com bônus e aparência.
6. Arte piloto do Rabbito com os dois moldes; aparência excepcional do Carcará.
7. Remontagem, retomada e testes de concorrência.
8. Balanceamento comparando exemplares fracos, médios e excelentes em duelos.
