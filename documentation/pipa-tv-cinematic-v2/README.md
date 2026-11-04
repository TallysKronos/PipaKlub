# Pipa TV · apresentação, pipeiros e batalha

Filme montado a partir de três clipes generativos locais, com a direção de personagens aprovada no Locutor V4. Arquivos de produção em `art/pipa-tv-cinematic-v2/`: imagens de cena, referências individuais, prompts, manifest e três workflows editáveis. Cada geração usa MiniMax H3 ref2va INT8, 20 passos, res_multistep/beta e três referências, sem nós pagos ou download de novos modelos.

## Continuidade

O locutor abre a transmissão e aponta para a arena. A câmera passa por Jamile e Gollia, mostra o manejo dos carretéis e acompanha a linha azul até o céu. O plano seguinte encontra Azulão e inicia a luta com Carcará. Linha laranja pertence a Jamile/Carcará; azul a Gollia/Azulão. Terraço de pedra, baía, balaustrada azul e dourada e luz do alto à esquerda mantêm a identidade do local.

Os clipes são independentes, interligados por montagem e dissoluções curtas de imagem/áudio. O modelo interpreta a coreografia e os gestos; não há garantia matemática de continuidade da linha em cada quadro ou de posições exatas no corte. Não representa uma simulação de gameplay nem declara vencedor.

## Reprodução

- `pipa-tv-apresentacao-pipeiros-batalha.mp4`: versão unificada de revisão, 19,42 segundos, com áudio.
- `planos.png` e `clipe-01/02/03-planos.png`: quadros de revisão.
- `montagem.json`: fontes, duração medida e caminhos de exportação.
- `godot/assets/campaign/cinematics/pipa-tv-abertura-v2.ogv`: versão Theora/Vorbis para o jogo.

A geração é 864×480 a 24 fps. A exportação 1280×720 é redimensionada, não 720p nativo. O H3 gera áudio junto com a imagem. Foi pedida uma fala curta de abertura em português; a dicção e o sincronismo labial precisam de revisão auditiva humana. Não foram introduzidas vozes clonadas de pessoas reais.

## Reproduzir a produção

Na biblioteca do ComfyUI local: **PipaTV V2 - 01 Locutor H3 local**, **02 Pipeiros H3 local**, **03 Batalha H3 local**. Os modelos usados e nomes das referências estão nos workflows e no manifest. Para outra instalação, carregar os arquivos de `fontes/` com os mesmos nomes em `input/` e selecionar os modelos locais compatíveis.

Montar saídas revisadas com `tools/assemble-pipa-tv-v2.py <01.mp4> <02.mp4> <03.mp4>`. O script preserva fontes, resampleia áudio para uma taxa comum, uniformiza tamanho/fps e usa transições de 0,16 s. `--overlap 0` permite cortes secos. O FFmpeg está instalado apenas em `tmp/video-encoder/`; o jogo usa o OGV, sem dependência de Python.

## Estado de revisão

Três clipes renderizados e montados. Inspeção visual de quadros dos três clipes e da montagem: identidade, figurino, gesto do locutor, passagem entre pipeiros, subida pelo fio e choque aéreo sem vencedor. MP4 unificado com áudio exportado (cerca de 11,6 MB), OGV para Godot exportado (cerca de 14,3 MB). Metadados de duração e presença de áudio registrados em `montagem.json`.

`opening_tv.gd` aponta localmente para o novo OGV; a versão anterior permanece em disco. O layout, o avanço das falas e os controles de pausa já existentes não foram alterados. Não houve reprodução nativa nem suíte de testes do jogo nesta etapa, seguindo a preferência do usuário; a dicção e a fluidez em reprodução completa precisam da revisão do usuário. Sem commit, push ou publicação.

Checagem estática dos caminhos de recursos: zero erros; quatro avisos preexistentes (três imports órfãos e fallback de Veredas). Não substitui reprodução no Godot.
