# Kael modular — revisão 2

No Soulgen Studio: **Projeto e biblioteca → Abrir Kael · Avatar modular**. Projetos antigos recuperados do navegador não são substituídos automaticamente. O seletor **Direção** oferece Frente, Esquerda, Direita e Costas; as 64 opções de aparência continuam disponíveis em cada vista.

## Correção artística

A revisão 1 verificava a conexão matemática dos pivôs e deixava passar mangas afastadas, contornos fechados de ombro e alças repetidas nos braços. Não era uma aprovação suficiente dos pixels ou dos extremos.

Esta revisão usa braços sem as alças douradas duplicadas, sobreposição maior entre mangas e tronco, posições próprias por direção e bases de roupa repintadas com tecido no lugar dos encaixes circulares. Aceno e comemoração têm amplitudes menores para não tratar um braço inteiro como se tivesse um cotovelo articulado. Oito peças continuam independentes. Uma articulação adicional de cotovelo seria necessária para gestos amplos mais naturais.

As costas possuem cabeça sem rosto, cabelo, roupa, pernas e mochila próprios. O perfil esquerdo é espelhado do direito: válido para este conjunto de roupas sem acessórios laterais exclusivos; roupas assimétricas precisam de arte própria. Escala e origem de renderização são comuns; profundidade e pivôs mudam conforme a vista. Não é uma rotação de uma imagem frontal.

## Entregas

- `kael-v2.soulgen.json`: projeto portátil com todas as fontes incorporadas e 64 combinações.
- `rig-data.mjs`: preset local do Studio.
- `parts/`: 45 atlas de camadas, quatro vistas cada, células de 320 px. Os recortes registrados usam a região ocupada pela peça, para seleção e foco no editor funcionarem.
- `exports/kael-four-directions.png` e `.json`: visual padrão em 480 quadros, células de 128 px, 12 FPS, seis ações por direção; 24 sequências. O pivô do PNG é `(64,110.5)` px. O atlas não é aplicado automaticamente no jogo.
- `exports/four-directions.png`: prancha comparativa de duas aparências em caminhada.

`customizeKael` seleciona texturas registradas; `setKaelDirection` seleciona recortes, posição, profundidade e pivôs da vista. Ambos preservam os clipes. Trocar de direção volta às posições de montagem registradas dessa direção: salve uma cópia antes de alterar uma montagem própria. Exportações feitas pelos botões do editor representam a direção selecionada; o atlas das quatro direções é produzido pelo script abaixo.

## Auditoria

`pixel-audit.json` registra 144 verificações: pixels opacos de manga e tronco precisam compartilhar pelo menos oito pixels numa renderização de 256 px, em duas roupas, quatro vistas e nove instantes de repouso, caminhada, corrida, aceno, dano e vitória. O controle negativo desloca deliberadamente um braço em 130 unidades e precisa detectar a desconexão. Os hashes SHA-256 vinculam o relatório aos PNGs e ao preset reais.

Isso detecta separação entre peças; não comprova qualidade de desenho, perspectiva, expressividade ou naturalidade. A revisão visual compara a prancha e as ações no Studio. Testes separados verificam 256 combinações de aparência/direção, células do atlas, retorno ao estado inicial e pivôs amostrados a 60 Hz nas seis ações.

## Fontes e reprodução

Quatro produções com a ferramenta nativa `image_gen`: frente corrigida, perfil direito, costas e bases de torso sem encaixe exposto. Referências: Kael do overworld e o kit modular anterior. Fontes PNG originais preservadas em `source/`, prompts em `prompts.json`. O build elimina alpha residual abaixo de 64/255 antes do recorte, removendo glows do fundo gerado. A troca de paleta preserva a silhueta já normalizada. O registro de cabelo traseiro ocupa uma caixa própria; não copie essa proporção para a frente.

```sh
node scripts/build-kael-avatar-v2.mjs
node scripts/audit-kael-avatar-v2.mjs
node scripts/export-kael-avatar-v2.mjs
node --test tools/soulgen-studio/kael.test.mjs
```

O jogo ainda usa o sprite anterior. Persistência na conta, seleção de roupa na campanha e expressões faciais alternativas continuam fora desta entrega. Não houve push ou deploy nesta revisão.
