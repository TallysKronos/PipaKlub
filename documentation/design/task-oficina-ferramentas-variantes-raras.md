# PIP-58 — Oficina das Almas

Demanda registrada no Linear: [PIP-58](https://linear.app/pipaklub/issue/PIP-58/epico-oficina-das-almas-ferramentas-materiais-bonus-de-fabricacao-e). Status na criação: Backlog. As duas referências visuais do Carcará estão anexadas à issue.

## Por quê

Transformar a Oficina das Almas em uma atividade de fabricação com habilidade e decisões reais. O jogador trabalha diretamente sobre a pipa que dará corpo ao Soulmonster, escolhe ferramentas e materiais e reconhece no resultado o cuidado da construção. Dois exemplares da mesma espécie podem ter desempenhos diferentes por causa da execução da oficina.

Adicionar também uma possibilidade muito baixa de nascer uma **variante física rara**, preservada no exemplar. O nome dessa mecânica será decidido depois.

## Estado e escopo

Esta é a demanda-mãe da evolução da oficina, a partir dos blueprints e do brainstorm aprovados. Registra especificação e critérios de aceite; não significa que as funcionalidades abaixo já estejam implementadas ou publicadas.

Existe uma primeira oficina em trabalho local, com etapas guiadas, kit básico fornecido pelo ateliê, qualidade sem bônus e animação própria do Rabbito. Esse trabalho e a migração `024_soul_workshop.sql` ainda precisam ser integrados ao remoto antes de servirem como base. Não confundir essa versão com a nova fabricação por ferramentas.

Referências de trabalho local: `documentation/blueprints-2026-10-22/ANALISE.md`, `documentation/design/oficina-artesa-brainstorm-v2.md`, `art/workshop-v1/README.md`, `src/workshop-model.js`, `src/workshop-renderer.js` e `src/summon-client.js`. Esses caminhos não são links para arquivos já publicados.

## Regras confirmadas pelo responsável

- Substituir a invocação por constelação pela construção interativa inspirada na dinâmica de ferramentas de Fossil Fighters.
- Trabalhar com corte, colagem/montagem, equilíbrio e união da rabiola, culminando no nascimento animado.
- Exigir itens reais de construção; o kit gratuito do protótipo não é a economia definitiva.
- **Falhar na fabricação consome os materiais de construção comprometidos naquela tentativa.**
- **A rabiola é a última peça e fica protegida nas falhas de construção.**
- Ter diferentes modelos/moldes de pipa, com graus de raridade.
- Equilíbrio, elo e qualidade de execução geram bônus reais no exemplar, além de efeitos visuais.
- Uma chance muito baixa pode produzir uma variante com diferença física no Soulmonster.
- O nome da mecânica e a chance exata ainda não estão definidos.
- Todos os Soulmonsters mantêm anatomia de pipa; a linha é o método de manifestação.

## Experiência proposta

**Alma e molde → conferir materiais → preparar bancada → cortar → colar e montar → testar equilíbrio → colocar rabiola → sincronizar o elo → despertar → resultado e coleção.**

A bancada deve ocupar a área principal. Ferramentas ficam ao alcance, com instruções contextuais, estado da peça e consequência visível da ação. Trocar de ferramenta precisa mudar a interação com o material; não apenas disparar uma animação pronta por botão.

### 1. Ferramentas e manipulação direta

| Ferramenta proposta | Interação | Avaliação |
|---|---|---|
| Tesoura | Traçar cortes, contornar peças e aparar sobras. | Precisão, material preservado e abas de colagem. |
| Pincel de cola | Aplicar cola nas faixas úteis de contato. | Cobertura, falta/excesso e preservação de articulações. |
| Pinça de montagem | Pegar, girar, alinhar, assentar e fixar peças; posicionar a rabiola no final. | Encaixe, orientação e posição dos pontos de fixação. |

- A geometria deve corresponder à anatomia da espécie. Orelhas de Rabbito e velas de Carcará não podem ser resolvidas por um único losango genérico.
- Mostrar sobra de papel, corte para dentro da peça, cola e sobreposição de forma compreensível.
- Permitir correções locais dentro das regras da tentativa, sem transformar todo erro pequeno em falha imediata.
- Ferramentas reutilizáveis são distintas dos materiais consumíveis; não quebrá-las ou consumi-las sem uma regra adicional aprovada.
- Oferecer entrada por mouse/toque e comandos equivalentes por teclado/controle. Precisão não pode depender da taxa de quadros ou da frequência de eventos do dispositivo.

### 2. Inspeção e tempo

- Incluir uma ferramenta de leitura, provisoriamente **Luz do molde**, para revelar armação, abas, regiões de colagem e encaixes. Ela orienta o trabalho, sem completá-lo automaticamente.
- Prototipar consulta permanente versus consulta temporária/limitada antes de fechar suas restrições.
- O cronômetro foi discutido, mas **não foi decidido se será obrigatório na fabricação normal ou reservado aos desafios**.
- Pausa, ajuda, carregamento e perda de conexão não devem consumir tempo de atividade.
- Expiração do tempo só pode gerar falha se isso estiver definido para o modo e informado antes de iniciar.

### 3. Moldes, raridade e compatibilidade

Separar claramente:

1. **Espécie/alma:** identidade e anatomia.
2. **Molde e sua raridade:** projeto compatível, construção, dificuldade e potencial.
3. **Materiais:** itens necessários e propriedades de construção.
4. **Qualidade:** resultado do trabalho do jogador.
5. **Variante física rara:** aparência individual excepcional; não confundir com raridade do molde.

- Catálogo deve informar compatibilidade, receita, quantidades, dificuldade e perfil de bônus.
- Perfis iniciais para estudo: tradicional, vela leve e armação reforçada. Nomes, receitas e distribuição finais precisam ser definidos.
- A raridade do molde não muda automaticamente a espécie.
- Molde que mude a silhueta precisa de arte e animação adequadas; não esticar a mesma textura para fingir outro corpo.
- Impedir iniciar sem os materiais exigidos ou sem uma rabiola compatível.
- Definir fontes de obtenção dos materiais dentro da demo: exploração/coleta, recompensas e/ou loja. Não conceder estoque ilimitado em produção para contornar a economia.

### 4. Economia, falha e proteção da alma

- Exibir antes da confirmação o lote e as quantidades que serão comprometidos, a regra de perda na falha e a proteção da rabiola.
- Reservar/debitar materiais de forma transacional e impedir uso simultâneo do mesmo estoque em outra tentativa.
- Em uma **falha de gameplay confirmada**, consumir os materiais comprometidos uma única vez, registrar o motivo e devolver o jogador à preparação com a rabiola intacta e utilizável.
- A nova tentativa exige novos materiais; não entrega um parceiro nem concede bônus por ter falhado.
- A rabiola só entra na união final, depois que o corpo passa pelas condições de construção.
- Sua utilização final e a concessão do exemplar devem ocorrer de forma consistente e atômica. Não pode haver rabiola consumida sem parceiro confirmado.
- **Queda de conexão, recarga, atraso de resposta e indisponibilidade do banco não equivalem a falha de fabricação.** Preservar o último estado confirmado e permitir retomada.
- Reenvio de confirmação, duplo clique ou reconexão não podem duplicar consumo, restituição ou recompensa.
- Definir explicitamente se desistir após iniciar uma operação equivale a perder o lote. Essa classificação está pendente; não introduzir perda silenciosa.
- Definir o que constitui falha: dano estrutural, corte irrecuperável, limite de operações, tempo ou outras condições. Mostrar os limites antes da tentativa e sinais legíveis durante o trabalho.
- Não adicionar uma falha aleatória que destrua materiais depois de uma execução correta sem uma decisão de design específica.
- Permitir treino sem consumo de recursos. Eventual fabricação automática pelo artesão não pode fornecer montagem perfeita gratuitamente e anular a habilidade manual.

### 5. Equilíbrio, elo e bônus reais

- Substituir o alvo universal de slider por um teste de voo: observar inclinação, oscilação e resposta ao vento, ajustar amarração e testar novamente.
- O equilíbrio ideal deve ser explicável pelo molde e pelos materiais, com pistas observáveis.
- Na união final, posicionar a rabiola e executar uma sequência curta de tensão/soltura ou sincronia com o vento/pulsação.
- Distinguir sincronia técnica de manifestação do vínculo afetivo com o parceiro.
- Calcular notas por dimensão, com consequência rastreável nos atributos.
- Relação inicial proposta: corte → aerodinâmica/velocidade; colagem → integridade da linha; equilíbrio → eficiência do voo; elo → recuperação/capacidade de energia.
- Usar atributos atuais quando possível: `line`, `energy`, `attack`, `defense`, `speed` e `regen`. Qualquer nova estatística exige definição de comportamento no combate.
- Fixar um orçamento máximo de fabricação por molde e raridade; validar sua interação com nível, classes e habilidades.
- Mostrar na ficha os valores base, progressão/classe e contribuição da fabricação separadamente.
- Dois exemplares iguais em espécie, molde, nível e classe devem apresentar diferença mensurável quando a execução da oficina diferir.
- O brainstorm de +4% em velocidade, +2% em linha e +2% em regeneração é **exemplo para balanceamento**, não tabela aprovada.
- Não neutralizar automaticamente os bônus no online: a intenção é que pertençam ao exemplar. Regulamentos específicos de torneio são uma discussão posterior.

### 6. Variante física rara — nome a definir

- Incluir uma possibilidade de nascimento excepcional, com probabilidade muito baixa e configurável.
- A mudança deve aparecer no desenho do Soulmonster: painel, capuz, padrão de construção, plumagem/velas, recortes ou outra característica física aprovada. Um brilho temporário, badge ou filtro global de cor não basta.
- Referência fornecida: duas versões de Carcará com corpo de pipa laranja/creme, asas e rabiola correspondentes; uma apresenta o painel superior/capuz castanho escuro e padrão facial diferente. Manter essa comparação como referência visual, sem presumir qual delas será a padrão.
- Aprovar a ficha padrão e a excepcional por espécie, preservando identidade, anatomia de pipa e personalidade.
- Registrar a variante no exemplar, independente da qualidade de fabricação e da raridade do molde.
- A variante deve permanecer em coleção, ficha, retrato, HUD, batalha, overworld, acompanhamento, save e nos fluxos de transferência permitidos para aquele exemplar.
- Não inventar um nome comercial definitivo para a mecânica; usar identificação técnica provisória como `appearance_variant`.
- **Recomendação para fechar a regra:** um sorteio autoritativo no primeiro despertar bem-sucedido, persistido na mesma transação da concessão. Falhas de construção não sorteiam; recarga, reenvio, remontagem, troca de molde e revisão da animação não sorteiam novamente.
- Momento do sorteio, vínculo definitivo da variante com a alma/exemplar e chance exata precisam ser aprovados antes da implementação da distribuição.
- Não atrelar a chance à nota, materiais premium, compras ou multiplicadores sem decisão explícita.
- Não adicionar um bônus de combate extra apenas pela aparência rara sem aprovação. Os bônus solicitados são os da fabricação.

### 7. Remontagem e preservação do parceiro

- Permitir evoluir a qualidade da construção sem exigir abandonar a alma.
- Preservar ID, nome, XP, classe, histórico e variante física.
- A remontagem usa materiais próprios e informa o custo antes de começar.
- Em falha, perder os materiais da nova tentativa, preservando o parceiro e a montagem anterior confirmada.
- Comparar a montagem completa anterior com a nova antes de substituir; não combinar os melhores atributos de tentativas diferentes silenciosamente.
- Remontagem não cria outro exemplar, não repete sorteio raro e não duplica recompensa.

### 8. Arte, animação e interface

- Planejar por molde/espécie: contorno de corte, abas, máscara de cola, armação, encaixes, pivôs, amarração e ligação da rabiola.
- Usar a mesma construção entre bancada e despertar, com transição coerente para o modelo final.
- Preservar o estilo colorido aprovado. As referências anexadas explicam diferenças de aparência; não exigem reverter a produção inteira ao ensaio antigo monocromático/pixel art.
- Preparar peças e expressões para as duas aparências, com recortes e raízes adequados.
- Validar repouso, voo, golpe, dano e vitória, além das direções de acompanhamento necessárias.
- Sem fendas, raízes flutuantes, olhos duplicados, mudança involuntária de volume ou troca de variante durante uma expressão.
- Ferramenta ativa, região de ação, integridade, inspeção disponível, qualidade e cronômetro devem ser legíveis sem cobrir a peça.
- Movimento reduzido preserva informações necessárias para construir e avaliar.
- Rever layout amplo e móvel na escala real e distinguir emulação de teste em aparelho físico.

### 9. Servidor, persistência e integração

- O servidor define receitas, estoque, molde, regras de falha, parâmetros de qualidade, chance rara, consumo e concessão.
- Não aceitar `nota:100`, bônus finais ou indicador de variante rara enviados pelo cliente como verdade.
- Validar ações da bancada, geometria, cobertura, ordem, limites de tempo e identificadores de operação. Isso não dispensa avaliar automação; recalcular notas não prova execução humana.
- Persistir o estado necessário para retomada e os resultados confirmados; não coletar movimentos fora da bancada.
- Garantir proteção entre contas, concorrência entre abas e consistência em recarga/retentativa.
- Versionar regras de fabricação e variantes. Planejar como futuras revisões de balanceamento afetam exemplares existentes, sem mudanças silenciosas.
- Preparar migrações aditivas e testes de atualização, preservando coleção, moedas, campanha e progresso.
- Integrar à engine própria JavaScript/Canvas 2D e à interface existente, sem substituição de motor.
- A criação desta issue não executa migrações ou publicação em produção.

## Critérios de aceite

- [ ] A bancada oferece ferramentas com ações distintas sobre a superfície da peça; não é apenas uma sequência de botões que completa etapas prontas.
- [ ] Uma receita válida informa e exige materiais reais antes do início.
- [ ] Falta de recursos ou incompatibilidade impede iniciar sem consumir nada.
- [ ] Uma falha de gameplay válida consome o lote comprometido exatamente uma vez, explica o motivo e preserva a rabiola.
- [ ] Interrupções técnicas permitem retomada sem serem classificadas como falha.
- [ ] A rabiola só é utilizada na etapa final e não é perdida sem o exemplar confirmado.
- [ ] Corte, cola, encaixe, equilíbrio e elo oferecem feedback e resultado rastreável.
- [ ] Execuções diferentes produzem bônus reais diferentes, respeitando o teto aprovado do molde.
- [ ] A ficha permite distinguir efeito de fabricação, nível e classe.
- [ ] A probabilidade rara e seu momento de avaliação estão definidos e versionados antes de ativar a distribuição.
- [ ] Sorteio e concessão são autoritativos e idempotentes; não há nova chance por reload, reenvio ou remontagem.
- [ ] Existe um piloto completo de aparência padrão e excepcional, com diferença física reconhecível e consistência entre os consumidores do jogo.
- [ ] Os bônus de fabricação e a variante persistem no exemplar correto após salvar/reabrir.
- [ ] Remontagem preserva identidade/progresso/variante e protege a construção anterior em uma tentativa malsucedida.
- [ ] Entradas acessíveis e movimento reduzido mantêm o fluxo concluível; ajuda não concede excelência automática de forma que anule o desafio.
- [ ] A primeira experiência e os caminhos de treino, erro, correção, falha, sucesso e retomada foram revisados no navegador.

## Plano de trabalho sugerido

1. [ ] **Fechar design e parâmetros:** falha, custo, cronômetro, compatibilidade, bônus, chance e momento do sorteio.
2. [ ] **Inventário e receitas:** catálogo, fontes de materiais, reserva/consumo e estados de tentativa.
3. [ ] **Bancada:** ferramentas, superfície de trabalho, correções e inspeção.
4. [ ] **Equilíbrio e elo:** teste de voo, amarração e sincronia.
5. [ ] **Arte piloto:** uma espécie com moldes de teste e duas aparências completas; Carcará é a referência para a diferença física.
6. [ ] **Concessão e atributos:** cálculo de notas, bônus limitados, variante persistida e integração de combate/coleção.
7. [ ] **Remontagem e recuperação:** preservar parceiro, evitar rerrolagem e garantir retomada.
8. [ ] **QA e balanceamento:** testes funcionais, economia, aparência, entrada, desempenho e comparação em duelos.

## Cenários obrigatórios de teste

- Sucesso com recursos exatos; tentativa sem materiais; receita incompatível; estoque disputado por duas abas.
- Corte/cola irrecuperáveis; falha repetida; clique duplo; desistência conforme regra aprovada.
- Queda antes e depois da reserva, perda de resposta no consumo, recarga durante montagem e falha de banco na união final.
- Reenvio da mesma operação; pedido alterado com o mesmo identificador; tentativa de manipular nota/atributos/chance; conta tentando acessar montagem alheia.
- Exemplar padrão e excepcional forçados por fixture de teste, com o mesmo rig/atlas consumidor usado pelo jogo.
- Testar a distribuição rara por método estatístico adequado e fonte de aleatoriedade controlável em testes; não exigir que um evento raro apareça casualmente numa sessão manual.
- Nenhum sorteio por falha, reload ou remontagem na regra recomendada; várias chamadas de conclusão retornam o mesmo exemplar e variante.
- Mesmo Soulmonster/molde/nível/classe com execuções fraca, intermediária e excelente; avaliar efeitos reais em combate.
- Remontagem malsucedida preserva o parceiro anterior; bem-sucedida não altera sua variante nem duplica coleção.
- Troca/equipamento/save/retorno entre cenas preservam os metadados onde essas operações forem permitidas.
- Revisão de recortes, transparência, pivôs, transições, expressões, loops, direções e legibilidade.
- Teste de atualização do banco preserva dados existentes e não concede materiais ou variantes em massa.

## Decisões ainda abertas

- Nome da mecânica de variante rara.
- Qual referência de Carcará será padrão e qual será excepcional; diferença final por espécie.
- Probabilidade exata, distribuição e momento definitivo do sorteio.
- Se fabricação normal usa cronômetro ou apenas desafios.
- Limites objetivos de falha e regra de desistência.
- Receitas, quantidades, fontes de materiais, raridades e compatibilidades.
- Pesos/tetos de bônus e tratamento futuro de balanceamento.
- Escopo inicial de espécies e moldes; efeito de eventuais assistências na nota.
- Regras finais de remontagem e comparação/substituição da construção.

**Fora desta issue:** nomear a mecânica definitivamente, introduzir monetização ou vantagens compradas, criar novos biomas completos, alterar o vínculo narrativo da alma, conceder poder adicional pela aparência rara ou executar deploy/migração sem o fluxo de publicação correspondente.
