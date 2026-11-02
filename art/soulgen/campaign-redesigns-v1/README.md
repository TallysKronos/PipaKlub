# Soulmonsters da campanha — conversão Soulgen

Estado: levantamento e propostas visuais. Nenhum modelo novo integrado ao jogo.

## Fontes e precedência

- Git remoto consultado em 02/11/2026, sem merge nos menus provisórios.
- Bíblia v2 da `origin/claude/unificacao`, decisões em `4495b525`. Cópia auditável: `historia-4495b525.md`.
- A história da `origin/feature/retalho-bosque-d` contém uma versão anterior da bíblia: os nomes Terral/Mormaço/Minuano/Aracati não substituem Trovareta/Rabiolava/Glacerol/Tufanocorte.
- Retalho: `art/characters/retalho/DECISOES.md` e `original-v1/prancha.png` da branch `origin/feature/retalho-bosque-d`, commit `c4fb5da0`. A arquitetura A foi escolhida pelo dono; respeitar a distinção original/possessão/evolução.
- As seis imagens enviadas pelo dono nesta conversa definem o acabamento: papel facetado, contorno escuro, estrutura artesanal, recortes completos e expressões legíveis. Anatomia específica continua própria de cada espécie.

## Primeiro lote narrativo

| Criatura | Contrato da história | Situação visual |
|---|---|---|
| Retalho | Parceira da Heleana; original e posterior forma marcada pelo ataque do lendário | Identidade aprovada já existe em outra branch; converter sem reinventar |
| Platyx | Ornitorrinco, parceiro do Grampo; contraste entre saque e recusa em obedecer | Arte existente em outra branch; inspecionar antes da conversão |
| Rai | Tigre dente-de-sabre, parceiro do Tyler | Conferir identidade existente e alias Saber; não criar uma segunda espécie por diferença de nome |
| Trovareta | Trovão + vareta; floresta à noite durante tempestade | Arquitetura A escolhida pelo dono após refinamento de trovão; rig pendente |
| Rabiolava | Lava + rabiola; vulcão | B escolhida pelo dono; A/C reservadas como outros Soulmonsters; rig pendente |
| Glacerol | Geleira + cerol; gelo | A escolhida pelo dono; B/C reservadas como outros Soulmonsters; rig pendente |
| Tufanocorte | Tufão + corte; montanha | Exploração A/B/C: carneiro de espirais cortantes, tamanduá de cauda em leque e náutilo aéreo; escolha pendente |
| Pipa-Dragão | Corpo com três rabiolas roubadas; forma desatada menor | Precisa diferenciar as duas formas sem inventar espécie canônica |
| Parceiro do Gollia | Forma sobrecarregada pelo Carretel Negro | Primeiro identificar o parceiro normal; não inventar substituto |
| Grande Carretel | Chefe em partes, quatro carretéis menores e duas fases | Objeto/constructo de chefe; não cadastrar automaticamente como espécie capturável |
| Lendário do Santuário | Visitante do mural; nome/design ainda pendentes | A bíblia pede 2–3 opções para escolha do dono |
| Parceiro do Rato | Identidade pendente na bíblia | Conferir propostas anteriores de Riscaz e escolhas do dono antes de produzir |

## Espécies regionais novas (§8.1)

Os nomes abaixo são nomes de trabalho do roteiro, não novos nomes aprovados para a Dex.

- Bosque: coruja de papel-manteiga, sagui de rabiola longa, espécie-tatu e onça de bambu.
- Bambuzal: bicho-pau de vareta e joaninha-pião.
- Canal: sapo-cano e Lacertubo jovem (variante etária, não espécie nova).
- Feira: pombo de jornal, gato de saco de papel e papagaio de feira.
- Cais: caranguejo-carretel, gaivota de sinalização e peixe-voador de seda.
- Vila Operária: mariposa de lâmpada, rato de bobina e tatu-bola de engrenagem.
- Pântano: jacaré-arraia, garça de papel crepom, capivara de boia e sucuri de rabiola.
- Palafitas: guaiamum e boto de papel; reutilizar a garça, sem duplicar espécie.
- Serra: gavião-carrapateiro, lagarto de pedra, lobo-guará de vareta e condor de pandorga.
- Vulcão: salamandra de brasa, urubu de fuligem, tatu-bola de pedra-pomes e fênix de papel-carvão.
- Geleira: pinguim de papel-vegetal, raposa de neve de seda e arraia-jamanta de gelo.
- Centro: morcego de antena e urubu-rei de cartaz; reutilizar pombo de jornal.
- Ruínas: formiga de mural, coruja de pedra e almáticas antigas ainda sem espécie definida.
- Desalmados são estados de espécies existentes, não simples novas espécies cinzentas.

## Ordem de produção proposta

1. Recuperar identidades existentes e produzir propostas dos Quatro Ventos, começando pela Trovareta.
2. Validar uma pose completa antes de decompor. Não confundir folha de conceito com rig utilizável.
3. Gerar família de partes: torso limpo, cabeça, membros próprios, velas e rabiola completa com fio e amarração.
4. Montar pivôs anatômicos, parentesco e profundidade próprios. Expressões neutra/golpe/dano/vitória registradas.
5. Inspecionar repouso, voo/deslocamento, golpe, dano e vitória; propor ação coerente com anatomia, sem copiar amplitudes de outro rig.
6. Só depois exportar/integrar quando solicitado. Manter fontes e PNGs aprovados, sem sobrescrever rascunhos manuais do editor.

Branch de trabalho: `codex/soulgen-redesigns`. Sem merge, push ou alteração de código do jogo nesta etapa.

## Banco de criaturas reservado pelo dono

Índice persistente: `catalogo-concepts.json`. São seis conceitos para outros Soulmonsters, ainda sem nomes: quadrúpede ressonante (Trovareta B), serpente elétrica (Trovareta C), fera de rabiolas de lava (Rabiolava A), caititu vulcânico (Rabiolava C), crustáceo de gelo (Glacerol B) e mariposa de seda gelada (Glacerol C). As opções escolhidas, Trovareta A, Rabiolava B e Glacerol A, também estão no índice. Nenhum desses registros adiciona uma espécie ao runtime ou declara um rig pronto.
