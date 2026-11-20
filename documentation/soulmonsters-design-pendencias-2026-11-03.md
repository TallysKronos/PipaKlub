# Mapa de pendências de design — 03/11/2026

Base examinada: `ffda7042`, integração atualizada. Escopo: arquivos locais de história, Dex, concepts, projetos Soulgen e consumidores Godot. Não é busca em banco remoto nem auditoria visual de todas as imagens. Existência de arquivo/rig não equivale a aprovação artística.

## Resultado e limites

A fila antiga de25/10 é uma fila de **conversão**, não de designs inéditos. A Dex local tem36 entradas; as quatro pendentes dessa fila já possuem arte. Não recriá-las por engano.

O cruzamento dos dois roteiros regionais preservados reúne **39 briefs de espécie**:34 sem design específico identificado nos índices/nomes de arquivos consultados, quatro candidatos a reaproveitar espécies existentes e um com direção escolhida já documentada (capivara de boia). São propostas de roteiro, não39 espécies canônicas aprovadas. Não somar formas possuídas, parceiros indefinidos ou reservas a essa contagem.

Fontes regionais: `documentation/historia/BIBLIA-DA-HISTORIA.md`, §8.1; `art/soulgen/campaign-redesigns-v1/README.md`, que preserva o lote com Vulcão/Geleira. As regiões/nomenclaturas desses documentos divergem: a bíblia local ainda tem Terral/Minuano/Aracati, enquanto o lote aprovado usa Trovareta/Rabiolava/Glacerol/Tufanocorte. **Não criar novas espécies por causa desses nomes antigos.**

## 1. Briefs sem design específico identificado —34

Nomes descritivos de trabalho. “Sem design identificado” significa falta de evidência localizada nesta auditoria; não é afirmação de inexistência em branches não integradas ou arquivos pessoais.

| Região/fonte | O que falta desenhar | Observação |
|---|---|---|
| Bosque | Coruja de papel-manteiga | Diferenciar da coruja de pedra das Ruínas. |
| Bambuzal | Bicho-pau de vareta; joaninha-pião | Dois briefs distintos. |
| Beira-Canal/Veredas | Sapo-cano | Reaparece no Pântano: não duplicar. |
| Feira | Pombo de jornal; gato de saco de papel; papagaio de feira | O pombo também aparece no Centro. Papagaio não é automaticamente Araruna. |
| Cais | Caranguejo-carretel; gaivota de sinalização; peixe-voador de seda | Gaivota reaproveitada no litoral. |
| Vila Operária | Mariposa de lâmpada; rato de bobina; tatu-bola de engrenagem | Rato de bobina não é automaticamente Riscaz. |
| Pântano | Jacaré-arraia; garça de papel crepom; sucuri de rabiola | Veskoro não prova que o jacaré-arraia é a mesma espécie. Garça também nas Palafitas. |
| Palafitas | Guaiamum; boto de papel | Hiponilo/Marulume não resolvem esses briefs por serem aquáticos. |
| Serra | Gavião-carrapateiro; lagarto de pedra; condor de pandorga | Não trocar pelos designs de Carcará/Tufanocorte sem decisão. |
| Ilha/litoral | Tartaruga de papel-cartão; arraia-jamanta | Fonte: bíblia local. |
| Centro | Morcego de antena; urubu-rei de cartaz | Pombo já contado na Feira. |
| Ruínas | Formiga de mural; coruja de pedra | Almáticas antigas genéricas ficam como grupo indefinido, fora da contagem. |
| Vulcão | Salamandra de brasa; urubu de fuligem; tatu-bola de pedra-pomes; fênix de papel-carvão | Fonte: lote de redesigns preservado. Auriflama/Trinca-brasas são designs existentes; associação à fênix/salamandra precisa decisão, não equivalência automática. |
| Geleira | Pinguim de papel-vegetal; raposa de neve de seda; arraia-jamanta de gelo | Fonte: lote de redesigns. Verificar se arraia de gelo será variante da arraia litorânea. Alvaneve/Nevagume não são automaticamente esses briefs. |

## 2. Conciliar antes de gerar —4 briefs

| Brief | Candidato existente | Evidência | Decisão necessária |
|---|---|---|---|
| Sagui de rabiola longa | Micofolha | `art/soulgen/keys/micofolha/README.md`: mico e rabiola enrolada, rig existente | Mesmo papel regional ou outra espécie? |
| Espécie-tatu de Cavar | Tatutrama | `art/soulgen/keys/tatutrama/README.md`: tatu de papel com carapaça | Atribuir habilidade/ocorrência ou criar outra espécie? |
| Onça de bambu noturna | Jaguarluar; alternativamente Yaguarú | READMEs dos dois rigs: onças de papel com vela/amarrações | Escolher uma identidade, não fundir duas por inferência. |
| Lobo-guará de vareta | Guaravento | `art/soulgen/keys/guaravento/README.md`, rig existente | Validar identidade visual e encaixe no brief antes de novo design. |

Essas correspondências são propostas de reaproveitamento, não decisões canônicas nem aprovação visual desta auditoria.

## 3. Design existe; faltam peças, animações, formas ou acabamento

| Criatura/forma | Evidência existente | Pendência real |
|---|---|---|
| Capivara de boia D | `art/creatures/capivara-boia/DECISOES.md`; `model-d-v1/` e `swim-v1/` | Nome próprio e produção Soulgen; revisar integração de Remar. Não tratar como Capimansa automaticamente. |
| Veskoro | `art/creatures/veskoro/battle-v1/README.md`: nome aprovado e pose de combate integrada | Rig articulado, expressões e ações autorais. A pose estática mapeada a seis estados não são seis animações. Documento antigo do crocodiliano sem nome está superado. |
| Mormaço possuído | `art/creatures/mormaco/possessed-c-v2/`, arte aprovada e versão de runtime | Projeto Soulgen específico e animações da forma; o preset `mormaco` é forma livre. |
| Trovareta, Rabiolava, Glacerol, Tufanocorte — estados presos/sombrios | Quatro formas livres com rigs aprovados em `art/soulgen/keys/` | Definir se cada um terá alteração de paleta/anatomia ou só amarração; produzir somente os estados exigidos. A cena de Tufanocorte fala em fios, mas não prova um redesign sombrio aprovado. |
| Lacertubo jovem | Lacertubo adulto possui arte/rig | Definir proporções de idade ou variação visual; não cadastrar como espécie nova automaticamente. |
| Desalmados | Grupo/estado descrito na bíblia | Linguagem visual própria de perda da rabiola e ausência de vontade; escolher espécies-base e produzir variantes, sem criar “espécie Desalmado”. |
| Platofolha, Celofita, Riovela, Javali de Biscoito | Dex e PNGs em `assets/creatures/colecoes/`; fila `art/soulgen/pendentes/` | Conversão para Soulgen, expressões/ações e eventual atualização do acabamento. Arte já existe. |
| Sakuradente e Bicoatrevido | `art/concepts/sakuradente-bicoatrevido-v1/` | Conceitos antigos não aprovados; resolver direção antes de rig. Rai/Saber já existe, não promover Sakuradente a alias dele. |
| Azulfazo B/Velocidade e C/Inteligência | `art/soulgen/campaign-redesigns-v1/azulfazo/concept-v1/opcoes.png` | Desenvolver pranchas individuais e rigs; não redesenhar a arquitetura do zero. A/Ataque normal e possuída já prontas. |

## 4. Decisões narrativas pendentes, não designs automaticamente novos

- **Parceiros dos treinadores:** os briefs de Bruno Solda, Vasken, Odrik, Teyra, Seyran, Oruvo, Kessai e Veldren registram parceiro indefinido. Primeiro escolher entre espécies existentes e novas. Não contar oito novos Soulmonsters obrigatórios. Caio já tem Veskoro; Marisol tem direção de capivara de boia para apoio de Remar, sem resolver automaticamente sua equipe competitiva inteira.
- **Nina/Mikka/Jamile presas:** `documentation/historia/coracao-das-ruinas-arte.md` pede sprites das três aliadas; são humanas, não três novas espécies. O código atual usa capangas para libertá-las. Se houver parceiros sombrios delas, identificar primeiro o parceiro correto; não transformar os modelos de teste em canon. Exemplo: `ruinas_elo.gd` usa Azulão na final de Jamile, embora a identidade artística da abertura a associe ao Carcará.
- **Rara do Canal**, **almáticas antigas das Ruínas** e o **parceiro faminto do Pipeiro Fantasma** ainda não definem uma identidade única. São vagas de roteiro, fora dos34 briefs.
- **Eremor/Enamor:** Eremor já tem concept, rig, arte de batalha/overworld e nome no runtime. Há documentos/flags antigos chamados Enamor. Não desenhar um segundo lendário sem resolver a nomenclatura. `coracao-das-ruinas-arte.md` também ficou atrás da integração recente.
- **Rai/Saber**, **Carcará/Básica** e os antigos nomes dos Ventos não devem inflar a contagem.
- **Retalho original/mascarada:** ambos já existem. O autor escolheu masked feroz para o primeiro encontro nesta conversa, mas `retalho_story.gd` ainda chama `retalho-original`; falta alinhar a integração, não novo concept.
- **Grande Carretel:** estudos existentes arquivados após a decisão dos Carretéis das Sombras. Não reativar como boss obrigatório nem como espécie capturável.

## 5. Designs já feitos que não entram na fila de criação inédita

Rabbito, Carcará, Mata verde, Azulão, Raio de sol, Nozinho, Lacertubo, Dóber, Platyx, Rai/Saber, Riscaz, Retalho original e mascarada, Pipa-Dragão sobrecarregada e desatada, Azulfazo A livre/possuído, Trovareta, Rabiolava, Glacerol, Tufanocorte, Mormaço e Eremor. Também os outros32 registros com rig da fila histórica da Dex, conferidos pelo inventário; existência de rig não significa integração ou revisão visual atual.

## 6. Reservas: desenvolver/reaproveitar, sem redesenhar por esquecimento

- Oito alternativas dos quatro guardiões no `catalogo-concepts.json`: quadrúpede ressonante, serpente elétrica, fera de rabiolas de lava, caititu vulcânico, crustáceo de gelo, mariposa de seda gelada, tamanduá de vento, criatura aérea de espiral vazada.
- Sete reservas das explorações do Mormaço: A/B/C/D da primeira exploração e A/B/D da segunda, documentadas em `art/creatures/reservas/quatro-guardioes-v1.md`.
- Três alternativas A/B/C da capivara de boia, preservadas após escolhaD.

São18 reservas nessas três famílias, sem contar as duas evoluções alternativas do Azulão já listadas. Falta nome, atribuição de região/papel e desenvolvimento; não são18 espécies confirmadas nem18 designs ausentes. Verificar possíveis sobreposições ao selecionar um brief.

## Ordem recomendada

1. Confirmar os quatro reaproveitamentos (especialmente Tatutrama para Cavar) e fechar a lista canônica: maior redução de trabalho duplicado.
2. Produzir rig/animação de Veskoro e capivaraD, aproveitando designs já escolhidos e uso na campanha.
3. Primeiro lote realmente novo: coruja de papel-manteiga, bicho-pau, joaninha-pião e sapo-cano. Completa identidade dos primeiros ambientes após as criaturas existentes.
4. Rato de bobina, mariposa e tatu de engrenagem para Vila Operária; depois aves/crustáceos do Cais e pantanosos.
5. Estados presos/sombrios e Desalmados conforme cenas necessárias; resolver parceiros dos bosses antes de encomendar novas espécies.

Próxima ação artística proposta: **coruja de papel-manteiga**, com três arquiteturas distintas antes da prancha. Não iniciada por esta auditoria.
