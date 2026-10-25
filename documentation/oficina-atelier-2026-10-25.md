# Oficina das Almas — preparação no ateliê

## Mudança

A entrada, a seleção de gabarito, a escolha de alma e a restauração passam a ocupar o cenário do ateliê em tela cheia, com a mesa e o mentor presentes. Não se usa a grande janela de papel do clube nesse trecho.

Gabaritos são objetos vetoriais na mesa, com bambu, nós e papel neutro. Seus quatro, cinco e seis apoios correspondem às classes da bancada v3. Etiquetas pequenas substituem cards emoldurados. A alma é representada por um embrulho numerado, com estado de seleção e sem revelar espécie. Assis orienta cada momento no mesmo balão. Uma montagem ativa recebe prioridade na entrada.

Assets existentes reutilizados: `tools/oficina-v3/atelier-v1.png`, `mesa.jpg` e `assis.png`. Novos objetos vetoriais ficam no módulo `src/workshop-entry-client.js`, com layout em `src/workshop-entry.css`; os dois builds incluem os mesmos módulos. Texto e ações continuam no DOM.

## Integração preservada

Inventário, elegibilidade por classe, reserva de rabiola, restauração, nascimento, bônus e retomada usam os handlers existentes. A montagem continua no iframe autenticado v3; não se criou economia ou API paralela. Escape volta uma escolha por vez antes de sair; o foco fica nos controles da cena durante a preparação.

## Revisão realizada

Revisão manual local com Ana Local, sem banco de produção: entrada → gabarito comum → seleção de embrulho → bancada v3 → sair com montagem guardada. Verificados o estado indisponível das outras classes, a restauração sem itens e o retorno por Escape. Não se concluiu um novo nascimento nem se revalidou o balanceamento; o limite de requisições da Oficina identificado na auditoria anterior não foi alterado.

Composições inspecionadas em 1131 × 884, 390 × 844 e 1280 × 720. Capturas em `art/ui-reviews/oficina-atelier-20261025/`. Em tela estreita a seleção de almas permite rolagem interna. Não houve verificação com controle físico ou celular físico.

Builds Node e Pages concluídos. Nenhuma suíte de testes automatizados executada, conforme preferência do usuário. Sem push, deploy ou migração de produção.
