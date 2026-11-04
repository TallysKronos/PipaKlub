# Parque dos Ventos A — Jardim das Pipas

Primeira área do parque depois do Morro do Sol. Recriação espacial do mapa existente `jardim-das-pipas`, mantendo a cena `park-trail`, IDs e ações existentes. A coleta da rabiola da Nina continua nas Veredas; o Jardim prepara a descoberta com os indícios previstos na bíblia, sem conceder item de missão ou revelar a identidade de Tyler. Cena narrativa/quest é pedido ao integrador.

## Planta de intenção — 48×40, u→ / v↓
```
              moldura de mata e pomar
 [pomar nível1]                 saída B (36,0), v−, terra0
 [mangueira/jabuticabeira]          |  [terraço norte1]
 [item escondido / mato opcional]           |    rampa v−
 [platô do jardim1]--[CORETO1]      |
 [floradas em grupos] [praça]       trilha baixa segura
         rampa v−     escada v−    | [mirante1/item]
             \        |           |     rampa v−
              praça baixa --------+---------/
     entrada (8,36)        indício de pegadas
     saída Rua (8,39), v+        fora da rota
```

Marco principal: coreto no patamar central, visível da praça baixa. Dois marcos secundários: pomar à esquerda e mirante florido à direita. Ritmo: entrada estreita → praça baixa aberta → escada entre bordas → praça do coreto; rota para B estreita entre os platôs, abrindo novamente antes da saída. Caminho principal 4 células, ramais 2–3, rampas sempre v−. Altura decidida em blocos 2×2; ≥40% de platô. Mata de moldura 4 células, com continuação além do mapa.

Três acessos opcionais têm finalidade: pomar leva a material escondido; mirante oferece item/vista; mato no pomar permite encontro; a praça baixa apresenta as pistas sem exigir combate na travessia. Coreto, bancos, canteiros e pomar são grupos de uso, não objetos distribuídos uniformemente. Os pilares existentes do coreto continuam bloqueios independentes, com passagem entre eles. Guardas sobre a borda da praça alta deixam a escada aberta.

Arte: reutilizar kits aprovados de chão/relevo, coreto e mobiliário do parque e frutíferas; chão claro e floradas distinguem o parque da floresta. Nenhuma nova arquitetura ilustrada antes de validar a blocagem. Capturas geral/jogo/detalhes em geometria e arte, sem atores sobre juntas, mais terreno sem vegetação. Comparação com o mapa anterior.

Conexão A→B: v− em (36,0), terra0, chegada na entrada atual da Clareira. Retorno B→A: v+ na saída existente da Clareira, chegada (36,2) em A. Somente metadados de chegada de B podem mudar nesta etapa; B/C continuam versões antigas e serão redesenhadas depois. Registrar esta limitação, sem declarar a região inteira renovada.
