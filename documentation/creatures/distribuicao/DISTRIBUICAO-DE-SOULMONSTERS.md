# Distribuição de Soulmonsters nos mapas · proposta de 07/11/2026

Estado: **proposta** para o dono decidir. Nenhuma espécie nova entra no jogo por este documento. A
arte do catálogo é quase toda *concept*; cada família que entrar em campo precisa de rig ou atlas
de batalha.

Fontes internas:

- [catálogo de famílias](../familias/FAMILIAS.md) (110 famílias, 326 formas);
- `BIBLIA-DA-HISTORIA.md` §2.2 (enroscada e drop), §8 (chefes) e §8.1 (selvagens por região, com
  espécies inventadas que aqui viram famílias reais);
- [benchmark de Digimon World DS](../../benchmark-digimon-world-ds/README.md).

## 1. Como Pokémon distribui

Os números de probabilidade são os conhecidos dos jogos principais. A Bulbapedia não abre nesta
sessão, então esses valores ficaram sem verificação nesta rodada.

- **Tabela por área.** Cada rota, caverna ou cidade tem a própria tabela de espécies com peso.
  - Na grama da 3ª e 4ª gerações são 12 vagas: **20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1 e 1%**.
  - Na 1ª geração são 10 vagas: 20/20/15/10/10/10/5/5/4/1.
  - Na prática: 2 ou 3 espécies comuns fazem 60–70% dos encontros, 2 ou 3 incomuns fazem cerca de
    25%, e uma ou duas raras ficam entre 1% e 5%.
- **Poucas espécies por rota.** Uma rota tem de 4 a 6 espécies. Muitas espécies se repetem nas
  rotas vizinhas, com nível maior.
- **Cada terreno tem a sua tabela.** Grama, água (surfar), pesca (vara velha, boa e super), cavernas,
  árvores e pedras quebráveis. Uma habilidade de campo nova revela espécies que estavam escondidas
  em lugares antigos.
- **Dia e noite, clima e surtos.** A mesma rota troca espécies por horário. Surtos põem uma espécie
  rara em evidência por um tempo.
- **Estágios acompanham a jornada.** As formas básicas aparecem no começo. A forma intermediária
  aparece selvagem mais tarde, perto do nível em que evoluiria. A forma final quase nunca é
  selvagem antes da Estrada da Vitória e do pós-jogo.
- **As rotas iniciais ensinam o ciclo.** As primeiras rotas trazem pássaro, roedor e inseto, que
  evoluem rápido e mostram como a evolução funciona.
- **Quem nunca é selvagem.** Os iniciais e os lendários. Os lendários são chefes de história (o
  Kyogre e o Groudon) ou ficam no pós-jogo, em lugar fixo e único.
- **Espécie-assinatura.** Um ponto escondido guarda uma espécie forte (o Dratini na Zona Safári, o
  Larvitar no Monte Prateado). É a recompensa por explorar.
- **Líderes temáticos.** Cada líder usa um tipo. Os treinadores da rota usam as espécies da rota.
- **Chefe que é espécie comum em versão maior.** Totem (Sol e Lua), Alfa (Legends Arceus) e Titã
  (Escarlate e Violeta): um indivíduo enorme de uma espécie comum, visível no mapa e opcional.
- **Encontros visíveis** (Let's Go e a Área Selvagem): o jogador escolhe a luta. As espécies grandes
  e fortes andam em zonas próprias e servem de aviso de perigo.

## 2. Como Digimon distribui

- **Digimon World 1 (PS1).** Cada Digimon "mora" num lugar. Depois de vencido (às vezes com uma
  missão), ele se muda para a cidade, e a cidade cresce. Os chefes são personagens com casa e
  história.
- **Digimon World DS / Digimon Story.** Cada área tem algumas subáreas e um conjunto fixo de cerca
  de 4 a 8 espécies, de atributos variados. A área termina num chefe (Champion ou Ultimate).
  - Vencer a mesma espécie várias vezes enche a porcentagem de varredura (scan). Com 100%, a espécie
    pode ser criada.
  - No pós-jogo, áreas antigas voltam com níveis maiores e chefes extras, e a curva vai até 60.
  - O estágio acompanha o avanço: Rookie no começo, Champion no meio, Ultimate no fim, Mega no
    pós-jogo.
- **Digimon World Dawn e Dusk.** As duas versões dividem os conjuntos de espécies por família:
  - Dawn: água, ave, dragão e sagrado;
  - Dusk: trevas, máquina, orgânico e fera.
- **Digimon World 2003.** Encontros aleatórios por domínio. Os Tamers inimigos têm equipes fixas.
  Os chefes de domínio são marcos.
- **Digimon World: Next Order.** Os Digimon ficam visíveis no campo, e os grandes servem de aviso.
  Recrutar é uma missão, e cada recrutado muda a cidade, como no primeiro jogo.

## 3. O que adotamos

| Regra | De onde vem | Como fica no nosso jogo |
| --- | --- | --- |
| Tabela por **parte** (A, B, C e D) | Rota (Pokémon) e área (DW DS) | Cada parte tem a sua tabela. A parte A ensina o bairro, a C tem o marco, a D é pós-jogo ou noite. |
| 3 comuns, 1 incomum, 1 rara e 1 visitante | Grama da 3ª geração | Pesos de 35, 25, 18, 12, 6 e 4%. O **visitante** é uma espécie da região seguinte, que antecipa a viagem. |
| Raras em mato denso e à noite | Grama alta e horários de Pokémon | A rara só aparece em `mato`. As noturnas só aparecem à noite (o ato 5 já tem noite). |
| Habilidade de campo abre tabela nova | Surfar e Quebra-pedra | **Remar** (água), **Cavar** (terra fofa) e **Planar** (correntes) revelam espécies próprias em regiões antigas. É o motivo para voltar. |
| Estágio pela faixa do ato | DW DS e Pokémon | **Bebê** até o Nv.15. **Criança** do Nv.12 ao 30. **Jovem** do Nv.26 ao 45 (rara antes disso). **Adulto** só como errante, guardião ou no pós-jogo. |
| Espécies se repetem nas vizinhas | Pokémon | Uma família aparece em 2 ou 3 regiões vizinhas, com estágio e nível subindo. |
| Treinadores usam a espécie do lugar | Treinadores de rota e líderes temáticos | Os tenentes de cada bairro usam as comuns da região. O campeão usa a **família-assinatura** do bairro (seção 5). |
| Guardião de área | Totem, Alfa e chefe de área do DW DS | Um **Adulto** de uma família local, maior e visível no fim da parte C ou na D. Opcional, com rabiola garantida na primeira vitória. |
| O vencido vai para a cidade | Digimon World 1 | Alma solta volta ao **Varal**: já existe (§9). Os guardiões vencidos aparecem no Varal ou no bairro. |
| Quem nunca é selvagem | Iniciais e lendários | **Rabbito**, **Rai**, **Platyx** (decidido), os **Quatro Ventos**, o **Eremor**, a **Retalho**, a **Pipa-Dragão** e o **Veskoro** (campeão). |

**Enroscada e drop** (§2.2) fazem o papel da varredura do DW DS. Quanto mais rara a espécie, menor
a chance. Os valores serão medidos no percurso; aqui não há números.

## 4. Famílias por região

Os nomes são os do catálogo (a família pelo primeiro estágio, quando ele tem nome). O estágio é o
que aparece selvagem naquela faixa. Entre parênteses está a espécie que a bíblia §8.1 pedia e que
esta família cobre.

| Região (níveis) | Comuns | Incomum | Rara | Visitante | Errante ou guardião (C/D) |
| --- | --- | --- | --- | --- | --- |
| Parque dos Ventos (1–8) | Mata Verde (Bebê), Azulim, Carquim | Pivico (galo) | Solim (Raio de Sol) | Brotim do cervo | Guardião: Lacertubo (já existe) |
| Bosque (1–5) | Brotim do cervo, Mata Verde, mico-samurai Bebê (sagui) | Caramund Bebê | Yaguim (onça, só à noite) | Cantim | D: Yaguarion (onça de bambu, noite) |
| Bambuzal (9–12) | Cantim (cigarra), Sussurim (flauta), cacaurama Bebê | Vespim | Tamanduá-tear | Selim | C: Vesperália |
| Beira-Canal (12–15) | Makim, Cascoronte Bebê, Penim (íbis) | Gotim (capivara) | Ofita | Bobim | C: Makaréu |
| Feira do Largo (15–18) | Selim (escaravelho), Gevim (saco de papel), gambá Bebê | Velim (camelo de caravana) | Javali de Biscoito | Recim | C: Velaravan |
| Caverna do Mural (15–18) | Seixim, Calquim (fóssil), viúva-anjo Bebê | Vortim | Entrelaço Paleórix (só depois do ato 6) | — | — |
| Cais Velho (18–21) | Recim (caranguejo), Marulhim (raia), Gotim | Bolhim | Pevidim (cavalo-marinho lanterna, noite) | Braseco | C: Alvorraia |
| Distrito Industrial (20–24) | caracol-pneu Criança, Braseco (brasa), Risaco (hiena) | pangolim-trovão Criança (tatu-bola de engrenagem) | Raptório Jovem | Atadim | D: Pipa-Dragão remendada (já na bíblia) |
| Pântano (5–7 na prévia; 23 na trajetória) | Atadim (jacaré), Capiboia, Ofirisco | anaconda do retrato Criança (sucuri) | Hipomoranga | Ibisco | D: Crocáfago |
| Palafitas (24–27) | Ibisco (garça), Recipinça (guaiamum), Capiboia | Cavalume | Coromar | Grifote | — (o campeão é o Veskoro) |
| Serra de Kronasta (26–32) | Grifote, Gravurso Criança, avelince Criança | Lupisco | Lince de Cerco Jovem | Nimbala | D: Grifarca (condor de pandorga) |
| Alto da Serra (27–30) | urso-polar Criança, Nimbala, Lupisco | Íbex-astrolábio | Alvaneve | — | C: Borealvo |
| Ilha do Aracati (30–34) | Trincaguarda, javali-guerreiro Jovem, Gevisco | Jarabrasa | Auriflama | — | Rabiolava (chefe de história) |
| Centro (30–33) | Riscaz, Miralís Criança, Chaspiral | melicódia Jovem (antena) | coruja-balança Jovem | gata-lunar Jovem | D: Dirubastião |
| Condomínio (33–36) | Dobrim (cão de guarda), Tatimbo (rolo de cartaz), gata-lunar Jovem | Torvargo Jovem | Chavalsa | Vortelo | C: Dobrácula |
| Porto Novo (36–40) | Vortelo, Coromar, Remansa (capivara Jovem) | Makaronda | Vortentáculo (adulto, noite) | Celofita | C: Marévia |
| Coração das Ruínas (40–45) | Ossirrex, Brontela, Cervela | Caligíbis | linha "memória": Araruna, Caimbira, Tamoatá | — | Eremor (chefe de história) |
| Alto do Mirante (40–44) | Grifalce, Nimbordo, Etrusvara | Guaravento | Pteralis | — | C: Etruslança |

**Famílias sem lugar ainda**, para decidir: Lobo-cordeiro (tem a forma Voto do Elo, ligada à
história?), Nozinho (personagem da bíblia), Stegaru, Rexal e Tricerafan (fósseis; candidatos a
Ruínas ou ao pós-jogo), Herravento, Celofita, Riovela, Hiponilo, Marulume, Azulongo, Capimansa,
Micofolha, Platofolha, Umbrocasco, Nevagume, Jaguarluar, Glacerol (saiu da história em 04/11),
Lupunhal e Crocáfago (entraram acima só como formas) e Galofuso (Pivico entrou como incomum do
Parque).

## 5. Chefes: quem pode ser chefe e de que tipo

| Tipo | Regra | Candidatos |
| --- | --- | --- |
| **Chefe de história** (único) | Nunca selvagem. Tem nome próprio e cena. | Os Quatro Ventos (Mormaço, Tufanocorte, Rabiolava e Trovareta), Eremor, Retalho, Pipa-Dragão, Platyx (do Grampo), Lacertubo (Veredas) |
| **Família-assinatura de campeão** | O ás do campeão é o **Adulto** de uma família da região. Os tenentes usam as comuns. | Mikka: Solguarda. Lohan: Vesperália. Kleie: Makaréu. Zulmira: Velaravan. Marisol: Alvorraia. Bruno Solda: Fulguar (pangolim). Caio Garça: Veskoro (já existe). Dona Neve: Borealvo. Leo Antena: Melicódia. Tainá: Dobrácula. Jurandir: Vortentáculo. Ícaro: Grifarca. Jamile: Azulígero (o Azulão já é o modelo dela). |
| **Guardião de área** | Adulto local, maior e visível no fim da C ou na D. Opcional, com rabiola garantida na primeira vitória (como os chefes das Trilhas). | Coluna "Errante ou guardião" da seção 4 |
| **Errante noturno** | Jovem ou Adulto que só anda à noite ou na parte D. | Yaguarion, Jaguarluar, Vortentáculo, Hipolanterna, Noctiluna |
| **Lendário do pós-jogo** | Lugar fixo e único, uma luta, com enroscada garantida no fim (como o Eremor desperto da §14). | Os oito cavaleiros: Bradamara, Cidraco, Geordraco, Joanacendra, Lacustrel, Rolandor, Tomoeryu e Valdrisa. Podem formar a **Liga dos Campeões**, um por bairro antigo, ou guardar as partes D. |

## 6. Como entra no código

Hoje as espécies estão fixas em `encounters.gd` (Bambuzal, Feira e Beira-Canal) e o resto usa
basica/mata/raio. A proposta é um arquivo de dados `godot/assets/campaign/encounters.json`:

```json
{"kronasta-cais-a": {"day": [["reciferreo-bebe", 35], ["alvorraia-bebe", 25], ["capivara-bebe", 18],
  ["coroabissal-bebe", 12], ["hipolanterna-bebe", 6, "mato"], ["trinca-brasas-bebe", 4]],
  "night": [...], "remar": [...], "cavar": [...]}}
```

O nível continua em `park_pacing.wild_level`. A espécie entra pelo `modelId`; sem arte de batalha,
a família não entra na tabela. Os tenentes passam a ler a espécie da tabela da região em vez da
cor.

## 7. Ordem sugerida

1. O dono escolhe: famílias por região (seção 4) e família-assinatura de cada campeão (seção 5).
2. **Primeira leva**, uma família por região dos atos 1–3, para ter variedade já no começo: Brotim
   do cervo, Cantim, Makim, Selim, Recim, Braseco e Atadim. Pedido de arte de batalha ao Codex.
3. Tabelas em JSON e leitura em `encounters.gd`. Teste: toda região tem tabela, nenhum
   "nunca selvagem" aparece, e a soma dos pesos é 100.
4. Depois, guardiões das partes C e D, e as tabelas de Remar e Cavar.
