# Soulgen Studio — ateliê de animação

## Nozinho artesanal em três quartos

Abra `/?preset=nozinho` ou **Projeto e biblioteca → Abrir Nozinho · três quartos**. Corpo e quatro membros articulados, cinco ações e expressões registradas. O preset tem recuperação própria quando aberto pelo endereço direto. Projeto portátil, imagens e limites em [Nozinho](../../art/soulgen/keys/nozinho/README.md). Configurado para revisão; ainda não substitui o atlas antigo do jogo.

## Kael: avatar do jogador

**Projeto e biblioteca → Abrir Kael · Avatar modular** abre oito peças ilustradas, seis ações e controles de pele, cabelo e roupa. O painel oferece 64 combinações sem alterar pivôs e animações. Projeto portátil, fontes, contrato e limites de integração em [Kael modular](../../art/soulgen/keys/kael/README.md). A revisão 2 inclui frente, costas e dois perfis no seletor Direção, com atlas de 480 quadros. A persistência de aparência no jogo ainda precisa de integração. Consulte [revisão 2 e auditoria de pixels](../../art/soulgen/keys/kael-v2/README.md).

Execute `npm run studio:sprites` e abra http://127.0.0.1:5240/. A ferramenta é independente do servidor do jogo. O ateliê de tiles também oferece um atalho para ela; ambos os servidores precisam estar ligados.

## Bancada guiada

A navegação **Montar → Animar → Revisar e exportar** mostra apenas os controles relevantes à etapa. A área de trabalho ocupa a janela; biblioteca e inspector têm rolagem própria. O layout se adapta a janelas menores, com controles mais compactos em telas de pouca altura.

- **Biblioteca visual:** miniaturas dos recortes, busca por nome, visibilidade por camada, bloqueio de edição e isolamento da peça selecionada. O isolamento é só uma ajuda da prévia: não altera visibilidade salva nem exportação. A revisão restaura a criatura completa.
- **Montagem:** arraste múltiplos PNGs para a prévia ou importe todos na mesma seleção. Setas movem peça e pivô juntos; Shift move dez unidades. V ativa movimento, P ativa marcação de pivô. Enquadrar volta à vista geral; Focar peça aproxima o recorte selecionado. Centralizar pivô é um ponto de partida, não substitui a articulação anatômica.
- **Interpolação:** *Suave* para na pose (bom para golpes e assentamentos); *Contínua* passa pela pose sem parar, com a curva puxada pelas poses vizinhas e fechando o ciclo nas ações contínuas (bom para voo e repouso); *Linear* mantém velocidade constante.
- **Simplificar poses:** reduz as poses da ação ao mínimo que mantém o movimento a até 0,04 unidade e 0,15° do atual, sempre preservando início, fim e impacto. Testa poses contínuas e suaves e fica com a que precisar de menos. Depois de simplificar, só repete após uma pose nova ser gravada, para o erro não se acumular. Use em gravações densas ou importadas.
- **Atraso do movimento (acompanhamento):** cada peça pode seguir seus próprios canais com atraso de 0 a 1 s. O corpo continua liderando e a peça termina o gesto um pouco depois, como rabiola e penas. Em ações contínuas o atraso dá a volta no ciclo; em ações únicas a peça segura a primeira pose até o atraso passar.
- **Recorte automático:** remove margens totalmente transparentes preservando a posição e escala dos pixels visíveis e o pivô. Não modifica o PNG. Peças com expressões registradas mantêm obrigatoriamente o recorte canônico e não usam essa operação.
- **Animação:** a linha do tempo posiciona as poses proporcionalmente à duração e marca o impacto. Clique para buscar um instante ou use Quadro anterior/próximo e Ir ao impacto. Pose anterior mostra uma referência translúcida do quadro-chave anterior apenas na prévia.
- **Reaproveitar poses:** copiar/colar atua no canal selecionado, entre instantes ou peças; Zerar canal restaura seus deslocamentos, rotação e escalas. Essas operações criam um ajuste pendente. Grave para confirmar ou use Descartar ajuste. O editor impede trocar de etapa, ação ou instante enquanto houver um ajuste pendente, sem recorrer a uma confirmação bloqueante.
- **Diálogos integrados:** criar animação, abrir exemplo, iniciar projeto e excluir ação usam confirmações dentro da bancada, com cancelamento e foco de teclado.
- **Revisão:** a biblioteca vira uma lista de ações, com duração, ciclo e impacto. O resultado da auditoria distingue problemas técnicos de revisão artística; alterações no projeto invalidam o resultado anterior.

Projetos anteriores continuam compatíveis. O bloqueio é salvo junto da peça; busca, câmera, referência translúcida e isolamento são ferramentas da sessão e não mudam o runtime do jogo.

## Fluxo de trabalho

1. Abra o Carcará aprovado como referência ou crie um projeto vazio em **Projeto e biblioteca**.
2. Importe peças PNG transparentes. Em **Montagem**, ajuste posição, tamanho, profundidade e pivô. Arraste na fonte para definir o recorte sem modificar o PNG. O parentesco permite que uma peça herde o movimento de outra.
3. Em **Animação**, selecione uma ação e um instante. Ajuste os canais da peça ou do corpo inteiro e pressione **Gravar pose**. Há interpolação linear/suave, ações contínuas ou únicas e instante de impacto. Alterações de pose ainda não gravadas bloqueiam salvar e exportar.
4. Importe expressões com o mesmo recorte e alpha do corpo canônico. Registre as janelas faciais em pixels da peça e determine em que intervalo cada expressão aparece.
5. Confira fundo claro/escuro, espelhamento, câmera pequena, reprodução lenta e extremos das poses. Use **Auditar rig e expressões** antes de exportar.
6. Salve o projeto JSON e revise a prévia independente. A recuperação automática no navegador é uma conveniência; mantenha cópias JSON dos projetos aprovados.

**Desfazer/refazer:** botões superiores ou Ctrl+Z / Ctrl+Shift+Z. As mudanças no projeto são reversíveis durante a sessão. Abrir outro projeto e recarregar podem alterar esse histórico.

## Eremor

Em **Projeto e biblioteca → Abrir Eremor · Elo das Ruínas**, carregue o rig colorido com sete peças, cinco ações e pivôs próprios. O projeto portátil `art/soulgen/keys/eremor/eremor.soulgen.json` incorpora todos os PNGs e pode ser aberto pela ferramenta. A revisão 3 inclui expressões registradas de golpe, dano e vitória e corrige o nó atrás do braço próximo. Contrato, fontes e limites em [Eremor](../../art/soulgen/keys/eremor/README.md). A inclusão no editor não registra o boss no jogo.

A revisão **rig v2** corrige proporções e encaixes e inclui referências anatômicas opcionais no projeto. O audit compara proporção, profundidade e pontos de ligação durante as ações; avisos aparecem em amarelo e não equivalem a aprovação visual. Arquivos antigos sem essas referências continuam compatíveis. Para usar a revisão mais recente, abra o preset atual ou `eremor-v3.soulgen.json`; projetos salvos anteriormente no navegador não são substituídos automaticamente. [Relatório de revisão e testes](../../art/soulgen/keys/eremor/AUDIT-V2.md).

## Formatos de exportação

- **Projeto JSON:** peças, fontes PNG originais incorporadas, pivôs, parentesco, ações, quadros e expressões. Pode ser reaberto no editor.
- **Spritesheet PNG + metadados JSON:** exporte os dois com os mesmos FPS, célula e conjunto de ações. O JSON descreve células, duração, ciclos, impacto e pivô em pixels. O atlas tem fundo transparente.
- **Runtime Canvas JS:** motor genérico, projeto incorporado e `loadImages()`. Use `sample(project, action, seconds)` e `render(context, project, images, pose, options)` para uma integração posterior.
- **Prévia HTML:** arquivo independente com imagens incorporadas e controles de reprodução; não depende do servidor depois de baixado.
- **Brief JSON:** direção de arte e especificação das peças para o artista ou geração assistida por IA. O editor não faz chamadas automáticas a serviços de geração de imagens.

## Convenções e limites

Coordenadas de montagem usam um espaço lógico comum a todas as peças; pivôs são absolutos nesse espaço. Os canais de animação são deslocamentos, rotação em graus e escalas. O movimento global é aplicado antes dos movimentos articulados; os parentes transmitem suas transformações aos filhos. Expressões substituem o recorte do corpo, sem sobrepor outro corpo.

O preset preserva a arte de `art/soulgen/keys/carcara/color-rig` e segue `art/soulgen/DIRETRIZES-RIG-COLORIDO.md`. Não reutilize sua anatomia e coordenadas cegamente em outras espécies. O Carcará é a validação visual inicial; outras anatomias precisam de revisão própria.

A auditoria verifica estrutura, ciclos de parentesco, recortes, tempos, alpha e pixels fora das janelas faciais. Avisos de margem exigem inspeção visual. Ela não substitui revisão artística de encaixes ou silhueta.

São aceitos PNGs incorporados ou fontes locais da biblioteca Soulgen. Há limites de peças, imagens, quadros e dimensão do atlas para evitar travar o navegador. O servidor escuta somente em loopback, serve arquivos permitidos e não aceita escrita HTTP. Não acessa contas, saves, banco ou economia do jogo.

## No jogo (`?rig`)

`npm run studio:export-game` copia os rigs aprovados para `assets/creatures/rig-v1/` (PNGs originais + projeto). O build serve e versiona esses arquivos como as outras artes. Abrindo o jogo com `?rig` no endereço, o Carcará da batalha é desenhado pelo rig em vez do atlas pintado; sem a opção nada é baixado nem muda.

O rig lê o mesmo estado da batalha que o atlas: dano, especial, voo e vitória. Quando um corte acerta (contador de golpes do jogador sobe), ele toca o Golpe a partir da pose de impacto e faz a recuperação em dobro de velocidade. O motor do jogo continua decidindo cada acerto; a animação se ajusta ao acerto, nunca o contrário. Enquanto as imagens carregam, e para as outras espécies, o atlas pintado continua sendo usado.

## Preset do Carcará

O preset usa as poses do rig aprovado em vez de gravar a curva 30 vezes por segundo: Golpe, Dano e Vitória têm as mesmas poses suaves do rig (6, 6 e 5 poses, sem diferença de movimento); Repouso e Voo usam 13 poses contínuas por ciclo (diferença máxima de 0,06°). Projetos salvos antes desta mudança continuam abrindo como estavam; para enxugar uma ação antiga, use **Simplificar poses**. O atraso fica desligado no preset: o movimento aprovado não muda.

## Validação

`node --test tools/soulgen-studio/model.test.mjs tools/soulgen-studio/workflow.test.mjs tools/soulgen-studio/editor.test.mjs tools/soulgen-studio/server.test.mjs art/soulgen/keys/carcara/color-rig/rig.test.mjs`

Os testes cobrem fidelidade do preset, composição hierárquica, amostragem, histórico, validação de projetos, atlas, isolamento do servidor, proteção das poses pendentes, bloqueio, busca, copiar/colar e fluxo real dos controles em DOM. A ferramenta ainda não aplica automaticamente os rigs no combate do jogo.

## Básicos e Rabbito — rigs coloridos

A biblioteca agora abre Mata verde, Azulão, Raio de sol e Rabbito, com cinco ações, expressões registradas e contratos de proporção/encaixe. Compare em `/basics-review.html` ou abra `/?preset=rabbito` (também mata-verde, azulao e raio-de-sol). Fontes, projetos portáteis e método em [lote de papel artesanal v2](../../art/soulgen/keys/basic-color-v2/README.md). A integração autorizada gera atlas de combate/coleção e acompanhamento com `export-starters.mjs`, usando a hierarquia manual salva do Rabbito. Editar no Studio não atualiza o jogo automaticamente: reexporte e gere os builds.

A revisão v2 usa o Carcará como referência de desenho: olhos pequenos/escuros, remendos costurados e papel facetado. Os presets abrem a nova geometria; projetos v1 e fontes anteriores continuam preservados.

Guaravento: `/?preset=guaravento`, oito peças, cinco ações e recuperação isolada. Não altera o atlas do jogo.

Micofolha: `/?preset=micofolha`, oito peças em três quartos e cinco ações, recuperação isolada. Fontes e roteiro reproduzível em `art/soulgen/keys/micofolha/`.

Capimansa: `/?preset=capimansa`, oito peças com profundidades distintas, cinco ações e recuperação isolada.

Tatutrama: `/?preset=tatutrama`, sete peças, cinco ações e recuperação isolada. Carapaça e corpo em uma peça, sem vela extra.

## Transformar uma peça

Selecione um elemento e use “Transformar esta peça” no inspetor: tamanho percentual proporcional, giro em graus, atalhos de tamanho/giro e inversão horizontal/vertical. Atua somente na arte dessa peça, ao redor do pivô, em todas as animações. Filhos e canais de animação não são alterados. Desfazer e Salvar projeto preservam os ajustes em artTransform. “Restaurar” retorna à transformação visual original. Peças bloqueadas desativam esses controles.

Flautrevo: `/?preset=flautrevo`, quatro peças, cinco ações, recuperação isolada e transformações por elemento.

Trinca-brasas: `/?preset=trinca-brasas`, nove peças, três cabeças articuladas e cinco ações. Recuperação isolada.

Alvaneve: `/?preset=alvaneve`, nove peças e cinco ações. Montagem preserva a proporção original de todos os recortes; preserveSourceAspect faz o exportador rejeitar esticamento.

Chaspiral: `/?preset=chaspiral`, seis peças proporcionais, cinco ações e ambos os braços animados. Recuperação isolada.

Hiponilo: `/?preset=hiponilo`, oito peças proporcionais e cinco ações. Recuperação isolada.

Marulume: `/?preset=marulume`, quatro peças proporcionais, cinco ações de nado e recuperação isolada.

Jarabrasa: `/?preset=jarabrasa`, quatro peças proporcionais, cinco ações e recuperação isolada.

Jaguarluar: `/?preset=jaguarluar`, oito peças proporcionais e cinco ações. Faces registradas da cabeça canônica. Recuperação isolada.

Azulongo: `http://127.0.0.1:5240/?preset=azulongo` — cabeça chibi, cinco peças articuladas e cinco ações. Cache separado; projeto portátil e revisão em `art/soulgen/keys/azulongo/color-rig-v2/`.

Umbrocasco: `http://127.0.0.1:5240/?preset=umbrocasco` — sete peças e cinco ações; casco de filtro dos sonhos e serpente.

Nevagume: `http://127.0.0.1:5240/?preset=nevagume` — sete peças editáveis, cinco ações e filtro dos sonhos.

Rexal: `http://127.0.0.1:5240/?preset=rexal` — oito peças proporcionais, vela de bambu e cinco ações.

Tricerafan: `http://127.0.0.1:5240/?preset=tricerafan` — oito peças, três chifres e leque independente.

Stegaru: `http://127.0.0.1:5240/?preset=stegaru` — oito peças, placas dorsais de pipa e cinco ações.
