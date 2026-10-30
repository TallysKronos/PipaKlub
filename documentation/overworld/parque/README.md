# Jardim das Pipas — revisão em platôs

A parte A foi refeita em 48×40, com praça do coreto elevada, pomar, mirante, quatro materiais e mato opcional. Brief, percurso automatizado e limites em [relatório da entrega](relatorios/entrega-jardim.md). Capturas em captures/jardim-das-pipas/ e comparação em comparativo-jardim/. Clareira e Veredas ainda usam as plantas anteriores. O registro PIP-85 abaixo é histórico.

# PIP-85 — revisão nativa

**Correção vigente: volume e piso anterior restaurado.** A composição v2 foi rejeitada porque a mata estava sendo desenhada no chão e a nova grama piorou o acabamento. A folhagem foi removida dos materiais de piso e substituída por sprites de arbustos com sombra e profundidade próprias. A família anterior de pisos foi restaurada. Evidências novas em `correcao-volume/depois/`; captura rejeitada preservada em `correcao-volume/antes/`.

**Revisão atual: composição v2.** Árvores da planta reduzidas de 44 para 27 nas duas áreas; preenchimentos automáticos removidos; grama nova e bordadura baixa, com menor contraste. Duas árvores centrais foram levadas para os jardins laterais. Evidências anteriores preservadas em `composicao-v2/antes/`, atuais em `composicao-v2/depois/`. Pesquisa e decisões em `composicao-v2/PESQUISA-E-DIRECAO.md`. As descrições abaixo também registram a etapa inicial; na versão atual as árvores obedecem às plantas revisadas, não às posições antigas.

O kit do Parque foi produzido e montado na prévia Godot, com posições derivadas das plantas. As imagens de conceito aproximadas não são fundos do jogo. Árvores e móveis do kit comum permanecem nas posições originais.

Revisão gráfica em Godot 4.7.2/OpenGL, 1280×720: Jardim inteiro, coreto, entrada do Jardim, Clareira inteira, capim e entrada da Clareira. A captura 1280×800 verifica a composição no formato do Steam Deck, sem alegar revisão em hardware físico. A sequência `vento-*.png` documenta o balanço das touceiras; `capim-vento.gif` reúne esses quadros.

Na primeira passagem, o coreto inteiro ficava transparente e o capim tinha halo. A revisão separou telhado e pilares para profundidade/transparência individuais e normalizou o recorte do capim. O gramado continua uma pintura comum; o capim de encontros é uma camada independente, com raiz fixa, duas formas e fases variadas. Preferência de movimento reduzido zera o vento.

A planta do Jardim agora contém cinco pequenos bloqueios de pilar em vez de uma pegada inteira bloqueada. A compilação padrão conferiu essa fonte e exportou os dois mapas. Isso não é prova de percurso jogado: não foi feita simulação de controles, não houve suíte de testes nem alteração de saves ou regras de batalha.

Reprodução: `godot --path godot --script res://tools/parque_capture.gd`. A ferramenta salva somente capturas e encerra. Fontes, âncoras, tamanhos, produção e limites em `art/overworld/kits/parque/README.md`. A PIP-85 segue em andamento para aprovação visual final e conferência de percurso quando solicitada.
