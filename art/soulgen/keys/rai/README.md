# Rai / Saber — parceiro do Tyler

## Projeto do dono incorporado

Recebido `rai-saber-parceiro-do-tyler.soulgen.json` com autorização de envio. Preservados retângulos, pivôs, hierarquia, pixels embutidos e os seis clipes do arquivo. Original integral em `cutout-rig-v1/author-approved.portable.soulgen.json`; hash em `author-import.json`. Rig ativo revision 2, artRevision 1. Auditoria de juntas recalibrada aos encaixes do autor, sem resetar sua geometria. O exportador reusa esse projeto aprovado por padrão. Rascunhos de revisão anterior no navegador são arquivados antes de abrir o atualizado.

Reexportados oito componentes, quatro rostos e 132 frames sem corte nas bordas; 18 testes passaram com a regressão do Platyx e do sampler/editor. Importação não integra no jogo nem cria nova espécie para o alias Saber.

Rai é o nome na bíblia; Saber é o nome anterior da prancha existente, não outra espécie. Identidade recuperada de `origin/feature/retalho-bosque-d:art/tyler-saber-manga-v2/saber-sheet-v2.png`, com cópia/hash em `art/soulgen/campaign-redesigns-v1/references/rai-saber-git/`. A referência original não foi sobrescrita, e não houve renomeação automática de IDs do jogo.

Conversão spritelizada com image_gen nativo: tigre branco de sabre, olhos vermelhos, manchas rosadas em losango, patas escuras, colar vermelho/sino pequeno, vela dorsal vermelho-creme com flor e armação de bambu, rabiola de quatro pétalas. Carcará e Tufanocorte fornecem somente o acabamento de contorno em degraus e sombras em blocos. Não substitui o tigre por um novo monstro e não transforma as marcas em remendos.

Oito partes: torso, cabeça, quatro pernas, vela e rabiola **com fio completo**, ligada à vela por parentesco/pivô. Todas as expressões contêm cabeça completa, orelhas, dentes e colar/sino; sem overlay que faça a face desaparecer. Mantidos os dois dentes longos no ataque.

Seis ações em revisão: vigília, passo do sabre (`flight` é ID técnico, não voo definido), bote, dano, vitória serena e derrota. Impacto proposto em 0,62 s; não define dano, habilidade, distribuição ou narrativa canônica. O passo é animação por recortes rígidos e não um ciclo redesenhado quadro a quadro.

Abrir `http://127.0.0.1:5241/?preset=rai` ou Projeto e biblioteca → Rai / Saber. `?preset=saber` também carrega o mesmo projeto com ID rai; armazenamento do navegador é separado por URL e não cria outro arquivo de criatura. Projeto portátil e prévia HTML independente em `cutout-rig-v1/`.

Verificado: estrutura, fontes, oito peças, quatro cabeças inteiras, seis clipes, fim de derrota, loops, marcador, articulações e cauda ligada à vela. 132 frames/12 fps sem corte nas bordas. Inspecionada montagem em repouso, passo, bote, dano e vitória em fundos claro e escuro. Cabeça, sobreposição dos membros e base da vela continuam sujeitos à revisão interativa do dono. Não integrado no jogo ou publicado por push nesta entrega.
