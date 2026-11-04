# Remar · Pântano A · percurso sobre cenário existente

Não altera planta, cotas, paredes, ponte, árvores nem itens. Duas interações de embarque são acrescentadas pelo adaptador da campanha. Capivara D escolhida pelo dono, empréstimo de apoio de Marisol, sem entrada no banco.

```text
      margem norte (16.5,18.5) · cota0 / terra ou grama
              ↑       ↓
       água cota0 · seis células internas
              ↑       ↓
      margem sul (16.5,25.5) · cota0 / terra ou grama
                    → ponte existente / alternativa a pé
```

Função: primeira prática após Exame Azul e orientação de Marisol. Ritmo: aproximação terrestre → embarque voluntário → corredor aquático → desembarque em solo firme. A ponte permanece disponível, nenhuma rota é bloqueada ou se torna beco. Ambas as margens alcançáveis por caminhada; pista azul vista antes da permissão. Acesso ao Pântano por esse aprendizado é independente do resgate de Retalho.

Verificação geométrica em `marisol_row_trip_checks.gd`: rota axial curta, pontos finitos, solo andável sem rampa nas pontas, faixa lateral livre, mesma cota0, todas as células internas água0 e sem peças sólidas. Água continua bloqueada à caminhada. A travessia é movimento específico, não concessão de caminhada sobre água.

Capturas novas de toda a área, quatro enquadramentos e ambas as margens ampliadas, geometria/arte sem atores. As demais juntas do mapa não foram alteradas; sua revisão completa anterior não está sendo refeita nesta alteração.
