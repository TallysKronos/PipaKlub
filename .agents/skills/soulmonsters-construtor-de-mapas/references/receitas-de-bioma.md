# Receitas de bioma

Pontos de partida. Cada receita diz a estrutura (camada 1), o percurso, o acabamento que costuma
quebrar e a vida. Ajuste à história da área.

## Floresta / mata (Kronasta, Bosque dos Ventos)

- **Estrutura:** 2 a 4 platôs de nível 1 (≥ 40% da área), uma mesa de nível 2 coberta de mata como
  marco, moldura de mata de 4 a 7 células, anel além do mapa.
- **Percurso:** trilha principal em curva entre os platôs, ligando entrada e saída por lados opostos;
  um ramal por platô, chegando pela face da frente e subindo em `u-`/`v-`; mato de encontro em manchas
  fora da trilha.
- **Costuma quebrar:** rampa virada para a câmera (some); copa tapando a trilha; paredão serrilhado
  quando a trilha corta o platô na diagonal; bolsão de grama atrás de platô sem acesso.
- **Vida:** item brilhando no alto de um platô; item escondido atrás de copa; bosques soltos de 3 a 7
  copas; flores e pedras em grupos; tufos nas bordas.
- Exemplo pronto: `kronasta-bosque-a`.

## Morro / bairro (Rua dos Ventos, Morro do Sol, bairros 2 a 12)

- **Estrutura:** ruas em patamares; barranco urbano é **muro de arrimo** (chapisco, bloco); laje com
  **mureta de borda**; escadaria de pedra ligando patamares; lotes com muro de divisa.
- **Percurso:** eixo ou praça central, ruas com os capangas, um descanso (banco, bica), a arena do
  campeão no ponto mais alto ou mais simbólico. 4 a 6 casas por tela de bairro.
- **Costuma quebrar:** casa com base oblíqua ao piso (confira as duas arestas da base e os três cantos,
  `continuidade-terreno-isometrico.md`); mureta atravessando boca de escada; acabamento alternando
  pedra e reboco no mesmo canto; vão de 1 célula no muro parecendo passagem.
- **Vida:** varal, caixa-d'água, fio de poste com pipa enroscada, muro pintado, campinho de terra.
  Objetos em conjuntos com função.

## Vereda / água (Veredas, rios, lagoas)

- **Estrutura:** água como plano baixo que organiza margens; margem natural curva e assimétrica;
  ponte com cabeceira e apoio; quando há cachoeira, poço rebaixado de verdade.
- **Percurso:** travessia como evento de percurso (ponte, pinguela, pedras); um desvio pela margem.
- **Costuma quebrar:** água como retângulo pintado sobre o chão; ponte sem terra firme nas pontas;
  espuma ou lateral vazando para fora da margem; textura de margem com fase diferente entre trechos.
- **Vida:** buriti, terra vermelha, arenito, reflexos, rastros do Bando do Cerol (peças arrancadas).

## Ruínas / caverna (Caverna do Mural, Coração das Ruínas)

- **Estrutura:** arenito gasto em terraços construídos; escadas e muretas de pedra; canais e tubos de
  barro; poço de cachoeira (`cave_basin.gd`).
- **Percurso:** entrada marcada com o motivo do nó (dois traços que se encontram); câmaras ligadas por
  passagens estreitas; o mural como marco e recompensa.
- **Costuma quebrar:** terraço sem face até a base; escada com o último degrau sobrando; parede
  atravessando passagem entre pisos da mesma cota.
- **Vida:** apitos de barro movidos pelo vento, murais, sinais do Bando, luz entrando por fendas.

## Antes de começar um bioma novo

Monte uma **sala de testes** do kit: trechos longos, curva, cruzamento, canto interno e externo,
rampa e escada nas direções visíveis, ponte, margem, mureta com canto e ponta, objetos junto às bordas.
Capture em cores chapadas e com arte. Só depois use o kit num mapa de jogo.
