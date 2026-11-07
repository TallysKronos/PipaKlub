# Pedidos visuais para o Codex · 06/11/2026

Levantamento de toda a arte que falta, feito no código e no jogo rodando (base `3b721d56`). Cada item diz onde aparece, o que o jogo usa hoje no lugar e o formato a seguir. Todos os formatos seguem um arquivo que já existe e já funciona no jogo. A ordem segue o peso para o jogador: primeiro o que aparece no caminho principal e quebra a leitura da história, depois o que só deixa o mundo repetido.

Legenda de prioridade: **A**, a história fica estranha sem isso; **B**, o lugar fica repetido ou genérico; **C**, acabamento ou pós-jogo.

## 1. Personagens no mapa (sprites de overworld)

Formato de referência: `godot/assets/npc-ds/feira-v1/veyra.png` (uma imagem por pessoa, cerca de 46–64 × 112 px, pose parada, pixel art no padrão do Kael). Os personagens que se movem em cena usam a folha de 8 direções `assets/npc-ds/professor.png` (256 × 192, quatro colunas por duas linhas, quadros de 64 × 96).

**Hoje 22 pessoas aparecem com o sprite do Professor (jaleco branco).**

| Prioridade | Bairro ou cena | Pessoas | Hoje usa | Pasta sugerida |
| --- | --- | --- | --- | --- |
| A | Centro (ato 4–5) | Davi, Vitra, Sinal, Oriel, **Leo Antena** (campeão) | Professor | `npc-ds/centro-v1/` |
| A | Condomínio (Lajes) | Jair, Lívia, Tomé, Rute, **Tainá** (campeã) | Professor | `npc-ds/lajes-v1/` |
| A | Porto Novo | Neris, Varko, Elune, Tervan, **Capitão Jurandir** | Professor | `npc-ds/porto-v1/` |
| A | Alto do Mirante | Vael, Ilyra, Orvik, Senael, **Ícaro** | Professor | `npc-ds/mirante-v1/` |
| A | Alto da Serra | Veyl, Sora, Oren, Kaiva, **Dona Neve** | Professor (ela também aparece na reunião dos campeões) | `npc-ds/serra-v1/` |
| A | Estádio | **Faye** (final da chave); Atendente do campeonato | sem sprite / Professor | `npc-ds/estadio-v1/` |
| A | Centro, ato 5 | Pipeiro Fantasma | Professor | `npc-ds/centro-v1/` |
| A | Liga (exames Vermelho e Dourado) | Dona Cida | Celina (de outro bairro) | `npc-ds/liga-v1/` |
| A | Pipa TV | Produtor da Pipa TV | Tião (do Morro) | `npc-ds/liga-v1/` |
| A | Galpão do Bando (ato 5) | Peteca, Cola-Fina, Navalha (três tenentes com nome e fala) | capanga genérico | `kits/camara-do-elo-v1/` ao lado dos capangas |
| B | Noite do cerol | Desalmado: na bíblia (§8.1), um parceiro cinzento e sem rabiola, não um capanga | capanga genérico | idem |
| B | Bosque | Guarda-parque Dito: o jogo o esconde por não ter sprite aprovado | escondido | `npc-ds/bambuzal-v1/` ou `bosque-v1/` |

Cada pessoa precisa do sprite de mapa e, se tiver fala, do retrato (seção 2). Os nomes, as falas e o papel de cada uma estão em `godot/assets/campaign/championship/districts.json`.

## 2. Retratos de diálogo

Formato de referência: `godot/assets/campaign/portrait-kael-manga-v4.png` (800 × 1200, mangá, meio corpo, fundo transparente), registrado em `content.json → portraits`. Hoje só 10 personagens têm retrato: Kael, Mãe/Heleana, Sr. Assis, Nina, Locutor, Iara, Nilo, Dora, Cauê e Celina. Os do Morro usam o recorte do próprio sprite.

| Prioridade | Personagem | Falas na campanha | Observação |
| --- | --- | --- | --- |
| A | Tyler | 36 | Retrato mangá integrado em `content.json`. Conferido no epílogo da flor a 1280×720. |
| A | Grampo | 15 | Retrato mangá integrado em `content.json`. Conferido no encontro da comporta a 1280×720. |
| A | Dona Cida | 13 | Liga. |
| A | Jamile | 9 | Integrado. Retrato da campeã na final e no pódio. |
| A | Rato | 9 | Integrado com base na prancha aprovada em `art/characters/bando-do-cerol/rato-prancha.png`. |
| A | Gollia | 7 | Integrado com base na arte de identidade da Pipa TV. |
| A | Os 12 campeões de bairro | 2+ cada | Lohan, Kleie, Dona Zulmira, Marisol, Bruno Solda e Caio Garça integrados e conferidos no HUD. Pendentes Dona Neve, Leo Antena, Tainá, Jurandir e Ícaro (Mikka já tem). |
| B | Faye, Navalha, Peteca, Cola-Fina, Capanga (masc./fem.), Atendente, Produtor | 1–9 | |
| C | Os ~45 tenentes de bairro | 1 cada | Podem usar um retrato por bairro ou o recorte do sprite, como no Morro. |

## 3. Cenários dos bairros

Os mapas já existem como geometria, mas cinco bairros vestem a arte de outro. Formato de referência: os kits em `godot/assets/overworld/kits/<bairro>-v1/` (peças isométricas como as da Feira e do Cais) e o documento `NEIGHBORHOOD-MAPS.md`.

| Prioridade | Lugar | Hoje parece | O que a história pede |
| --- | --- | --- | --- |
| A | Vila Operária (Distrito Industrial, partes A–D) | blocos cinza sem textura | galpões, chaminés, trilhos, o galpão do Bando (ato 5) |
| A | Centro (Praça da Matriz, A–C) | barracas da Feira | praça com igreja, prédios, estúdio da Pipa TV, sede da Liga |
| A | Condomínio (Lajes, A–C) | barracas da Feira | prédios, portaria, piscina, jardins e o terraço da Tainá (luta de noite) |
| A | Porto Novo (A–C) | casas do Cais Velho | terminal, docas de carga, guindastes, sinalização náutica |
| A | Palafitas (A–C) | casas do Cais Velho | casas sobre palafitas e passarelas sobre a água |
| B | Alto do Mirante (A–C) | casas da Feira sobre grama | subida, praça e mirante no topo (vento que muda a cada passo) |

## 4. Fundos de batalha

Formato de referência: `godot/assets/campaign/rooftop-arena-wide-v2.png` (1672 × 941), com a linha do horizonte e o piso na mesma altura.

Hoje os duelos de bairro usam o mesmo terraço, menos nas Palafitas. Todos os duelos 1 contra 1 fora das Ruínas usam as Veredas, inclusive a final no Estádio.

| Prioridade | Arena | Usada em |
| --- | --- | --- |
| A | Estádio de Kronasta | toda a chave final (Grampo, Tyler, Faye, Jamile) |
| A | Cume da Serra | Tufanocorte, Dona Neve e o Alto da Serra |
| A | Galpão do Bando | tenentes, capangas e Pipa-Dragão |
| B | Uma por bairro | Bambuzal, Beira-Canal, Feira, Cais, Centro, Condomínio, Porto Novo e Mirante integrados e renderizados em Godot. Vila Operária integrada. Palafitas já tem arte própria. |
| B | Aracati (terreiro) e Bosque (Clareira na tempestade) | Integrados para Rabiolava, Navalha e Trovareta. |
| C | Pântano | Integrado para Mormaço. |

O código escolhe o fundo em `encounter_view.gd` (linha do `background`) e em `morro_battle_view.gd`. Com os arquivos prontos, eu ligo cada um ao seu lugar.

## 5. Criaturas

Formato de referência: a arte de batalha em `content.json → combat` (folha com `idle`, `attack`, `victory`, `defeat`; por exemplo `combat-basic-azulao.png`, 2048 × 4608) e o sprite de mapa quando a criatura anda no mundo (`platyx-overworld-eight.png`).

**Hoje os 55 rivais de bairro e quase todos os duelos de história usam as quatro espécies básicas (Carcará, Raio, Mata verde, Azulão) ou o Lacertubo.**

| Prioridade | Criatura | Hoje usa | Onde |
| --- | --- | --- | --- |
| A | Parceiro do Rato | Azulão | Câmara do Elo, chefe do ato 6 |
| A | Parceiro da Jamile | Azulão | final do título |
| A | Parceiro do Gollia (a bíblia o descreve à parte) | Azulão | galpão e Câmara |
| A | Parceiro da Faye | Lacertubo | final da chave |
| A | Platyx (versão final) | `platyx-draft` (rascunho) | Grampo, Beira-Canal, Ruínas e Estádio |
| A | Desalmados (cinzentos, sem rabiola) | Lacertubo/Raio | noite do cerol |
| B | Bicho-pau de Vareta e Joaninha-pião (versão final) | rascunhos marcados "[rascunho]" | Bambuzal, Feira e Clareira |
| B | Espécies novas por região (§8.1 da bíblia) | as quatro básicas | coruja de papel-manteiga e sagui (Bosque); sapo-cano (Beira-Canal); pombo de jornal, gato de saco de papel e papagaio de feira (Feira, Centro); caranguejo-carretel e gaivota (Cais, Porto Novo); mariposa de lâmpada, rato de bobina e tatu-bola de engrenagem (Vila Operária); jacaré-arraia, garça de crepom e capivara de boia (Pântano); guaiamum e boto de papel (Palafitas); gavião-carrapateiro, lagarto de pedra e lobo-guará (Serra); morcego de antena e urubu-rei de cartaz (Centro, Condomínio) |
| C | Lendário do Santuário e errantes das partes D | — | pós-jogo (§14), ainda sem conteúdo no jogo |

Os briefs das espécies novas seguem o agente de concept (`.agents/skills/soulmonsters-concept-personagens/`), como a bíblia já indica. Proponho começar pelas criaturas da linha A, porque são parceiros de personagens com nome que a história apresenta.

## 6. Itens e insígnias

Formato de referência: `godot/assets/ui/key-items/insignia-morro-do-sol.png` (128 × 128).

| Prioridade | Item | Hoje |
| --- | --- | --- |
| A | Insígnias dos outros 11 bairros (Bambuzal, Beira-Canal, Feira, Cais, Vila Operária, Palafitas, Alto da Serra, Centro, Condomínio, Porto Novo, Mirante) | o porta-emblemas mostra espaço sem selo |
| A | Fita dourada da Liga (título) | só a linha desenhada no pódio |
| A | Braçadeira do Bando, Flor de cerejeira, Apito de vento, Apito de Lalau, Agulha de desatar (esta já tem SVG; refazer no padrão PNG se quiser unificar) | ícone genérico da mochila |
| B | Certificados das rabiolas Verde e Azul; Autorização do Carcará da Nina; Fecho da guia; Página do caderno | ícone genérico |
| B | Materiais da oficina: papel de seda, vareta de bambu, cola de reparo, linha encerada | ícone genérico |
| C | Rabiolas dos rascunhos (Bicho-pau, Joaninha) | Ícones próprios ligados à mochila e à recompensa. |

## 7. Mapa da cidade

`godot/assets/campaign/maps/kronasta-atlas-v1.png` (1536 × 1024) foi pintado antes dos atos 4–6. O Centro, o Condomínio, o Alto do Mirante, o Estádio e o Porto Novo não aparecem na pintura, e os marcadores ficam sobre floresta e campo (as posições em `kronasta_atlas.gd` são provisórias). **Prioridade A:** uma versão v2 com esses cinco lugares visíveis. Com a v2 pronta, eu acerto as coordenadas.

## 8. Cenas da história sem imagem

| Prioridade | Cena | Hoje |
| --- | --- | --- |
| B | Epílogo (§13): câmara do ovo com a chave em pedaços; Assis e Tyler no ateliê; Heleana convidando o Kael (três vertentes da Retalho); carretel do Tyler se desfazendo (pós-créditos) | quatro quadros integrados, capturados no fluxo de créditos |
| B | Câmara após o Eremor: pedaços da chave do Elo | cinco fragmentos ilustrados em atlas e animados na cena |
| C | Fita passando ao carretel no pódio | linha desenhada em código (`TitleRibbon`) |

Para as ilustrações, um quadro por página no formato das cenas da Pipa TV (`art/pipa-tv-cinematic-v3`) basta. O código já exibe as páginas; eu troco o fundo de cada uma pela imagem.

## Ordem sugerida de produção

1. Sprites e retratos dos cinco bairros dos atos 4–6 (Centro, Condomínio, Porto Novo, Mirante, Serra), da Faye e do Tyler. É o que mais aparece com o Professor no lugar.
2. Mapa da cidade v2 e as 11 insígnias.
3. Arenas do Estádio, da Serra e do galpão.
4. Cenários da Vila Operária, Centro, Condomínio, Porto Novo e Palafitas.
5. Parceiros do Rato, Jamile, Gollia e Faye; Platyx final; Desalmados.
6. Espécies regionais, ilustrações do epílogo e o pós-jogo.

## Correções feitas durante o levantamento

- No Estádio, o Tyler lutava com uma Mata verde; agora luta com o Rai, que já tinha arte de batalha.
- As falas da Heleana nos atos finais não mostravam retrato, porque o retrato estava registrado como "Mãe"; agora usa o mesmo.
- A Braçadeira do Bando e a Flor de cerejeira apareciam na mochila com o nome interno; agora têm nome.

## Entregas do lote visual

- Retratos de Jamile, Gollia e Rato ligados ao diálogo. Os títulos com nível ou afiliação também resolvem o retrato do personagem.
- Onze insígnias regionais ligadas à grade e ao detalhe do porta-emblemas. Treze ícones de missão e fabricação ligados ao inventário, além da fita dourada do encerramento.
- Atlas v2 ligado ao mapa e à seleção de save, com marcadores reposicionados sobre os cinco marcos novos.
- Fundos de combate do Estádio, Cume da Serra e Galpão ligados aos encontros correspondentes e renderizados com o HUD. Galpão com iluminação noturna. O fluxo automatizado do Galpão passou em 129 verificações com resultados de batalha simulados.

### Refino explorável dos bairros

- Centro, Condomínio, Porto Novo e Palafitas receberam pisos e volumes próprios nas pegadas existentes. O Centro recebeu um campanário como marco. O Alto do Mirante foi renderizado para conferência.
- O passe preserva os caminhos, cotas, colisões e eventos. A leitura de cada acesso em escala de jogo, os marcos adicionais e a revisão dos percursos A–C ainda estão pendentes.
