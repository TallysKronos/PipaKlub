# NPCs — bases direcionais Soulmon DS

Professor Assis, mãe do Kael, Nina, Bia, Juninho, Lia, Zeca e Tião, seguindo o Kael atual aprovado. Cada personagem tem oito vistas estáticas: S, SO, O, NO / N, NE, E, SE. São 64 poses ao todo, não 64 quadros de caminhada.

Célula 64×96, pivô 32,94, pés na linha 94, alpha binário e até 32 cores opacas. Alturas relativas preservam os adultos maiores que as crianças. Uma paleta por personagem mantém suas próprias roupas, pele e cabelo; não se força a paleta azul do Kael em todo o elenco.

## Arquivos

`pacote/<personagem>/` contém folha PNG `*-directions.png`, projeto Pixelgen, documento Aseprite indexado com oito tags `idle-*`, prévia ampliada 3× e manifesto. Os quadros exportados pelo Aseprite são comparados pixel a pixel ao projeto Pixelgen; resultados em `qa.json`. `todos-1x.png` mostra as oito vistas no tamanho nativo e `elenco-3x.png` reúne o elenco. `npc-directions-v1.zip` agrupa as entregas atuais.

As fontes geradas e suas versões anteriores ficam em `fontes/`; `brief.json` registra os prompts, referências de identidade, escala pretendida e a associação manual das células. Geração pela ferramenta de imagem integrada, seguida de normalização de grade/paleta e acabamento no Aseprite headless. A normalização automática não equivale a desenho manual de cada cluster ou aprovação visual do usuário.

## Revisão

A revisão independente inicial deu 8/10, sem bloqueios, para professor, mãe, Bia, Juninho, Zeca e Tião. Encontrou dois bloqueios no primeiro candidato: a bolsa da Nina trocava de lado nas diagonais e a quantização tornava marrons os shorts ameixa da Lia. A Nina recebeu uma correção das diagonais na fonte; os shorts da Lia receberam uma rampa ameixa aplicada em regiões específicas no documento nativo. As versões anteriores foram preservadas para comparação.

A comparação independente escolheu as duas versões corrigidas, ambas com 8/10 e sem bloqueios remanescentes. Também foram substituídos por tinta azul-escura os pretos RGB puros que o desenho em documento indexado confundia com o índice transparente. Os 64 quadros finais exportados pelo Aseprite coincidem exatamente com o Pixelgen, incluindo alpha e cores. Essa revisão não substitui a aprovação artística do usuário.

O pequeno símbolo da bolsa, o crachá e o fio do carretel foram simplificados em favor da leitura. Não há fio solto nos carretéis. As vistas de costas não mostram o rosto. O boné do Juninho continua virado para trás.

## Escopo

Este lote produz bases direcionais editáveis. Após aprovação do pacote, o usuário pediu a aplicação no jogo: a integração local está registrada em `documentation/pixelgen/npc-in-game-v1/`, com cópias em `godot/assets/npc-ds/`. Os retratos dos diálogos e os saves permanecem separados. O pacote ainda não contém ciclos de caminhada, subida de escada ou gestos. Esses movimentos precisam de poses próprias e revisão em movimento; girar ou deslocar estas bases não os substitui.
