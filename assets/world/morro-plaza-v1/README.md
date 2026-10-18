# Praça da Chegada — fatia pintada para Tiled

Estado: integrado localmente, em revisão artística. Não publicado.

Atualização: o piloto agora usa a sequência de cinco áreas descrita em `../morro-road-v1/README.md`. `road-1.tmj` é a primeira área com somente Zeca e passagem bloqueada até a vitória. `plaza.tmj` conserva o estudo anterior de dois encontros para comparação e testes; não representa o fluxo atual da sequência.

Abra `plaza.tmj` no Tiled. São 1536 × 1024 px, grade de 32 px, seis camadas de objetos e duas camadas de imagem. A praça, oficina e escadaria estão conectadas ao patamar. A entrada tem colisões e uma região de oclusão da cobertura. A árvore é uma PNG RGBA separada, ordenada pelo apoio dos pés; a copa reduz sua opacidade quando cobre o jogador. Kael usa altura de 64 px e volume conservador de 24 × 24 px nos pés.

## Arquivos e procedência

- `plaza-base-v1.png`: chão e arquitetura pintados para esta fatia; RGB, 1536 × 1024.
- `plaza-tree-v1.png`: primeiro plano com alpha; RGBA, 1536 × 1024. A área transparente conserva o alinhamento original, com custo de memória ainda a otimizar em produção.
- `manifest.json`: registro fechado das imagens e dimensões, usado pelo build e pelo servidor de assets.
- `prompts.json`: prompts completos da ferramenta integrada image_gen. A imagem guia do bairro foi usada como referência de arquitetura e composição, sem aplicação direta do mapa inteiro como fundo.
- `plaza.tmj`: áreas caminháveis, bases físicas, encontros, entrada, saída, suporte da árvore e camadas visuais.

As coordenadas de colisão foram desenhadas depois de inspecionar a imagem realmente entregue; não foram presumidas a partir do prompt. O carregador valida dimensões e nomes registrados. Não usa URLs de imagens fornecidas pelo mapa em requisições arbitrárias.

## Acesso e compatibilidade

`?overworld=pilot` usa esta fatia do Morro. `?overworld=blockout` conserva a planta modular anterior para comparação. A campanha normal mantém o mapa completo e seus cinco encontros; os dois encontros desta fatia não alteram as regras de progressão.

Esta etapa acrescenta suporte limitado a camadas de imagem do Tiled, não um importador geral de tilesets, GIDs ou mapas infinitos. O Ateliê recém-integrado trabalha com projetos de seis camadas de objetos e kit recortado; ainda não importa este TMJ de oito camadas. A edição desta fatia deve ser feita no Tiled até ampliar explicitamente o contrato do Ateliê. Não converter ou sobrescrever uma bancada salva do usuário.

## Verificação e pendências

MCP Tiled: zero erros e avisos nas classes verificadas. Testes verificam caminhos, mudanças de piso, impedimento de atravessar os muros, recortes, alpha, profundidade, publicação dos assets e rejeição de imagens não registradas. Builds Worker e Pages e validação ESM executados. A inspeção local conferiu Kael no chão da praça e nos degraus. Testes geométricos não equivalem a aprovação artística.

Após puxar o commit f5516a3, o consumidor também usa os novos NPCs chibi e preserva o quintal modular do outro trabalho. A próxima revisão visual deve comparar densidade e saturação da árvore, escala dos personagens e limites do portão; a árvore ainda tem uma franja suave de cor que deve ser revista antes de aprovação artística. Casas continuam na camada de arquitetura; não há interiores, população dinâmica ou o bairro inteiro nesta fatia.
