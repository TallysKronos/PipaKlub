# Lacertubo · Estudo B

Alternativa visual independente, criada a partir da montagem salva pelo usuário
em 24/10/2026. As pernas entram sob o papel do tronco; suas bocas de cano foram
substituídas por terminações fechadas de papel. O PVC permanece nas articulações.
A vela dorsal foi reduzida em 18% em torno do pivô de inserção.

Comparação animada: http://127.0.0.1:5261/lacertubo-compare.html

Editor: http://127.0.0.1:5261/?preset=lacertubo-v2

O preset B usa uma chave própria de recuperação do navegador. A montagem A foi
arquivada em `../lacertubo/user-adjustment/user-saved.soulgen.json`, com todos os
pivôs, posições, hierarquia e animações do arquivo enviado; apenas as imagens
embutidas foram referenciadas pelos mesmos PNGs originais do projeto.

`source/parts-v2.png`: fonte gerada por image_gen. Prompt em `production.json`.
`color-rig-v2/lacertubo-v2.soulgen.json`: projeto editável com seis ações.
`color-rig-v2/comparison.png`: mesma escala e pose para A e B.
`color-rig-v2/study-atlas.png` e `export.json`: exportação offline a 12 fps.

Recriar os arquivos: `node scripts/build-lacertubo-study-b.mjs`.
Esse comando não escreve no atlas do jogo. Sem substituição do boss ou deploy.
Foram feitas inspeção da prancha e validação de exportação; não foram rodados
testes de gameplay.
