# PIP-87 — cinco estudos de identidade do Morro

Os cinco `*-estudo-v2.png` foram gerados com `image_gen.imagegen` a partir das referências da PIP-81, da esquina de estilo do Morro e da arte antiga usada somente para conteúdo. A Praça também foi usada como referência de família para as outras áreas. Os prompts integrais estão em `geracao-v2.json`.

| Área | Marco e intenção |
|---|---|
| Praça da Chegada | Praça aberta, portão e bancada de pipas |
| Escadaria da Sombra | Árvore grande, sombra no patamar e varal |
| Laje dos Ventos | Área ensolarada, varais e banca com toldo |
| Mirante da Caixa-d’água | Caixa azul, guarda-corpo e cidade distante |
| Parque dos Ventos | Gramado livre, árvore e abrigo com bandeirolas |

Os briefs registram hashes, peças, eventos e rampas das plantas atuais. As pinturas são estudos de identidade: não foram aprovadas pelo proprietário nem verificadas como alinhamento de pixels. Há interpretações que não devem virar regra de jogo: escada secundária na Praça, caixas-d’água decorativas repetidas em outras pinturas e alterações de fachada/contorno. Os marcos de runtime permanecem nas posições do mapa, não nas posições reinterpretadas pela imagem.

A montagem Godot é uma etapa separada. Foram integrados marcos, seis fachadas, acessos, guarda-corpo e identidade de piso/varal da Laje; ela ainda não reproduz todos os acabamentos desses estudos. Evidências em `documentation/overworld/morro-pip87/`. Não usar as pinturas como fundo único nem remover a arte antiga da campanha sem a integração correspondente.
