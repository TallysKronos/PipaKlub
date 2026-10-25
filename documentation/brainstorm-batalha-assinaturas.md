# Batalhas com identidade — proposta para discussão

Data: 25/10/2026. Brainstorm, sem implementação ou alteração de números no jogo.

## O que existe

Leitura de `src/engine.js`: contato, ângulo e movimento afetam o corte; existem esquiva perfeita, contra-ataque, energia e seis técnicas de linha. As quatro habilidades genéricas usam a cor. Os atributos básicos dependem do nível, classe e bônus de montagem, com pouca diferenciação por espécie. Um corte perfeito crítico tem base 24 × 1,75 = 42 antes dos outros modificadores, contra linha básica 100. Lacertubo já possui duas fases, preparação de golpe e recuperação vulnerável; essa base pode ser aprofundada.

## Objetivo

Cada parceiro deve mudar as decisões do jogador. Dificuldade deve vir de leitura, execução e gestão de recursos, com oportunidades claras de resposta. Especial forte precisa de preparação e contrajogo; inimigos não devem depender apenas de mais HP ou reflexos impossíveis.

## Cinco prioridades

1. **Assinatura por espécie.** Uma ação emblemática, com animação, áudio e efeito próprios. Selecionada por espécie, não somente pela cor. Dano combinado com função distinta: perseguir, controlar espaço, proteger e responder, ou aproveitar posicionamento.
2. **Medidor de Ímpeto (nome provisório).** Carrega por acertos válidos e esquivas bem executadas, não por apertar ataque no vazio ou simplesmente aguardar. Carga por ações repetidas deve ter limite para impedir exploração. Usar o especial consome o medidor; não adicionar simultaneamente um grande custo de energia sem necessidade. Meta inicial: aproximadamente um uso por rodada comum; não é um valor já validado.
3. **Inimigos com padrões legíveis.** Fases de disputar posição, ameaçar, atacar e recuperar. Inimigos diferentes pressionam de maneiras diferentes. Dificuldade maior pode variar escolhas e encurtar aberturas dentro de limites humanos, sem ler comandos futuros nem esquivar instantaneamente de tudo.
4. **Recompensar abrir uma oportunidade.** O especial não é um botão de dano garantido. Pode errar se mal posicionado e ter dano reduzido por uma resposta correta. Acertá-lo após provocar uma falha deve ser um momento desejável. Não tornar todo erro uma perda inevitável da luta.
5. **Feedback com hierarquia.** Ataques comuns curtos e legíveis; acertos precisos mais fortes; assinatura com antecipação reconhecível, expressão do mon, impacto e recuperação. Evitar cutscenes longas e efeitos que escondam as linhas. Efeitos visuais não podem alterar a física ou bloquear controles arbitrariamente.

## Assinaturas para uma primeira versão

Nomes e efeitos são propostas, não habilidades já existentes.

| Parceiro | Assinatura | Papel | Resposta possível |
| --- | --- | --- | --- |
| Carcará | Mergulho do Sertão | Antecipa uma trajetória e mergulha em corte preciso; recompensa boa leitura | Sair do corredor anunciado; recuperação curta se errar |
| Mata Verde | Laço da Mata | Faz uma curva de linha e cria uma breve zona de controle; dano menor que o mergulho | Afastar-se antes do laço fechar; evitar imobilização longa |
| Azulão | Maré de Retorno | Prepara uma defesa curta; aparar no tempo correto permite uma resposta forte | Esperar a defesa passar ou mudar o ângulo de aproximação |
| Raio de Sol | Clarão Solar | Carrega um avanço luminoso com maior compromisso de posição e alto impacto | Ler o brilho inicial e sair da trajetória; sem cegar a interface |
| Rabbito | Salto de Estilingue | Recua, tensiona a rabiola e salta para um golpe de aproximação | Esquivar da chegada; distância inicial denuncia a intenção |

Azulão não deve ganhar defesa prolongada mais dano máximo; Mata Verde não deve somar controle longo e dano máximo. Essas diferenças sustentam a escolha de parceiro.

## Controles

Manter quatro decisões principais: cortar, esquivar, técnica de linha e assinatura. A assinatura pode ocupar o lugar da habilidade genérica atual; parte da identidade antiga pode virar um traço passivo pequeno, revisto por espécie. Evitar empilhar mais botões e sistemas antes de validar o combate principal.

O medidor indica progresso e prontidão. O oponente tem uma preparação reconhecível no corpo/linha/som. Não mostrar uma bandeja com todas as ações futuras ou habilidades ainda desconhecidas. Legibilidade suficiente para reagir deve coexistir com a surpresa da descoberta.

## Balanceamento: ponto de partida, não tabela definitiva

Usar confrontos com nível e equipamento equivalentes, inicialmente sem bônus de montagem. Como hipótese, para linha de referência 100: corte comum 10–14, corte preciso 16–20 e assinatura ofensiva 26–32. Controle, defesa e mobilidade devem ocupar parte do orçamento de poder; nem toda assinatura precisa desse dano. A proposta exige reavaliar também críticos, contra-ataques e técnicas de linha para evitar combinações que eliminem o adversário sem resposta.

Revisar conjuntamente: desgaste por troca, frequência dos acertos válidos, energia, janelas de defesa e carga do especial. Só depois ajustar progressão e bônus. O bônus de montagem atual afeta vários atributos; seu impacto conjunto é maior que olhar apenas para o percentual anunciado. Preservar a vantagem de uma boa criação sem permitir que ela elimine o contrajogo.

Hipóteses de experiência: rodada comum em torno de 30–50 segundos, primeiro contato com um rival permitindo entender seu padrão, uma vitória do jogador atribuível a decisões claras. Respeitar os limites atuais de rodada/partida ou discutir explicitamente sua mudança; não aplicar essas metas indistintamente ao duelo inteiro.

## Lacertubo

Ampliar o ciclo já existente: canos vibram e ele prepara uma investida; falhar abre uma oportunidade de punição. Na segunda fase, variar entre investida e varredura, mantendo sinais distinguíveis. A assinatura pode ser usada nessa abertura ou guardada como ferramenta de resposta. Nível 15 é a referência de preparação, com derrota possível por execução ruim e vitória possível por leitura boa. Não prometer dificuldade equivalente para todas as espécies sem confrontos comparáveis.

## Escopo recomendado

Primeiro: fechar o ciclo com Carcará e um rival, incluindo assinatura, medidor, antecipação, resposta e dano. Depois: um rival defensivo e o Lacertubo. Só então expandir às demais assinaturas e traços. Isso permite identificar se a melhora vem da mecânica principal antes de multiplicar conteúdo.

Na avaliação futura, observar ataques por vitória, frequência de especial, acerto/erro do especial, energia desperdiçada, dano recebido sem sinal perceptível e estratégias dominantes. São critérios propostos para uma próxima validação; não houve teste ou alteração de gameplay neste brainstorm.
