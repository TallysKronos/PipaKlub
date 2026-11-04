# Ilha do Aracati

A ilha abre após o Alto da Serra. O confronto fica na parte C. Rato observa e tenta recrutar Kael, que recusa. Libertar Aracati dá acesso à Corrente de ar. O caminho obrigatório de ida deve funcionar antes de receber essa habilidade.

```text
A | continente == ponte/cancela == desembarque amplo
  |                                    + enseada (item oculto)
  |                         escada ^ platô 1 -- saída B
B | entrada A -- trilha costeira -- mirante aberto
  |                  + mato opcional / item
  |                  + banco / item oculto
  |               rampa ^ platô 2 -- saída C
C | entrada B -- corredor de pedra -- terreiro do confronto
  |                   + reentrância (item oculto)
  |            platô 2: Aracati no centro, Rato na lateral
  |            retorno curto para A após a libertação
```

- A alterna a vista aberta do desembarque, a ponte estreita e a abertura do platô. A cancela é o marco principal.
- B alterna o mirante aberto, o trecho entre barrancos e o descanso. O mato de encontro fica no ramal lateral.
- C abre no terreiro. A silhueta de Aracati serve de marco. Kael, Rato e Aracati têm posições próprias, fora da faixa de passagem e sem sobreposição na câmera.
- As duas pontas de cada ligação usam a mesma cota, direção e superfície. Subidas orientadas para u- ou v-. Cada parte reserva três pontos de item, um deles escondido e alcançável.
- Referência de escala: Kael no overworld do Godot. Sprites e objetos usam a mesma projeção 2:1 e luz. Os pés dos personagens ficam ancorados na superfície. Validar numa captura com o elenco e em outra com as juntas livres.
- Geometria, arte, conexões e capturas ainda pendentes.

## Revisão integrada A/B/C

A, B e C usam o mesmo acabamento costeiro, com trilha orgânica por nível, espuma nas bordas e faces quentes nos barrancos. B ganhou os recortes da costa, descanso ao lado da trilha e mirante; C ganhou uma praça ampla para o confronto, com Rato em seu ponto original (28, 11). A arte de Aracati depende de aprovação, e o centro está reservado para ele.

Conferência Zero Quebra sem erros ou avisos nas três partes. A, B e C têm respectivamente 40,2%, 55,4% e 47,6% de platô. O Godot calculou uma rota da entrada a cada evento e aos pontos focais, e renderizou Kael e Rabbito nos três. Os seis testes do Mapa Studio passaram. A campanha, o comportamento do confronto e a travessia manual das ligações ainda precisam ser validados.
